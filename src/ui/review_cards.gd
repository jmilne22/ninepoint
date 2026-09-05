## Up to three positions from a finished game, one per card: the board before
## the move, the move played, the move that was better, and what it cost.
## Also the single card for a steady game and the single card for no review.
class_name ReviewCards
extends CanvasLayer

signal closed

const BOARD_PX := 140
const TEXT_X := 160
const TEXT_W := 178

var review: Dictionary
var opponent_name := ""
var _index := 0
var _card: Control
var _board: GoBoardView
var _title: Label
var _body: Label


func setup(value: Dictionary, who: String = "") -> void:
    review = value
    opponent_name = who


func _ready() -> void:
    name = "ReviewCards"
    layer = 30
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    var dim := ColorRect.new()
    dim.color = Color(0.05, 0.05, 0.08, 0.82)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(dim)
    _card = UiKit.panel(root, Rect2(18, 12, 348, 192))
    var card := _card
    _board = GoBoardView.new()
    _board.position = Vector2(10, 26)
    _board.size = Vector2(BOARD_PX, BOARD_PX)
    _board.interactive = false
    _board.show_coordinates = true
    card.add_child(_board)
    _title = UiKit.label(card, Vector2(TEXT_X, 12), TEXT_W, UiKit.INK, 22)
    _body = UiKit.label(card, Vector2(TEXT_X, 38), TEXT_W, UiKit.INK_SOFT, 146)
    _show()


## The tally comes first: what went right, in numbers a learner can hold on
## to, before the positions where something went wrong.
func _tally_text() -> String:
    var tally: Dictionary = review.get("tally", {})
    if tally.is_empty():
        return ""
    var moves := int(tally.get("moves", 0))
    var best := int(tally.get("best", 0))
    var fine := int(tally.get("fine", 0))
    var looked := "You played %d moves." % moves
    if bool(review.get("partial", false)):
        looked = "The first %d of your %d moves were looked at." % [moves, int(review.get("total_moves", moves))]
    var verdict := ""
    if best > 0 and fine > 0:
        verdict = "%d %s the best move on the board, and another %d gave nothing away." % [
            best, "was" if best == 1 else "were", fine]
    elif best > 0:
        verdict = "%d %s the best move on the board." % [best, "was" if best == 1 else "were"]
    elif fine > 0:
        verdict = "None matched the best move exactly, but %d gave nothing away." % fine
    else:
        verdict = "Every one of them cost something. That happens; the next game is the fix."
    var text := "%s %s" % [looked, verdict]
    var best_moves: Array = tally.get("best_moves", [])
    if not best_moves.is_empty():
        var shown: Array = best_moves.slice(0, 12)
        # A saved review comes back through JSON, where every number is a float.
        var numbers := ", ".join(shown.map(func(n: Variant) -> String: return str(int(n))))
        if best_moves.size() > shown.size():
            numbers += " and %d more" % (best_moves.size() - shown.size())
        text += "\n\nYour best moves: %s." % numbers
    return text


func _card_count() -> int:
    var findings: Array = review.get("findings", [])
    return findings.size() + (1 if not findings.is_empty() and review.has("tally") else 0)


func _show() -> void:
    var findings: Array = review.get("findings", [])
    if findings.is_empty():
        # No board, so no reason for a board-sized card: one message, sized to
        # its text like every other card in the game.
        _board.visible = false
        _title.visible = false
        var text := "A steady game.\n%s\n\n[Space] close" % str(review.get("summary", "No single move gave much away."))
        if str(review.get("availability", "")) == "steady" and review.has("tally"):
            text = "A steady game.\n%s\n\n[Space] close" % _tally_text()
        if str(review.get("availability", "")) != "steady":
            text = "No review today.\nNothing came of going over it. The game still counts as it was played.\n\n[Space] close"
        UiKit.fit_card(_card, _body, text, 288)
        return
    var total := _card_count()
    _index = clampi(_index, 0, total - 1)
    var has_tally := total > findings.size()
    _board.visible = true
    _title.visible = true
    _card.size = Vector2(348, 192)
    _card.position = Vector2(18, 12)
    _body.position = Vector2(TEXT_X, 38)
    _body.size = Vector2(TEXT_W, 146)
    if has_tally and _index == 0:
        _board.visible = false
        _title.visible = false
        UiKit.fit_card(_card, _body, "How it went.\n%s\n\n%d of %d   Left/Right   [Space] close" % [
            _tally_text(), 1, total], 288)
        return
    var f: Dictionary = findings[_index - (1 if has_tally else 0)]
    var game := MatchAnalysis.position(int(f.get("size", 9)), f.get("cells", []))
    if game == null:
        closed.emit()
        queue_free()
        return
    _board.set_game(game)
    var actual := int(f.get("actual", -1))
    var best := int(f.get("best", -1))
    # The two marks mean the same thing on every card: filled = the move
    # played, ring = the better move. The legend says so; colour never has to.
    _board.mark_point = actual
    _board.highlight = PackedInt32Array([best]) if best >= 0 and best != actual else PackedInt32Array()
    _title.text = "Move %d. You played %s." % [int(f.get("move_number", 0)), game.board.label(actual)]
    var lines: Array[String] = []
    if str(f.get("kind", "")) == "strength":
        lines.append("That was the move. The next best gave away about %s points." % _points(float(f.get("stake", 0.0))))
        lines.append("Filled = your move")
    else:
        lines.append("%s was better, by about %s points." % [game.board.label(best), _points(float(f.get("point_loss", 0.0)))])
        lines.append("%s %s" % [str(f.get("changed", "")), str(f.get("habit", ""))])
        lines.append("Filled = your move\nRing = the better move")
    if bool(review.get("partial", false)):
        lines.append("(The first %d of your %d moves were looked at.)" % [
            int(review.get("analysed_moves", 0)), int(review.get("total_moves", 0))])
    lines.append("%d of %d   Left/Right   [Space] close" % [_index + 1, total])
    _body.text = "\n\n".join(lines)
    if UiKit.text_height(_body.text, TEXT_W) > int(_body.size.y):
        push_warning("ReviewCards: card %d text runs off the card" % _index)


static func _points(v: float) -> String:
    return "%.1f" % v if absf(v - roundf(v)) > 0.05 else str(int(roundf(v)))


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("move_left"):
        _index -= 1
        _show()
    elif event.is_action_pressed("move_right"):
        _index += 1
        _show()
    elif event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        closed.emit()
        queue_free()
    else:
        return
    get_viewport().set_input_as_handled()
