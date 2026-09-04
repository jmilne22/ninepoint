## The things on the walls, and the two pieces of furniture you sit down at.
##
## `_read_sign` in world.gd began as "two signs are not signs" and grew to eight
## sentinels, a puzzle track, a rank tutorial and the bed -- five jobs in a file
## that was already two and a half times its own convention. This is ROADMAP
## section 8's event desk: everything you *read* or *sit at* lives here, and
## everything that starts a *match* stays in the World, because that is the seam
## the two halves actually fall along.
##
## It owns no state of its own beyond the panels. `set_talking` is handed in by
## the World rather than duplicated, because two flags meaning "a box is open"
## is exactly the kind of second definition this project keeps writing bugs
## about -- see `knows_the_rules` in M27.
class_name SignDesk
extends RefCounted

var _player: Player
var _dialogue: DialogueBox
var _league_board: LeagueBoard
var _cup_board: CupBoard
var _exam_board: ExamBoard
## Called with true when a box opens and false when it closes. The World's own
## `_talking` is the one copy.
var _set_talking: Callable
## The class board starts a lesson and spends an hour, so it stays with the
## World's other match routing and is reached from here by name.
var _start_class: Callable
## True while one of this desk's own boxes is open, so the caller can refuse to
## open a second one on top of it.
var talking: bool = false


func _init(player: Player, dialogue: DialogueBox, league_board: LeagueBoard,
        cup_board: CupBoard, exam_board: ExamBoard,
        set_talking: Callable, start_class: Callable) -> void:
    _player = player
    _dialogue = dialogue
    _league_board = league_board
    _cup_board = cup_board
    _exam_board = exam_board
    _set_talking = set_talking
    _start_class = start_class


## The map data marks these with sentinels so the map generator never has to
## know about a UI scene.
func read(text: String) -> void:
    if talking:
        return
    if text == "__LEAGUE_BOARD__":
        _player.clear_target()
        _league_board.show_board()
        return
    if text == "__CUP_BOARD__":
        _player.clear_target()
        _cup_board.show_board()
        return
    if text == "__EXAM_BOARD__":
        _player.clear_target()
        _exam_board.show_board()
        return
    if text == "__CLASS_BOARD__":
        await _start_class.call()
        return
    if text.begins_with("__DESK__"):
        await study_desk(text.trim_prefix("__DESK__"))
        return
    if text.begins_with("__BED__"):
        await offer_sleep(text.trim_prefix("__BED__"))
        return
    await narrate([text])


## A narrator aside, with no choices and nothing to decide.
func narrate(lines: Array) -> void:
    _begin()
    var graph := DialogueGraph.new()
    graph.nodes = {"start": {"speaker": "narrator", "text": lines}}
    await _dialogue.run(graph, {"name": "", "portrait": null})
    _end()


func _begin() -> void:
    talking = true
    _set_talking.call(true)
    _player.input_locked = true
    _player.clear_target()


## `unlock` is false where the caller is about to change scene: releasing input
## first let the same keypress that chose the option re-trigger the sign behind
## the box that was closing.
func _end(unlock: bool = true) -> void:
    talking = false
    _set_talking.call(false)
    if unlock:
        _player.input_locked = false


## Runs a one-node choice box and returns the exit it produced.
func _choose(lines: Array, choices: Array, decline: String) -> Dictionary:
    var graph := DialogueGraph.new()
    graph.nodes = {
        "start": {"speaker": "narrator", "text": lines, "choices": choices},
        "no": {"speaker": "narrator", "text": [decline]},
    }
    _begin()
    var exit: Dictionary = await _dialogue.run(graph, {"name": "", "portrait": null})
    # Deliberately does not unlock: every caller decides, because half of them
    # are about to change scene and half of them are not.
    talking = false
    _set_talking.call(false)
    return exit


# --- the study desk ----------------------------------------------------------

## GAME_DESIGN promised that the board in your room replays the problems you have
## been set, and until M21 it was a sign you could read.
##
## Order matters more than choice here: the problems run in the order the concepts
## are taught, so the desk hands out the first one the player has not solved and
## only repeats itself once they have all been solved.
const PUZZLE_TRACK := ["capture_1", "capture_2", "capture_3", "escape_1",
                       "escape_2", "live_1", "capture_4", "live_2",
                       "capture_5", "escape_3", "live_3", "connect_1"]


func next_puzzle() -> String:
    for puzzle in PUZZLE_TRACK:
        if not GameState.has_flag("%s_solved" % puzzle):
            return puzzle
    return PUZZLE_TRACK[GameState.match_records.size() % PUZZLE_TRACK.size()]


func study_desk(prose: String) -> void:
    if not GameState.has_flag("knows_the_rules"):
        await narrate([prose.strip_edges(),
            "You still do not know what any of it is for. Somebody will have to show you."])
        return
    var puzzle := next_puzzle()
    var solved_all := GameState.has_flag("%s_solved" % PUZZLE_TRACK[PUZZLE_TRACK.size() - 1])
    var lines: Array = [prose.strip_edges()]
    lines.append("You could sit down with a problem." if not solved_all
        else "You have done all of them. You could do one again -- it is not the same twice, because you are not.")
    var choices: Array = [{"text": "Set a problem.", "exit": {"type": "study"}}]
    choices.append({"text": "Leave it.", "goto": "no"})
    var exit := await _choose(lines, choices, "The stones stay in the bowl.")
    if str(exit.get("type", "")) != "study":
        _player.input_locked = false
        return
    MatchBridge.start_puzzle(puzzle, _player.global_position)


# --- the bed -----------------------------------------------------------------

## Nothing in the game runs on a clock, so the bed is furniture.
func offer_sleep(prose: String) -> void:
    await narrate([prose.strip_edges(), "Not now."])
