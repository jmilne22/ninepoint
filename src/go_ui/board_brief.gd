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
    var actions := MouseActions.new()
    actions.position = Vector2(10, 182)
    panel.add_child(actions)
    actions.configure([["Next / play", "interact"], ["Skip", "cancel"]])
    actions.action_selected.connect(func(action: StringName): _input(MouseActions.event(action)))
    _body.text = pages[0]

func _input(event: InputEvent) -> void:
    if event is InputEventMouse:
        return
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
