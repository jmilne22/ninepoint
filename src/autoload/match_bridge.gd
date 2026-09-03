## The single seam between the town and the Go board.
##
## The world hands over a MatchRequest and gets back a MatchResult. Neither side
## knows anything else about the other. See ARCHITECTURE.md section 4.
extends Node

const MATCH_SCENE := "res://src/go_ui/go_match.tscn"
const PUZZLE_SCENE := "res://src/go_ui/go_puzzle.tscn"
const LESSON_SCENE := "res://src/go_ui/go_lesson.tscn"
const REVIEW_SCENE := "res://src/go_ui/go_review.tscn"

var pending_request: MatchRequest = null
var pending_puzzle: String = ""
var pending_lesson: String = ""
## The remaining lessons of a run started from the title screen, in order.
var lesson_queue: Array[String] = []
var last_result: MatchResult = null
## Everything the review screen needs about the game just played. Empty when
## there is nothing worth saying, which is most of a good game.
var pending_review: Dictionary = {}
## The lesson just finished, so the world can let its teacher respond.
var last_lesson: String = ""


## Leaves the world, plays a game, and comes back to the same spot.
func start_match(request: MatchRequest, player_position: Vector2) -> void:
    pending_request = request
    GameState.return_position = player_position
    GameState.has_return_position = true
    EventBus.match_started.emit(request.context_id)
    await SceneRouter.go_to(MATCH_SCENE)


## Called by the match scene when the game is over.
func finish_match(result: MatchResult) -> void:
    last_result = result
    pending_request = null
    # Every game is recorded, unrated ones included: you remember losing to the
    # man under the arches even though no ladder does. What "unrated" changes is
    # that LeagueTable refuses to count it -- see league_table.gd.
    GameState.record_match(result)
    EventBus.match_finished.emit(result)
    # In Go the review is often longer than the game. It only happens when there
    # is something to say and somebody stronger than you to say it, so it grows
    # rarer as the player improves -- which is itself the honest progress signal
    # this game keeps looking for.
    pending_review = _review_for(result)
    if not pending_review.is_empty():
        await SceneRouter.go_to(REVIEW_SCENE)
        return
    await _return_to_world()


## The review payload, or {} when the game should go straight back to the town.
func _review_for(result: MatchResult) -> Dictionary:
    if result == null or result.npc_id == "" or result.findings.is_empty():
        return {}
    var path := "res://data/npcs/%s.tres" % result.npc_id
    if not ResourceLoader.exists(path):
        return {}
    var npc: NpcData = load(path)
    # Joos has no rank on his card, so his strength lives on the profile. Asking
    # NpcData alone would make the strongest man under the arches unqualified to
    # comment on a beginner's game.
    var strength := npc.strength()
    if npc.opponent_profile != null:
        strength = npc.opponent_profile.strength()
    return {
        "npc_id": result.npc_id,
        "name": npc.display_name,
        "rank": npc.rank_label,
        "portrait": npc.portrait_texture(),
        "qualified": strength > maxi(GameState.rank_strength, 0),
        "size": result.board_size,
        "final_cells": result.final_cells,
        "findings": result.findings,
    }


func finish_review() -> void:
    pending_review = {}
    await _return_to_world()


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
    for l in TUTORIAL_TRACK:
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
    EventBus.lesson_finished.emit(lesson_id, completed)
    # A title-screen run walks the whole track, then hands the player the town.
    if completed and not lesson_queue.is_empty():
        pending_lesson = lesson_queue.pop_front()
        await SceneRouter.go_to(LESSON_SCENE)
        return
    if completed and lesson_queue.is_empty():
        GameState.set_flag("knows_the_rules", true)
    await _return_to_world()


func finish_puzzle(puzzle_id: String, solved: bool) -> void:
    pending_puzzle = ""
    EventBus.puzzle_finished.emit(puzzle_id, solved)
    await _return_to_world()


func _return_to_world() -> void:
    var pos = GameState.return_position if GameState.has_return_position else null
    await SceneRouter.go_to(SceneRouter.WORLD_SCENE, GameState.spawn_point, pos)
    GameState.has_return_position = false
