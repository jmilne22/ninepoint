## Reading a finished game's positions back: how to get a board out of one, how
## to ask what happened to a group after it, and how to remember a group that
## has already been discussed.
##
## Split out of GoReview when that file went over the ~300-line convention. It
## is the right seam anyway: GoReview decides what is worth saying about a game,
## and every function here is instead about the replay GoReview.positions_of()
## produced. The detectors are almost the only caller.
class_name GoReviewReplay
extends RefCounted


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
