## The single seam between the town and the Go board.
##
## The world hands over a MatchRequest and gets back a MatchResult. Neither side
## knows anything else about the other. See ARCHITECTURE.md section 4.
extends Node

const MATCH_SCENE := "res://src/go_ui/go_match.tscn"
const PUZZLE_SCENE := "res://src/go_ui/go_puzzle.tscn"
const LESSON_SCENE := "res://src/go_ui/go_lesson.tscn"

var pending_request: MatchRequest = null
var pending_puzzle: String = ""
var pending_lesson: String = ""
## The remaining lessons of a run started from the title screen, in order.
var lesson_queue: Array[String] = []
var last_result: MatchResult = null
var last_record_index := -1
var _committed_result: MatchResult
## Evidence from the autopilot-only KataGo trial. It is deliberately separate
## from saved match data and only populated by the dev fixture context.
var dev_trial: Dictionary = {}
## The lesson just finished, so the world can let its teacher respond.
var last_lesson: String = ""


func _ready() -> void:
    EventBus.session_ended.connect(_clear_session)


func _clear_session() -> void:
    pending_request = null
    pending_puzzle = ""
    pending_lesson = ""
    lesson_queue.clear()
    last_result = null
    last_record_index = -1
    _committed_result = null
    last_lesson = ""


## Leaves the world, plays a game, and comes back to the same spot.
func start_match(request: MatchRequest, player_position: Vector2) -> void:
    pending_request = request
    if request.context_id == "dev_katago_trial":
        dev_trial.clear()
    GameState.return_position = player_position
    GameState.has_return_position = true
    EventBus.match_started.emit(request.context_id)
    KataGoService.prewarm(request.profile)
    await SceneRouter.go_to(MATCH_SCENE)


## Leaving during preparation is not a played game and must not create a record.
func cancel_match() -> void:
    if pending_request != null:
        KataGoService.cancel(pending_request.profile)
    pending_request = null
    await _return_to_world()


## Called by the match scene when the game is over.
func finish_match(result: MatchResult) -> void:
    record_completed_match(result)
    await _return_to_world()


## Identity protects duplicate completion callbacks for the same encounter.
func record_completed_match(result: MatchResult) -> int:
    if result == _committed_result:
        return last_record_index
    _committed_result = result
    last_result = result
    pending_request = null
    GameState.record_match(result)
    last_record_index = GameState.match_records.size() - 1
    EventBus.match_finished.emit(result)
    return last_record_index


## Analysis is requested by record index and never records another result.
func request_review(index: int) -> bool:
    if index < 0 or index >= GameState.match_records.size():
        return false
    if not MatchAnalysis.eligible(GameState.match_records[index]):
        return false
    GameState.match_records[index]["review_requested"] = true
    var existing: Dictionary = GameState.match_analysis.get(str(index), {})
    if str(existing.get("availability", "")) not in ["pending", "available", "steady"]:
        MatchReviewService.start(index)
    return true


## Compatibility for board-only tools. World games request after the reaction.
func finish_match_with_review(result: MatchResult) -> int:
    var index := record_completed_match(result)
    request_review(index)
    return index


func return_to_world_after_review() -> void:
    await _return_to_world()


func record_dev_trial(result: MatchResult, engine: Dictionary) -> void:
    if result.context_id != "dev_katago_trial":
        return
    dev_trial = {
        "engine": engine,
        "has_sgf": not result.sgf.is_empty(),
        "has_match_fields": pending_request != null
            and result.board_size == pending_request.profile.board_size
            and result.sgf.contains("SZ[%d]" % result.board_size) and result.move_count > 0
            and result.context_id == "dev_katago_trial",
        "result": result,
    }
    print("KATAGO TRIAL: recorded engine evidence")


func start_puzzle(puzzle_id: String, player_position: Vector2) -> void:
    pending_puzzle = puzzle_id
    GameState.return_position = player_position
    GameState.has_return_position = true
    await SceneRouter.go_to(PUZZLE_SCENE)


## The teaching order. Wren walks a beginner through it at De Ketel; there is no
## menu item, because being taught by somebody is the point.
const TUTORIAL_TRACK := ["liberties", "capture", "self_capture"]


## Queues the rest of the track after `first`, so one "teach me" runs them all
## without sending the player back and forth across the room.
func queue_track_after(first: String) -> void:
    lesson_queue.clear()
    var started := false
    var track: Array = ["first_game_rules", "finishing"] if first == "first_game_rules" else TUTORIAL_TRACK
    for l in track:
        if l == first:
            started = true
            continue
        if started:
            lesson_queue.append(l)


func start_lesson(lesson_id: String, player_position: Vector2, whole_track: bool = false) -> void:
    pending_lesson = lesson_id
    if whole_track:
        queue_track_after(lesson_id)
    else:
        lesson_queue.clear()
    GameState.return_position = player_position
    GameState.has_return_position = true
    await SceneRouter.go_to(LESSON_SCENE)


func finish_lesson(lesson_id: String, completed: bool) -> void:
    pending_lesson = ""
    last_lesson = lesson_id if completed else ""
    if completed and lesson_id == "two_eyes":
        GameState.set_flag("institute_class_ready", true)
    if not completed:
        lesson_queue.clear()
    _refresh_knows_the_rules()
    EventBus.lesson_finished.emit(lesson_id, completed)
    # A title-screen run walks the whole track, then hands the player the town.
    if completed and not lesson_queue.is_empty():
        pending_lesson = lesson_queue.pop_front()
        await SceneRouter.go_to(LESSON_SCENE)
        return
    if completed and lesson_queue.is_empty():
        _refresh_knows_the_rules()
    await _return_to_world()


## `knows_the_rules` gates the study desk, Joos, Bertie, Tomas and Wren's ko
## lesson. It used to be set by *any* lesson finishing with an empty queue, so
## Bertie's ladders or Tomas's counting or a class at the Instituut all declared
## the rulebook taught -- a flag measuring something far broader than its own
## name, which is why it was never wrong and never right either. The worst of it
## was Kesh: `offer_escape` is not gated on this flag, so one lesson from her
## retroactively unlocked the study desk, Joos, Bertie and Tomas at once.
##
## Two questions, kept apart: what you have been *taught*, and what you have
## *said*. A player who tells Wren they know how the stones move is taken at
## their word -- every reader of this flag is asking "can this person sit at a
## board", not "did they sit through the tutorial".
func _refresh_knows_the_rules() -> void:
    if GameState.has_flag("said_knows_the_rules") or GameState.has_flag("lesson_first_game_rules_done"):
        GameState.set_flag("knows_the_rules", true)
        return
    for l in TUTORIAL_TRACK:
        if not GameState.has_flag("lesson_%s_done" % l):
            return
    GameState.set_flag("knows_the_rules", true)


func finish_puzzle(puzzle_id: String, solved: bool) -> void:
    pending_puzzle = ""
    # The exam paper listener belongs to the returned world. Emitting while
    # that world is absent leaves the paper on its first position forever.
    await _return_to_world()
    EventBus.puzzle_finished.emit(puzzle_id, solved)


func _return_to_world() -> void:
    var pos = GameState.return_position if GameState.has_return_position else null
    await SceneRouter.go_to(SceneRouter.WORLD_SCENE, GameState.spawn_point, pos)
    GameState.has_return_position = false
