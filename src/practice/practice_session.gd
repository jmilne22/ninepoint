## Practice owns all persistence and routes; campaign state is never a scratch save.
extends Node

const HUB := "res://src/practice/hub.tscn"
const MATCH := "res://src/practice/match.tscn"
var store := PracticeStore.new()
var settings := PracticeSettings.new()
var active := false
var resume_snapshot: Dictionary = {}
var game_id := ""
var tab := "Play"
var selected_record := -1
var lesson_queue: Array[String] = []
var notice := ""
var _routing := false
var _destination := ""

func _ready() -> void:
    store.read()
    settings = PracticeSettings.from_dict(store.data.settings)

func enter() -> void:
    active = true
    KettleNextProfile.practice_presentation = true
    context()
    show_hub()

func context() -> ActivityContext:
    var value := ActivityContext.new()
    value.standalone = true
    value.player_name = settings.player_name
    value.match_finished = finish_match
    value.match_cancelled = show_hub
    value.lesson_finished = finish_lesson
    value.puzzle_finished = finish_puzzle
    value.flag_read = func(key: String) -> bool: return bool(store.data.completed.get(key, false))
    value.flag_written = func(key: String, state: bool) -> void:
        store.data.completed[key] = state
        save()
    MatchBridge.activity_context = value
    return value

func save() -> bool:
    store.data.settings = settings.to_dict()
    if store.write(): return true
    notice = store.error if not store.error.is_empty() else "Practice could not be saved. Check available disk space and permissions."
    return false

func start_game(resume_game := false) -> void:
    MatchReviewService.cancel()
    resume_snapshot = {}
    if resume_game:
        var saved: Dictionary = store.data.active
        if saved.is_empty(): return
        settings = PracticeSettings.from_dict(saved.settings)
        resume_snapshot = saved.snapshot.duplicate(true)
        if PracticeSnapshot.restore(resume_snapshot) == null:
            notice = "This suspended game could not be restored. It has been kept; you can replace it."
            return
        game_id = saved.id
    else:
        game_id = "%d_%d" % [Time.get_unix_time_from_system() * 1000000, randi()]
    tab = "Play"
    var value := context()
    value.request = PracticeProfile.make(settings)
    save()
    _go_to(MATCH)

func checkpoint(game: GoGame, player: int, dead: Dictionary, coaching: bool) -> bool:
    store.data.active = {"id": game_id, "settings": settings.to_dict(),
        "snapshot": PracticeSnapshot.capture(game, player, dead, coaching)}
    return save()

func finish_match(result: MatchResult) -> void:
    var record := result.to_dict()
    record["settings"] = settings.to_dict()
    record["date"] = Time.get_datetime_string_from_system(false, true)
    selected_record = store.complete(game_id, record)
    if not store.last_write_ok:
        notice = "This result is in memory but could not be saved. Check disk space before quitting."
    resume_snapshot = {}
    tab = "Result"
    show_hub()

func show_hub() -> void:
    _go_to(HUB)

func leave() -> void:
    MatchReviewService.cancel()
    save()
    active = false
    KettleNextProfile.practice_presentation = false
    MatchBridge.activity_context = null
    _go_to("res://src/ui/title_screen.tscn")

func start_lesson(id: String, sequence := false) -> void:
    if sequence:
        lesson_queue.assign(["pip_first_capture", "first_game_rules", "finishing", "openings"])
        lesson_queue.erase(id)
    var value := context()
    value.lesson_id = id
    _go_to(MatchBridge.LESSON_SCENE)

func finish_lesson(_id: String, completed: bool) -> void:
    if completed and not lesson_queue.is_empty():
        start_lesson(lesson_queue.pop_front())
        return
    lesson_queue.clear()
    tab = "Learn"
    show_hub()

func start_puzzle(id: String) -> void:
    var value := context()
    value.puzzle_id = id
    _go_to(MatchBridge.PUZZLE_SCENE)

func finish_puzzle(_id: String, _solved: bool) -> void:
    tab = "Learn"
    show_hub()

func request_review(index: int) -> void:
    if index < 0 or index >= store.data.records.size(): return
    MatchReviewService.start_record(index, store.data.records[index], record_review)

func record_review(index: int, payload: Dictionary) -> void:
    store.data.reviews[str(index)] = payload
    save()

func discard() -> void:
    store.data.active = {}
    resume_snapshot = {}
    save()


## A fast preparation failure can happen during the incoming fade. Queue its
## return instead of letting SceneRouter's busy guard silently drop it.
func _go_to(path: String) -> void:
    _destination = path
    if _routing: return
    _routing = true
    while not _destination.is_empty():
        while SceneRouter.is_busy(): await get_tree().process_frame
        var next := _destination
        _destination = ""
        await SceneRouter.go_to(next)
    _routing = false
