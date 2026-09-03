## Stepping through the game the review is talking about.
##
## A controller rather than a Node: it owns a cursor over the positions the
## replay produced and tells a GoBoardView what to draw. The review screen keeps
## the board; this decides which board.
##
## The positions cost nothing to have. GoReview.positions_of() already walks the
## whole game to find the findings and used to throw every board away, so the
## difference between "three snapshots" and "watch your game back" is a cursor
## and an arrow key.
class_name GoReplay
extends RefCounted

## Moves per second while an arrow is held. Slow enough to read a 9x9 board.
const SCRUB_RATE := 6.0

var positions: Array = []
var moves: Array = []
var size: int = 9

var cursor: int = 0
## Where the current finding sits, so the caption can say how far you have
## wandered from the thing being discussed.
var anchor: int = 0

var _held := 0.0


func bind(payload: Dictionary) -> void:
	positions = payload.get("positions", [])
	moves = payload.get("moves", [])
	size = int(payload.get("size", 9))
	cursor = last()
	anchor = cursor


func available() -> bool:
	return positions.size() > 1


func last() -> int:
	return maxi(positions.size() - 1, 0)


## Puts the cursor on the position a finding is about. `move_index` is the move,
## and the board worth looking at is the one *after* it -- what the move did.
func focus(move_index: int) -> void:
	anchor = clampi(move_index + 1, 0, last())
	cursor = anchor


## Returns true when the cursor actually moved, so the caller can skip a redraw.
func step(delta: int) -> bool:
	var want := clampi(cursor + delta, 0, last())
	if want == cursor:
		return false
	cursor = want
	return true


## Held-arrow scrubbing. `dir` is -1, 0 or 1; returns true when it stepped.
func scrub(dir: int, delta_time: float) -> bool:
	if dir == 0:
		_held = 0.0
		return false
	_held += delta_time * SCRUB_RATE
	if _held < 1.0:
		return false
	_held -= 1.0
	return step(dir)


func cells() -> PackedByteArray:
	if positions.is_empty():
		return PackedByteArray()
	return positions[clampi(cursor, 0, last())]


## The move that produced the position now showing, or {} at the start.
func current_move() -> Dictionary:
	if cursor <= 0 or cursor > moves.size():
		return {}
	return moves[cursor - 1]


## The point of that move, or -1 for a pass, a resignation or the empty board.
## GoBoardView draws its own last-move marker from this.
func last_point() -> int:
	var m := current_move()
	if m.is_empty():
		return -1
	return int(m.get("point", -1))


## "Move 34  ·  Black D5" -- or where you are, when you have wandered off.
func caption() -> String:
	if not available():
		return ""
	if cursor == 0:
		return "Before move 1"
	var m := current_move()
	if m.is_empty():
		return ""
	var who := "Black" if int(m.get("color", GoBoard.BLACK)) == GoBoard.BLACK else "White"
	var where := str(m.get("label", ""))
	var text := "Move %d  %s %s" % [cursor, who, where]
	if cursor != anchor:
		text += "   (%+d)" % (cursor - anchor)
	return text
