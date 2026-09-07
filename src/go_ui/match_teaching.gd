## Optional teaching occupies the side panel and pauses input, not the game record.
class_name MatchTeaching
extends Node

var scene: Control
var opened := false
var passed_once := false


func setup(value: Control) -> void:
    scene = value


func enabled() -> bool:
    return scene.request != null and scene.request.context_id == "wren_first"


func show_help() -> void:
    if opened:
        return
    var text: String
    var stones := PackedInt32Array()
    if scene.game.state == GoGame.State.SCORING:
        text = "The crosses are proposed dead stones. Inspect each group before accepting. A group without two eyes is not automatically dead.\n\nMarked stones are removed for counting and become prisoners. Their empty points may also become territory.\n\nClick a group to change its mark. The score preview updates. P accepts your marks."
    else:
        var observation := PracticeGuide.observation(scene.game, scene.player_color)
        text = observation["text"]
        stones = observation["stones"]
    show_text(text, stones)


func first_pass() -> void:
    if not enabled() or passed_once:
        return
    passed_once = true
    show_text("Passing offers to finish; it does not concede. Your opponent may still play a move. Check whether that move threatens a group before deciding to reply or pass again. Two passes in a row start counting.")


func show_text(text: String, stones: PackedInt32Array = PackedInt32Array()) -> void:
    if opened:
        return
    opened = true
    var board: GoBoardView = scene.board_view
    var old: PackedInt32Array = board.highlight
    var old_targets := board.liberty_targets
    var liberties := board.show_liberties
    board.liberty_targets = stones
    board.highlight = stones
    board.show_liberties = not stones.is_empty()
    board.interactive = false
    board.queue_redraw()
    var brief := BoardBrief.new()
    var blocks: Array[String] = []
    for block in text.split("\n\n"):
        blocks.append(block)
    brief.pages = ReviewComparison.pages(blocks, 158, 165)
    scene.add_child(brief)
    await brief.closed
    if not is_instance_valid(board):
        return
    board.liberty_targets = old_targets
    board.highlight = old
    board.show_liberties = liberties
    board.queue_redraw()
    opened = false
