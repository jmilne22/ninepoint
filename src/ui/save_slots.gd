## The three save slots: the list, and the two ways to lose one.
##
## One component rather than two lists. The title screen and the pause menu ask
## the same question of the same three files, and a second copy of that question
## is a second copy to keep in step.
class_name SaveSlots
extends Control

enum Mode {
    LOAD,   ## pick a slot to read. Empty and unreadable slots refuse.
    SAVE,   ## pick a slot to write, from inside a running game.
    NEW,    ## pick a slot for a playthrough that does not exist yet.
}

signal chosen(slot: int)
signal cancelled()
## A slot was deleted. Whoever raised the panel may be showing a summary of its
## own that now describes a file that is gone.
signal changed()

const PANEL := Rect2(16, 40, 352, 128)
const ROW_Y := 30
const ROW_STEP := 24
const CARD_W := 288

const HEADERS := {
    Mode.LOAD: "LOAD GAME",
    Mode.SAVE: "SAVE TO SLOT",
    Mode.NEW: "START A NEW GAME IN...",
}
const HINTS := {
    Mode.LOAD: "[Space] load   [Del] delete   [Esc] back",
    Mode.SAVE: "[Space] save here   [Del] delete   [Esc] back",
    Mode.NEW: "[Space] start here   [Del] delete   [Esc] back",
}

var mode: int = Mode.LOAD

var _rows: Array[Label] = []
var _subs: Array[Label] = []
var _info: Array[Dictionary] = []
var _index := 0
var _header: Label
var _hint: Label
var _card: NinePatchRect
var _card_text: Label
## "" while the list is live; "delete" or "overwrite" while the card is up.
var _confirm := ""
var _confirm_slot := 0


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.07, 0.1, 0.72)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(dim)

    var panel := UiKit.panel(self, PANEL)
    var inner := int(PANEL.size.x) - UiKit.PAD * 2
    _header = UiKit.label(panel, Vector2(UiKit.PAD, 8), inner, UiKit.GOLD)

    for i in SaveSystem.SLOT_COUNT:
        var y := ROW_Y + i * ROW_STEP
        _rows.append(_line(panel, Vector2(UiKit.PAD, y), inner, UiKit.INK))
        _subs.append(_line(panel, Vector2(UiKit.PAD, y + 10), inner, UiKit.INK_FAINT))
        _info.append({"status": "empty"})

    _hint = _line(panel, Vector2(UiKit.PAD, int(PANEL.size.y) - 22), inner, UiKit.INK_FAINT)

    # The card is a child of this full-rect Control because UiKit.fit_card
    # positions against the viewport, not against the panel.
    _card = UiKit.panel(self, Rect2(0, 0, CARD_W, 80))
    _card_text = UiKit.label(_card, Vector2(UiKit.PAD, UiKit.PAD),
        CARD_W - UiKit.PAD * 2, UiKit.INK)
    _card.visible = false
    visible = false


## A single-line row. Wrapping is off and clipping on, so a long place name is
## truncated rather than pushed onto a line the panel has no room for.
func _line(parent: Node, pos: Vector2, width: int, colour: Color) -> Label:
    var l := UiKit.label(parent, pos, width, colour)
    l.autowrap_mode = TextServer.AUTOWRAP_OFF
    l.clip_text = true
    return l


func open(m: int, cursor: int = 0) -> void:
    mode = m
    _read_all()
    _index = clampi(cursor, 0, SaveSystem.SLOT_COUNT - 1)
    _confirm = ""
    _card.visible = false
    _header.text = HEADERS[mode]
    _hint.text = HINTS[mode]
    _refresh()
    visible = true


func close() -> void:
    visible = false
    _card.visible = false
    _confirm = ""


func _read_all() -> void:
    # Once, here, rather than per keypress: slot_info parses the file off disk
    # and _refresh() runs on every press of an arrow key.
    for i in SaveSystem.SLOT_COUNT:
        _info[i] = SaveSystem.slot_info(i + 1)


func _refresh() -> void:
    var width := int(PANEL.size.x) - UiKit.PAD * 2
    for i in _rows.size():
        var occupied: bool = str(_info[i]["status"]) == "ok"
        var selected := i == _index
        _rows[i].text = ("> " if selected else "  ") + _headline(i)
        _subs[i].text = ("    " + _fit(_detail(i), width)) if occupied else ""
        var colour := UiKit.INK_FAINT
        if occupied:
            colour = UiKit.INK if selected else UiKit.INK_SOFT
        elif selected:
            colour = UiKit.INK_SOFT
        _rows[i].add_theme_color_override("font_color", colour)


func _headline(i: int) -> String:
    var d := _info[i]
    match str(d["status"]):
        "empty":
            return "%d   empty" % (i + 1)
        "corrupt":
            return "%d   unreadable" % (i + 1)
    return "%d   %s   %s   %d min" % [i + 1, d["player_name"], d["rank"], d["minutes"]]


func _detail(i: int) -> String:
    var d := _info[i]
    return "day %d, %s -- %s" % [d["day"], d["time_block"], d["place"]]


## What a slot holds, said in one line, for the two confirm cards.
func _describe(i: int) -> String:
    var d := _info[i]
    if str(d["status"]) != "ok":
        return "An unreadable save."
    return "%s, %s, day %d at %s." % [d["player_name"], d["rank"], d["day"], d["place"]]


static func _fit(text: String, width: int) -> String:
    if UiKit.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
            UiKit.FONT_SIZE).x <= float(width):
        return text
    var s := text
    while s.length() > 1 and UiKit.FONT.get_string_size(s + "...",
            HORIZONTAL_ALIGNMENT_LEFT, -1.0, UiKit.FONT_SIZE).x > float(width):
        s = s.substr(0, s.length() - 1)
    return s + "..."


func _input(event: InputEvent) -> void:
    # in_tree rather than `visible`: the pause menu hides its whole root, and a
    # panel that is invisible but still eating keys is the worst of both.
    if not is_visible_in_tree():
        return
    if _confirm != "":
        if _input_confirm(event):
            get_viewport().set_input_as_handled()
        return
    # Checked before the arrows, and before interact, because it is the one key
    # here that destroys something.
    if event.is_action_pressed("delete_save"):
        _ask_delete()
    elif event.is_action_pressed("move_down"):
        _index = (_index + 1) % SaveSystem.SLOT_COUNT
        Audio.play("ui_move")
        _refresh()
    elif event.is_action_pressed("move_up"):
        _index = (_index - 1 + SaveSystem.SLOT_COUNT) % SaveSystem.SLOT_COUNT
        Audio.play("ui_move")
        _refresh()
    elif event.is_action_pressed("interact"):
        _pick()
    elif event.is_action_pressed("cancel"):
        close()
        cancelled.emit()
    else:
        return
    get_viewport().set_input_as_handled()


func _pick() -> void:
    var slot := _index + 1
    var status := str(_info[_index]["status"])
    if mode == Mode.LOAD:
        # An empty slot has nothing to read and an unreadable one would only
        # half-restore. Both stay selectable so they can still be deleted.
        if status != "ok":
            return
        Audio.play("ui_confirm")
        close()
        chosen.emit(slot)
        return
    # Saving over the slot this run already lives in is not an overwrite, and
    # asking about it every time would train the player to dismiss the card.
    if status != "empty" and not (mode == Mode.SAVE and slot == GameState.active_slot):
        _ask_overwrite()
        return
    Audio.play("ui_confirm")
    close()
    chosen.emit(slot)


func _ask_delete() -> void:
    if str(_info[_index]["status"]) == "empty":
        return
    _confirm = "delete"
    _confirm_slot = _index + 1
    Audio.play("ui_move")
    _show_card("Delete slot %d?\n\n%s\n\nThis cannot be undone.\n\n[Del] delete   [Esc] keep"
        % [_confirm_slot, _describe(_index)])


func _ask_overwrite() -> void:
    _confirm = "overwrite"
    _confirm_slot = _index + 1
    Audio.play("ui_move")
    _show_card("Overwrite slot %d?\n\n%s\n\nThat game is lost.\n\n[Space] overwrite   [Esc] keep"
        % [_confirm_slot, _describe(_index)])


func _show_card(text: String) -> void:
    UiKit.fit_card(_card, _card_text, text, CARD_W)
    _card.visible = true


## The resign guard's shape, for the same reason: while the card is up nothing
## else may hear a key. Deleting answers only to [Del], never to the accept key,
## so a mistyped Space cannot throw a playthrough away.
func _input_confirm(event: InputEvent) -> bool:
    if _confirm == "delete" and event.is_action_pressed("delete_save"):
        var slot := _confirm_slot
        SaveSystem.delete_save(slot)
        _info[slot - 1] = SaveSystem.slot_info(slot)
        _dismiss_card()
        _refresh()
        changed.emit()
        return true
    if _confirm == "overwrite" and event.is_action_pressed("interact"):
        var slot := _confirm_slot
        _dismiss_card()
        Audio.play("ui_confirm")
        close()
        chosen.emit(slot)
        return true
    if event.is_action_pressed("cancel"):
        _dismiss_card()
        return true
    return event is InputEventKey and event.pressed


func _dismiss_card() -> void:
    _card.visible = false
    _confirm = ""
