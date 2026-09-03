## Title screen: the illustration, the name, and three choices.
extends Control

const ITEMS := ["New Game", "Continue", "Quit"]
const OPENING_SCENE := "res://src/ui/opening.tscn"

var _labels: Array[Label] = []
var _index: int = 0
var _busy := false


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    # The one place the game is allowed to announce itself. It carries on under
    # the opening -- Hana speaks over it -- and World._apply_music() takes over
    # the moment the city exists.
    Audio.play_music("theme_title")
    var art := TextureRect.new()
    art.texture = load("res://art/title/title.png")
    art.set_anchors_preset(Control.PRESET_FULL_RECT)
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_SCALE
    art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(art)

    var title := Label.new()
    title.position = Vector2(18, 14)
    title.text = "NINEPOINT"
    title.add_theme_font_size_override("font_size", 27)
    title.add_theme_color_override("font_color", Color("#f2d791"))
    title.add_theme_color_override("font_shadow_color", Color("#14121a"))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 2)
    add_child(title)

    var sub := Label.new()
    sub.position = Vector2(21, 46)
    sub.text = "Verhaven, and the people who play there"
    sub.add_theme_font_size_override("font_size", 9)
    sub.add_theme_color_override("font_color", Color("#ddd0b8"))
    sub.add_theme_color_override("font_shadow_color", Color("#14121a"))
    sub.add_theme_constant_override("shadow_offset_x", 1)
    sub.add_theme_constant_override("shadow_offset_y", 1)
    add_child(sub)

    var y := 130
    for item in ITEMS:
        var l := Label.new()
        l.position = Vector2(22, y)
        l.add_theme_font_size_override("font_size", 9)
        l.add_theme_color_override("font_shadow_color", Color("#14121a"))
        l.add_theme_constant_override("shadow_offset_x", 1)
        l.add_theme_constant_override("shadow_offset_y", 1)
        l.text = item
        add_child(l)
        _labels.append(l)
        y += 16

    var slot := SaveSystem.newest_slot()
    if slot > 0:
        var info := Label.new()
        info.position = Vector2(128, 172)
        info.text = SaveSystem.slot_summary(slot)
        info.add_theme_font_size_override("font_size", 9)
        info.add_theme_color_override("font_color", Color("#f2e9d8"))
        info.add_theme_color_override("font_shadow_color", Color("#14121a"))
        info.add_theme_constant_override("shadow_offset_x", 1)
        info.add_theme_constant_override("shadow_offset_y", 1)
        add_child(info)
    else:
        _index = 0

    _refresh()


func _refresh() -> void:
    var can_continue := SaveSystem.any_save()
    for i in _labels.size():
        var enabled := i != 1 or can_continue
        var selected := i == _index
        _labels[i].text = ("> " if selected else "  ") + ITEMS[i]
        var colour := Color("#f2d791") if selected else Color("#ddd0b8")
        if not enabled:
            colour = Color("#6b6577")
        _labels[i].add_theme_color_override("font_color", colour)


func _unhandled_input(event: InputEvent) -> void:
    if _busy:
        return
    if event.is_action_pressed("move_down"):
        _index = (_index + 1) % ITEMS.size()
        Audio.play("ui_move")
        _refresh()
    elif event.is_action_pressed("move_up"):
        _index = (_index - 1 + ITEMS.size()) % ITEMS.size()
        Audio.play("ui_move")
        _refresh()
    elif event.is_action_pressed("interact"):
        Audio.play("ui_confirm")
        _activate()
    else:
        return
    get_viewport().set_input_as_handled()


func _activate() -> void:
    match _index:
        0:
            # New Game goes to the cold open, which names the player and then
            # sends them to Steenbeek itself.
            _busy = true
            SceneRouter.go_to(OPENING_SCENE)
        1:
            var slot := SaveSystem.newest_slot()
            if slot <= 0:
                return
            _busy = true
            SaveSystem.load_game(slot)
            if GameState.has_return_position:
                SceneRouter.go_to(SceneRouter.WORLD_SCENE, "", GameState.return_position)
            else:
                SceneRouter.go_to_map(GameState.current_map, GameState.spawn_point)
        2:
            get_tree().quit()
