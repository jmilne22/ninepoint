## Short measured choices beside the board; every dismissal consumes its input.
class_name TeachingChoice
extends Control
signal selected(index: int)

var heading := "PRACTICE"
var text := ""
var options: Array[String] = []
var cancel_index := 0
var _index := 0
var _buttons: Array[Button] = []
var _closed := false
var _frame := 0


func _ready() -> void:
    name = "TeachingChoice"
    z_index = 85
    _frame = Engine.get_process_frames()
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var panel := UiKit.panel(self, Rect2(202, 4, 178, 208))
    UiKit.label(panel, Vector2(10, 9), 158, UiKit.GOLD).text = heading
    var height := UiKit.text_height(text, 158) + UiKit.LINE_H
    UiKit.label(panel, Vector2(10, 28), 158, UiKit.INK, height).text = text
    var choices := VBoxContainer.new()
    choices.position = Vector2(10, 33 + height)
    choices.size.x = 158
    choices.add_theme_constant_override("separation", 5)
    panel.add_child(choices)
    for i in options.size():
        var bar := MouseActions.new()
        choices.add_child(bar)
        bar.configure([[options[i], "option_%d" % i]])
        var button := bar.get_child(0) as Button
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bar.action_selected.connect(func(_action: StringName): choose(i))
        button.mouse_entered.connect(func(): _index = i; _refresh())
        _buttons.append(button)
    UiKit.label(panel, Vector2(10, 188), 158, UiKit.INK_SOFT).text = "Arrows / Space or click"
    _refresh()


func _refresh() -> void:
    for i in _buttons.size():
        _buttons[i].text = ("> " if i == _index else "  ") + options[i]


func _input(event: InputEvent) -> void:
    if event is InputEventMouse:
        return
    get_viewport().set_input_as_handled()
    if _closed or Engine.get_process_frames() <= _frame or event.is_echo():
        return
    if event.is_action_pressed("cancel"):
        choose(cancel_index)
    elif event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
        _index = posmod(_index - 1, options.size())
        _refresh()
    elif event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
        _index = (_index + 1) % options.size()
        _refresh()
    elif event.is_action_pressed("interact"):
        choose(_index)


func choose(index: int) -> void:
    if _closed or index < 0 or index >= options.size():
        return
    _closed = true
    get_viewport().set_input_as_handled()
    selected.emit(index)
    queue_free()
