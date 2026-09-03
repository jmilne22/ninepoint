## Walks a GoLessonData: a position, a thing to do, and a sentence about what
## happened. Reuses GoBoardView, so a lesson looks exactly like a real game.
extends Control

var lesson: GoLessonData
var game: GoGame
var board_view: GoBoardView

var step_index: int = 0
var attempts: int = 0
var _finished := false
var _awaiting: StringName = &""

var _title: Label
var _instruction: Label
var _message: Label
var _progress: Label
var _hints: Label
var _overlay: Control
var _card: NinePatchRect
var _overlay_text: Label


func _ready() -> void:
    var lesson_id := MatchBridge.pending_lesson
    if lesson_id == "":
        lesson_id = "liberties"
    lesson = GoLessonData.load_lesson(lesson_id)
    if lesson == null:
        MatchBridge.finish_lesson(lesson_id, false)
        return
    _build_ui()
    set_process_unhandled_input(true)
    _run()


func _build_ui() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color("#2a2633")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    board_view = GoBoardView.new()
    board_view.position = Vector2(6, 12)
    board_view.size = Vector2(192, 192)
    board_view.point_activated.connect(_on_point)
    add_child(board_view)

    var panel := NinePatchRect.new()
    panel.texture = load("res://art/ui/panel.png")
    for m in ["left", "top", "right", "bottom"]:
        panel.set("patch_margin_%s" % m, 6)
    panel.position = Vector2(202, 8)
    panel.size = Vector2(176, 158)
    panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(panel)

    # Two lines for the title. "You May Not Take It Straight Back" wrapped and
    # landed on top of the step counter; a title is written for the lesson, not
    # measured against a panel, so the panel gives it the room.
    _title = _label(panel, Vector2(10, 8), 156, 9, "#8a6023", 22)
    _title.text = lesson.title
    _progress = _label(panel, Vector2(10, 30), 156, 9, "#6b6577")
    _instruction = _label(panel, Vector2(10, 44), 156, 9, "#14121a", 52)
    _message = _label(panel, Vector2(10, 98), 156, 9, "#367f72", 52)
    _hints = _label(self, Vector2(204, 172), 176, 9, "#8a8494", 40)
    _hints.text = "Arrows: move   Space: play"

    _overlay = Control.new()
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.visible = false
    add_child(_overlay)
    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.07, 0.1, 0.72)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.add_child(dim)
    _card = UiKit.panel(_overlay, Rect2(36, 46, 312, 124))
    _overlay_text = UiKit.label(_card, Vector2(10, 10), 292, UiKit.INK, 104)


func _label(parent: Node, pos: Vector2, width: int, font_size: int, colour: String,
        height: int = 0) -> Label:
    var l := Label.new()
    l.position = pos
    l.size = Vector2(width, height if height > 0 else font_size + 6)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color(colour))
    parent.add_child(l)
    return l


func _ask(what: StringName) -> void:
    _awaiting = what
    while _awaiting == what and is_inside_tree():
        await get_tree().process_frame


func _run() -> void:
    if lesson.intro.size() > 0:
        await _show_card("\n\n".join(lesson.intro))
    for i in lesson.step_count():
        if not is_inside_tree():
            return
        step_index = i
        attempts = 0
        _load_step()
        await _ask(&"step")
        if not is_inside_tree():
            return
        var explanation := str(lesson.steps[i]["explanation"])
        if explanation != "":
            await _show_card(explanation)
    if lesson.outro.size() > 0:
        await _show_card("\n\n".join(lesson.outro))
    _finished = true
    GameState.set_flag("lesson_%s_done" % lesson.id, true)
    MatchBridge.finish_lesson(lesson.id, true)


func _load_step() -> void:
    var step: Dictionary = lesson.steps[step_index]
    game = lesson.make_game(step_index)
    board_view.set_game(game)
    board_view.show_liberties = bool(step["show_liberties"])
    board_view.highlight = step["target"]
    _instruction.text = str(step["instruction"])
    _progress.text = "Step %d of %d" % [step_index + 1, lesson.step_count()]
    _message.text = ""
    if bool(step["show_liberties"]):
        _hints.text = "Arrows: move   Space: play\nThe rings show liberties."
    else:
        _hints.text = "Arrows: move   Space: play"


func _on_point(point: int) -> void:
    if _finished or _awaiting != &"step":
        return
    var code := game.legality(point)
    var legal := code == GoGame.Legality.LEGAL
    var captured := 0
    if legal:
        var probe := game.board.duplicate_board()
        captured = probe.place(point, game.to_move).size()

    if lesson.step_accepts(step_index, point, legal, captured):
        if legal:
            game.play(point)
            Audio.play_stone()
            board_view.animate_placement(point)
            var taken: PackedInt32Array = game.last_move()["captured"]
            if taken.size() > 0:
                board_view.animate_capture(taken)
                Audio.play("capture")
            board_view.queue_redraw()
            # "You are going to count," says the openings class, and then it never
            # counted anything on screen. The pocket the move just sealed is
            # highlighted and its size stated, so the argument is made by the
            # board rather than by the paragraph underneath it.
            _show_pocket()
            await get_tree().create_timer(0.45).timeout
        else:
            Audio.play("illegal")
            _message.text = game.legality_reason(code)
            await get_tree().create_timer(0.6).timeout
        _awaiting = &""
        return

    # Not what the step wanted.
    attempts += 1
    if not legal:
        Audio.play("illegal")
        _message.text = game.legality_reason(code)
        return
    game.play(point)
    Audio.play_stone()
    board_view.queue_redraw()
    await get_tree().create_timer(0.5).timeout
    game.undo()
    board_view.queue_redraw()
    var hint := str(lesson.steps[step_index]["hint"])
    _message.text = hint if (attempts >= 2 and hint != "") else "Not that one. Try again."


## Highlights the empty region a step claims to have enclosed, and says how many
## points it is and what it cost. Only for steps that declare `encloses`.
func _show_pocket() -> void:
    var step: Dictionary = lesson.steps[step_index]
    var claimed := int(step.get("encloses", 0))
    var anchor := int(step.get("region_at", -1))
    if claimed <= 0 or anchor < 0:
        return
    var region := _region_at(anchor)
    if region.is_empty():
        return
    board_view.highlight = region
    board_view.queue_redraw()
    var walls := game.board.count_color(game.board.get_idx(int(step["points"][0])))
    _message.text = "%d points, for %d stones." % [region.size(), walls]


## The connected empty area containing `start`. Flood fill over empty points --
## the same shape as the validator's pocket_after, and used for the same reason.
func _region_at(start: int) -> PackedInt32Array:
    var out := PackedInt32Array()
    if game.board.get_idx(start) != GoBoard.EMPTY:
        return out
    var seen := {}
    var stack: Array[int] = [start]
    while not stack.is_empty():
        var i: int = stack.pop_back()
        if seen.has(i):
            continue
        seen[i] = true
        out.append(i)
        for n in game.board.neighbours(i):
            if game.board.get_idx(n) == GoBoard.EMPTY and not seen.has(n):
                stack.append(n)
    return out


## Long explanations are paginated rather than clipped -- the lesson text is the
## product here, so it must never run off the bottom of the card.
func _show_card(text: String) -> void:
    _overlay.visible = true
    var pages := UiKit.paginate(text, 292, 150)
    for i in pages.size():
        var tail := "[Space] to carry on" if i == pages.size() - 1 else "[Space] for more"
        UiKit.fit_card(_card, _overlay_text, "%s\n\n%s" % [pages[i], tail], 312)
        await _ask(&"card")
        if not is_inside_tree():
            return
    _overlay.visible = false


func _unhandled_input(event: InputEvent) -> void:
    if board_view == null or not is_instance_valid(board_view):
        return
    if _awaiting == &"card":
        if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
            _awaiting = &""
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("move_left"):
        board_view.move_cursor(Vector2i(-1, 0))
    elif event.is_action_pressed("move_right"):
        board_view.move_cursor(Vector2i(1, 0))
    elif event.is_action_pressed("move_up"):
        board_view.move_cursor(Vector2i(0, -1))
    elif event.is_action_pressed("move_down"):
        board_view.move_cursor(Vector2i(0, 1))
    elif event.is_action_pressed("interact"):
        board_view.activate_cursor()
    elif event.is_action_pressed("cancel"):
        _finished = true
        MatchBridge.finish_lesson(lesson.id, false)
    else:
        return
    get_viewport().set_input_as_handled()
