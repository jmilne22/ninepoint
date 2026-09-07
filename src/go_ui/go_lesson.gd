## Walks a GoLessonData: a position, a thing to do, and a sentence about what
## happened. Reuses GoBoardView, so a lesson looks exactly like a real game.
extends Control

var lesson: GoLessonData
var game: GoGame
var lesson_actions := GoLessonActions.new()
var board_view: GoBoardView
var _navigation: BoardNavigation
var _actions: MouseActions
var _modal_actions: MouseActions
var _busy := false

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
    LessonLayout.build(self)


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
            await _show_feedback(explanation)
        await LessonDemonstration.show_proofs(self)
    if lesson.outro.size() > 0:
        await _show_card("\n\n".join(lesson.outro))
    _finished = true
    GameState.set_flag("lesson_%s_done" % lesson.id, true)
    MatchBridge.finish_lesson(lesson.id, true)


func _load_step() -> void:
    var step: Dictionary = lesson.steps[step_index]
    game = lesson.make_game(step_index)
    board_view.set_game(game)
    lesson_actions.setup(game, step)
    board_view.dead = lesson_actions.dead
    board_view.show_territory = step["action"] == "count"
    board_view.show_liberties = bool(step["show_liberties"])
    board_view.highlight = step["target"]
    _instruction.size.y = 52
    _message.show()
    _message.position.y = 85 if step["action"] == "count" else 98
    _message.size.y = 66 if step["action"] == "count" else 52
    _instruction.text = str(step["instruction"])
    _progress.text = "Step %d of %d" % [step_index + 1, lesson.step_count()]
    _message.text = ""
    if step["action"] == "count":
        _message.text = lesson_actions.score_text()
        board_view.territory = lesson_actions.current_score()["territory"]
    if step["action"] != "play":
        _hints.text = "Click / Space: inspect"
    elif bool(step["show_liberties"]):
        _hints.text = "Click / Space: play\nThe rings show liberties."
    else:
        _hints.text = "Click / Space: play"


func _on_point(point: int) -> void:
    if _finished or _busy or _awaiting != &"step":
        return
    if lesson.steps[step_index]["action"] != "play":
        if lesson.steps[step_index]["action"] == "inspect":
            board_view.liberty_targets = game.board.chain_at(point)["stones"]
        if lesson_actions.activate(point):
            _awaiting = &""
        elif lesson.steps[step_index]["action"] == "inspect":
            _message.text = "Group inspected. Now inspect the other highlighted group."
        if lesson.steps[step_index]["action"] == "count":
            _message.text = lesson_actions.score_text()
            board_view.territory = lesson_actions.current_score()["territory"]
        board_view.queue_redraw()
        return
    var code := game.legality(point)
    var legal := code == GoGame.Legality.LEGAL
    var captured := 0
    if legal:
        var probe := game.board.duplicate_board()
        captured = probe.place(point, game.to_move).size()

    if lesson.step_accepts(step_index, point, legal, captured):
        _busy = true
        _sync_pointer()
        if legal:
            _message.text = ""
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
            if not is_inside_tree() or _finished:
                return
            if not lesson_actions.play_reply():
                push_error("Invalid authored lesson reply")
                return
            board_view.queue_redraw()
        else:
            Audio.play("illegal")
            _message.text = game.legality_reason(code)
            await get_tree().create_timer(0.6).timeout
        if _finished or not is_inside_tree():
            return
        _awaiting = &""
        _busy = false
        _sync_pointer()
        return

    # Not what the step wanted.
    attempts += 1
    if not legal:
        Audio.play("illegal")
        _message.text = game.legality_reason(code)
        return
    _busy = true
    _sync_pointer()
    _message.text = ""
    game.play(point)
    Audio.play_stone()
    board_view.queue_redraw()
    await get_tree().create_timer(0.5).timeout
    if _finished or not is_inside_tree():
        return
    game.undo()
    _busy = false
    _sync_pointer()
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
    for region in GoScoring.empty_regions(game.board):
        if region["points"].has(start):
            return region["points"]
    return PackedInt32Array()


## Long explanations are paginated rather than clipped -- the lesson text is the
## product here, so it must never run off the bottom of the card.
func _show_feedback(text: String) -> void:
    _message.hide()
    _instruction.size.y = 110
    for page in UiKit.paginate(text, 156, 110):
        _instruction.text = page
        _hints.text = "Inspect the board.\nSpace: next   Esc: leave"
        await _ask(&"feedback")
        if not is_inside_tree() or _finished:
            return


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
    if event.is_action_pressed("cancel"):
        _finished = true
        get_viewport().set_input_as_handled()
        MatchBridge.finish_lesson(lesson.id, false)
        return
    if _awaiting == &"feedback":
        if event.is_action_pressed("interact"):
            _awaiting = &""
            get_viewport().set_input_as_handled()
            return
    if _awaiting == &"card":
        if event.is_action_pressed("interact"):
            _awaiting = &""
            get_viewport().set_input_as_handled()
        return
    if _busy and not event.is_action_pressed("cancel"):
        get_viewport().set_input_as_handled()
        return
    if _navigation.handle_input(event):
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
    elif event.is_action_pressed("go_pass") and _awaiting == &"step":
        if lesson_actions.pass_and_reply() or (lesson.steps[step_index]["action"] == "count" and lesson_actions.accept_count()):
            _awaiting = &""
        else:
            _message.text = "Check the marked group twice, restore the count, then confirm."
    else:
        return
    get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
    _sync_pointer()


func _sync_pointer() -> void:
    if board_view == null:
        return
    var active := not _finished and not _busy and _awaiting == &"step"
    board_view.interactive = active and not _overlay.visible
    board_view.inspection = board_view.interactive or _awaiting == &"feedback"
    var mode := BoardPointer.Mode.PLACE if board_view.interactive and lesson.steps[step_index]["action"] == "play" else BoardPointer.Mode.INSPECT
    board_view.pointer.configure(mode, game.to_move if game != null else GoBoard.BLACK, board_view)
    _navigation.visible = not _overlay.visible
    _actions.visible = not _overlay.visible
    var specs: Array = [["Leave Esc", "cancel"]]
    if _awaiting == &"feedback":
        specs.push_front(["Next", "interact"])
    elif active and lesson.steps[step_index]["action"] in ["pass", "count"]:
        specs.push_front(["Pass P" if lesson.steps[step_index]["action"] == "pass" else "Confirm P", "go_pass"])
    _actions.configure(specs)


func _mouse_action(action: StringName) -> void:
    _unhandled_input(MouseActions.event(action))
    _sync_pointer()
