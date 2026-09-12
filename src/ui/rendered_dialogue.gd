## Same dialogue interpreter/input, with model-rendered busts and a measured bottom card.
extends DialogueBox

const PAPER := Color("#e5dbc1")
const GOLD := Color("#d6b777")
const PANEL_Y := 154
var _portrait_id := ""
var _choice_scroll: ScrollContainer


func _build() -> void:
    super._build()
    _panel.texture = load("res://art/rendered/ui/panel_dark.png")
    _panel.position = Vector2(8, PANEL_Y)
    _panel.size = Vector2(368, 56)
    _name_label.position = Vector2(12, 5)
    _name_label.add_theme_color_override("font_color", GOLD)
    _name_plate.hide()
    _text.position = Vector2(12, 20)
    _text.size = Vector2(344, 33)
    _text.add_theme_color_override("font_color", PAPER)
    _more.position = Vector2(352, 41)
    _more.add_theme_color_override("font_color", GOLD)
    _portrait.reparent(_root)
    _portrait.size = Vector2(108, 108)
    _portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _portrait.position = Vector2(266, PANEL_Y - 108)
    # The card covers the bottom of the model; its shoulders rise above the frame.
    _root.move_child(_portrait, 0)
    _choice_scroll = ScrollContainer.new()
    _choice_scroll.position = Vector2(12, 20)
    _choice_scroll.size = Vector2(344, 66)
    _choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _panel.add_child(_choice_scroll)
    _choice_box.reparent(_choice_scroll)
    _choice_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _choice_box.add_theme_constant_override("separation", 3)


func show_box() -> void:
    _root.show()


func _set_speaker(who: Dictionary, expression: String) -> void:
    _name_label.text = str(who.get("name", ""))
    if not str(who.get("rank", "")).is_empty():
        _name_label.text += "   " + str(who.rank)
    _portrait_id = str(who.get("id", ""))
    if _portrait_id == "":
        var portrait: Texture2D = who.get("portrait")
        if portrait != null:
            _portrait_id = portrait.resource_path.get_file().get_basename()
    var path := "res://art/rendered/people/%s_bust.png" % _portrait_id
    _portrait.visible = ResourceLoader.exists(path)
    if _portrait.visible:
        var strip_path := "res://art/rendered/people/%s_busts.png" % _portrait_id
        if ResourceLoader.exists(strip_path):
            var atlas := AtlasTexture.new()
            atlas.atlas = load(strip_path)
            atlas.region = Rect2(PortraitMoods.column(expression) * 108, 0, 108, 108)
            _portrait.texture = atlas
        else:
            _portrait.texture = load(path)
    _text.size.x = 344


func _speaker_for(key: String, fallback: Dictionary) -> Dictionary:
    var who := super._speaker_for(key, fallback)
    who["id"] = key
    return who


func _pages(line: String) -> PackedStringArray:
    return UiKit.paginate(line, 344, 33)


func _say(line: String) -> void:
    _choice_scroll.hide()
    _panel.position.y = PANEL_Y
    _panel.size.y = 56
    _portrait.position.y = PANEL_Y - 108
    await super._say(line)


func _choose(options: Array) -> Dictionary:
    var total := 0
    for option: Dictionary in options:
        total += UiKit.text_height("> " + str(option.get("text", "")), 332) + 3
    var body_h := mini(total + 3, 88)
    var height := body_h + 29
    _panel.position.y = 210 - height
    _panel.size.y = height
    _portrait.position.y = maxf(8, _panel.position.y - 108)
    _choice_scroll.size.y = body_h
    _choice_scroll.show()
    var result := await super._choose(options)
    _choice_scroll.hide()
    return result


func _highlight() -> void:
    super._highlight()
    for i in _choice_nodes.size():
        _choice_nodes[i].add_theme_color_override("font_color", GOLD if i == _choice_index else PAPER)
    _follow_choice.call_deferred()


func _follow_choice() -> void:
    if _choice_index < _choice_nodes.size() and is_instance_valid(_choice_nodes[_choice_index]):
        _choice_scroll.ensure_control_visible(_choice_nodes[_choice_index])
