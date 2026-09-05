## The viewing controls describe where the learner is looking, not what to play.
class_name BoardNavigation
extends Control

var compact := false
var board: GoBoardView
var _caption: Label
var _actions: MouseActions


func setup(value: GoBoardView) -> void:
    board = value
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _caption = UiKit.label(self, Vector2.ZERO, int(size.x), UiKit.PAPER, int(size.y))
    _caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _actions = MouseActions.new()
    _actions.position = Vector2(26, 0)
    add_child(_actions)
    _actions.action_selected.connect(_action)
    board.view_changed.connect(refresh)
    refresh()


func refresh() -> void:
    visible = board.game != null
    var point := board.target_point()
    _caption.text = board.game.board.label(point) if visible and point >= 0 else ""
    var specs: Array = []
    if visible and board.game.size() == 19:
        specs.append(["Whole" if board.zoomed else "Zoom V", "go_zoom"])
        if board.zoomed:
            specs.append(["<", "left"])
            specs.append([">", "right"])
            specs.append(["Up", "up"])
            specs.append(["Dn", "down"])
    _actions.configure(specs)


func _action(action: StringName) -> void:
    if action == &"go_zoom":
        board.toggle_zoom()
    else:
        var directions := {&"left": Vector2i.LEFT, &"right": Vector2i.RIGHT,
            &"up": Vector2i.UP, &"down": Vector2i.DOWN}
        board.pan_view(directions[action])


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
