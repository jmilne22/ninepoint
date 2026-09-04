## Where a game of Go has stopped being in doubt.
##
## Pulled out of HeuristicOpponent in M29, when the opponent learned to stop:
## deciding that a region is finished is a judgement about the board rather than
## a way of scoring a move, it is the thing the tests need to see, and the file
## it grew inside was seventy lines over the convention.
##
## It sits in src/go_ai/ and not src/go/ on purpose. Nothing here is a rule --
## "small enough to be sure of" is an opinion held by a two-ply reader, and
## src/go/ may only contain things that are true.
class_name GoEndgame
extends RefCounted


## How big an enemy enclosure this reader is willing to call sealed. Being wrong
## about their territory only means declining to invade, and an invasion is
## exactly the judgement a two-ply reader does not have.
static func invasion_cap(board: GoBoard) -> int:
    return maxi(8, board.cells.size() / 4)


## And how big one of its own may be. Filling your own territory is wrong at any
## size under Japanese scoring, so this is not a judgement about the points -- it
## is the sanity bound that stops "enclosed by one colour" from meaning "the open
## board, and only I have a stone near it". Wall the opponent's last group into a
## corner and the whole of the rest of the board answers to that description; a
## test found the opponent passing on a 9x9 with sixty-five points still empty.
static func territory_cap(board: GoBoard) -> int:
    return board.cells.size() / 2


## Empty points inside a region that belongs to one colour and is finished.
##
## Settled means all of: enclosed by exactly one colour; small enough for that
## claim to mean something (see the two caps above); and walls that are neither
## in atari nor already judged dead. An empty region borders one colour from the
## first move onwards, and on a handicap board it does so before either player
## has moved -- which is why the size of it is load-bearing rather than tidy.
static func settled_points(board: GoBoard, color: int) -> Dictionary:
    var out := {}
    var enclosed: Array[Dictionary] = []
    for region in GoScoring.empty_regions(board):
        var borders: Dictionary = region["borders"]
        if borders.size() != 1:
            continue
        var cap: int = territory_cap(board) if borders.has(color) else invasion_cap(board)
        if int(region["points"].size()) > cap:
            continue
        enclosed.append(region)
    if enclosed.is_empty():
        return out
    var dead := GoScoring.estimate_dead(board)
    for region in enclosed:
        var owner: int = region["borders"].keys()[0]
        var pts: PackedInt32Array = region["points"]
        if not _wall_holds(board, pts, owner, dead):
            continue
        for p in pts:
            out[p] = owner
    return out


## Is the wall around this region actually finished? A chain on one liberty is a
## capture away from opening the whole thing, and a chain the scorer already
## reads as dead is not enclosing anything.
static func _wall_holds(board: GoBoard, pts: PackedInt32Array, owner: int, dead: Dictionary) -> bool:
    var seen := {}
    for p in pts:
        for nb in board.neighbours(p):
            if board.get_idx(nb) != owner or seen.has(nb):
                continue
            if dead.has(nb):
                return false
            var chain := board.chain_at(nb)
            for s in chain["stones"]:
                seen[s] = true
            if chain["liberties"].size() <= 1:
                return false
    return true


## The share of the board still in dispute: empty, and nobody's yet.
static func openness(board: GoBoard, settled: Dictionary) -> float:
    var open_points := 0
    for i in board.cells.size():
        if board.is_empty(i) and not settled.has(i):
            open_points += 1
    return float(open_points) / float(board.cells.size())
