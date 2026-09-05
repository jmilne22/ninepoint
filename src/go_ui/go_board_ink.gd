## Stone and teaching marks, separate from navigation and board geometry.
class_name GoBoardInk
extends RefCounted

const C_LINE := Color("#3a2a18")
const C_BLACK := Color("#0d0b10")
const C_BLACK_HI := Color("#2e2a35")
const C_WHITE := Color("#f7f2e6")
const C_WHITE_LO := Color("#cfc6b4")
const C_SHADOW := Color(0.08, 0.07, 0.1, 0.35)
const C_LIBERTY := Color("#367f72")
const FONT_SIZE := 9

## Small open circles on each liberty, plus a count. Deliberately drawn over the
## stones so it cannot be missed.
static func liberties(view: CanvasItem, game: GoGame, geometry: GoBoardGeometry, cursor: int, font: Font) -> void:
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
        if not geometry.contains(l):
            continue
        var p := geometry.position(l)
        view.draw_arc(p, geometry.cell * 0.26, 0, TAU, 14, C_LIBERTY, 1.5)
        view.draw_circle(p, geometry.cell * 0.09, C_LIBERTY)
    if here != GoBoard.EMPTY and libs.size() > 0 and geometry.contains(cursor):
        var at := geometry.position(cursor) + Vector2(geometry.cell * 0.28, -geometry.cell * 0.28)
        view.draw_string(font, at, str(libs.size()), HORIZONTAL_ALIGNMENT_LEFT, -1,
            FONT_SIZE, C_LIBERTY)


static func territory_marks(view: CanvasItem, game: GoGame, geometry: GoBoardGeometry, territory: PackedByteArray) -> void:
    for i in territory.size():
        if not geometry.contains(i) or territory[i] == GoBoard.EMPTY or game.board.get_idx(i) != GoBoard.EMPTY:
            continue
        var p := geometry.position(i)
        var s := geometry.cell * 0.26
        var col: Color = C_BLACK if territory[i] == GoBoard.BLACK else C_WHITE
        view.draw_rect(Rect2(p - Vector2(s, s), Vector2(s * 2, s * 2)), col)
        # a diagonal tick as well, so the marks read without relying on colour
        if territory[i] == GoBoard.WHITE:
            view.draw_line(p - Vector2(s, s), p + Vector2(s, s), C_LINE, 1.0)


static func stone(view: CanvasItem, cell: float, pos: Vector2, colour: int, is_dead: bool,
        scale: float = 1.0, fade: float = 1.0) -> void:
    if scale <= 0.01:
        return
    var r := cell * 0.46 * scale
    var alpha := (0.4 if is_dead else 1.0) * fade
    view.draw_circle(pos + Vector2(1, 1), r, Color(C_SHADOW.r, C_SHADOW.g, C_SHADOW.b, C_SHADOW.a * alpha))
    if colour == GoBoard.BLACK:
        view.draw_circle(pos, r, Color(C_BLACK, alpha))
        view.draw_circle(pos - Vector2(r * 0.33, r * 0.33), r * 0.28, Color(C_BLACK_HI, alpha))
    else:
        view.draw_circle(pos, r, Color(C_WHITE_LO, alpha))
        view.draw_circle(pos - Vector2(r * 0.16, r * 0.16), r * 0.8, Color(C_WHITE, alpha))
        view.draw_arc(pos, r, 0, TAU, 20, Color(C_LINE, alpha * 0.8), 1.0)
    if is_dead:
        var d := r * 0.5
        var mark: Color = C_LINE
        view.draw_line(pos - Vector2(d, d), pos + Vector2(d, d), mark, 1.0)
        view.draw_line(pos - Vector2(d, -d), pos + Vector2(d, -d), mark, 1.0)


## Lettered onto the wooden margin, not outside the board where the dark
## background swallows them. Row numbers are right-aligned to the grid so that
## "13" and "9" end in the same place -- ragged on the left, which is how a
## column of numbers is meant to read anyway.
static func coordinates(view: CanvasItem, geometry: GoBoardGeometry, font: Font) -> void:
    var n := geometry.board_size
    var pad := geometry.margin
    var _origin := geometry.origin
    var _cell := geometry.cell
    var letters := "ABCDEFGHJKLMNOPQRSTUVWXYZ"
    var col := Color(0.42, 0.30, 0.15, 0.9)
    for i in geometry.region.size.x:
        var column := geometry.region.position.x + i
        var row := geometry.region.position.y + i
        var step := geometry.coordinate_step() if n == 19 and geometry.region.size.x == n else 1
        var x := _origin.x + i * _cell
        if column % step == 0:
            view.draw_string(font, Vector2(x - 3.0, _origin.y - pad + 7.0), letters[column],
                HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, col)
        var y := _origin.y + i * _cell
        var label := str(n - row)
        if row % step == 0:
            view.draw_string(font, Vector2(_origin.x - 3.0 - font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x, y + 4.0),
                label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, col)


static func crop_edges(view: CanvasItem, geometry: GoBoardGeometry) -> void:
    var _origin := geometry.origin
    var _cell := geometry.cell
    var used := _cell * (geometry.region.size.x - 1)
    # Continuation ticks cross a cropped grid boundary. A true edge has none,
    # so zoom never suggests an extra wall that could give a group liberties.
    var region := geometry.region
    for i in region.size.x:
        var offset := i * _cell
        if region.position.x > 0:
            view.draw_line(_origin + Vector2(-3, offset), _origin + Vector2(0, offset), C_LINE)
        if region.end.x < geometry.board_size:
            view.draw_line(_origin + Vector2(used, offset), _origin + Vector2(used + 3, offset), C_LINE)
        if region.position.y > 0:
            view.draw_line(_origin + Vector2(offset, -3), _origin + Vector2(offset, 0), C_LINE)
        if region.end.y < geometry.board_size:
            view.draw_line(_origin + Vector2(offset, used), _origin + Vector2(offset, used + 3), C_LINE)
