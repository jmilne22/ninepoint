## Up to three positions from a finished game, one per card: the board before
## the move, the move played, the move that was better, and what it cost.
## Long explanations use pages that retain the board and its marker legend.
## Also the single card for a steady game and the single card for no review.
## REV-04 POC: when the payload carries a curve, the first card is a graph of the
## whole game; Left/Right walk your moves on the board, Up/Down jump between the
## explained positions, and Space opens the card for one of those.
class_name ReviewCards
extends CanvasLayer

signal closed
var requested_lesson := ""
var _lesson_id := ""

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
var _navigation: BoardNavigation
var _actions: MouseActions
var _text_pages := PackedStringArray()
var _text_page := 0
var _legend := ""
var _comparison := 0
var _plain := false
var _graph: ReviewGraph
var _replay: Dictionary = {}
var _graph_started := false


func setup(value: Dictionary, who: String = "") -> void:
    review = ReviewEnrichment.restore_entries({"review":value})["review"]
    var source := int(review.get("source_match", -1))
    if source >= 0 and source < GameState.match_records.size():
        for finding in review.get("findings", []):
            finding["player"] = int(GameState.match_records[source].get("player_color", GoBoard.BLACK))
        _replay = MatchAnalysis.replay(str(GameState.match_records[source].get("sgf", "")))
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
    _board.inspection = true
    _board.pointer.mode = BoardPointer.Mode.INSPECT
    _board.show_coordinates = true
    card.add_child(_board)
    _navigation = BoardNavigation.new()
    _navigation.position = Vector2(10, 168)
    _navigation.size = Vector2(140, 22)
    _navigation.compact = true
    card.add_child(_navigation)
    _navigation.setup(_board)
    _board.view_changed.connect(_refresh_navigation)
    _title = UiKit.label(card, Vector2(TEXT_X, 12), TEXT_W, UiKit.INK, 22)
    _body = UiKit.label(card, Vector2(TEXT_X, 38), TEXT_W, UiKit.INK_SOFT, 146)
    _graph = ReviewGraph.new()
    _graph.position = Vector2(TEXT_X, 36)
    _graph.size = Vector2(TEXT_W, 50)
    _graph.visible = false
    _graph.selected_changed.connect(func(_index: int) -> void: _show_graph())
    card.add_child(_graph)
    _actions = MouseActions.new()
    _actions.position = Vector2(158, 197)
    root.add_child(_actions)
    _actions.configure([["<", "move_left"], [">", "move_right"], ["Compare C", "go_compare"], ["Close", "interact"]])
    _actions.action_selected.connect(_mouse_action)
    _show()


func _mouse_action(action: StringName) -> void:
    if action == &"go_compare":
        _comparison = (_comparison + 1) % 3
        _show()
    elif action == &"move_left" or action == &"move_right":
        if _on_graph():
            _graph.step(-1 if action == &"move_left" else 1)
        else:
            _navigate(-1 if action == &"move_left" else 1)
    else:
        _unhandled_input(MouseActions.event(action))


func _has_graph() -> bool:
    var curve: Variant = review.get("curve", [])
    return curve is Array and not curve.is_empty() and not _replay.is_empty() and review.has("tally")


func _on_graph() -> bool:
    return _has_graph() and _index == 0


func _card_count() -> int:
    var findings: Array = review.get("findings", [])
    if _has_graph():
        return findings.size() + 1
    return findings.size() + (1 if not findings.is_empty() and review.has("tally") else 0)


func _show() -> void:
    _navigation.hide()
    _lesson_id = ""
    _configure_actions()
    _text_pages = PackedStringArray()
    _plain = false
    _graph.visible = false
    if _on_graph():
        _show_graph()
        return
    var findings: Array = review.get("findings", [])
    if findings.is_empty():
        # No board, so no reason for a board-sized card: one message, sized to
        # its text like every other card in the game.
        _board.visible = false
        _title.visible = false
        var text := "A steady game.\n%s" % str(review.get("summary", "No single move gave much away."))
        if str(review.get("availability", "")) == "steady" and review.has("tally"):
            text = "A steady game.\n%s" % ReviewSummary.text(review)
        if str(review.get("availability", "")) != "steady":
            text = "Review unavailable.\nThe engine could not finish this review. Your result has been saved."
        _show_plain(text)
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
        _show_plain("How it went.\n" + ReviewSummary.text(review))
        return
    var f: Dictionary = findings[_index - (1 if has_tally else 0)]
    var game := ReviewComparison.position(f, _comparison)
    if game == null:
        closed.emit()
        queue_free()
        return
    _board.set_game(game)
    var overlay := ReviewComparison.overlay(f, _comparison)
    _board.review_ownership = overlay["ownership"]
    _board.review_regions = overlay["regions"]
    _lesson_id = str(f.get("lesson_id", "")) if f.has("facts") else ""
    _configure_actions()
    var actual := int(f.get("actual", -1))
    var best := int(f.get("best", -1))
    # The two marks mean the same thing on every card: filled = the move
    # played, ring = the better move. The legend says so; colour never has to.
    _board.focus_point(actual if actual >= 0 else maxi(best, 0))
    _board.inspection = true
    _board.mark_point = actual
    _board.highlight = PackedInt32Array([best]) if best >= 0 and best != actual else PackedInt32Array()
    _board.mark_good = str(f.get("kind", "")) == "strength"
    # The page line lives with the title: the body below is the part that
    # grows, and a nav line under a long explanation fell off the card.
    _title.text = "Move %d. You played %s.\n%d of %d   Left/Right   [Space]" % [
        int(f.get("move_number", 0)), game.board.label(actual), _index + 1, total]
    var lines: Array[String] = []
    if str(f.get("kind", "")) == "strength":
        var matched := bool(f.get("matched", best == actual))
        var head := "That was the engine's preferred move." if matched \
            else "A good move: it gave nothing away."
        var why := str(f.get("does", ""))
        var stake := float(f.get("stake", 0.0))
        if matched and stake >= MatchAnalysis.MEANINGFUL_LOSS:
            why += " The engine estimated its next choice about %s points lower." % _points(stake)
        elif not matched:
            why += " %s was best; yours was within a point of it." % game.board.label(best)
        lines.append("%s %s" % [head, why])
        _legend = "Filled = your move" if matched else "Filled = your move\nRing = engine preference"
    else:
        if f.has("facts") and not f.get("narration", []).is_empty():
            lines.assign(f["narration"])
        else:
            lines.append("The engine preferred %s, by about %s points." % [game.board.label(best), _points(float(f.get("point_loss", 0.0)))])
            lines.append("%s %s" % [str(f.get("critique", "")), str(f.get("changed", ""))])
            lines.append("Next time: %s" % str(f.get("habit", "")))
        _legend = "Filled = your move\nRing = engine preference"
    if bool(review.get("partial", false)):
        lines.append("(The first %d of your %d moves were looked at.)" % [
            int(review.get("analysed_moves", 0)), int(review.get("total_moves", 0))])
    _legend = ["Before either move", "After your move", "After engine choice"][_comparison] + "\n" + _legend
    if not _board.review_ownership.is_empty():
        _legend += "\nBlue: yours / red: theirs"
    var available := int(_body.size.y) - UiKit.text_height(_legend, TEXT_W) - UiKit.LINE_H
    _text_pages = ReviewComparison.pages(lines, TEXT_W, available)
    _text_page = _text_pages.size() - 1 if _text_page < 0 else mini(_text_page, _text_pages.size() - 1)
    _refresh_text()
    _refresh_navigation()
    if UiKit.text_height(_body.text, TEXT_W) > int(_body.size.y):
        push_warning("ReviewCards: card %d text runs off the card" % _index)


static func _points(v: float) -> String:
    return "%.1f" % v if absf(v - roundf(v)) > 0.05 else str(int(roundf(v)))


## The position before the selected move, rebuilt from the record's SGF, in the
## same shape a finding has so Compare C and the board marks work unchanged.
func _graph_finding(point: Dictionary) -> Dictionary:
    var moves: Array = _replay.get("moves", [])
    var move := int(point.get("move", 0))
    if move < 1 or move > moves.size():
        return {}
    var entry: Dictionary = moves[move - 1]
    var board := GoBoard.new(int(_replay["size"]))
    return {"kind": "graph", "move_number": move, "size": int(_replay["size"]), "cells": entry["cells"],
        "player": int(entry["color"]), "actual": board.from_label(str(point.get("actual", ""))),
        "best": board.from_label(str(point.get("best", "")))}


func _show_graph() -> void:
    _lesson_id = ""
    _text_pages = PackedStringArray()
    var marks := {}
    var findings: Array = review.get("findings", [])
    for i in findings.size():
        marks[int(findings[i].get("move_number", 0))] = i + 1
    _graph.setup(review["curve"], marks)
    if not _graph_started:
        # What went right first: open on the praised move, not on move one.
        _graph_started = true
        for f in findings:
            if str(f.get("kind", "")) == "strength":
                _graph.selected = maxi(_graph.index_of_move(int(f.get("move_number", 0))), 0)
    var point: Dictionary = _graph.selected_move()
    var f := _graph_finding(point)
    var game := ReviewComparison.position(f, _comparison) if not f.is_empty() else null
    if game == null:
        _show_plain("How it went.\n" + ReviewSummary.text(review))
        return
    _graph.visible = true
    _board.visible = true
    _title.visible = true
    _card.size = Vector2(348, 192)
    _card.position = Vector2(18, 12)
    _body.position = Vector2(TEXT_X, 90)
    _body.size = Vector2(TEXT_W, 94)
    _board.set_game(game)
    var actual := int(f["actual"])
    var best := int(f["best"])
    _board.focus_point(actual)
    _board.inspection = true
    _board.mark_point = actual
    _board.highlight = PackedInt32Array([best]) if best >= 0 and best != actual else PackedInt32Array()
    _board.mark_good = best == actual
    _configure_actions()
    var move := int(point["move"])
    var loss := float(point.get("loss", 0.0))
    var verdict := "The engine's preferred move."
    if best >= 0 and best != actual and loss < MatchAnalysis.MEANINGFUL_LOSS:
        verdict = "Close to the engine's %s." % game.board.label(best)
    elif best >= 0 and best != actual:
        verdict = "The engine preferred %s, about %d points." % [game.board.label(best), roundi(loss)]
    var tally: Dictionary = review.get("tally", {})
    var lines: Array[String] = [verdict, "%d of %d matched the engine." % [int(tally.get("best", 0)), int(tally.get("moves", 0))]]
    if marks.has(move):
        lines.append("[Space] opens this position.")
    _legend = ["Before either move", "After your move", "After engine choice"][_comparison] + "\nFilled = your move"
    if best >= 0 and best != actual:
        _legend += "\nRing = engine preference"
    _title.text = "Move %d. You played %s.\n" % [move, game.board.label(actual)]
    _body.text = "\n".join(lines) + "\n\n" + _legend
    _refresh_navigation()
    if UiKit.text_height(_body.text, TEXT_W) > int(_body.size.y):
        push_warning("ReviewCards: graph caption runs off the card")


func _show_plain(text: String) -> void:
    _plain = true
    var blocks: Array[String] = []
    for block in text.split("\n\n"):
        blocks.append(block)
    _text_pages = ReviewComparison.pages(blocks, 288, 132)
    _text_page = clampi(_text_page, 0, _text_pages.size() - 1)
    _refresh_text()


func _refresh_text() -> void:
    if _plain:
        var footer := "Left/Right   [Space] close"
        if _text_pages.size() > 1:
            footer = "Page %d/%d   " % [_text_page + 1, _text_pages.size()] + footer
        UiKit.fit_card(_card, _body, _text_pages[_text_page] + "\n\n" + footer, 288)
        return
    _body.text = _text_pages[_text_page] + "\n\n" + _legend
    _refresh_heading()


func _refresh_heading() -> void:
    if _on_graph():
        var heading := _title.text.split("\n")[0]
        _title.text = heading + "\n" + ("Arrows: look   V: whole" if _board.zoomed else
            "Left/Right  Up/Down  [Space]")
        return
    if _text_pages.is_empty():
        return
    var heading := _title.text.split("\n")[0]
    var page := " p%d/%d" % [_text_page + 1, _text_pages.size()] if _text_pages.size() > 1 else ""
    _title.text = heading + "\n" + ("Arrows: look   V: whole" if _board.zoomed else
        "%d/%d%s Left/Right [Space]" % [_index + 1, _card_count(), page])


func _navigate(direction: int) -> void:
    if not _text_pages.is_empty() and _text_page + direction >= 0 and _text_page + direction < _text_pages.size():
        _text_page += direction
        _refresh_text()
        return
    if _card_count() < 1:
        return
    var next := clampi(_index + direction, 0, _card_count() - 1)
    if next != _index:
        if next == 0 and _has_graph():
            # Land on the graph at the position the card was about.
            var f: Dictionary = review["findings"][_index - 1]
            _graph.selected = maxi(_graph.index_of_move(int(f.get("move_number", 0))), 0)
        _index = next
        _comparison = 0
        _text_page = -1 if direction < 0 else 0
        _show()


func _refresh_navigation() -> void:
    _navigation.refresh()
    _navigation.visible = _board.visible and _board.game != null
    if _navigation.visible:
        # Dark ink on this paper card; the match footer is over a dark backdrop.
        _navigation.modulate = Color("#45404f")
    _refresh_heading()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("go_lesson") and _lesson_id != "":
        requested_lesson = _lesson_id
        closed.emit()
        queue_free()
    elif event.is_action_pressed("go_compare") and _board.visible:
        _comparison = (_comparison + 1) % 3
        _show()
    elif _board.visible and _navigation.handle_input(event):
        _board.inspection = true
        _board.queue_redraw()
    elif _board.visible and _board.zoomed:
        if event.is_action_pressed("cancel"):
            _board.toggle_zoom()
            _board.inspection = true
        elif event.is_action_pressed("move_left"):
            _board.move_cursor(Vector2i.LEFT)
        elif event.is_action_pressed("move_right"):
            _board.move_cursor(Vector2i.RIGHT)
        elif event.is_action_pressed("move_up"):
            _board.move_cursor(Vector2i.UP)
        elif event.is_action_pressed("move_down"):
            _board.move_cursor(Vector2i.DOWN)
        elif event.is_action_pressed("interact"):
            closed.emit()
            queue_free()
        else:
            return
    elif _on_graph():
        if event.is_action_pressed("move_left"):
            _graph.step(-1)
        elif event.is_action_pressed("move_right"):
            _graph.step(1)
        elif event.is_action_pressed("move_up"):
            _graph.jump(-1)
        elif event.is_action_pressed("move_down"):
            _graph.jump(1)
        elif event.is_action_pressed("interact"):
            var move := int(_graph.selected_move().get("move", 0))
            if _graph.marked.has(move):
                _index = int(_graph.marked[move])
                _comparison = 0
                _text_page = 0
                _show()
        elif event.is_action_pressed("cancel"):
            closed.emit()
            queue_free()
        else:
            return
    elif event.is_action_pressed("move_left"):
        _navigate(-1)
    elif event.is_action_pressed("move_right"):
        _navigate(1)
    elif event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        closed.emit()
        queue_free()
    else:
        return
    get_viewport().set_input_as_handled()


func _configure_actions() -> void:
    var specs: Array = [["<", "move_left"], [">", "move_right"], ["Compare C", "go_compare"]]
    if _on_graph():
        specs.append(["Open", "interact"])
        specs.append(["Close", "cancel"])
        _actions.position.x = 122
        _actions.configure(specs)
        return
    if _lesson_id != "":
        specs.append(["Lesson L", "go_lesson"])
    specs.append(["Close", "interact"])
    _actions.position.x = 110 if _lesson_id != "" else 158
    _actions.configure(specs)
