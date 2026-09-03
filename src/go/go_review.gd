## Reads a finished game back and reports what actually happened in it.
##
## Pure RefCounted like the rest of src/go/: no Node, no UI, no autoload. It is
## handed a GoGame and returns findings. Who says them out loud, and in whose
## voice, is somebody else's problem entirely -- see src/go_ui/go_review.gd.
##
## Every finding is derived from the rules: a group that had one liberty and
## died is a fact about the board, not an opinion about it. What is priced on
## top of that -- how much a mistake cost in points -- comes from a GoEvaluator,
## which is arithmetic on settled regions today and could be an engine later
## without any of this changing. See go_evaluator.gd for why that is a seam.
class_name GoReview
extends RefCounted

## At most this many things are said about one game. Three is a review; ten is
## a telling-off, and this is a game about somebody who has just started.
const MAX_FINDINGS := 3

## How far after a mistake to look for its consequence when pricing it. Six of
## the player's own moves: long enough for a group to actually come off the
## board, short enough that the next mistake is not billed to this one.
const COST_WINDOW := 12

## Below this many moves there is no game to have played well. Twelve rather
## than twenty: a 9x9 that ends by resignation on move fifteen is a short game
## but a real one, with real mistakes in it, and the bar only has to be high
## enough to exclude somebody who sat down and immediately quit. The fallback
## compliment must not fire on a three-move resignation: MatchBridge skips the
## review entirely when there are no findings, and that is the mechanism by
## which somebody who sits down and immediately resigns is not walked through
## it. A consolation prize for that is worse than silence.
const ENOUGH_GAME := 12

## The player strength at which each kind becomes worth mentioning, as a GoRank
## strength value.
##
## This used to follow the lesson order, on the theory that the review should
## teach in the order the classes do. That was wrong: the lessons are ordered by
## what builds on what, and a review has to be ordered by what the player can
## act on tomorrow. "You could have taken those two stones" is the easiest
## sentence in Go to act on and it used to wait until 18k -- above the band
## where most of the game is actually played. So the gate now holds back only
## the kinds that genuinely need a stronger reader, and everything else is
## ranked by what it cost rather than hidden.
const MIN_STRENGTH := {
	"atari_ignored": 0,
	"capture_missed": 0,
	"died_savable": 0,
	"own_eye_filled": 0,
	"dead_group_fed": 0,
	"filled_own_territory": 0,
	"big_swing": 0,
	"good_capture": 0,
	"good_save": 0,
	"atari_answered": 0,
	"nothing_broke": 0,
	"best_moment": 0,
	"self_atari": 8,          # 22k
	"cut_ignored": 10,        # 20k
	"ladder_failed": 15,      # 15k
	"should_have_passed": 15, # 15k
}

## What to go and study after hearing a finding. Ids are lessons in
## data/lessons/; an empty string means the finding recommends nothing, and an
## id that does not exist degrades to no recommendation rather than an error.
##
## first_line_early is deliberately absent from this file entirely: the opponent
## now says it at the table, on the move, through GoTableTalk's "edge_early".
## Said on move eight it is a nudge; repeated on the result screen it is a
## lecture about a game that is already over.
const CONCEPT := {
	"atari_ignored": "liberties",
	"self_atari": "liberties",
	"capture_missed": "capture",
	"dead_group_fed": "life_and_death",
	"died_savable": "escape",
	"cut_ignored": "connection",
	"own_eye_filled": "two_eyes",
	"ladder_failed": "ladders",
	"filled_own_territory": "counting",
	"should_have_passed": "counting",
}


## The whole of the public surface. `player_colour` is GoBoard.BLACK or WHITE;
## `player_strength` is a GoRank value, or -1 for unranked.
static func findings(game: GoGame, player_colour: int,
		player_strength: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if game == null or game.moves.is_empty():
		return out
	var positions := positions_of(game)
	if positions.is_empty():
		return out
	var ctx := {
		"size": game.size(),
		"colour": player_colour,
		"enemy": GoBoard.opponent(player_colour),
		"moves": game.moves,
		"positions": positions,
	}
	var evaluator := GoProgress.new()
	evaluator.prepare(ctx, game.komi)
	ctx["evaluator"] = evaluator

	var all: Array[Dictionary] = []
	GoReviewDetectors.run_all(ctx, all)
	GoReviewDetectorsShape.run_all(ctx, all)
	tally(all)
	price(all, ctx)
	return select(all, player_strength, ctx)


## Every position the game passed through. `positions_of(g)[k]` is the board as
## it stood *before* move k, so the last entry is the final position.
##
## Returns [] when the replay does not reproduce the game's own board -- a
## position set wholesale by set_position() (a puzzle, a lesson) cannot be
## rebuilt from a move list, and reviewing the wrong board is worse than
## reviewing nothing.
static func positions_of(game: GoGame) -> Array:
	var b := GoBoard.new(game.size())
	if game.handicap >= 2:
		for i in GoGame.handicap_points(game.size(), game.handicap):
			b.set_idx(i, GoBoard.BLACK)
	var out: Array = [b.cells.duplicate()]
	for m in game.moves:
		var p: int = int(m["point"])
		if p >= 0:
			b.place(p, int(m["color"]))
		out.append(b.cells.duplicate())
	if b.cells != game.board.cells:
		return []
	return out


## Stamps every finding with how many of its kind the game contained.
##
## Only one instance of a kind is ever said out loud, so without this the count
## is thrown away -- and "you did that four times" is a different sentence from
## "you did that", and a more useful one. Detectors that already fold their own
## instances together (a group fed six stones is one finding, not six) pass
## their own count and keep it.
static func tally(all: Array[Dictionary]) -> void:
	var counts := {}
	for f in all:
		counts[f["kind"]] = int(counts.get(f["kind"], 0)) + 1
	for f in all:
		if int(f.get("instances", 1)) <= 1:
			f["instances"] = int(counts[f["kind"]])


## Fills in what each mistake actually cost, in points, from the evaluator.
##
## Severity was an ad-hoc scalar per detector -- "stones + 3" here, a flat 5.0
## there -- which ranked instances of one kind sensibly and instances of
## different kinds not at all. Points are comparable across kinds, so the worst
## thing that happened in the game can be found rather than guessed at. Severity
## survives as the tiebreak, and as the whole answer when no evaluator is
## available.
static func price(all: Array[Dictionary], ctx: Dictionary) -> void:
	var ev: GoEvaluator = ctx.get("evaluator", null)
	if ev == null or not ev.available():
		return
	for f in all:
		if bool(f.get("good", false)):
			continue
		var from_i: int = int(f["move_index"])
		var detail: Dictionary = f.get("detail", {})
		# A finding that knows when its consequence landed prices itself over
		# exactly that window; everything else gets the default lookahead.
		var to_i: int = int(detail.get("died_at", from_i + COST_WINDOW)) + 1
		f["cost"] = maxf(ev.lead_after(from_i) - ev.lead_after(to_i), 0.0)


## Filters by what the player is ready to hear, then picks the three to say.
static func select(all: Array[Dictionary], player_strength: int,
		ctx: Dictionary = {}) -> Array[Dictionary]:
	var strength: int = maxi(player_strength, 0)
	var good: Array[Dictionary] = []
	var bad: Array[Dictionary] = []
	for f in all:
		if strength < int(MIN_STRENGTH.get(f["kind"], 0)):
			continue
		if bool(f.get("good", false)):
			good.append(f)
		else:
			bad.append(f)
	good.sort_custom(_worst_first)
	bad.sort_custom(_worst_first)

	# P5: losing is content, not punishment. A review opens with something the
	# player actually did, and only then says what went wrong.
	#
	# This used to be conditional on there being any praise to give, which meant
	# the games it was written for -- the bad ones -- were the likeliest to open
	# on a criticism. If nothing good happened, say that honestly rather than
	# skipping the slot: a game with no disasters in it is worth being told.
	if good.is_empty():
		var consolation := _nothing_broke(bad, ctx)
		if not consolation.is_empty():
			good.append(consolation)

	var out: Array[Dictionary] = []
	var said := {}
	if not good.is_empty():
		out.append(good[0])
		said[good[0]["kind"]] = true
	# One of each kind. A beginner who ignored four ataris has made one mistake
	# four times, not four mistakes, and hearing the same sentence three times
	# teaches less than hearing three different ones. The worst instance stands
	# for the rest, because `bad` is already sorted worst-first.
	for f in bad:
		if out.size() >= MAX_FINDINGS:
			break
		if said.has(f["kind"]):
			continue
		out.append(f)
		said[f["kind"]] = true
	# A game with nothing to criticise still deserves the rest of the praise.
	if bad.is_empty():
		for i in range(1, good.size()):
			if out.size() >= MAX_FINDINGS:
				break
			if said.has(good[i]["kind"]):
				continue
			out.append(good[i])
			said[good[i]["kind"]] = true

	# Chosen by weight, but told in order. A review walks forward through the
	# game the way the game was played; jumping from move 100 back to move 12
	# is a list of grievances rather than a retelling. The opening compliment
	# keeps its place at the front regardless of when it happened.
	if out.size() > 2:
		var rest := out.slice(1)
		rest.sort_custom(_by_move)
		out = [out[0]] as Array[Dictionary]
		out.append_array(rest)
	return out


## The fallback compliment, for a game in which nothing went visibly right.
## Needs the final position to draw, so it is only available when select() was
## given the context -- a bare select() call keeps the old behaviour.
static func _nothing_broke(bad: Array[Dictionary], ctx: Dictionary) -> Dictionary:
	if not ctx.has("positions"):
		return {}
	var positions: Array = ctx["positions"]
	if positions.size() <= ENOUGH_GAME:
		return {}
	# Never after a resignation. "Nothing went badly wrong in that one" is not a
	# thing to say to somebody who has just given up: they resigned because they
	# thought it was hopeless, and telling them it was clean either calls them a
	# coward or calls the review a liar. best_moment still covers the slot.
	for m in ctx.get("moves", []):
		if int(m.get("point", 0)) == GoGame.RESIGN \
				and int(m.get("color", 0)) == int(ctx.get("colour", 0)):
			return {}
	# Only honest when the game really was tidy. Losing four groups and being
	# told nothing went wrong is worse than being told nothing at all.
	for f in bad:
		if float(f.get("cost", 0.0)) >= 8.0:
			return {}
	return finding("nothing_broke", positions.size() - 1, positions[-1],
		PackedInt32Array(), 0.0, true)


static func _by_move(a: Dictionary, b: Dictionary) -> bool:
	return int(a["move_index"]) < int(b["move_index"])


## Worst first: what it cost, then how bad the shape of it was, then when. Cost
## is zero for praise and for every finding when no evaluator ran, in which case
## this falls back to exactly the old severity ordering.
static func _worst_first(a: Dictionary, b: Dictionary) -> bool:
	var ca := float(a.get("cost", 0.0))
	var cb := float(b.get("cost", 0.0))
	if not is_equal_approx(ca, cb):
		return ca > cb
	if not is_equal_approx(float(a["severity"]), float(b["severity"])):
		return float(a["severity"]) > float(b["severity"])
	return int(a["move_index"]) < int(b["move_index"])


## `instances` is how many times this kind fired before one was picked to stand
## for the rest -- "you did that four times" is a different and better sentence
## than "you did that". `cost` is filled in later by price(); `concept` is what
## to go and study, from CONCEPT.
static func finding(kind: String, index: int, cells: PackedByteArray,
		points: PackedInt32Array, severity: float, good: bool = false,
		detail: Dictionary = {}, instances: int = 1) -> Dictionary:
	return {
		"kind": kind, "move_index": index, "cells": cells, "points": points,
		"severity": severity, "good": good, "detail": detail,
		"cost": 0.0, "instances": instances,
		"concept": str(CONCEPT.get(kind, "")),
	}
