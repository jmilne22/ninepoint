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
    var delta := Vector2i(point % n - board.cursor % n, point / n - board.cursor / n)
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
    var board := board_in(tree)
    if board == null:
        fail(tree, "No board for input probe")
        return
    var n := board.game.size()
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
    if spec.has("click") or spec.has("click_legal") or spec.has("click_blocked"):
        var xy: Array = spec.get("click", spec.get("click_legal", spec.get("click_blocked", [])))
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
        elif board.cursor != point or (not bool(spec.get("counting", false)) and board.game.move_number() <= before):
            fail(tree, "Mouse placement did not activate %d (cursor %d, moves %d -> %d, screen %s)" % [point, board.cursor, before, board.game.move_number(), pos])
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
