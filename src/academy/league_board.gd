## The notice board in the Institute hall: the standings, as a panel.
##
## This is the thing the player is meant to come back and look at. It is the
## only place their position is stated, and it changes only because they won.
class_name LeagueBoard
extends CanvasLayer

## The students in the league, in rank order. Read from their NpcData so the
## board and the opponents can never disagree about who is what rank.
const ROSTER := ["kesh", "ilse", "sunny", "orla", "nadia", "marguerite"]

var open: bool = false

var _root: Control
## One label per column per row. The font is proportional -- a space is 4px and
## a digit is 6 -- so padding a single string with spaces does not line columns
## up, it only looks as though it might.
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
    _header.text = "ESSENVELD INSTITUUT -- LOWER LEAGUE"

    var headings := ["", "NAME", "RANK", "P", "W", "L"]
    for c in headings.size():
        var head := UiKit.label(panel, Vector2(COL_X[c], 24), COL_W[c], UiKit.INK_FAINT)
        head.text = str(headings[c])
        if c >= 3:
            head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    for i in ROSTER.size() + 1:
        var row: Array[Label] = []
        for c in COL_X.size():
            var cell := UiKit.label(panel, Vector2(COL_X[c], 38 + i * 12),
                COL_W[c], UiKit.INK)
            if c >= 3:
                cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
            row.append(cell)
        _cells.append(row)

    _footer = UiKit.label(panel, Vector2(10, 132), 304, UiKit.INK_SOFT, 50)


func show_board() -> void:
    var roster := []
    for npc_id in ROSTER:
        var path := "res://data/npcs/%s.tres" % npc_id
        if not ResourceLoader.exists(path):
            continue
        var data: NpcData = load(path)
        roster.append({"id": npc_id, "name": data.display_name,
                       "rank_label": data.rank_label})

    var rows := LeagueTable.standings(GameState.match_records, roster,
        GameState.player_name, GameState.rank_label())

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

    _footer.text = "%s\n\nThe qualifying exam is at the end of term. Entry is by league position." % \
        LeagueTable.summary(rows)
    GameState.set_flag("read_league_board", true)
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
