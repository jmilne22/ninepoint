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


func _show() -> void:
    var findings: Array = review.get("findings", [])
    if findings.is_empty():
        # No board, so no reason for a board-sized card: one message, sized to
        # its text like every other card in the game.
        _board.visible = false
        _title.visible = false
        var text := "A steady game.\n%s\n\n[Space] close" % str(review.get("summary", "No single move gave much away."))
        if str(review.get("availability", "")) != "steady":
            text = "No review today.\nNothing came of going over it. The game still counts as it was played.\n\n[Space] close"
        UiKit.fit_card(_card, _body, text, 288)
        return
    _index = clampi(_index, 0, findings.size() - 1)
    var f: Dictionary = findings[_index]
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
    lines.append("%d of %d   Left/Right   [Space] close" % [_index + 1, findings.size()])
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
