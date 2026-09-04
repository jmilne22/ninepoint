## The hooks at the back of De Ketel, as a panel.
##
## Deliberately the same shape as LeagueBoard and deliberately not the same
## columns. The league board has P, W and L on it because the Instituut counts;
## the hooks have a hook number, a name and whatever is written on the card, and
## the card is blank for the one man who never filled one in.
class_name HooksBoard
extends CanvasLayer

var open: bool = false

var _root: Control
var _cells: Array[Array] = []
var _header: Label
var _footer: Label

const COL_X := [10, 30, 200]
const COL_W := [20, 170, 104]


func _ready() -> void:
    layer = 25
    _build()
    _root.visible = false


func _build() -> void:
    _root = Control.new()
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_root)

    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.07, 0.1, 0.72)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.add_child(dim)

    var panel := UiKit.panel(_root, Rect2(30, 12, 324, 192))
    _header = UiKit.label(panel, Vector2(10, 8), 304, UiKit.GOLD)
    _header.text = "DE KETEL -- THE HOOKS"

    var headings := ["", "NAME", "CARD"]
    for c in headings.size():
        var head := UiKit.label(panel, Vector2(COL_X[c], 24), COL_W[c], UiKit.INK_FAINT)
        head.text = str(headings[c])

    # One hook per regular, plus yours once there is a card to hang.
    for i in HooksLadder.ROSTER.size() + 1:
        var row: Array[Label] = []
        for c in COL_X.size():
            var cell := UiKit.label(panel, Vector2(COL_X[c], 38 + i * 12),
                COL_W[c], UiKit.INK)
            row.append(cell)
        _cells.append(row)

    _footer = UiKit.label(panel, Vector2(10, 138), 304, UiKit.INK_SOFT, 50)


func show_board() -> void:
    var rows := HooksLadder.rows_for(GameState)

    for i in _cells.size():
        var row: Array = _cells[i]
        if i >= rows.size():
            for cell in row:
                cell.text = ""
            continue
        var r: Dictionary = rows[i]
        var mine: bool = bool(r["is_player"])
        # A card the player has taken keeps a mark against it, because "I have
        # beaten that man" is the thing a ladder is actually a record of and it
        # would otherwise vanish the moment they moved past him.
        var card := str(r["rank_label"])
        if card == "?":
            card = "-- no card --"
        elif bool(r.get("taken", false)):
            card += "   taken"
        var values := [
            "%d." % (i + 1),
            ("> " if mine else "") + str(r["name"]),
            card,
        ]
        for c in row.size():
            row[c].text = str(values[c])
            row[c].add_theme_color_override("font_color",
                UiKit.GOLD if mine else UiKit.INK)

    _footer.text = "%s\nBeat somebody hanging above you and you take their hook. Losing costs nothing. Every game in this room counts, and no game in this room is rated." % HooksLadder.summary(rows)
    GameState.set_flag("read_the_hooks", true)
    open = true
    _root.visible = true
    Audio.play("ui_confirm")


func close() -> void:
    open = false
    _root.visible = false


func _input(event: InputEvent) -> void:
    if not open:
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        close()
        get_viewport().set_input_as_handled()
