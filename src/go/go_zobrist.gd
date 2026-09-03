## Deterministic Zobrist hashing for board positions.
##
## Used for ko / positional superko detection and for repetition tests.
## The seed is fixed so that hashes are stable across runs and across saves.
class_name GoZobrist
extends RefCounted

const SEED := 1234567891

static var _tables: Dictionary = {}


## Returns a table of size (points * 3) of random 64-bit keys for a board size.
static func table_for(size: int) -> PackedInt64Array:
    if _tables.has(size):
        return _tables[size]
    var rng := RandomNumberGenerator.new()
    rng.seed = SEED + size * 7919
    var t := PackedInt64Array()
    t.resize(size * size * 3)
    for i in t.size():
        t[i] = rng.randi() | (int(rng.randi()) << 32)
    _tables[size] = t
    return t


static func hash_board(board: GoBoard) -> int:
    var t := table_for(board.size)
    var h := 0
    for i in board.cells.size():
        var c := board.cells[i]
        if c != GoBoard.EMPTY:
            h ^= t[i * 3 + c]
    return h
