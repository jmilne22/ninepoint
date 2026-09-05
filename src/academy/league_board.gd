## Saved Novice/Academy standings and archived attempts on the hall wall.
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
var _shown_attempt: int = -1

const COL_X := [10, 26, 150, 208, 238, 268]
const COL_W := [16, 124, 56, 28, 28, 28]
## The unplayed summary is six wrapped lines at the board's 304 px text width.
## Keep one pixel-font line per row, plus the panel's lower breathing room.
const FOOTER_H := UiKit.LINE_H * 6


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

    # The initial standing is the board's longest footer. The old 192 px card
    # gave its six lines 62 px, so the final line landed on the frame.
    var panel := UiKit.panel(_root, Rect2(30, 8, 324, 200))
    _header = UiKit.label(panel, Vector2(10, 8), 304, UiKit.GOLD)
    _header.text = "ESSENVELD INSTITUUT -- LEAGUES"

    var headings := ["", "NAME", "ENTRY", "P", "W", "L"]
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

    # The standing, the rule, and whether you are meeting the exam cut.
    _footer = UiKit.label(panel, Vector2(10, 126), 304, UiKit.INK_SOFT, FOOTER_H)


func show_board() -> void:
    _shown_attempt = GameState.active_league
    _draw_attempt()
    GameState.set_flag("read_league_board", true)
    open = true
    _root.visible = true
    Audio.play("ui_confirm")


func _draw_attempt() -> void:
    var attempt: Dictionary = GameState.league_attempts[_shown_attempt] if _shown_attempt >= 0 and _shown_attempt < GameState.league_attempts.size() else {}
    var rows := LeagueAttempt.rows(attempt, GameState.match_records)
    _header.text = "ESSENVELD INSTITUUT -- LEAGUES"
    if not attempt.is_empty():
        var title := "NOVICE" if str(attempt["division"]) == LeagueAttempt.NOVICE else "ACADEMY"
        _header.text = "%s LEAGUE - ATTEMPT %d%s" % [title, attempt["number"],
            " (PAST)" if _shown_attempt != GameState.active_league else ""]

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

    # The footer gives the current standing and the next action in six measured lines.
    _footer.text = LeagueProgress.summary(GameState, attempt)
    if GameState.league_attempts.size() > 1:
        _footer.text += "\nLeft/Right: browse attempts."


## The promise in the line above, answered. Until the exam existed the board
## could state the rule and say nothing about whether you were meeting it.
static func _exam_line(rows: Array[Dictionary]) -> String:
    if LeagueProgress.exam_eligible(GameState):
        return "You are eligible. Register at the Bondszaal desk."
    return "Complete the Academy League to qualify for the exam."


func close() -> void:
    open = false
    _root.visible = false


func _input(event: InputEvent) -> void:
    if not open:
        return
    if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
        var delta := -1 if event.is_action_pressed("move_left") else 1
        _shown_attempt = clampi(_shown_attempt + delta, 0, maxi(0, GameState.league_attempts.size() - 1))
        _draw_attempt()
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        close()
        get_viewport().set_input_as_handled()
