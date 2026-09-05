## Draws a GoGame. Knows the rules module; knows nothing about the town.
##
## Purely a view plus a cursor: it reports the point the player activated and
## lets the match scene decide whether that is legal, a dead-stone toggle, or
## nothing at all.
class_name GoBoardView
extends Control

signal point_activated(point: int)
signal cursor_moved(point: int)
signal view_changed

const C_BOARD := Color("#d9ac66")
const C_BOARD_EDGE := Color("#a97b3c")
const C_LINE := GoBoardInk.C_LINE
const C_BLACK := GoBoardInk.C_BLACK
const C_BLACK_HI := GoBoardInk.C_BLACK_HI
const C_WHITE := GoBoardInk.C_WHITE
const C_WHITE_LO := GoBoardInk.C_WHITE_LO
const C_SHADOW := GoBoardInk.C_SHADOW
const C_CURSOR := Color("#8c4034")
const C_LAST := Color("#b8624a")
const C_LIBERTY := GoBoardInk.C_LIBERTY
const C_GOOD := Color("#c9962b")
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
## The review's one positive card: the same mark, in the paper's gold rather
## than the liberty teal, so praise and correction never look alike.
var mark_good: bool = false

var zoomed := false
var inspection := false
var geometry := GoBoardGeometry.new()

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
    zoomed = false
    if g != null and (cursor < 0 or cursor >= g.size() * g.size()):
        cursor = g.board.idx(g.size() / 2, g.size() / 2)
    queue_redraw()


func _ready() -> void:
    focus_mode = Control.FOCUS_ALL
    resized.connect(queue_redraw)
    mouse_filter = Control.MOUSE_FILTER_STOP


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
    geometry.configure(game.size(), size, zoomed, cursor, _label_width(str(game.size())))
    _cell = geometry.cell
    _origin = geometry.origin


func point_position(i: int) -> Vector2:
    _layout()
    return geometry.position(i)


func point_at(pos: Vector2) -> int:
    if game == null:
        return -1
    _layout()
    return geometry.point_at(pos)


func point_visible(point: int) -> bool:
    _layout()
    return geometry.contains(point)


func toggle_zoom() -> void:
    if game == null or game.size() != 19:
        return
    zoomed = not zoomed
    _layout()
    view_changed.emit()
    queue_redraw()


func focus_point(point: int) -> void:
    if game == null:
        return
    cursor = clampi(point, 0, game.size() * game.size() - 1)
    _layout()
    cursor_moved.emit(cursor)
    view_changed.emit()
    queue_redraw()


func view_caption() -> String:
    if game == null:
        return ""
    return "%s  %s  V: %s" % [game.board.label(cursor),
        "Close view" if zoomed else "Whole board", "whole" if zoomed else "zoom"]


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
    var count := geometry.region.size.x
    var used := _cell * float(count - 1)
    var pad := geometry.margin

    draw_rect(Rect2(_origin - Vector2(pad, pad) - Vector2(2, 2),
        Vector2(used + pad * 2 + 4, used + pad * 2 + 4)), C_BOARD_EDGE)
    draw_rect(Rect2(_origin - Vector2(pad, pad), Vector2(used + pad * 2, used + pad * 2)), C_BOARD)

    for i in count:
        var a := _origin + Vector2(0, i * _cell)
        draw_line(a, a + Vector2(used, 0), C_LINE, 1.0)
        var b := _origin + Vector2(i * _cell, 0)
        draw_line(b, b + Vector2(0, used), C_LINE, 1.0)

    for s in star_points(n):
        if not geometry.contains(s):
            continue
        draw_circle(point_position(s), maxf(1.5, _cell * 0.09), C_LINE)

    if show_coordinates:
        GoBoardInk.coordinates(self, geometry, FONT)
    if zoomed:
        GoBoardInk.crop_edges(self, geometry)

    if show_territory and territory.size() == game.board.cells.size():
        GoBoardInk.territory_marks(self, game, geometry, territory)

    for point in _ghosts:
        if not geometry.contains(int(point)):
            continue
        var g: Dictionary = _ghosts[point]
        GoBoardInk.stone(self, _cell, point_position(int(point)), int(g["colour"]), false,
            float(g["scale"]), float(g["alpha"]))

    for i in game.board.cells.size():
        var c := game.board.get_idx(i)
        if c != GoBoard.EMPTY and geometry.contains(i):
            GoBoardInk.stone(self, _cell, point_position(i), c, dead.has(i),
                float(_placing.get(i, 1.0)))

    var last := game.last_move()
    if not last.is_empty() and geometry.contains(int(last["point"])):
        var lp := point_position(int(last["point"]))
        var col: Color = C_WHITE if int(last["color"]) == GoBoard.BLACK else C_BLACK
        draw_arc(lp, _cell * 0.22, 0, TAU, 12, col, 1.5)

    if show_liberties and cursor >= 0:
        GoBoardInk.liberties(self, game, geometry, cursor, FONT)

    for h in highlight:
        if not geometry.contains(h):
            continue
        draw_arc(point_position(h), _cell * 0.42, 0, TAU, 16, C_LAST, 1.0)

    if geometry.contains(mark_point):
        draw_circle(point_position(mark_point), _cell * 0.18, C_GOOD if mark_good else C_LIBERTY)

    if (interactive or inspection) and geometry.contains(cursor):
        var cp := point_position(cursor)
        var r := _cell * 0.5
        for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
            var o: Vector2 = cp + corner * r
            draw_line(o, o - Vector2(corner.x * r * 0.45, 0), C_CURSOR, 1.5)
            draw_line(o, o - Vector2(0, corner.y * r * 0.45), C_CURSOR, 1.5)


func _label_width(text: String) -> float:
    var f: Font = FONT
    return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


# --- input -------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
    if not interactive or game == null:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var i := point_at(event.position)
        if i >= 0:
            focus_point(i)
            point_activated.emit(i)
            accept_event()


func move_cursor(delta: Vector2i) -> void:
    if game == null:
        return
    _layout()
    focus_point(geometry.moved_cursor(cursor, delta))


func activate_cursor() -> void:
    if interactive and cursor >= 0:
        point_activated.emit(cursor)
