## Title screen: the illustration, the name, and three choices.
extends Control

## New Game and Continue stay at 0 and 1. The autopilot navigates this menu by
## counting move_downs, so anything new goes on the end.
const ITEMS := ["New Game", "Continue", "Load Game", "Quit"]
const OPENING_SCENE := "res://src/ui/opening.tscn"

## The framed left column. Every position in it is measured off this rect.
const CARD := Rect2(12, 10, 142, 186)
const FIRST_ROW := 74
const ROW_STEP := 16

var _labels: Array[Label] = []
var _index: int = 0
var _busy := false
var _card: Control
var _cursor: Control
var _info: Label
var _hint: Label
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
    # overlay. The illustration belongs to the right, the information to this
    # framed left column. Everything in the column is measured off CARD so the
    # rules and the save line cannot drift away from the rows they divide.
    _card = Control.new()
    _card.set_anchors_preset(Control.PRESET_FULL_RECT)
    _card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_card)
    UiKit.panel(_card, CARD, true)

    # Size 18, not 21. The bitmap font's native size is 9 and only whole
    # multiples of it land on whole pixels; 21 was scaling the largest piece of
    # type in the game by a seventh, which is the one thing a bitmap font is
    # chosen to avoid (ART_DIRECTION 4b).
    UiKit.shadow_label(_card, Vector2(CARD.position.x + 12, CARD.position.y + 12),
        int(CARD.size.x) - 20, Color("#f2d791"), 18, 2).text = "NINEPOINT"
    _rule(CARD.position.y + 36)
    UiKit.shadow_label(_card, Vector2(CARD.position.x + 13, CARD.position.y + 42),
        int(CARD.size.x) - 24, Color("#ddd0b8")).text = "Verhaven plays Go."

    # A drawn cursor rather than a "> " prefix: the prefix moved every row's
    # text two characters sideways as the selection passed it, and a menu that
    # shuffles under the cursor is a menu that looks unfinished.
    _cursor = Control.new()
    _cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _card.add_child(_cursor)
    for i in 5:
        var bar := ColorRect.new()
        bar.color = Color("#f2d791")
        bar.position = Vector2(0, i)
        bar.size = Vector2(3 - absi(i - 2), 1)
        _cursor.add_child(bar)

    var y := int(CARD.position.y + FIRST_ROW)
    for item in ITEMS:
        var l := UiKit.shadow_label(_card, Vector2(CARD.position.x + 20, y),
            int(CARD.size.x) - 30, Color("#ddd0b8"))
        l.text = item
        _labels.append(l)
        y += ROW_STEP

    _rule(CARD.position.y + 138)

    # Built once and driven by _refresh(): deleting the newest save used to
    # leave this line describing a file that no longer existed. It sits inside
    # the card now instead of over the skyline, where a known-issue note in
    # MILESTONES has had it since M31.
    _info = UiKit.shadow_label(_card, Vector2(CARD.position.x + 13, CARD.position.y + 145),
        int(CARD.size.x) - 24, Color("#f2e9d8"))
    _info.size.y = 22
    _info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    # Inside the card, not under it: at 384x216 there are twenty pixels below
    # the panel and a nine-pixel line put on them lands on the letterbox.
    _hint = UiKit.shadow_label(_card, Vector2(CARD.position.x + 13,
        CARD.position.y + 168), int(CARD.size.x) - 24, Color("#6b6577"))
    _hint.text = "Up Down     Space"

    _slots = SaveSlots.new()
    _slots.chosen.connect(_on_slot_chosen)
    _slots.cancelled.connect(_refresh)
    _slots.changed.connect(_refresh)
    add_child(_slots)

    _refresh()
    _fade_in()


## A hairline the width of the card's type column, between the blocks.
func _rule(y: float) -> void:
    var line := ColorRect.new()
    line.color = Color("#6b6577")
    line.position = Vector2(CARD.position.x + 13, y)
    line.size = Vector2(CARD.size.x - 26, 1)
    _card.add_child(line)


## The illustration comes up, then the card. Skipped under the autopilot: a
## hundred fixture scripts wait 0.8s and press a key, and a title screen that
## is still fading when they do is a title screen that eats the key.
func _fade_in() -> void:
    if Autopilot.active:
        return
    _card.modulate.a = 0.0
    _hint.modulate.a = 0.0
    modulate = Color(1, 1, 1, 0)
    var t := create_tween()
    t.tween_property(self, "modulate:a", 1.0, 0.45)
    t.parallel().tween_property(_card, "modulate:a", 1.0, 0.7).set_delay(0.25)
    t.parallel().tween_property(_hint, "modulate:a", 1.0, 0.7).set_delay(0.45)


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
    _card.visible = not listing
    _hint.visible = not listing
    _cursor.position = Vector2(CARD.position.x + 13,
        CARD.position.y + FIRST_ROW + _index * ROW_STEP + 2)
    _cursor.visible = _enabled(_index)
    for i in _labels.size():
        var enabled := _enabled(i)
        var selected := i == _index
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
