## The in-town menu: save, look at your rank, or go back to the title.
class_name PauseMenu
extends CanvasLayer

signal opened()
signal closed()

## "Save game" stays at index 1 and stays a save with no further prompt: four
## autopilot scripts end on one move_down and an interact, and expect a file to
## exist afterwards. Anything new goes after it.
const ITEMS := ["Resume", "Save game", "Save to slot...", "Back to title"]

var open: bool = false

var _root: Control
var _labels: Array[Label] = []
var _index := 0
var _status: Label
var _slots: SaveSlots


func _ready() -> void:
    layer = 30
    _root = Control.new()
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_root)

    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.07, 0.1, 0.6)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.add_child(dim)

    var panel := NinePatchRect.new()
    panel.texture = load("res://art/ui/panel.png")
    for m in ["left", "top", "right", "bottom"]:
        panel.set("patch_margin_%s" % m, 6)
    panel.position = Vector2(112, 46)
    panel.size = Vector2(160, 124)
    panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _root.add_child(panel)

    var y := 12
    for item in ITEMS:
        var l := Label.new()
        l.position = Vector2(16, y)
        l.add_theme_font_size_override("font_size", 9)
        l.text = item
        panel.add_child(l)
        _labels.append(l)
        y += 18

    _status = Label.new()
    _status.position = Vector2(14, 92)
    _status.size = Vector2(132, 26)
    _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _status.add_theme_font_size_override("font_size", 9)
    _status.add_theme_color_override("font_color", Color("#6b6577"))
    panel.add_child(_status)

    _slots = SaveSlots.new()
    _slots.chosen.connect(_on_slot_chosen)
    _root.add_child(_slots)

    _root.visible = false


func toggle() -> void:
    if open:
        close()
    else:
        show_menu()


func show_menu() -> void:
    open = true
    _index = 0
    _status.text = "%s   %s" % [GameState.player_name, GameState.rank_label()]
    _refresh()
    _root.visible = true
    opened.emit()


func close() -> void:
    open = false
    _slots.close()
    _root.visible = false
    closed.emit()


func _refresh() -> void:
    for i in _labels.size():
        var selected := i == _index
        _labels[i].text = ("> " if selected else "  ") + ITEMS[i]
        _labels[i].add_theme_color_override(
            "font_color", Color("#14121a") if selected else Color("#6b6577"))


func _input(event: InputEvent) -> void:
    if not open or _slots.visible:
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
    elif event.is_action_pressed("menu") or event.is_action_pressed("cancel"):
        close()
    else:
        return
    get_viewport().set_input_as_handled()


func _activate() -> void:
    match _index:
        0:
            close()
        1:
            _save_to(GameState.active_slot)
        2:
            _slots.open(SaveSlots.Mode.SAVE, GameState.active_slot - 1)
        3:
            close()
            SceneRouter.go_to("res://src/ui/title_screen.tscn")


func _on_slot_chosen(slot: int) -> void:
    _save_to(slot)


func _save_to(slot: int) -> void:
    if SaveSystem.save_game(slot):
        # Naming the slot is the only place the silent choice New Game made is
        # ever shown to the player.
        _status.text = "Saved to slot %d." % slot
        EventBus.toast.emit("Game saved to slot %d." % slot)
    else:
        _status.text = "Could not save."
