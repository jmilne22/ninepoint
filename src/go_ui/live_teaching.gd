## Match-owned orchestration. The rules, worker and question policy know no scene.
class_name LiveTeaching
extends Node

var scene: Control
var active := false
var busy := false
var worker := KataGoTeaching.new()
var policy := TeachingPolicy.new()
var last_note := ""
var _note_position: GoGame
var _reply_facts := {}
var _reply_key := ""
var _closed := false


func setup(value: Control) -> void:
    scene = value


static func eligible(request: MatchRequest, setup: GoMatchSetup) -> bool:
    if request == null or request.profile == null or not request.unrated or not request.practice \
            or request.profile.capture_goal != 0 or setup.board_size != 9:
        return false
    return (request.npc_id == "wren" and request.context_id == "wren_first") \
        or (request.npc_id == "kesh" and request.context_id in ["kesh_first", "practice_kesh"] and setup.is_handicap())


func choose_mode() -> void:
    if not eligible(scene.request, scene.setup):
        return
    busy = true
    var choice := TeachingChoice.new()
    choice.text = "Pause occasionally to look at a move together? You can turn teaching off in Help."
    choice.options = ["With teaching", "Play normally"]
    choice.cancel_index = 1
    scene.add_child(choice)
    var selected: int = await choice.selected
    if _closed:
        return
    active = selected == 0
    busy = false
    if active:
        worker.start()


func _process(_delta: float) -> void:
    if active and not busy and worker.ready and scene.is_player_turn_ready():
        worker.prefetch(scene.game)


## The live move is provisional. The match's turn loop remains parked in _ask.
func consider(before: GoGame, point: int) -> bool:
    _reply_facts.clear()
    _reply_key = ""
    if not active or not worker.ready:
        return true
    busy = true
    scene._sync_mouse()
    var comparison: Dictionary = await worker.compare(before, point, scene.profile.gtp_time_per_move)
    if _closed:
        return false
    if comparison.is_empty():
        busy = false
        return true
    _reply_facts = comparison["facts"]
    _reply_key = TeachingPosition.key(scene.game)
    var question := policy.question(_reply_facts, float(comparison["loss"]), TeachingPosition.key(before))
    if question.is_empty():
        busy = false
        return true
    var board: GoBoardView = scene.board_view
    var old_highlight := board.highlight
    var old_mark := board.mark_point
    var old_liberties := board.show_liberties
    board.set_game(before)
    board.highlight = PackedInt32Array()
    for label: String in question["targets"]:
        board.highlight.append(before.board.from_label(label))
    board.mark_point = point
    board.show_liberties = false
    board.queue_redraw()
    var choice := TeachingChoice.new()
    choice.heading = "BEFORE YOUR MOVE"
    choice.text = question["text"] + "\n\nThe dot marks the move you tried."
    choice.options = ["Undo", "Play it anyway"]
    choice.cancel_index = 1
    scene.add_child(choice)
    var selected: int = await choice.selected
    if _closed:
        return false
    if selected == 0:
        scene.game.undo()
        _reply_facts.clear()
        _reply_key = ""
    board.set_game(scene.game)
    board.highlight = old_highlight
    board.mark_point = old_mark
    board.show_liberties = old_liberties
    busy = false
    return selected != 0


func commit_turn() -> void:
    policy.commit_turn()


func passed() -> void:
    if active:
        worker.invalidate()
    _reply_facts.clear()
    _reply_key = ""
    commit_turn()


func opponent_played(before_key: String) -> void:
    if active and before_key == _reply_key:
        var note := TeachingPolicy.reply_note(_reply_facts, scene.game, scene.player_color, scene.request.opponent_name.split(" ")[0])
        if note != "":
            last_note = note
            _note_position = scene.game.fork()
            scene._set_message(note)
    _reply_facts.clear()
    _reply_key = ""


func show_help() -> void:
    busy = true
    var choice := TeachingChoice.new()
    choice.heading = "PRACTICE HELP"
    choice.text = "What would you like to look at?"
    var actions: Array[String] = ["position"]
    choice.options = ["This position"]
    if last_note != "":
        actions.append("note")
        choice.options.append("Last explanation")
    if scene.setup.is_handicap():
        actions.append("handicap")
        choice.options.append("Handicap stones")
    actions.append("off")
    choice.options.append("Turn teaching off")
    actions.append("back")
    choice.options.append("Back to game")
    choice.cancel_index = actions.size() - 1
    scene.add_child(choice)
    var selected: int = await choice.selected
    if _closed:
        return
    busy = false
    match actions[selected]:
        "position": scene._teaching.show_help()
        "note":
            busy = true
            scene.board_view.set_game(_note_position)
            await scene._teaching.show_text("After move %d:\n\n%s" % [_note_position.move_number(), last_note])
            if _closed:
                return
            scene.board_view.set_game(scene.game)
            busy = false
        "handicap": scene._open_handicap_help(false)
        "off":
            close()
            await worker.shutdown()
            scene._set_message("Teaching is off for this game.")
    scene._refresh()


func close() -> void:
    active = false
    worker.close()
    _reply_facts.clear()
    _reply_key = ""


func _exit_tree() -> void:
    _closed = true
    close()
