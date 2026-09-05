## Small encounter controls. Mouse and keyboard share the scene's action handler.
class_name MouseActions
extends HBoxContainer

signal action_selected(action: StringName)
var _specs: Array = []


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_theme_constant_override("separation", 3)


func configure(specs: Array) -> void:
    if specs == _specs:
        return
    _specs = specs.duplicate(true)
    for child in get_children():
        remove_child(child)
        child.queue_free()
    for spec: Array in specs:
        var button := Button.new()
        button.text = str(spec[0])
        button.name = str(spec[1])
        button.focus_mode = Control.FOCUS_NONE
        button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        button.disabled = spec.size() > 2 and not bool(spec[2])
        button.add_theme_font_override("font", UiKit.FONT)
        button.add_theme_font_size_override("font_size", 9)
        for state in ["normal", "hover", "pressed", "disabled"]:
            var style := StyleBoxFlat.new()
            style.bg_color = UiKit.PAPER if state == "normal" else (
                Color("#eccd96") if state == "hover" else Color("#bda98c"))
            style.border_color = UiKit.INK_FAINT
            style.set_border_width_all(1)
            style.content_margin_left = 3
            style.content_margin_right = 3
            style.content_margin_top = 2
            style.content_margin_bottom = 2
            button.add_theme_stylebox_override(state, style)
            button.add_theme_color_override("font_" + state + "_color", UiKit.INK)
        button.add_theme_color_override("font_color", UiKit.INK)
        button.add_theme_color_override("font_disabled_color", UiKit.INK_FAINT)
        button.pressed.connect(func(): action_selected.emit(StringName(spec[1])))
        add_child(button)


static func event(action: StringName) -> InputEventAction:
    var value := InputEventAction.new()
    value.action = action
    value.pressed = true
    return value
