## Development-only input driver. It uses the same actions and mouse events as
## a person; calling the match's placement handler would skip the UI under test.
class_name BoardPlayProbe
extends RefCounted


static func board_in(tree: SceneTree) -> GoBoardView:
    var cards := tree.root.find_child("ReviewCards", true, false) as ReviewCards
    if cards != null:
        return cards.get("_board") as GoBoardView
    var scene := tree.current_scene
    return scene.get("board_view") as GoBoardView if scene != null else null


static func tap(tree: SceneTree, action: String) -> void:
    for pressed in [true, false]:
        var event := InputEventAction.new()
        event.action = action
        event.pressed = pressed
        event.strength = 1.0 if pressed else 0.0
        Input.parse_input_event(event)
        await tree.process_frame


static func navigate(tree: SceneTree, point: int) -> void:
    var board := board_in(tree)
    if board == null:
        fail(tree, "No board to navigate")
        return
    var n := board.game.size()
    var start := board.target_point() if board.target_point() >= 0 else board.cursor
    var delta := Vector2i(point % n - start % n, point / n - start / n)
    for i in absi(delta.x):
        await tap(tree, "move_right" if delta.x > 0 else "move_left")
    for i in absi(delta.y):
        await tap(tree, "move_down" if delta.y > 0 else "move_up")
    if board.cursor != point:
        fail(tree, "Navigation reached %d instead of %d" % [board.cursor, point])


static func place(tree: SceneTree, point: int) -> void:
    await navigate(tree, point)
    await tap(tree, "interact")


static func perform(tree: SceneTree, spec: Dictionary, screenshot: Callable = Callable()) -> void:
    if spec.has("ceremony"):
        var ceremony := NigiriCeremony.new()
        ceremony.size = UiKit.VIEW
        tree.root.add_child(ceremony)
        for colour in ["white", "black"]:
            _click_after_shot.call_deferred(tree, colour, screenshot)
            var chosen := await ceremony.ask_colour()
            if chosen != (GoBoard.WHITE if colour == "white" else GoBoard.BLACK):
                fail(tree, "Mouse selected the wrong nigiri colour")
        ceremony.queue_free()
        return
    if spec.has("nigiri_mouse"):
        await click_button(tree, "odd")
        var deadline := Time.get_ticks_msec() + 20000
        while Time.get_ticks_msec() < deadline:
            var ceremony: NigiriCeremony
            for node in tree.root.find_children("*", "Control", true, false):
                if node is NigiriCeremony:
                    ceremony = node
                    break
            if ceremony == null:
                return
            if ceremony.get("_awaiting") == &"colour":
                if screenshot.is_valid():
                    await screenshot.call("nigiri_colour_choice")
                await click_button(tree, str(spec["nigiri_mouse"]))
                return
            await tree.process_frame
        fail(tree, "Nigiri did not finish")
        return
    if spec.has("button_hover"):
        await click_button(tree, str(spec["button_hover"]), true, true)
        return
    if spec.has("button_wait"):
        await click_button(tree, str(spec["button_wait"]), false)
        return
    if spec.has("button"):
        await click_button(tree, str(spec["button"]))
        return
    var board := board_in(tree)
    if board == null or board.game == null:
        fail(tree, "No board for input probe")
        return
    var n := board.game.size()
    if spec.has("scale"):
        tree.root.size = Vector2i(384, 216) * int(spec["scale"])
        await tree.process_frame
        await tree.process_frame
    if spec.has("hover") or spec.has("hover_out") or spec.has("hover_blocked"):
        var xy: Array = spec.get("hover", spec.get("hover_blocked", [0, 0]))
        var point := int(xy[1]) * n + int(xy[0])
        var local := Vector2(-8, -8) if spec.has("hover_out") else board.point_position(point)
        var region := board.geometry.region
        var cells := board.game.board.cells.duplicate()
        var moves := board.game.move_number()
        var pos := tree.root.get_final_transform() * (board.get_global_transform_with_canvas() * local)
        var event := InputEventMouseMotion.new()
        event.position = pos
        event.global_position = pos
        event.relative = Vector2(1, 1)
        Input.parse_input_event(event)
        await tree.process_frame
        await tree.process_frame
        var expected := -1 if spec.has("hover_out") or spec.has("hover_blocked") else point
        if board.pointer.hover != expected:
            fail(tree, "Hover target %d != %d" % [board.pointer.hover, expected])
        if board.geometry.region != region or board.game.board.cells != cells or board.game.move_number() != moves:
            fail(tree, "Hover changed the view or game")
    if spec.has("key"):
        for pressed in [true, false]:
            var event := InputEventKey.new()
            event.physical_keycode = OS.find_keycode_from_string(str(spec["key"]))
            event.pressed = pressed
            Input.parse_input_event(event)
            await tree.process_frame
    if spec.has("move_to"):
        var xy: Array = spec["move_to"]
        await navigate(tree, int(xy[1]) * n + int(xy[0]))
    if spec.has("click") or spec.has("click_legal") or spec.has("click_blocked") or spec.has("click_attempt"):
        var xy: Array = spec.get("click", spec.get("click_legal", spec.get("click_blocked", spec.get("click_attempt", []))))
        var point := int(xy[1]) * n + int(xy[0])
        if spec.has("click_legal"):
            var searched := 0
            while not board.game.is_legal(point) and searched < n * n:
                point = (point + 1) % (n * n)
                searched += 1
            if searched == n * n:
                fail(tree, "No legal mouse target")
                return
        if not board.point_visible(point):
            fail(tree, "Mouse probe asked for a hidden point")
            return
        var pos := tree.root.get_final_transform() * (board.get_global_transform_with_canvas() * board.point_position(point))
        var before := board.game.move_number()
        var before_cursor := board.cursor
        for pressed in [true, false]:
            var event := InputEventMouseButton.new()
            event.button_index = MOUSE_BUTTON_LEFT
            event.pressed = pressed
            event.position = pos
            event.global_position = pos
            Input.parse_input_event(event)
            await tree.process_frame
        if spec.has("click_blocked"):
            if board.cursor != before_cursor or board.game.move_number() != before:
                fail(tree, "Modal allowed mouse input onto the board")
        elif spec.has("click_attempt"):
            if board.game.move_number() != before:
                fail(tree, "Illegal attempt changed move history")
        elif board.cursor != point or (not bool(spec.get("counting", false)) and board.game.move_number() <= before):
            fail(tree, "Mouse placement did not activate %d (cursor %d, moves %d -> %d, screen %s)" % [point, board.cursor, before, board.game.move_number(), pos])
    if spec.has("toggle_group_mouse"):
        var point := -1
        for i in board.game.board.cells.size():
            if board.game.board.get_idx(i) != GoBoard.EMPTY and board.point_visible(i):
                point = i
                break
        if point < 0:
            fail(tree, "No visible counting group")
            return
        var xy := [point % n, point / n]
        await perform(tree, {"hover": xy})
        if screenshot.is_valid():
            await screenshot.call("count_hover_group")
        var before := board.dead.duplicate()
        await perform(tree, {"click": xy, "counting": true})
        if board.dead == before:
            fail(tree, "Mouse did not toggle the group")
        if screenshot.is_valid():
            await screenshot.call("count_mouse_changed")
        await perform(tree, {"click": xy, "counting": true})
        if board.dead != before:
            fail(tree, "Mouse did not restore the group")
    if spec.has("toggle_group"):
        # Choose a group that actually exists in this played position. Count
        # changes are checked in both directions, through mouse and keyboard.
        var point := -1
        for i in board.game.board.cells.size():
            if board.game.board.get_idx(i) != GoBoard.EMPTY:
                point = i
                break
        if point < 0:
            fail(tree, "No group to mark in the played game")
            return
        var before := board.dead.duplicate()
        await navigate(tree, point)
        await tap(tree, "interact")
        if board.dead == before:
            fail(tree, "Keyboard did not toggle the group")
        if screenshot.is_valid():
            await screenshot.call("count_group_changed")
        var xy := [point % n, point / n]
        await perform(tree, {"click": xy, "counting": true})
        if board.dead != before:
            fail(tree, "Mouse did not restore the same group")
    if spec.has("fallback"):
        var opponent: GoOpponent = tree.current_scene.get("opponent")
        var fallback := not (opponent is GtpOpponent) or (opponent as GtpOpponent).fallback_used
        if fallback != bool(spec["fallback"]):
            fail(tree, "Unexpected opponent fallback state")
    if spec.has("mode") and board.pointer.mode != BoardPointer.Mode[str(spec["mode"])]:
        fail(tree, "Wrong pointer mode: %s" % board.pointer.mode)
    if spec.has("zoomed") and board.zoomed != bool(spec["zoomed"]):
        fail(tree, "Unexpected zoom mode")
    if spec.has("size") and n != int(spec["size"]):
        fail(tree, "Wrong board size")
    if spec.has("cursor"):
        var xy: Array = spec["cursor"]
        if board.cursor != int(xy[1]) * n + int(xy[0]):
            fail(tree, "Cursor moved unexpectedly")
    if spec.has("moves") and board.game.move_number() != int(spec["moves"]):
        fail(tree, "Modal input reached the game")
    if spec.has("dead") and board.dead.size() != int(spec["dead"]):
        fail(tree, "Dead-group toggle did not change the expected stones")
    if spec.has("counting"):
        if bool(tree.current_scene.call("is_counting")) != bool(spec["counting"]):
            fail(tree, "Expected the counting phase")
    print("BOARD INPUT: %s" % spec)


static func fail(tree: SceneTree, reason: String) -> void:
    push_error("Board play probe: %s" % reason)
    tree.quit(1)


static func walk_review(tree: SceneTree, screenshot: Callable) -> void:
    var cards := tree.root.find_child("ReviewCards", true, false) as ReviewCards
    if cards == null:
        fail(tree, "No review to inspect")
        return
    while is_instance_valid(cards):
        var index: int = cards.get("_index")
        var page: int = cards.get("_text_page")
        var pages: PackedStringArray = cards.get("_text_pages")
        await screenshot.call("review_%d_page_%d" % [index + 1, page + 1])
        if index == cards.call("_card_count") - 1 and page >= pages.size() - 1:
            return
        await tap(tree, "move_right")
        if index == cards.get("_index") and page == cards.get("_text_page"):
            fail(tree, "Review navigation stopped before its final page")
            return


static func click_button(tree: SceneTree, action: String, activate: bool = true, hover_only: bool = false) -> void:
    var target: Button
    var deadline := Time.get_ticks_msec() + 30000
    while target == null and Time.get_ticks_msec() < deadline:
        for node in tree.root.find_children("*", "Button", true, false):
            var button := node as Button
            if str(button.name) == action and button.is_visible_in_tree() and not button.disabled:
                target = button
                break
        if target == null:
            await tree.process_frame
    if target == null:
        fail(tree, "No enabled visible button: " + action)
        return
    if not activate:
        return
    var pos := tree.root.get_final_transform() * (target.get_global_transform_with_canvas() * (target.size * 0.5))
    var motion := InputEventMouseMotion.new()
    motion.position = pos
    motion.global_position = pos
    Input.parse_input_event(motion)
    await tree.process_frame
    if hover_only:
        return
    for pressed in [true, false]:
        var event := InputEventMouseButton.new()
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = pressed
        event.position = pos
        event.global_position = pos
        Input.parse_input_event(event)
        await tree.process_frame
    await tree.process_frame
    print("BOARD BUTTON: " + action)


static func _click_after_shot(tree: SceneTree, action: String, screenshot: Callable) -> void:
    await tree.process_frame
    if screenshot.is_valid():
        await screenshot.call("choose_" + action)
    await click_button(tree, action)
