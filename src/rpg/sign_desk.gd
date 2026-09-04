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
var _hooks_board: HooksBoard
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
        cup_board: CupBoard, exam_board: ExamBoard, hooks_board: HooksBoard,
        set_talking: Callable, start_class: Callable) -> void:
    _player = player
    _dialogue = dialogue
    _league_board = league_board
    _cup_board = cup_board
    _exam_board = exam_board
    _hooks_board = hooks_board
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
    if text.begins_with("__HOOKS__"):
        await read_hooks(text.trim_prefix("__HOOKS__"))
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
    return PUZZLE_TRACK[GameState.day % PUZZLE_TRACK.size()]


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
    var exit := await _choose(lines, [
        {"text": "Set a problem.", "exit": {"type": "study"}},
        {"text": "Leave it.", "goto": "no"},
    ], "The stones stay in the bowl.")
    if str(exit.get("type", "")) != "study":
        _player.input_locked = false
        return
    # Studying alone is free. It is the one thing in the game that costs no hours,
    # because an evening spent on problems is not what a day is for spending.
    MatchBridge.start_puzzle(puzzle, _player.global_position)


# --- the hooks ---------------------------------------------------------------

## The brass hooks at the back of De Ketel, with the regulars' cards on them.
##
## Two different things hang here and the game has to keep them apart, because
## the whole setting is the argument between them. The *card* says your rank,
## which is a document: rated games only, computed by GoRating, the Instituut's
## kind of truth. The *hook you hang it on* is where you sit in the room, and
## that counts every game played in it -- the park, the arches and the back
## table included. Joos would not recognise the first and Marguerite has never
## heard of the second.
func read_hooks(prose: String) -> void:
    var lines: Array = [prose.strip_edges()]
    if not GameState.is_ranked():
        lines.append("There is no card with your name on it yet.")
        lines.append("Play a rated game against somebody who has one, and Tomas will write you a card whether you ask him to or not.")
        await narrate(lines)
        return
    lines.append("Your card is on the hooks: %s." % GameState.rank_label())
    var exit := await _choose(lines, [
        {"text": "Look at the order of the hooks.", "exit": {"type": "ladder"}},
        {"text": "What does the number mean?", "exit": {"type": "ranks"}},
        {"text": "Leave them.", "goto": "no"},
    ], "You leave the cards where they are.")
    match str(exit.get("type", "")):
        "ladder":
            _player.input_locked = false
            _player.clear_target()
            _hooks_board.show_board()
        "ranks":
            await narrate(_rank_lesson())
        _:
            _player.input_locked = false


## The only place in the game that ever explains what a rank is or how it moves.
## A player who has never met kyu grading has no way to guess that the number
## counts downwards, and nothing else on screen is going to tell them.
func _rank_lesson() -> Array:
    return [
        "Ranks count downwards. Twenty kyu is a beginner, twelve kyu is better, one kyu is better still -- and then it turns over into dan and counts up again.",
        "One rank is one handicap stone. That is what the number is for: it says how many stones make a game with you fair.",
        GoRating.explain(GameState.match_records),
        "The club works it out the way every club does: who you have been playing, and how often you beat them.",
        "An even score against a rank leaves you at that rank. Win more and you move up it. Lose more and you move down.",
        "Stones count against you. Winning on four stones from a nine kyu is a thirteen kyu result, not a nine kyu one.",
        "Which is why the stones thin out as you get better, and why that is the thing worth watching.",
        "Only rated games, for the card. The order of the hooks is a different question, and Tomas keeps that one himself.",
    ]


# --- the bed -----------------------------------------------------------------

## The bed is the only thing that moves the calendar, so it asks first: a night
## lost to a mistimed [Space] would be a real one.
func offer_sleep(prose: String) -> void:
    var left := GameState.SLOTS_PER_DAY - GameState.slots_used
    var state := "Today is gone." if left <= 0 else (
        "There is still the rest of today." if left > 1 else "There is an hour left in today.")
    var choices: Array = [{"text": "Sleep.", "exit": {"type": "sleep"}}]
    # A fortnight is still a dozen keypresses, and nobody should spend them one
    # at a time. Once there is a fixed thing to wait for, you can wait for it.
    # (This was the plaster over a six-week term with four days in it; M26 cut
    # the term to fit, so it is now a convenience rather than a cover-up.)
    #
    # There are two fixed things now, and only the nearer one may be offered: a
    # bed that offers to sleep past an exam you are entered for is a bed that can
    # lose you the term while you are looking at a menu.
    var to_exam := GameState.EXAM_DAY - GameState.day
    var to_cup := GameState.CUP_DAY - GameState.day
    var exam_pending: bool = GameState.has_flag("exam_entered") \
        and not GameState.has_flag("exam_finished")
    if exam_pending and to_exam > 0:
        choices.append({"text": "Sleep until the exam (%d days)." % to_exam,
                        "exit": {"type": "sleep_until_exam"}})
    elif GameState.has_flag("cup_entered") and to_cup > 0:
        choices.append({"text": "Sleep until the Cup (%d days)." % to_cup,
                        "exit": {"type": "sleep_until_cup"}})
    choices.append({"text": "Not yet.", "goto": "not_yet"})
    var exit := await _choose([prose.strip_edges(), state], choices,
        "You leave it for now.")
    var kind := str(exit.get("type", ""))
    if kind != "sleep" and kind != "sleep_until_cup" and kind != "sleep_until_exam":
        _player.input_locked = false
        return
    # Turn the day over first, then hand the player back: unlocking here let the
    # keypress that chose "Sleep" read the bed sign again on the way out.
    _player.input_locked = false
    GameState.sleep()
    if kind == "sleep_until_cup":
        while GameState.day < GameState.CUP_DAY:
            GameState.sleep()
        EventBus.toast.emit("The last week of term. Day %d -- the Cup." % GameState.day)
        return
    if kind == "sleep_until_exam":
        while GameState.day < GameState.EXAM_DAY:
            GameState.sleep()
        EventBus.toast.emit("The last week of term. Day %d -- the exam." % GameState.day)
        return
    var days := GameState.days_until_cup()
    if days > 0 and GameState.has_flag("wren_told_about_cup"):
        EventBus.toast.emit("Day %d. %d days to the Cup." % [GameState.day, days])
    else:
        EventBus.toast.emit("Day %d." % GameState.day)
