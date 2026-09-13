class_name PracticeLibrary
extends VBoxContainer

const BASICS := ["pip_first_capture", "liberties", "capture", "self_capture", "first_game_rules", "ko"]
const FINISHING := ["finishing", "counting", "territory_shapes"]

func _ready() -> void:
    var content := PracticeUi.scroll(self)
    PracticeUi.button(content, "Beginner sequence: capture → rules → finishing → openings", func(): PracticeSession.start_lesson("pip_first_capture", true))
    PracticeUi.paragraph(content, "Everything is available now. Completion is remembered only in Practice.")
    var lessons := _catalog("lessons")
    for group in ["Basics", "Finishing and counting", "Tactics"]:
        PracticeUi.label(content, group, true)
        for lesson: Dictionary in lessons:
            var id: String = lesson.id
            var category := "Basics" if id in BASICS else ("Finishing and counting" if id in FINISHING else "Tactics")
            if category != group: continue
            var complete := bool(PracticeSession.store.data.completed.get("lesson_%s_done" % id, false))
            PracticeUi.button(content, ("✓ " if complete else "") + str(lesson.title), func(): PracticeSession.start_lesson(id))
        for puzzle: Dictionary in _catalog("puzzles"):
            var id: String = puzzle.id
            var category := "Basics" if id in ["capture_1", "capture_2", "capture_3"] else "Tactics"
            if category != group: continue
            var complete := bool(PracticeSession.store.data.completed.get("%s_solved" % id, false))
            PracticeUi.button(content, ("✓ " if complete else "") + "Puzzle: " + str(puzzle.get("title", id)), func(): PracticeSession.start_puzzle(id))

func _catalog(folder: String) -> Array:
    var items: Array = []
    var paths := DirAccess.get_files_at("res://data/" + folder)
    paths.sort()
    for path in paths:
        if not path.ends_with(".json"): continue
        var item: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s/%s" % [folder, path]))
        if item is Dictionary and item.has("id"): items.append(item)
    return items
