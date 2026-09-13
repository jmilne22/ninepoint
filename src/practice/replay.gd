class_name PracticeReplay
extends Control

var record: Dictionary
var board: GoBoardView
var positions: Array[GoGame] = []
var current := 0
var detail: Label
var bar: MouseActions

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    z_index = 50
    var bg := ColorRect.new()
    bg.color = Color("203b36")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var replay := MatchAnalysis.replay(record.sgf)
    var game := GoGame.new(int(record.board_size), float(record.komi), int(record.handicap))
    game.capture_goal = int(record.get("capture_goal", 0))
    positions.append(game.fork())
    for move: Dictionary in replay.get("moves", []):
        if int(move.point) == GoGame.PASS: game.pass_turn()
        else: game.play(int(move.point))
        positions.append(game.fork())
    board = GoBoardView.new()
    board.position = Vector2(6, 8)
    board.size = Vector2(192, 192)
    board.interactive = false
    board.inspection = true
    board.show_coordinates = true
    add_child(board)
    var panel := VBoxContainer.new()
    panel.position = Vector2(210, 15)
    panel.size = Vector2(164, 170)
    add_child(panel)
    PracticeUi.label(panel, "GAME REPLAY", true)
    detail = PracticeUi.paragraph(panel, "")
    detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    bar = MouseActions.new()
    panel.add_child(bar)
    bar.configure([["First", "first"], ["<", "previous"], [">", "next"], ["Last", "last"]])
    bar.action_selected.connect(action)
    PracticeUi.button(panel, "Close", queue_free)
    refresh()

func refresh() -> void:
    board.set_game(positions[current])
    detail.text = "Move %d of %d\n%s\n\nLeft / Right: one move\nHome / End: first / last\nEsc: close" % [current, positions.size() - 1, record.summary]

func action(value: StringName) -> void:
    match value:
        &"first": current = 0
        &"last": current = positions.size() - 1
        &"previous": current = maxi(0, current - 1)
        &"next": current = mini(positions.size() - 1, current + 1)
    refresh()

func _input(event: InputEvent) -> void:
    if event is InputEventMouse: return
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("cancel"): queue_free()
    elif event.is_action_pressed("move_left"): action(&"previous")
    elif event.is_action_pressed("move_right"): action(&"next")
    elif event is InputEventKey and event.pressed:
        if event.keycode == KEY_HOME: action(&"first")
        if event.keycode == KEY_END: action(&"last")
