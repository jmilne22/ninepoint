## The exam list, pinned up at the Bondszaal.
##
## The same shape as CupBoard and LeagueBoard, and for the same reason: this is
## the thing the player comes back and looks at between rounds. It shows the
## crosstable and who they meet next, and nothing here decides anything -- Exam
## does.
class_name ExamBoard
extends CanvasLayer

const PLAYER_ID := "player"

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
    _header.text = "ESSENVELD INSTITUUT -- QUALIFYING EXAM"

    var headings := ["", "NAME", "RANK", "P", "W", "L"]
    for c in headings.size():
        var head := UiKit.label(panel, Vector2(COL_X[c], 24), COL_W[c], UiKit.INK_FAINT)
        head.text = str(headings[c])
        if c >= 3:
            head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    for i in Exam.FIELD_SIZE:
        var row: Array[Label] = []
        for c in COL_X.size():
            var cell := UiKit.label(panel, Vector2(COL_X[c], 38 + i * 12),
                COL_W[c], UiKit.INK)
            if c >= 3:
                cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
            row.append(cell)
        _cells.append(row)

    _footer = UiKit.label(panel, Vector2(10, 100), 304, UiKit.INK_SOFT, 84)


## Who the exam is for, in seating order.
##
## Unlike the Cup, whose field is a constant, this one is *earned*. Before the
## exam starts it is a live preview of the standings -- look at the list in week
## two and it tells you who would sit it if the term ended now, which is the
## whole point of having it on a wall. The first time it is asked for *after* the
## exam has started it is written down, and read back from then on. That is what
## entries closing means, and it is why the list survives the player going off
## and winning three more league games between rounds.
static func entrants() -> Array:
    var stored: Variant = GameState.get_flag("exam_field", [])
    var ids: Array = []
    if stored is Array and not (stored as Array).is_empty():
        for entry in stored:
            ids.append(str(entry))
        return ids
    for row in provisional():
        ids.append(str(row.get("id", "")))
    if GameState.has_flag("exam_started"):
        GameState.set_flag("exam_field", ids)
    return ids


## The four who would sit it if the term ended now. Used to preview the list
## before entries close, and to write the list down when they do.
static func provisional() -> Array[Dictionary]:
    return LeagueTable.qualifiers(LeagueTable.current_rows(),
        Exam.FIELD_SIZE, Exam.EXCLUDED)


## The field as Exam wants it, read from NpcData so the list and the opponents
## can never disagree about who is what rank.
static func field() -> Array:
    var out: Array = []
    for npc_id in entrants():
        if npc_id == PLAYER_ID:
            out.append({"id": PLAYER_ID, "name": GameState.player_name,
                        "rank_label": GameState.rank_label()})
            continue
        var path := "res://data/npcs/%s.tres" % npc_id
        if not ResourceLoader.exists(path):
            continue
        var data: NpcData = load(path)
        out.append({"id": npc_id, "name": data.display_name,
                    "rank_label": data.rank_label})
    return out


func show_board() -> void:
    var state := Exam.run(field(), GameState.match_records, PLAYER_ID)
    var rows: Array = state["rows"]

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

    _footer.text = summary(state)
    GameState.set_flag("read_exam_board", true)
    open = true
    _root.visible = true
    Audio.play("ui_confirm")


## The line the list and Marguerite both use, so they never disagree.
static func summary(state: Dictionary) -> String:
    var rows: Array = state["rows"]
    if not bool(state.get("player_in_field", true)):
        return "The top %d of the lower league sit it, and you are not one of them.\nThe study hall is open all term. That is the whole of the appeal process." % Exam.FIELD_SIZE
    var place := Exam.placing(rows, PLAYER_ID)
    if bool(state["complete"]):
        if bool(state["passed"]):
            return "Three rounds played. You finished %d of %d.\nThe top %d qualify. You qualified." % [
                place, rows.size(), Exam.PASS_PLACES]
        return "Three rounds played. You finished %d of %d.\nThe top %d qualify. You did not." % [
            place, rows.size(), Exam.PASS_PLACES]
    var round_number: int = int(state["next_round"]) + 1
    var who := str(state["next_opponent"])
    for r in rows:
        if str(r["id"]) == who:
            who = str(r["name"])
            break
    if who == "":
        return "Round %d of %d. Top %d qualify." % [
            round_number, Exam.ROUNDS, Exam.PASS_PLACES]
    return "Round %d of %d. You are drawn against %s.\nTop %d qualify. One round a day; see Marguerite when you are ready." % [
        round_number, Exam.ROUNDS, who, Exam.PASS_PLACES]


func close() -> void:
    open = false
    _root.visible = false


func _input(event: InputEvent) -> void:
    if not open:
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        close()
        get_viewport().set_input_as_handled()
