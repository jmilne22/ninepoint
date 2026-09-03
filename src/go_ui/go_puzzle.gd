## A Go problem, played on the same board view as a real game.
##
## Wrong answers are undone and explained rather than punished -- this is the
## teaching surface of the game.
extends Control

var puzzle: GoPuzzleData
var game: GoGame
var board_view: GoBoardView
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
    # A puzzle handed over in memory by the review takes priority: it is the
    # player's own position from the game they just lost, and there is no file.
    var puzzle_id := MatchBridge.pending_puzzle
    if MatchBridge.pending_puzzle_data != null:
        puzzle = MatchBridge.pending_puzzle_data
        puzzle_id = puzzle.id
    else:
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

    _title = _label(panel, Vector2(10, 8), 156, 9, "#8a6023", 14)
    _title.text = puzzle.title
    _goal = _label(panel, Vector2(10, 26), 156, 9, "#14121a", 40)
    _goal.text = puzzle.goal
    _message = _label(panel, Vector2(10, 74), 156, 9, "#8c4034", 60)
    _hints = _label(self, Vector2(204, 172), 176, 9, "#8a8494", 40)
    _hints.text = "Arrows: move   Space: play\nR: reset the position"

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
    if solved or _finished:
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
    game.play(point)
    board_view.queue_redraw()
    await get_tree().create_timer(0.55).timeout
    game.undo()
    board_view.queue_redraw()
    if attempts == 1:
        _message.text = "Not quite. Look again -- nothing was captured."
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
