## A Go problem, played on the same board view as a real game.
##
## Wrong answers are undone and explained rather than punished -- this is the
## teaching surface of the game.
extends Control

var puzzle: GoPuzzleData
var game: GoGame
var board_view: GoBoardView
var _navigation: BoardNavigation
var _actions: MouseActions
var _modal_actions: MouseActions
var _busy := false
var attempts: int = 0
var solved: bool = false

var _title: Label
var _goal: Label
var _message: Label
var _hints: Label
var _overlay: Control
var _card: NinePatchRect
var _overlay_text: Label
var _dismissed := false
var _finished := false


func _ready() -> void:
    var puzzle_id := MatchBridge.pending_puzzle
    if puzzle_id == "":
        puzzle_id = "capture_1"
    puzzle = GoPuzzleData.load_puzzle(puzzle_id)
    if puzzle == null:
        MatchBridge.finish_puzzle(puzzle_id, false)
        return
    game = puzzle.make_game()
    _build_ui()
    board_view.set_game(game)
    board_view.highlight = puzzle.target
    _message.text = ""
    set_process_unhandled_input(true)


func _build_ui() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color("#2a2633")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    board_view = GoBoardView.new()
    board_view.position = Vector2(6, 8)
    board_view.size = Vector2(192, 192)
    board_view.point_activated.connect(_on_point)
    add_child(board_view)
    _navigation = BoardNavigation.new()
    _navigation.position = Vector2(6, 200)
    _navigation.size = Vector2(192, 16)
    add_child(_navigation)
    _navigation.setup(board_view)
    _actions = MouseActions.new()
    _actions.position = Vector2(204, 197)
    add_child(_actions)
    _actions.action_selected.connect(_mouse_action)

    var panel := NinePatchRect.new()
    panel.texture = load("res://art/ui/panel.png")
    for m in ["left", "top", "right", "bottom"]:
        panel.set("patch_margin_%s" % m, 6)
    panel.position = Vector2(202, 8)
    panel.size = Vector2(176, 158)
    panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(panel)

    _title = _label(panel, Vector2(10, 8), 156, 9, "#8a6023", 14)
    _title.text = puzzle.title
    _goal = _label(panel, Vector2(10, 26), 156, 9, "#14121a", 40)
    _goal.text = puzzle.goal
    _message = _label(panel, Vector2(10, 74), 156, 9, "#8c4034", 60)
    _hints = _label(self, Vector2(204, 172), 176, 9, "#8a8494", 40)
    _hints.text = "Click / Space: play\nR: reset the position"

    _overlay = Control.new()
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.visible = false
    add_child(_overlay)
    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.07, 0.1, 0.72)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.add_child(dim)
    _card = UiKit.panel(_overlay, Rect2(40, 52, 304, 112))
    _overlay_text = UiKit.label(_card, Vector2(10, 10), 284, UiKit.INK, 88)
    _modal_actions = MouseActions.new()
    _modal_actions.position = Vector2(138, 197)
    _overlay.add_child(_modal_actions)
    _modal_actions.configure([["Continue", "interact"]])
    _modal_actions.action_selected.connect(_mouse_action)


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


func _on_point(point: int) -> void:
    if solved or _finished or _busy:
        return
    var code := game.legality(point)
    if code != GoGame.Legality.LEGAL:
        _message.text = game.legality_reason(code)
        return

    if puzzle.is_solution(point):
        game.play(point)
        board_view.highlight = PackedInt32Array()
        board_view.queue_redraw()
        solved = true
        await _succeed()
        return

    attempts += 1
    _busy = true
    _sync_pointer()
    game.play(point)
    board_view.queue_redraw()
    await get_tree().create_timer(0.55).timeout
    if _finished or not is_inside_tree():
        return
    game.undo()
    _busy = false
    _sync_pointer()
    board_view.queue_redraw()
    if attempts == 1:
        _message.text = "That move does not solve this position. Try again."
    else:
        _message.text = "Hint: %s" % puzzle.hint


func _succeed() -> void:
    _finished = true
    GameState.set_flag("%s_solved" % puzzle.id, true)
    UiKit.fit_card(_card, _overlay_text,
        "Correct.\n\n%s\n\n[Space] to carry on" % puzzle.explanation, 304)
    _overlay.visible = true
    _hints.text = ""
    while not _dismissed:
        await get_tree().process_frame
    MatchBridge.finish_puzzle(puzzle.id, true)


func _unhandled_input(event: InputEvent) -> void:
    if board_view == null or not is_instance_valid(board_view):
        return
    if _finished:
        if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
            _dismissed = true
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
    elif event.is_action_pressed("go_resign"):
        game = puzzle.make_game()
        board_view.set_game(game)
        board_view.highlight = puzzle.target
        _message.text = "Position reset."
    elif event.is_action_pressed("cancel"):
        _finished = true
        MatchBridge.finish_puzzle(puzzle.id, false)
    else:
        return
    get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
    _sync_pointer()


func _sync_pointer() -> void:
    if board_view == null:
        return
    var active := not _finished and not _busy and not solved
    board_view.interactive = active and not _overlay.visible
    board_view.inspection = board_view.interactive
    var mode := BoardPointer.Mode.PLACE if board_view.interactive else BoardPointer.Mode.HIDDEN
    board_view.pointer.configure(mode, game.to_move if game != null else GoBoard.BLACK, board_view)
    _navigation.visible = not _overlay.visible
    _actions.visible = not _overlay.visible
    _actions.configure([["Reset R", "go_resign", not _busy], ["Leave Esc", "cancel"]])


func _mouse_action(action: StringName) -> void:
    _unhandled_input(MouseActions.event(action))
    _sync_pointer()
