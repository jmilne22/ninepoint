class_name BoardViewTests
extends RefCounted


static func run(t: TestKit) -> void:
    t.section("board geometry")
    var geo := GoBoardGeometry.new()
    for n in [7, 9, 13, 19]:
        for extent in [Vector2(192, 192), Vector2(140, 140)]:
            geo.configure(n, extent, false, 0, 11.0 if n > 9 else 5.0)
            for point in n * n:
                t.eq(geo.point_at(geo.position(point)), point, "overview picks its global intersection")
            t.eq(geo.point_at(Vector2(-10, -10)), -1, "outside board cannot place")
    geo.configure(7, Vector2(192, 192), false, 0, 5.0)
    t.ok(geo.origin.x - geo.margin - 2 >= 0, "seven-line wood stays inside its panel")
    t.ok(geo.position(48).x + geo.margin + 2 <= 192, "seven-line wood clears opponent panel")
    geo.configure(9, Vector2(192, 192), false, 0, 5.0)
    t.eq(geo.cell, 20.0, "nine-line spacing remains unchanged")
    t.eq(geo.origin, Vector2(16, 16), "nine-line origin remains unchanged")
    geo.configure(13, Vector2(192, 192), false, 0, 11.0)
    t.eq(geo.cell, 13.0, "thirteen-line spacing remains unchanged")
    t.eq(geo.origin, Vector2(18, 18), "thirteen-line origin remains unchanged")
    geo.configure(19, Vector2(192, 192), false, 0, 11.0)
    t.eq(geo.position(0), Vector2(24, 24), "overview A19 is on the expected pixel")
    t.eq(geo.point_at(Vector2(168, 168)), 360, "overview bottom right selects T1")
    t.eq(geo.coordinate_step(), 2, "overview leaves space between coordinate labels")
    for cursor in [0, 18, 180, 342, 360]:
        geo.configure(19, Vector2(192, 192), true, cursor, 11.0)
        t.ok(geo.contains(cursor), "cursor stays visible at every corner and centre")
        t.ok(geo.region.position.x >= 0 and geo.region.position.y >= 0
            and geo.region.end.x <= 19 and geo.region.end.y <= 19, "crop stays on the real board")
        for y in range(geo.region.position.y, geo.region.end.y):
            for x in range(geo.region.position.x, geo.region.end.x):
                var point := y * 19 + x
                t.eq(geo.point_at(geo.position(point)), point, "zoom never renumbers an intersection")
    geo.configure(19, Vector2(192, 192), true, 360, 11.0)
    t.eq(geo.region, Rect2i(10, 10, 9, 9), "bottom-right zoom shows the actual final nine lines")
    t.eq(geo.point_at(Vector2(172, 172)), 360, "zoom bottom right selects global T1")
    t.eq(geo.coordinate_step(), 1, "zoom labels every line")
    t.eq(geo.moved_cursor(360, Vector2i(1, 1)), 360, "cursor clamps at bottom right")
    t.eq(geo.moved_cursor(0, Vector2i(-1, -1)), 0, "cursor clamps at top left")
    t.ok(not geo.contains(0), "distant move is outside the close view")
    t.eq(geo.point_at(geo.position(0)), -1, "cannot click a hidden intersection")

    t.section("view input before drawing")
    var board := GoBoardView.new()
    board.size = Vector2(192, 192)
    board.set_game(GoGame.new(19))
    board.focus_point(360)
    board.toggle_zoom()
    t.eq(board.point_at(board.point_position(360)), 360, "toggle updates picking before a redraw")
    board.toggle_zoom()
    t.eq(board.cursor, 360, "overview preserves the point under consideration")
    board.toggle_zoom()
    board.move_cursor(Vector2i(-18, -18))
    t.eq(board.point_at(board.point_position(0)), 0, "following cursor updates picking immediately")
    board.set_game(GoGame.new(9))
    board.toggle_zoom()
    t.ok(not board.zoomed, "smaller boards keep their established view")
    t.ok(board.cursor < 81, "replacing a board cannot leave an invalid cursor")
    var activations := {"count": 0}
    board.point_activated.connect(func(_point: int) -> void: activations["count"] += 1)
    board.interactive = false
    board.activate_cursor()
    t.eq(activations["count"], 0, "disabled board does not activate beneath a modal")
    board.interactive = true
    board.activate_cursor()
    t.eq(activations["count"], 1, "enabled board still emits the existing activation signal")
    board.free()


    t.section("mouse targets and stable zoom")
    for n in [7, 9, 13, 19]:
        for extent in [Vector2(192, 192), Vector2(140, 140), Vector2(230, 180)]:
            var view := GoBoardView.new()
            view.size = extent
            view.set_game(GoGame.new(n))
            view.pointer.mode = BoardPointer.Mode.PLACE
            for point in [0, n - 1, n * n / 2, n * n - 1]:
                var motion := InputEventMouseMotion.new()
                motion.position = view.point_position(point)
                var region := view.geometry.region
                view._gui_input(motion)
                t.eq(view.target_point(), point, "mouse targets global board coordinates")
                t.eq(view.geometry.region, region, "hover does not pan")
                t.eq(view.game.move_number(), 0, "hover cannot play")
            view.move_cursor(Vector2i.LEFT)
            t.eq(view.cursor, n * n - 2, "keyboard starts from hovered point")
            t.ok(not view.pointer.using_mouse, "keyboard takes ownership")
            var motion := InputEventMouseMotion.new()
            motion.position = view.point_position(0)
            view._gui_input(motion)
            t.eq(view.target_point(), 0, "mouse takes ownership again")
            view._clear_pointer()
            t.eq(view.target_point(), -1, "leaving clears the visible target")
            t.eq(view.cursor, 0, "leaving remembers the point for zoom and keyboard")
            var activation := ActivationProbe.new()
            view.point_activated.connect(activation.record)
            view.activate_cursor()
            t.eq(activation.point, 0, "Space resumes the saved selection after mouse exit")
            view.toggle_zoom()
            if n == 19:
                t.eq(view.geometry.region.position, Vector2i.ZERO, "zoom uses remembered mouse point")
                var region := view.geometry.region
                motion.position = view.point_position(4 * n + 4)
                view._gui_input(motion)
                t.eq(view.geometry.region, region, "close view is steady while hovering")
                view.toggle_zoom()
                view.activate_cursor()
                t.eq(activation.point, 4 * n + 4, "Space after V activates the same mouse-selected point")
                view.toggle_zoom()
                view.pan_view(Vector2i.RIGHT)
                t.ok(view.geometry.region.position.x > 0, "explicit pan moves close view")
                t.eq(view.pointer.hover, -1, "pan invalidates the old pixel target")
            view.free()

    t.section("hover does not judge moves")
    var view := GoBoardView.new()
    view.size = Vector2(192, 192)
    var spy := HoverGame.new(9)
    view.set_game(spy)
    view.pointer.mode = BoardPointer.Mode.PLACE
    # B8 is self-capture; an empty illegal point gets the same preview as any other.
    for p in [1, 9, 11, 19]:
        spy.board.set_idx(p, GoBoard.WHITE)
    t.eq(spy.legality(10), GoGame.Legality.SUICIDE, "fixture is genuinely self-capture")
    spy.calls = 0
    var motion := InputEventMouseMotion.new()
    motion.position = view.point_position(10)
    view._gui_input(motion)
    t.ok(view.pointer.preview_visible(spy, view.target_point()), "self-capture still has occupancy-only preview")
    t.eq(spy.calls, 0, "hover and preview never ask legality")
    spy.ko_point = 20
    t.ok(view.pointer.preview_visible(spy, 20), "ko point has ordinary empty-point preview")
    t.ok(not view.pointer.preview_visible(spy, 1), "occupied point has no preview")
    view.pointer.configure(BoardPointer.Mode.INSPECT, GoBoard.BLACK, view)
    t.ok(not view.pointer.preview_visible(spy, 20), "opponent turn or review never previews placement")
    view.pointer.configure(BoardPointer.Mode.HIDDEN, GoBoard.BLACK, view)
    t.eq(view.pointer.hover, -1, "modal clears hover immediately")
    view.interactive = false
    view.inspection = false
    view._gui_input(motion)
    t.eq(view.pointer.hover, -1, "blocked board ignores mouse motion")
    view.free()


class HoverGame extends GoGame:
    var calls := 0

    func legality(point: int, colour: int = -1) -> int:
        calls += 1
        return super.legality(point, colour)


class ActivationProbe extends RefCounted:
    var point := -1

    func record(value: int) -> void:
        point = value
