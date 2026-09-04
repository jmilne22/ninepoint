## The notice board in the Institute hall: the standings, as a panel.
##
## This is the thing the player is meant to come back and look at. It is the
## only place their position is stated, and it changes only because they won.
class_name LeagueBoard
extends CanvasLayer

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

    for i in LeagueTable.ROSTER.size() + 1:
        var row: Array[Label] = []
        for c in COL_X.size():
            var cell := UiKit.label(panel, Vector2(COL_X[c], 38 + i * 12),
                COL_W[c], UiKit.INK)
            if c >= 3:
                cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
            row.append(cell)
        _cells.append(row)

    # Four lines now: the standing, the rule, and whether you are meeting it.
    _footer = UiKit.label(panel, Vector2(10, 126), 304, UiKit.INK_SOFT, 62)


func show_board() -> void:
    # The roster and the standings both live on LeagueTable now, because the exam
    # gates on the same numbers and the two must not be able to disagree.
    var rows := LeagueTable.current_rows()

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

    # The standing, the rank rule, and the exam rule. The card is already the
    # full height of the panel, so nothing here may run to a fifth line.
    _footer.text = "%s\n%s\nThe top four sit the qualifying exam at the Bondszaal. %s" % [
        LeagueTable.summary(rows), GoRankLadder.explain(), _exam_line(rows)]
    GameState.set_flag("read_league_board", true)
    open = true
    _root.visible = true
    Audio.play("ui_confirm")


## The promise in the line above, answered. Until the exam existed the board
## could state the rule and say nothing about whether you were meeting it.
static func _exam_line(rows: Array[Dictionary]) -> String:
    var place := LeagueTable.player_position(rows)
    var cut := Exam.FIELD_SIZE
    # Marguerite is on the board and does not sit the exam, so a place below her
    # is still inside the four. Count how many of the rows above are entrants.
    var above := 0
    for i in mini(place - 1, rows.size()):
        if not Exam.EXCLUDED.has(str(rows[i].get("id", ""))):
            above += 1
    if above < cut:
        return "As it stands, you are in."
    return "As it stands, you are not."


func close() -> void:
    open = false
    _root.visible = false


func _input(event: InputEvent) -> void:
    if not open:
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        close()
        get_viewport().set_input_as_handled()
