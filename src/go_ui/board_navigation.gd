## The viewing controls describe where the learner is looking, not what to play.
class_name BoardNavigation
extends Control

var compact := false
var board: GoBoardView
var _caption: Label


func setup(value: GoBoardView) -> void:
    board = value
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _caption = UiKit.label(self, Vector2.ZERO, int(size.x), UiKit.PAPER, int(size.y))
    _caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    board.view_changed.connect(refresh)
    refresh()


func refresh() -> void:
    visible = board.game != null and board.game.size() == 19
    _caption.text = board.view_caption() if visible else ""
    if visible and compact:
        _caption.text = "%s %s\nV: %s" % [board.game.board.label(board.cursor),
            "Close view" if board.zoomed else "Whole board",
            "whole; arrows move" if board.zoomed else "zoom"]


func handle_input(event: InputEvent) -> bool:
    if board.game == null or board.game.size() != 19:
        return false
    if event.is_action_pressed("go_zoom") and not event.is_echo():
        board.toggle_zoom()
        return true
    return false


static func opponent_move_text(board_view: GoBoardView, player_color: int) -> String:
    var game := board_view.game
    for i in range(game.moves.size() - 1, -1, -1):
        var move: Dictionary = game.moves[i]
        if int(move.get("color", 0)) == player_color:
            continue
        var point := int(move.get("point", -1))
        if point < 0:
            return "Opponent passed"
        var outside := " outside view" if board_view.zoomed and not board_view.point_visible(point) else ""
        return "Opp: %s%s" % [game.board.label(point), outside]
    return "Opponent has not played"
