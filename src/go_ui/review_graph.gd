## The whole game as one line: your estimated lead after each of your moves.
## Marked points are the positions the cards explain. Drawing only; no engine.
class_name ReviewGraph
extends Control

signal selected_changed(index: int)

var curve: Array = []
var marked: Dictionary = {}
var selected := 0


func setup(values: Array, marks: Dictionary) -> void:
    curve = values
    marked = marks
    selected = clampi(selected, 0, maxi(curve.size() - 1, 0))
    queue_redraw()


func select(index: int) -> void:
    if curve.is_empty():
        return
    var next := clampi(index, 0, curve.size() - 1)
    if next == selected:
        return
    selected = next
    queue_redraw()
    selected_changed.emit(selected)


func step(delta: int) -> void:
    select(selected + delta)


## The previous or next explained position; stops at the ends.
func jump(direction: int) -> void:
    var i := selected + direction
    while i >= 0 and i < curve.size():
        if marked.has(int(curve[i]["move"])):
            select(i)
            return
        i += direction


func selected_move() -> Dictionary:
    return curve[selected] if not curve.is_empty() else {}


func index_of_move(move: int) -> int:
    for i in curve.size():
        if int(curve[i]["move"]) == move:
            return i
    return -1


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        select(_nearest(event.position.x))
        accept_event()


func _plot() -> Rect2:
    return Rect2(Vector2(36, 3), size - Vector2(38, 14))


func _x(i: int, plot: Rect2) -> float:
    if curve.size() < 2:
        return plot.position.x + plot.size.x / 2.0
    return plot.position.x + plot.size.x * float(i) / float(curve.size() - 1)


func _nearest(x: float) -> int:
    var plot := _plot()
    var best := 0
    for i in curve.size():
        if absf(_x(i, plot) - x) < absf(_x(best, plot) - x):
            best = i
    return best


func _draw() -> void:
    if curve.is_empty():
        return
    var plot := _plot()
    var limit := 5.0
    for point: Dictionary in curve:
        limit = maxf(limit, absf(float(point["lead"])))
    limit = ceilf(limit / 5.0) * 5.0
    var half := plot.size.y / 2.0
    var zero_y := plot.position.y + half
    draw_line(Vector2(plot.position.x, zero_y), Vector2(plot.end.x, zero_y), UiKit.INK_FAINT, 1.0)
    draw_line(plot.position, Vector2(plot.position.x, plot.end.y), UiKit.INK_FAINT, 1.0)
    # Up is good, down is bad; the caption carries the number in words.
    draw_string(UiKit.FONT, Vector2(0, plot.position.y + 8), "ahead", HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE, UiKit.INK_FAINT)
    draw_string(UiKit.FONT, Vector2(0, plot.end.y), "behind", HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE, UiKit.INK_FAINT)
    var points := PackedVector2Array()
    for i in curve.size():
        points.append(Vector2(_x(i, plot), zero_y - float(curve[i]["lead"]) / limit * half))
    if points.size() >= 2:
        draw_polyline(points, UiKit.INK_SOFT, 1.0)
    for i in curve.size():
        if marked.has(int(curve[i]["move"])):
            var mistake := float(curve[i]["loss"]) >= MatchAnalysis.MEANINGFUL_LOSS
            draw_circle(points[i], 2.5, UiKit.RUST if mistake else UiKit.TEAL)
    var cursor := points[selected]
    draw_line(Vector2(cursor.x, plot.position.y), Vector2(cursor.x, plot.end.y), UiKit.GOLD, 1.0)
    draw_circle(cursor, 2.0, UiKit.GOLD)
    var label := "move %d" % int(curve[selected]["move"])
    draw_string(UiKit.FONT, Vector2(clampf(cursor.x - 20, plot.position.x, plot.end.x - 42), size.y - 1), label,
        HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE, UiKit.INK_SOFT)
