## Draws a GoGame. Knows the rules module; knows nothing about the town.
##
## Purely a view plus a cursor: it reports the point the player activated and
## lets the match scene decide whether that is legal, a dead-stone toggle, or
## nothing at all.
class_name GoBoardView
extends Control

signal point_activated(point: int)
signal cursor_moved(point: int)

const C_BOARD := Color("#d9ac66")
const C_BOARD_EDGE := Color("#a97b3c")
const C_LINE := Color("#3a2a18")
const C_BLACK := Color("#0d0b10")
const C_BLACK_HI := Color("#2e2a35")
const C_WHITE := Color("#f7f2e6")
const C_WHITE_LO := Color("#cfc6b4")
const C_SHADOW := Color(0.08, 0.07, 0.1, 0.35)
const C_CURSOR := Color("#8c4034")
const C_LAST := Color("#b8624a")
const C_LIBERTY := Color("#367f72")
const FONT := preload("res://art/ui/ninepoint_font.fnt")
const FONT_SIZE := 9

var game: GoGame
## Board indices the player has marked dead during scoring.
var dead: Dictionary = {}
var show_territory: bool = false
var territory: PackedByteArray = PackedByteArray()
var show_coordinates: bool = true
## Teaching aid: mark the liberties of whatever the cursor is on. On a stone it
## shows that chain's liberties; on an empty point it shows the liberties a
## stone played there would have. Nothing explains "liberty" as fast as this.
var show_liberties: bool = false
var cursor: int = -1
var interactive: bool = true
## Points to draw a hollow marker on (puzzle targets).
var highlight: PackedInt32Array = PackedInt32Array()
## One point to single out among the highlighted ones: the move that was there
## and was not played. The review needs to say "this group died" and "here is
## what would have saved it" on the same board, and one ring cannot say both.
var mark_point: int = -1

var _cell: float = 20.0
var _origin: Vector2 = Vector2.ZERO

## Purely presentational animation state, keyed by board point. The view still
## renders whatever the GoGame says; this only changes how a stone arrives or
## leaves, so the "the board knows nothing about the town" boundary holds.
##   placement: point -> scale 0..1
##   ghosts:    point -> {colour, scale, alpha} for stones already removed
var _placing: Dictionary = {}
var _ghosts: Dictionary = {}


func set_game(g: GoGame) -> void:
    game = g
    clear_animations()
    dead.clear()
    territory = PackedByteArray()
    if cursor < 0 and g != null:
        cursor = g.board.idx(g.size() / 2, g.size() / 2)
    queue_redraw()


func _ready() -> void:
    focus_mode = Control.FOCUS_ALL
    resized.connect(queue_redraw)


## A stone going down: a quick scale-up with a little overshoot, so it lands
## rather than appears.
func animate_placement(point: int) -> void:
    _placing[point] = 0.0
    var tw := create_tween()
    tw.tween_method(func(v: float):
        _placing[point] = v
        queue_redraw(), 0.0, 1.0, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_callback(func():
        _placing.erase(point)
        queue_redraw())


## Captured stones shrink and fade instead of blinking out, so you can see what
## you just lost.
func animate_capture(points: PackedInt32Array) -> void:
    if game == null:
        return
    for p in points:
        # The stones are already gone from the position; remember their colour.
        var colour := GoBoard.opponent(game.to_move)
        _ghosts[p] = {"colour": colour, "scale": 1.0, "alpha": 1.0}
    var tw := create_tween()
    tw.tween_method(func(v: float):
        for p in points:
            if _ghosts.has(p):
                _ghosts[p]["scale"] = 1.0 - v * 0.7
                _ghosts[p]["alpha"] = 1.0 - v
        queue_redraw(), 0.0, 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.tween_callback(func():
        for p in points:
            _ghosts.erase(p)
        queue_redraw())


func clear_animations() -> void:
    _placing.clear()
    _ghosts.clear()


func _layout() -> void:
    if game == null:
        return
    var n := game.size()
    var span: float = minf(size.x, size.y)
    # Leave a wooden margin wide enough to letter the coordinates onto.
    _cell = floorf((span - 30.0) / float(n - 1))
    # The margin has to hold the widest row number, and _cell shrinks as the
    # board grows while "13" does not. Re-fit only when the number is what is
    # forcing the margin: at nine lines the margin has always come from the cell
    # size and this leaves that board pixel-for-pixel where it was.
    var floor_pad := _label_width(str(n)) + 4.0
    if _cell * 0.72 < floor_pad:
        _cell = floorf((span - 4.0 - floor_pad * 2.0) / float(n - 1))
    var used := _cell * float(n - 1)
    _origin = Vector2(
        floorf((size.x - used) * 0.5),
        floorf((size.y - used) * 0.5))


func point_position(i: int) -> Vector2:
    var p := game.board.point(i)
    return _origin + Vector2(p.x * _cell, p.y * _cell)


func point_at(pos: Vector2) -> int:
    if game == null:
        return -1
    var rel := (pos - _origin) / _cell
    var x := int(roundf(rel.x))
    var y := int(roundf(rel.y))
    if not game.board.in_bounds(x, y):
        return -1
    if (pos - point_position(game.board.idx(x, y))).length() > _cell * 0.6:
        return -1
    return game.board.idx(x, y)


static func star_points(n: int) -> PackedInt32Array:
    var out := PackedInt32Array()
    if n < 7:
        return out
    var e := 2 if n < 13 else 3
    var m := n / 2
    var coords := [e, m, n - 1 - e] if n >= 13 else [e, n - 1 - e]
    for y in coords:
        for x in coords:
            out.append(y * n + x)
    if n % 2 == 1 and not out.has(m * n + m):
        out.append(m * n + m)
    return out


func _draw() -> void:
    if game == null:
        return
    _layout()
    var n := game.size()
    var used := _cell * float(n - 1)
    var pad := _margin(n)

    draw_rect(Rect2(_origin - Vector2(pad, pad) - Vector2(2, 2),
        Vector2(used + pad * 2 + 4, used + pad * 2 + 4)), C_BOARD_EDGE)
    draw_rect(Rect2(_origin - Vector2(pad, pad), Vector2(used + pad * 2, used + pad * 2)), C_BOARD)

    for i in n:
        var a := _origin + Vector2(0, i * _cell)
        draw_line(a, a + Vector2(used, 0), C_LINE, 1.0)
        var b := _origin + Vector2(i * _cell, 0)
        draw_line(b, b + Vector2(0, used), C_LINE, 1.0)

    for s in star_points(n):
        draw_circle(point_position(s), maxf(1.5, _cell * 0.09), C_LINE)

    if show_coordinates:
        _draw_coordinates(n, used, pad)

    if show_territory and territory.size() == game.board.cells.size():
        _draw_territory()

    for point in _ghosts:
        var g: Dictionary = _ghosts[point]
        _draw_stone(point_position(int(point)), int(g["colour"]), false,
            float(g["scale"]), float(g["alpha"]))

    for i in game.board.cells.size():
        var c := game.board.get_idx(i)
        if c != GoBoard.EMPTY:
            _draw_stone(point_position(i), c, dead.has(i),
                float(_placing.get(i, 1.0)))

    var last := game.last_move()
    if not last.is_empty() and int(last["point"]) >= 0:
        var lp := point_position(int(last["point"]))
        var col: Color = C_WHITE if int(last["color"]) == GoBoard.BLACK else C_BLACK
        draw_arc(lp, _cell * 0.22, 0, TAU, 12, col, 1.5)

    if show_liberties and cursor >= 0:
        _draw_liberties()

    for h in highlight:
        draw_arc(point_position(h), _cell * 0.42, 0, TAU, 16, C_LAST, 1.0)

    if mark_point >= 0:
        draw_circle(point_position(mark_point), _cell * 0.18, C_LIBERTY)

    if interactive and cursor >= 0:
        var cp := point_position(cursor)
        var r := _cell * 0.5
        for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
            var o: Vector2 = cp + corner * r
            draw_line(o, o - Vector2(corner.x * r * 0.45, 0), C_CURSOR, 1.5)
            draw_line(o, o - Vector2(0, corner.y * r * 0.45), C_CURSOR, 1.5)


## How much wood to leave, in pixels. 0.72 of a cell is what it has always been
## and is what a 9x9 gets; the floor is the width of the widest row number plus
## a little air, because the numbers are drawn at a fixed FONT_SIZE and do not
## shrink with the board. At 13x13 the old margin was 9 px and "13" is 11 px
## wide, so the label was drawn from the left edge of the wood and finished on
## top of the first column of stones.
func _margin(n: int) -> float:
    return maxf(_cell * 0.72, _label_width(str(n)) + 4.0)


func _label_width(text: String) -> float:
    var f: Font = FONT
    return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


## Lettered onto the wooden margin, not outside the board where the dark
## background swallows them. Row numbers are right-aligned to the grid so that
## "13" and "9" end in the same place -- ragged on the left, which is how a
## column of numbers is meant to read anyway.
func _draw_coordinates(n: int, _used: float, pad: float) -> void:
    var font: Font = FONT
    var letters := "ABCDEFGHJKLMNOPQRSTUVWXYZ"
    var col := Color(0.42, 0.30, 0.15, 0.9)
    for i in n:
        var x := _origin.x + i * _cell
        draw_string(font, Vector2(x - 3.0, _origin.y - pad + 7.0), letters[i],
            HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, col)
        var y := _origin.y + i * _cell
        var label := str(n - i)
        draw_string(font, Vector2(_origin.x - 3.0 - _label_width(label), y + 4.0),
            label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, col)


## Small open circles on each liberty, plus a count. Deliberately drawn over the
## stones so it cannot be missed.
func _draw_liberties() -> void:
    var libs := PackedInt32Array()
    var here := game.board.get_idx(cursor)
    if here != GoBoard.EMPTY:
        libs = game.board.chain_at(cursor)["liberties"]
    else:
        # What would a stone played here be touching?
        for nb in game.board.neighbours(cursor):
            if game.board.get_idx(nb) == GoBoard.EMPTY:
                libs.append(nb)
    for l in libs:
        var p := point_position(l)
        draw_arc(p, _cell * 0.26, 0, TAU, 14, C_LIBERTY, 1.5)
        draw_circle(p, _cell * 0.09, C_LIBERTY)
    if here != GoBoard.EMPTY and libs.size() > 0:
        var at := point_position(cursor) + Vector2(_cell * 0.28, -_cell * 0.28)
        draw_string(FONT, at, str(libs.size()), HORIZONTAL_ALIGNMENT_LEFT, -1,
            FONT_SIZE, C_LIBERTY)


func _draw_territory() -> void:
    for i in territory.size():
        if territory[i] == GoBoard.EMPTY or game.board.get_idx(i) != GoBoard.EMPTY:
            continue
        var p := point_position(i)
        var s := _cell * 0.26
        var col: Color = C_BLACK if territory[i] == GoBoard.BLACK else C_WHITE
        draw_rect(Rect2(p - Vector2(s, s), Vector2(s * 2, s * 2)), col)
        # a diagonal tick as well, so the marks read without relying on colour
        if territory[i] == GoBoard.WHITE:
            draw_line(p - Vector2(s, s), p + Vector2(s, s), C_LINE, 1.0)


func _draw_stone(pos: Vector2, colour: int, is_dead: bool,
        scale: float = 1.0, fade: float = 1.0) -> void:
    if scale <= 0.01:
        return
    var r := _cell * 0.46 * scale
    var alpha := (0.4 if is_dead else 1.0) * fade
    draw_circle(pos + Vector2(1, 1), r, Color(C_SHADOW.r, C_SHADOW.g, C_SHADOW.b, C_SHADOW.a * alpha))
    if colour == GoBoard.BLACK:
        draw_circle(pos, r, Color(C_BLACK, alpha))
        draw_circle(pos - Vector2(r * 0.33, r * 0.33), r * 0.28, Color(C_BLACK_HI, alpha))
    else:
        draw_circle(pos, r, Color(C_WHITE_LO, alpha))
        draw_circle(pos - Vector2(r * 0.16, r * 0.16), r * 0.8, Color(C_WHITE, alpha))
        draw_arc(pos, r, 0, TAU, 20, Color(C_LINE, alpha * 0.8), 1.0)
    if is_dead:
        var d := r * 0.5
        var mark: Color = C_LINE
        draw_line(pos - Vector2(d, d), pos + Vector2(d, d), mark, 1.0)
        draw_line(pos - Vector2(d, -d), pos + Vector2(d, -d), mark, 1.0)


# --- input -------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
    if not interactive or game == null:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var i := point_at(event.position)
        if i >= 0:
            cursor = i
            queue_redraw()
            point_activated.emit(i)
            accept_event()


func move_cursor(delta: Vector2i) -> void:
    if game == null:
        return
    var p := game.board.point(maxi(cursor, 0))
    var n := game.size()
    p.x = clampi(p.x + delta.x, 0, n - 1)
    p.y = clampi(p.y + delta.y, 0, n - 1)
    cursor = game.board.idx(p.x, p.y)
    cursor_moved.emit(cursor)
    queue_redraw()


func activate_cursor() -> void:
    if cursor >= 0:
        point_activated.emit(cursor)
