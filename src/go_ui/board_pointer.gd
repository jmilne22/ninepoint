## Hover is presentation only: occupancy, never legality or puzzle correctness.
class_name BoardPointer
extends RefCounted

enum Mode { HIDDEN, INSPECT, PLACE, COUNT }
var mode := Mode.HIDDEN
var colour := GoBoard.BLACK
var hover := -1
var using_mouse := false


func clear() -> void:
    hover = -1


func configure(value: int, stone_colour: int, view: GoBoardView) -> void:
    if mode == value and colour == stone_colour:
        return
    mode = value
    colour = stone_colour
    if mode == Mode.HIDDEN:
        if hover >= 0:
            view.cursor = hover
        clear()
    view.queue_redraw()


func preview_visible(game: GoGame, point: int) -> bool:
    return mode == Mode.PLACE and point >= 0 and point < game.size() * game.size() \
        and game.board.get_idx(point) == GoBoard.EMPTY


func draw_feedback(view: GoBoardView) -> void:
    var point := view.target_point()
    if mode == Mode.HIDDEN or not (view.interactive or view.inspection):
        return
    var geo := view.geometry
    if not geo.contains(point):
        return
    var cp := geo.position(point)
    var cell := geo.cell
    var occupied := view.game.board.get_idx(point) != GoBoard.EMPTY
    if preview_visible(view.game, point):
        GoBoardInk.stone(view, cell, cp, colour, false, 1.0, 0.38)
    if mode == Mode.COUNT and occupied:
        for stone: int in view.game.board.chain_at(point)["stones"]:
            if geo.contains(stone):
                view.draw_arc(geo.position(stone), cell * 0.43, 0, TAU, 16,
                    UiKit.TEAL, 1.0)
    var r := maxf(2.0, cell * 0.5)
    for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
        var at := cp + corner * r
        view.draw_line(at, at - Vector2(corner.x * r * 0.45, 0), view.C_CURSOR, 1.0)
        view.draw_line(at, at - Vector2(0, corner.y * r * 0.45), view.C_CURSOR, 1.0)


func handle_input(view: GoBoardView, event: InputEvent) -> void:
    if view.game == null or not (view.interactive or view.inspection):
        return
    if event is InputEventMouseMotion:
        hover = view.point_at(event.position)
        using_mouse = true
        view.view_changed.emit()
        view.queue_redraw()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var point := view.point_at(event.position)
        if point >= 0:
            # Selection changes; the close-view anchor stays under the same hand.
            view.cursor = point
            hover = point
            using_mouse = true
            view.cursor_moved.emit(point)
            view.view_changed.emit()
            view.queue_redraw()
            if view.interactive:
                view.point_activated.emit(point)
            view.accept_event()
