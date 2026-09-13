class_name PracticeHistory
extends VBoxContainer

var status: Label
var index := -1
var review_button: Button

func _ready() -> void:
    var records: Array = PracticeSession.store.data.records
    if records.is_empty():
        PracticeUi.paragraph(self, "Your completed practice games will appear here. Every game can be replayed, even without engine analysis.")
        return
    var content := PracticeUi.scroll(self)
    if PracticeSession.tab == "Result" and PracticeSession.selected_record >= 0:
        index = PracticeSession.selected_record
        _detail(content, records[index])
        return
    for i in range(records.size() - 1, -1, -1):
        var record: Dictionary = records[i]
        var settings := PracticeSettings.from_dict(record.get("settings", {}))
        var title := "%s · %d×%d · %s · %s\n%s" % [str(record.get("date", "")).left(16),
            int(record.board_size), int(record.board_size), settings.rank_label() if settings.mode != "capture" else "Capture Go",
            settings.mode.capitalize(), str(record.summary)]
        PracticeUi.button(content, title, func():
            PracticeSession.selected_record = i
            get_tree().current_scene.show_tab("Result"))

func _detail(parent: Node, record: Dictionary) -> void:
    var settings := PracticeSettings.from_dict(record.get("settings", {}))
    PracticeUi.label(parent, "Practice ended" if record.get("practice_ended", false) else ("You win" if record.player_won else ("Draw" if int(record.winner) == 0 else "You lose")), true)
    PracticeUi.paragraph(parent, "%s · %s\n%s" % [record.summary, record.get("date", ""), settings.summary()])
    var row := HBoxContainer.new()
    parent.add_child(row)
    PracticeUi.button(row, "Replay", func():
        var replay := PracticeReplay.new()
        replay.record = record
        get_tree().current_scene.add_child(replay))
    review_button = PracticeUi.button(row, "Review", open_review)
    PracticeUi.button(row, "Export SGF", func():
        var directory := "user://practice/exports"
        DirAccess.make_dir_recursive_absolute(directory)
        var path := "%s/%s.sgf" % [directory, record.id]
        var file := FileAccess.open(path, FileAccess.WRITE)
        if file == null:
            status.text = "The SGF could not be exported."
            return
        file.store_string(record.sgf)
        file.close()
        status.text = "Saved: " + ProjectSettings.globalize_path(path))
    var next := HBoxContainer.new()
    parent.add_child(next)
    PracticeUi.button(next, "Rematch", func():
        PracticeSession.settings = settings
        if not PracticeSession.store.data.active.is_empty():
            get_tree().current_scene.show_tab("Play")
            return
        PracticeSession.start_game())
    PracticeUi.button(next, "Change Setup", func():
        PracticeSession.settings = settings
        get_tree().current_scene.show_tab("Play"))
    PracticeUi.button(next, "Practice Hub", func(): get_tree().current_scene.show_tab("Play"))
    status = PracticeUi.paragraph(parent, "")
    if int(record.get("capture_goal", 0)) > 0:
        review_button.disabled = true
        status.text = "Capture Go has replay; full-game engine review is available for ordinary and teaching games."

func _process(_delta: float) -> void:
    if status == null or index < 0: return
    var payload: Dictionary = PracticeSession.store.data.reviews.get(str(index), {})
    if payload.get("availability", "") == "pending":
        status.text = "Review is running. You can browse Practice and return here later."
        review_button.text = "Review running"
        review_button.disabled = true
    elif review_button.text == "Review running":
        status.text = "Review ready." if payload.get("availability", "") in ["available", "steady"] else "Review interrupted or unavailable. You can retry."
        review_button.text = "Review"
        review_button.disabled = false

func open_review() -> void:
    var payload: Dictionary = PracticeSession.store.data.reviews.get(str(index), {})
    if payload.get("availability", "") not in ["available", "steady"]:
        PracticeSession.request_review(index)
        var response: Dictionary = PracticeSession.store.data.reviews.get(str(index), {})
        if response.get("availability", "") == "failed":
            status.text = "Review unavailable: %s. Replay is still available; you can retry." % response.get("reason", "engine unavailable")
        return
    var cards := ReviewCards.new()
    cards.setup(payload, "Practice AI", PracticeSession.store.data.records[index])
    get_tree().current_scene.add_child(cards)
    await cards.closed
    if not cards.requested_lesson.is_empty(): PracticeSession.start_lesson(cards.requested_lesson)
