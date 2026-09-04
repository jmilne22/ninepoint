## The draw, pinned to the board at the front of the Bondszaal.
##
## The same shape as LeagueBoard, and for the same reason: this is the thing the
## player comes back and looks at between rounds. It shows the crosstable and
## who they meet next, and nothing here decides anything -- CupDraw does.
class_name CupBoard
extends CanvasLayer

## Which section the player entered, and therefore which board they are playing
## on. The vocabulary itself lives in CupDraw, which is pure and can be reasoned
## about with the rest of the project deleted; this file reads a flag.
static func section() -> String:
    return CupDraw.section_of(str(GameState.get_flag("cup_section", "")))



var open: bool = false

var _root: Control
var _cells: Array[Array] = []
var _header: Label
var _footer: Label

const COL_X := [10, 26, 150, 208, 238, 268]
const COL_W := [16, 124, 56, 28, 28, 28]


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
    # Filled in show_board(): which section is on the wall is a question about
    # the save, and _build() runs once before there is one.
    _header.text = CupDraw.title_for(CupDraw.BEGINNERS)

    var headings := ["", "NAME", "RANK", "P", "W", "L"]
    for c in headings.size():
        var head := UiKit.label(panel, Vector2(COL_X[c], 24), COL_W[c], UiKit.INK_FAINT)
        head.text = str(headings[c])
        if c >= 3:
            head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    var widest: int = maxi(CupDraw.FIELD_BEGINNERS.size(), CupDraw.FIELD_OPEN.size())
    for i in widest + 1:
        var row: Array[Label] = []
        for c in COL_X.size():
            var cell := UiKit.label(panel, Vector2(COL_X[c], 38 + i * 12),
                COL_W[c], UiKit.INK)
            if c >= 3:
                cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
            row.append(cell)
        _cells.append(row)

    _footer = UiKit.label(panel, Vector2(10, 126), 304, UiKit.INK_SOFT, 60)


## The field as CupDraw wants it, player included, read from NpcData so the
## board and the opponents can never disagree about who is what rank.
static func field(section_id: String = "") -> Array:
    var ids: Array = CupDraw.FIELDS.get(section_id if section_id != "" else section(),
        CupDraw.FIELD_BEGINNERS)
    var out: Array = [{
        "id": CupDraw.PLAYER_ID, "name": GameState.player_name,
        "rank_label": GameState.rank_label(),
    }]
    for npc_id in ids:
        var path := "res://data/npcs/%s.tres" % npc_id
        if not ResourceLoader.exists(path):
            continue
        var data: NpcData = load(path)
        out.append({"id": npc_id, "name": data.display_name,
                    "rank_label": data.rank_label})
    return out


func show_board() -> void:
    var section_id := section()
    var state := CupDraw.run(field(section_id), GameState.match_records, CupDraw.PLAYER_ID)
    var rows: Array = state["rows"]
    _header.text = CupDraw.title_for(section_id)

    for i in _cells.size():
        var row: Array = _cells[i]
        if i >= rows.size():
            for cell in row:
                cell.text = ""
            continue
        var r: Dictionary = rows[i]
        var mine: bool = bool(r["is_player"])
        var values := [
            "%d" % (i + 1),
            ("> " if mine else "") + str(r["name"]),
            str(r["rank_label"]),
            str(int(r["played"])), str(int(r["won"])), str(int(r["lost"])),
        ]
        for c in row.size():
            row[c].text = str(values[c])
            row[c].add_theme_color_override("font_color",
                UiKit.GOLD if mine else UiKit.INK)

    _footer.text = CupDraw.summary(state, section_id)
    GameState.set_flag("read_cup_board", true)
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
