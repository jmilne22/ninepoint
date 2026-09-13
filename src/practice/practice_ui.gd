## Container-based controls share the production typeface and palette.
class_name PracticeUi
extends RefCounted

static func label(parent: Node, text: String, heading := false) -> Label:
    var node := Label.new()
    node.text = text
    node.add_theme_font_override("font", UiKit.FONT)
    node.add_theme_font_size_override("font_size", 12 if heading else 9)
    node.add_theme_color_override("font_color", Color("f2d791") if heading else Color("eee4d0"))
    parent.add_child(node)
    return node

static func paragraph(parent: Node, text: String) -> Label:
    var node := label(parent, text)
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return node

static func button(parent: Node, text: String, action: Callable) -> Button:
    var node := Button.new()
    node.text = text
    node.custom_minimum_size.y = 17
    node.add_theme_font_override("font", UiKit.FONT)
    node.add_theme_font_size_override("font_size", 9)
    for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
        node.add_theme_color_override(state, Color("203b36"))
    node.pressed.connect(action)
    parent.add_child(node)
    return node

static func choice(parent: Node, title: String, labels: Array, selected: int, changed: Callable) -> OptionButton:
    var row := HBoxContainer.new()
    parent.add_child(row)
    var name := label(row, title)
    name.custom_minimum_size.x = 74
    var node := OptionButton.new()
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    node.add_theme_font_override("font", UiKit.FONT)
    node.add_theme_font_size_override("font_size", 9)
    for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
        node.add_theme_color_override(state, Color("203b36"))
    for value in labels: node.add_item(str(value))
    node.select(selected)
    node.item_selected.connect(changed)
    row.add_child(node)
    return node

static func number(parent: Node, title: String, value: float, minimum: float, maximum: float, step: float, changed: Callable) -> SpinBox:
    var row := HBoxContainer.new()
    parent.add_child(row)
    var name := label(row, title)
    name.custom_minimum_size.x = 74
    var node := SpinBox.new()
    node.min_value = minimum
    node.max_value = maximum
    node.step = step
    node.value = value
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    node.value_changed.connect(changed)
    row.add_child(node)
    style_field(node.get_line_edit())
    return node

static func style_field(field: LineEdit) -> void:
    field.add_theme_font_override("font", UiKit.FONT)
    field.add_theme_font_size_override("font_size", 9)
    field.add_theme_color_override("font_color", Color("203b36"))
    field.add_theme_color_override("font_uneditable_color", Color("62766a"))

static func scroll(parent: Node) -> VBoxContainer:
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    parent.add_child(scroll)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 5)
    scroll.add_child(content)
    scroll.follow_focus = true
    return content
