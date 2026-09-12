## Replays only the recorded capture. It neither requests analysis nor records a game.
class_name CaptureReview
extends CanvasLayer

signal closed
var payload: Dictionary
var _board: GoBoardView
var _body: Label
var _after := false


func _ready() -> void:
    var game := CaptureGuide.review_position(payload)
    if game == null:
        _close.call_deferred()
        return
    layer = 30
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.07, 0.1, 0.95)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(dim)
    _board = GoBoardView.new()
    _board.position = Vector2(6, 8)
    _board.size = Vector2(192, 192)
    _board.interactive = false
    root.add_child(_board)
    var panel := UiKit.panel(root, Rect2(202, 4, 178, 208))
    _body = UiKit.label(panel, Vector2(10, 12), 158, UiKit.INK, 165)
    var actions := MouseActions.new()
    actions.position = Vector2(10, 182)
    panel.add_child(actions)
    actions.configure([["Next", "interact"], ["Close", "cancel"]])
    actions.action_selected.connect(func(action: StringName): _input(MouseActions.event(action)))
    _show_position()


func _show_position() -> void:
    var game := CaptureGuide.review_position(payload, _after)
    _board.set_game(game)
    var point := int(payload["point"])
    if _after:
        _body.text = "AFTER THE CAPTURE\n\n%s played at %s. The captured stones had no liberties left, so they came off.\n\nThat ended this Capture Go practice.\n\nSpace: return" % [GoBoard.color_name(int(payload["color"])), game.board.label(point)]
        _board.highlight = PackedInt32Array([point])
        _board.animate_placement(point)
        _board.animate_capture(game.last_move()["captured"])
    else:
        var captured := CaptureGuide.review_position(payload, true).last_move()["captured"] as PackedInt32Array
        _board.highlight = captured
        _board.liberty_targets = captured
        _board.show_liberties = true
        _body.text = "BEFORE THE CAPTURE\n\nThe highlighted stones have one liberty left, at %s.\n\n%s filled it on the final move.\n\nSpace: see the capture" % [game.board.label(point), GoBoard.color_name(int(payload["color"]))]
    _board.queue_redraw()


func _input(event: InputEvent) -> void:
    if event is InputEventMouse:
        return
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("cancel") or (_after and event.is_action_pressed("interact")):
        _close()
    elif event.is_action_pressed("interact"):
        _after = true
        _show_position()


func _close() -> void:
    closed.emit()
    queue_free()
