## The three things a review is allowed to be pleased about.
##
## Separate from the mistakes because P5 makes them structurally different, not
## just tonally: the review is *required* to open with one of these, so they are
## not optional content that happens to be positive. A game that produced none
## of them is a bug in this file, not a quiet game -- which is why the
## thresholds here are deliberately generous where the mistake detectors are
## deliberately conservative.
class_name GoReviewDetectorsGood
extends RefCounted

## How long a rescued group has to stay on the board before the rescue counts.
## Roughly four of the player's own moves -- long enough that it was a real
## escape rather than a one-move reprieve, short enough that credit does not
## depend on the rest of the game going well.
const SAFE_FOR := 8


static func run_all(ctx: Dictionary, out: Array) -> void:
	good_capture(ctx, out)
	atari_answered(ctx, out)
	good_save(ctx, out)


## Two stones or more taken at once. A beginner remembers this for a week.
##
## The threshold was three, which almost never fires in a beginner's game --
## two-stone captures are the norm on 9x9 -- and so the losing games, the ones
## the opening-compliment rule was written for, were the likeliest to have
## nothing to open with.
static func good_capture(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or m["captured"].size() < 2:
			continue
		var pts := PackedInt32Array(m["captured"])
		pts.append(int(m["point"]))
		out.append(GoReview.finding("good_capture", k, ctx["positions"][k], pts,
			float(m["captured"].size()), true,
			{"stones": m["captured"].size()}))


## Your group was put on one liberty and you saw it and took the liberty.
##
## The plainest thing a beginner can be congratulated for, and the reason it is
## here: answering atari is the first skill in the game, most beginners' games
## contain at least one, and a review that can only praise a three-stone capture
## has nothing to say about a game where nothing spectacular happened.
static func atari_answered(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	var seen := {}
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) == colour or int(m["point"]) < 0:
			continue
		if k + 1 >= moves.size():
			continue
		var reply: Dictionary = moves[k + 1]
		if int(reply["color"]) != colour or int(reply["point"]) < 0:
			continue
		var after := GoReviewReplay.board_at(ctx, k + 1)
		for nb in after.neighbours(int(m["point"])):
			if after.get_idx(nb) != colour:
				continue
			var ch := after.chain_at(nb)
			if ch["liberties"].size() != 1:
				continue
			if int(reply["point"]) != int(ch["liberties"][0]):
				continue
			# Playing the liberty is only an answer if it actually bought air.
			var saved := GoReviewReplay.board_at(ctx, k + 2).chain_at(int(reply["point"]))
			if saved["liberties"].size() < 2:
				continue
			var key := GoReviewReplay.group_key(saved["stones"])
			if seen.has(key):
				continue
			seen[key] = true
			out.append(GoReview.finding("atari_answered", k + 1,
				ctx["positions"][k + 2], saved["stones"],
				float(saved["stones"].size()), true,
				{"stones": saved["stones"].size(), "liberty": int(reply["point"])}))
			break


## A group taken off one liberty and out into space.
##
## Deliberately not "and then lived": a group that got out and died forty
## moves later still got out, and the move that did it was still the right
## move. Requiring survival to the end of the game meant the credit was
## withdrawn for something that happened long afterwards.
static func good_save(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or int(m["point"]) < 0:
			continue
		var before := GoReviewReplay.board_at(ctx, k)
		var was_atari := false
		for nb in before.neighbours(int(m["point"])):
			if before.get_idx(nb) == colour \
					and before.chain_at(nb)["liberties"].size() == 1:
				was_atari = true
				break
		if not was_atari:
			continue
		var ch := GoReviewReplay.board_at(ctx, k + 1).chain_at(int(m["point"]))
		if ch["liberties"].size() < 2:
			continue
		var fell := GoReviewReplay.captured_at(ctx, k + 1, ch["stones"])
		if fell >= 0 and fell - k < SAFE_FOR:
			continue        # it never actually got out
		out.append(GoReview.finding("good_save", k, ctx["positions"][k + 1],
			ch["stones"], float(ch["stones"].size()) + 1.0, true,
			{"stones": ch["stones"].size()}))
