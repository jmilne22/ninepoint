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
        "Nineteen lines.\n\nYou can see the whole board. Press V for a close view around your cursor; press V again to see it all.\n\nArrows move. Space places a stone. In close view, lines continuing past the edge mean there is more board.\n\n[Space] try it", 320)
    shown = true


func _input(event: InputEvent) -> void:
    # Dismissing this must never also place the first stone underneath it.
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        closed.emit()
        queue_free()
