## Once per running session, before the first move on nineteen lines.
class_name BoardControls
extends CanvasLayer

signal closed
static var shown := false


func _ready() -> void:
    name = "BoardControls"
    layer = 40
    var dim := ColorRect.new()
    dim.color = Color(0.05, 0.05, 0.08, 0.82)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var card := UiKit.panel(dim, Rect2())
    var body := UiKit.label(card, Vector2.ZERO, 280, UiKit.INK)
    UiKit.fit_card(card, body,
        "Nineteen lines.\n\nPoint and click to place a stone. Arrows and Space also work.\n\nZoom V opens a close view at your selected point. Whole returns to the full board. The arrow buttons pan the close view.\n\nLines continuing past an edge mean there is more board.\n\n[Space] try it", 320)
    var actions := MouseActions.new()
    actions.position = Vector2(140, 197)
    dim.add_child(actions)
    actions.configure([["Try it", "interact"]])
    actions.action_selected.connect(func(action: StringName): _input(MouseActions.event(action)))
    shown = true


func _input(event: InputEvent) -> void:
    if event is InputEventMouse:
        return
    # Dismissing this must never also place the first stone underneath it.
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        closed.emit()
        queue_free()
