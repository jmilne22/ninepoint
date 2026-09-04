## Title screen: the illustration, the name, and three choices.
extends Control

## New Game and Continue stay at 0 and 1. The autopilot navigates this menu by
## counting move_downs, so anything new goes on the end.
const ITEMS := ["New Game", "Continue", "Load Game", "Quit"]
const OPENING_SCENE := "res://src/ui/opening.tscn"

var _labels: Array[Label] = []
var _index: int = 0
var _busy := false
var _info: Label
var _slots: SaveSlots


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

    # A title card needs a quiet place for type. The old screen put its title,
    # subtitle and save menu straight on the skyline and then placed the board
    # underneath them; it made the most important screen read like a debug
    # overlay. The illustration now belongs to the right, the information to
    # this framed left column.
    UiKit.panel(self, Rect2(12, 12, 142, 192), true)

    var title := Label.new()
    title.position = Vector2(24, 26)
    title.size = Vector2(118, 24)
    title.text = "NINEPOINT"
    title.add_theme_font_override("font", UiKit.FONT)
    title.add_theme_font_size_override("font_size", 21)
    title.add_theme_color_override("font_color", Color("#f2d791"))
    title.add_theme_color_override("font_shadow_color", Color("#14121a"))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 2)
    add_child(title)

    var sub := Label.new()
    sub.position = Vector2(25, 55)
    sub.size = Vector2(116, UiKit.LINE_H)
    sub.text = "Verhaven plays Go."
    sub.add_theme_font_override("font", UiKit.FONT)
    sub.add_theme_font_size_override("font_size", 9)
    sub.add_theme_color_override("font_color", Color("#ddd0b8"))
    sub.add_theme_color_override("font_shadow_color", Color("#14121a"))
    sub.add_theme_constant_override("shadow_offset_x", 1)
    sub.add_theme_constant_override("shadow_offset_y", 1)
    add_child(sub)

    var y := 94
    for item in ITEMS:
        var l := Label.new()
        l.position = Vector2(25, y)
        l.size = Vector2(110, UiKit.LINE_H)
        l.add_theme_font_override("font", UiKit.FONT)
        l.add_theme_font_size_override("font_size", 9)
        l.add_theme_color_override("font_shadow_color", Color("#14121a"))
        l.add_theme_constant_override("shadow_offset_x", 1)
        l.add_theme_constant_override("shadow_offset_y", 1)
        l.text = item
        add_child(l)
        _labels.append(l)
        y += 16

    # Built once and driven by _refresh(): deleting the newest save used to
    # leave this line describing a file that no longer existed.
    _info = Label.new()
    _info.position = Vector2(25, 169)
    _info.size = Vector2(110, 24)
    _info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _info.add_theme_font_override("font", UiKit.FONT)
    _info.add_theme_font_size_override("font_size", 9)
    _info.add_theme_color_override("font_color", Color("#f2e9d8"))
    _info.add_theme_color_override("font_shadow_color", Color("#14121a"))
    _info.add_theme_constant_override("shadow_offset_x", 1)
    _info.add_theme_constant_override("shadow_offset_y", 1)
    add_child(_info)

    _slots = SaveSlots.new()
    _slots.chosen.connect(_on_slot_chosen)
    _slots.cancelled.connect(_refresh)
    _slots.changed.connect(_refresh)
    add_child(_slots)

    _refresh()


func _enabled(i: int) -> bool:
    # Continue and Load Game both need something to read.
    return not (i == 1 or i == 2) or SaveSystem.any_save()


func _refresh() -> void:
    # The slot list is a card over the artwork, and the menu underneath it was
    # showing through below its bottom edge.
    var listing := _slots != null and _slots.visible
    var slot := SaveSystem.newest_slot()
    _info.visible = slot > 0 and not listing
    if slot > 0:
        _info.text = SaveSystem.slot_summary(slot)
    for l in _labels:
        l.visible = not listing
    for i in _labels.size():
        var enabled := _enabled(i)
        var selected := i == _index
        _labels[i].text = ("> " if selected else "  ") + ITEMS[i]
        var colour := Color("#f2d791") if selected else Color("#ddd0b8")
        if not enabled:
            colour = Color("#6b6577")
        _labels[i].add_theme_color_override("font_color", colour)


func _unhandled_input(event: InputEvent) -> void:
    if _busy or _slots.visible:
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
        if not _enabled(_index):
            return
        Audio.play("ui_confirm")
        _activate()
    else:
        return
    get_viewport().set_input_as_handled()


func _activate() -> void:
    match _index:
        0:
            # New Game goes to the cold open, which names the player and then
            # sends them to Steenbeek itself. It only asks which slot when it
            # has to: a menu in front of the cold open every time would be a
            # tax on the common case to cover the rare one.
            var empty := SaveSystem.first_empty_slot()
            if empty > 0:
                _start_new(empty)
            else:
                _slots.open(SaveSlots.Mode.NEW, SaveSystem.newest_slot() - 1)
                _refresh()
        1:
            _enter_slot(SaveSystem.newest_slot())
        2:
            _slots.open(SaveSlots.Mode.LOAD, SaveSystem.newest_slot() - 1)
            _refresh()
        3:
            get_tree().quit()


func _on_slot_chosen(slot: int) -> void:
    if _slots.mode == SaveSlots.Mode.NEW:
        _start_new(slot)
    else:
        _enter_slot(slot)


func _start_new(slot: int) -> void:
    _busy = true
    # Nothing is written yet -- a new run has no file until it is saved. This
    # only says where it will go.
    GameState.active_slot = slot
    SceneRouter.go_to(OPENING_SCENE)


## The one place a slot becomes a position in the world. Continue and the slot
## list both come through here so the routing rule is written once.
func _enter_slot(slot: int) -> void:
    if slot <= 0 or not SaveSystem.load_game(slot):
        _refresh()
        return
    _busy = true
    if GameState.has_return_position:
        SceneRouter.go_to(SceneRouter.WORLD_SCENE, "", GameState.return_position)
    else:
        SceneRouter.go_to_map(GameState.current_map, GameState.spawn_point)
