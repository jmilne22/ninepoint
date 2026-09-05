## One coordinate transform for drawing, cursor following and mouse picking.
## Board points always remain global, even when only part of the board is shown.
class_name GoBoardGeometry
extends RefCounted

## Starting view size: reuse the familiar nine-line board, then inspect dense
## positions at native resolution. Reduce this if the markers stop being legible.
const ZOOM_LINES := 9

var board_size := 9
var region := Rect2i(0, 0, 9, 9)
var cell := 20.0
var origin := Vector2.ZERO
var margin := 15.0


func configure(n: int, extent: Vector2, zoomed: bool, cursor: int,
        widest_label: float) -> void:
    board_size = n
    var count := mini(ZOOM_LINES, n) if zoomed else n
    var start := Vector2i.ZERO
    if zoomed:
        var at := Vector2i(clampi(cursor, 0, n * n - 1) % n,
            clampi(cursor, 0, n * n - 1) / n)
        start = Vector2i(clampi(at.x - count / 2, 0, n - count),
            clampi(at.y - count / 2, 0, n - count))
    region = Rect2i(start, Vector2i(count, count))
    var span := minf(extent.x, extent.y)
    cell = floorf((span - 30.0) / float(count - 1))
    var floor_pad := widest_label + 4.0
    if cell * 0.72 < floor_pad:
        cell = floorf((span - 4.0 - floor_pad * 2.0) / float(count - 1))
    cell = maxf(1.0, cell)
    margin = maxf(cell * 0.72, floor_pad)
    var used := cell * float(count - 1)
    origin = Vector2(floorf((extent.x - used) * 0.5), floorf((extent.y - used) * 0.5))


func contains(point: int) -> bool:
    return point >= 0 and point < board_size * board_size \
        and region.has_point(Vector2i(point % board_size, point / board_size))


func position(point: int) -> Vector2:
    var at := Vector2i(point % board_size, point / board_size) - region.position
    return origin + Vector2(at) * cell


func point_at(pos: Vector2) -> int:
    var rel := (pos - origin) / cell
    var at := Vector2i(roundi(rel.x), roundi(rel.y)) + region.position
    if not region.has_point(at):
        return -1
    var point := at.y * board_size + at.x
    return point if pos.distance_to(position(point)) <= cell * 0.6 else -1


func moved_cursor(cursor: int, delta: Vector2i) -> int:
    var at := Vector2i(maxi(cursor, 0) % board_size, maxi(cursor, 0) / board_size)
    at += delta
    return clampi(at.y, 0, board_size - 1) * board_size + clampi(at.x, 0, board_size - 1)


func coordinate_step() -> int:
    # Glyphs are seven pixels tall even though a prose row is eleven. Dense
    # overviews label alternate intersections; the footer names the exact one.
    return 2 if cell < 11.0 else 1
