## Pure Go board position: stones, chains, liberties, capture.
##
## Knows nothing about turns, ko, komi or scoring -- that is GoGame's job.
## Contains no engine coupling of any kind; safe to unit test headlessly.
class_name GoBoard
extends RefCounted

const EMPTY := 0
const BLACK := 1
const WHITE := 2

var size: int
var cells: PackedByteArray
## neighbour index table, built once per size; shared between boards of equal size.
var _neighbours: Array[PackedInt32Array]

static var _neighbour_cache: Dictionary = {}


func _init(board_size: int = 9) -> void:
    assert(board_size >= 2 and board_size <= 25)
    size = board_size
    cells = PackedByteArray()
    cells.resize(size * size)
    _neighbours = _get_neighbour_table(size)


static func opponent(color: int) -> int:
    return WHITE if color == BLACK else BLACK


static func color_name(color: int) -> String:
    match color:
        BLACK: return "Black"
        WHITE: return "White"
        _: return "Empty"


static func _get_neighbour_table(n: int) -> Array[PackedInt32Array]:
    if _neighbour_cache.has(n):
        return _neighbour_cache[n]
    var table: Array[PackedInt32Array] = []
    table.resize(n * n)
    for y in n:
        for x in n:
            var list := PackedInt32Array()
            if x > 0: list.append(y * n + x - 1)
            if x < n - 1: list.append(y * n + x + 1)
            if y > 0: list.append((y - 1) * n + x)
            if y < n - 1: list.append((y + 1) * n + x)
            table[y * n + x] = list
    _neighbour_cache[n] = table
    return table


# --- coordinates -------------------------------------------------------------

func idx(x: int, y: int) -> int:
    return y * size + x


func point(i: int) -> Vector2i:
    return Vector2i(i % size, i / size)


func in_bounds(x: int, y: int) -> bool:
    return x >= 0 and y >= 0 and x < size and y < size


func neighbours(i: int) -> PackedInt32Array:
    return _neighbours[i]


## "D4" style coordinate label (column letter skips I, row 1 at the bottom).
func label(i: int) -> String:
    var p := point(i)
    var letters := "ABCDEFGHJKLMNOPQRSTUVWXYZ"
    return "%s%d" % [letters[p.x], size - p.y]


# --- stones ------------------------------------------------------------------

func get_at(x: int, y: int) -> int:
    return cells[idx(x, y)]


func get_idx(i: int) -> int:
    return cells[i]


func set_idx(i: int, color: int) -> void:
    cells[i] = color


func is_empty(i: int) -> bool:
    return cells[i] == EMPTY


func count_color(color: int) -> int:
    var n := 0
    for i in cells.size():
        if cells[i] == color:
            n += 1
    return n


func duplicate_board() -> GoBoard:
    var b := GoBoard.new(size)
    b.cells = cells.duplicate()
    return b


func equals(other: GoBoard) -> bool:
    return other != null and other.size == size and other.cells == cells


# --- chains ------------------------------------------------------------------

## Flood-fills the chain containing `i`.
## Returns {stones: PackedInt32Array, liberties: PackedInt32Array}.
func chain_at(i: int) -> Dictionary:
    var color := cells[i]
    var stones := PackedInt32Array()
    var libs := PackedInt32Array()
    if color == EMPTY:
        return {"stones": stones, "liberties": libs}
    var seen := {}
    var lib_seen := {}
    var stack := [i]
    seen[i] = true
    while not stack.is_empty():
        var cur: int = stack.pop_back()
        stones.append(cur)
        for nb in _neighbours[cur]:
            var nc := cells[nb]
            if nc == EMPTY:
                if not lib_seen.has(nb):
                    lib_seen[nb] = true
                    libs.append(nb)
            elif nc == color and not seen.has(nb):
                seen[nb] = true
                stack.append(nb)
    return {"stones": stones, "liberties": libs}


func liberty_count(i: int) -> int:
    if cells[i] == EMPTY:
        return 0
    return chain_at(i)["liberties"].size()


## Every chain on the board, as an array of chain dictionaries with a "color" key.
func all_chains() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    var seen := {}
    for i in cells.size():
        if cells[i] == EMPTY or seen.has(i):
            continue
        var ch := chain_at(i)
        ch["color"] = cells[i]
        for s in ch["stones"]:
            seen[s] = true
        out.append(ch)
    return out


# --- placement ---------------------------------------------------------------

## Places a stone without any legality check and resolves captures.
## Returns the indices of stones removed from the board.
func place(i: int, color: int) -> PackedInt32Array:
    cells[i] = color
    var enemy := opponent(color)
    var captured := PackedInt32Array()
    var handled := {}
    for nb in _neighbours[i]:
        if cells[nb] != enemy or handled.has(nb):
            continue
        var ch := chain_at(nb)
        for s in ch["stones"]:
            handled[s] = true
        if ch["liberties"].is_empty():
            for s in ch["stones"]:
                cells[s] = EMPTY
                captured.append(s)
    return captured


## True when playing `color` at `i` would leave its own chain without liberties
## (after any captures it makes). Assumes `i` is currently empty.
func is_suicide(i: int, color: int) -> bool:
    var enemy := opponent(color)
    # A neighbouring empty point is an immediate liberty.
    for nb in _neighbours[i]:
        if cells[nb] == EMPTY:
            return false
    # Connecting to a friendly chain that keeps a liberty is fine.
    for nb in _neighbours[i]:
        if cells[nb] == color:
            var ch := chain_at(nb)
            if ch["liberties"].size() > 1:
                return false
    # Capturing an enemy chain frees space.
    for nb in _neighbours[i]:
        if cells[nb] == enemy:
            var ch := chain_at(nb)
            if ch["liberties"].size() == 1:
                return false
    return true


## True when `i` is an empty point surrounded by `color` on all orthogonal sides,
## with at most one diagonal held by the opponent (a "real enough" eye).
## Used by scoring and by the AI to avoid filling its own eyes.
func is_eye_like(i: int, color: int) -> bool:
    if cells[i] != EMPTY:
        return false
    for nb in _neighbours[i]:
        if cells[nb] != color:
            return false
    var p := point(i)
    var enemy := opponent(color)
    var bad := 0
    var edge := 0
    for d: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
        var q := p + d
        if not in_bounds(q.x, q.y):
            edge += 1
        elif cells[idx(q.x, q.y)] == enemy:
            bad += 1
    # On the edge or in the corner a single hostile diagonal already breaks the eye.
    return bad == 0 if edge > 0 else bad <= 1


# --- debugging ---------------------------------------------------------------

func to_ascii() -> String:
    var s := ""
    for y in size:
        for x in size:
            match cells[idx(x, y)]:
                BLACK: s += "X"
                WHITE: s += "O"
                _: s += "."
        s += "\n"
    return s


## Builds a board from ASCII art ("X" black, "O" white, "." empty), for tests.
static func from_ascii(art: String) -> GoBoard:
    var rows: Array[String] = []
    for line in art.split("\n"):
        var t := line.strip_edges()
        if t != "":
            rows.append(t)
    var b := GoBoard.new(rows.size())
    for y in rows.size():
        for x in rows[y].length():
            match rows[y][x]:
                "X": b.cells[b.idx(x, y)] = BLACK
                "O": b.cells[b.idx(x, y)] = WHITE
    return b
