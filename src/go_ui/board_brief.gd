## A player-controlled rules reminder next to the board being used.
class_name BoardBrief
extends Control
signal closed
var pages: PackedStringArray
var _index := 0
var _body: Label

func _ready() -> void:
    name = "BoardBrief"
    z_index = 80
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := UiKit.panel(self, Rect2(202, 4, 178, 208))
    _body = UiKit.label(panel, Vector2(10, 12), 158, UiKit.INK, 165)
    UiKit.label(panel, Vector2(10, 182), 158, UiKit.GOLD, 15).text = "Space: next  Esc: skip"
    _body.text = pages[0]

func _input(event: InputEvent) -> void:
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("cancel"):
        closed.emit()
        queue_free()
    elif event.is_action_pressed("interact"):
        _index += 1
        if _index >= pages.size():
            closed.emit()
            queue_free()
        else:
            _body.text = pages[_index]
