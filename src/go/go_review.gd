## Reads a finished game back and reports what actually happened in it.
##
## Pure RefCounted like the rest of src/go/: no Node, no UI, no autoload. It is
## handed a GoGame and returns findings. Who says them out loud, and in whose
## voice, is somebody else's problem entirely -- see src/go_ui/go_review.gd.
##
## There is no engine here and none is wanted. Every finding is derived from the
## rules alone: a group that had one liberty and died is a fact about the board,
## not an opinion about it. Those are exactly the mistakes that matter at the
## strength this game is about, and they cost nothing to find. An engine would
## add "this move was worth four points rather than nine", which is a sentence
## no beginner can act on.
class_name GoReview
extends RefCounted

## At most this many things are said about one game. Three is a review; ten is
## a telling-off, and this is a game about somebody who has just started.
const MAX_FINDINGS := 3

## The player strength at which each kind becomes worth mentioning, as a GoRank
## strength value. The order is Yasuda's -- the same one the lessons follow --
## so you are told about atari long before you are told about the first line.
const MIN_STRENGTH := {
	"atari_ignored": 0,
	"own_eye_filled": 0,
	"good_capture": 0,
	"good_save": 0,
	"self_atari": 8,          # 22k
	"died_savable": 10,       # 20k
	"capture_missed": 12,     # 18k
	"first_line_early": 15,   # 15k
	"ladder_failed": 15,      # 15k
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
	var all: Array[Dictionary] = []
	GoReviewDetectors.run_all(ctx, all)
	return select(all, player_strength)


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


## Filters by what the player is ready to hear, then picks the three to say.
static func select(all: Array[Dictionary], player_strength: int) -> Array[Dictionary]:
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


static func _by_move(a: Dictionary, b: Dictionary) -> bool:
	return int(a["move_index"]) < int(b["move_index"])


static func _worst_first(a: Dictionary, b: Dictionary) -> bool:
	if not is_equal_approx(float(a["severity"]), float(b["severity"])):
		return float(a["severity"]) > float(b["severity"])
	return int(a["move_index"]) < int(b["move_index"])


# --- querying the replay -----------------------------------------------------
#
# These live here rather than with the detectors because they are all about the
# positions positions_of() produced: how to read one, how to ask what happened
# to a group after it, and how to remember a group you have already discussed.

## A read-only board for position `k`. Packed arrays are copy-on-write, so this
## shares the stored cells until somebody writes to them -- see mutable_at().
static func board_at(ctx: Dictionary, k: int) -> GoBoard:
	var b := GoBoard.new(int(ctx["size"]))
	b.cells = ctx["positions"][k]
	return b


## A board for position `k` that is safe to place stones on.
static func mutable_at(ctx: Dictionary, k: int) -> GoBoard:
	var b := GoBoard.new(int(ctx["size"]))
	b.cells = ctx["positions"][k].duplicate()
	return b


## The move index at which any of `stones` was taken off, or -1 if they lived.
static func captured_at(ctx: Dictionary, from_index: int,
		stones: PackedInt32Array) -> int:
	var want := {}
	for s in stones:
		want[s] = true
	var moves: Array = ctx["moves"]
	for k in range(maxi(from_index, 0), moves.size()):
		for c in moves[k]["captured"]:
			if want.has(c):
				return k
	return -1


static func intersects(a: PackedInt32Array, b: PackedInt32Array) -> bool:
	var want := {}
	for s in b:
		want[s] = true
	for s in a:
		if want.has(s):
			return true
	return false


## A stone of `stones` that was already on the board, and the player's, at the
## position `board` describes -- or -1 if the group is entirely new. Detectors
## reason about a group as it stood earlier, and the captured set they are
## handed is the group as it ended.
static func representative(board: GoBoard, stones: PackedInt32Array,
		colour: int) -> int:
	for s in stones:
		if board.get_idx(s) == colour:
			return s
	return -1


## Groups are remembered stone by stone rather than as a set, because a chain
## that grows between the atari and the capture is still, to the person who
## lost it, the same group. Telling them about it twice is not a review.
static func mark_group(reported: Dictionary, stones: PackedInt32Array) -> void:
	for s in stones:
		reported[s] = true


static func already_reported(reported: Dictionary, stones: PackedInt32Array) -> bool:
	for s in stones:
		if reported.has(s):
			return true
	return false


## Identifies a group so the same one is not reported twice.
static func group_key(stones: PackedInt32Array) -> String:
	var a := Array(stones)
	a.sort()
	return str(a)


static func finding(kind: String, index: int, cells: PackedByteArray,
		points: PackedInt32Array, severity: float, good: bool = false,
		detail: Dictionary = {}) -> Dictionary:
	return {
		"kind": kind, "move_index": index, "cells": cells, "points": points,
		"severity": severity, "good": good, "detail": detail,
	}
