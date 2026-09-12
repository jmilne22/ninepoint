## Facts about liberties and the actual final capture; no score estimates.
class_name CaptureGuide
extends RefCounted


static func observation(game: GoGame, player: int, selected: int = -1) -> Dictionary:
    var text := "Capture one stone to win. Choose a group with the cursor, then press H to inspect its liberties. Diagonals do not count."
    var stones := PackedInt32Array()
    if selected >= 0 and selected < game.board.cells.size() and not game.board.is_empty(selected):
        var group := game.board.chain_at(selected)
        stones = group["stones"]
        var labels := PackedStringArray()
        for liberty in group["liberties"]:
            labels.append(game.board.label(liberty))
        text = "This %s group has %d liberties: %s. The rings mark them. A connected group shares its liberties." % [
            GoBoard.color_name(game.board.get_idx(selected)), labels.size(), ", ".join(labels)]
    var threat := _threat(game, player)
    if not threat.is_empty():
        text += "\n\n" + str(threat["text"])
        if stones.is_empty():
            stones = threat["stones"]
    elif stones.is_empty():
        text += "\n\nStart near the middle. Then inspect the groups as stones meet. Pip tries nearby moves and takes an available capture."
    text += "\n\nP offers to end practice; Pip will pass too. Neither player wins that way. R offers resignation, which is a loss."
    return {"text": text, "stones": stones}


static func _threat(game: GoGame, player: int) -> Dictionary:
    var danger: Dictionary = {}
    var seen := {}
    for point in game.board.cells.size():
        var color := game.board.get_idx(point)
        if color == GoBoard.EMPTY or seen.has(point):
            continue
        var group := game.board.chain_at(point)
        for stone in group["stones"]:
            seen[stone] = true
        if group["liberties"].size() != 1:
            continue
        var liberty: int = group["liberties"][0]
        if color != player and game.is_legal(liberty, player):
            return {"text": "A capture is available at %s: that opposing group's last liberty. Playing there removes it." % game.board.label(liberty), "stones": group["stones"]}
        if color == player:
            danger = {"text": "Your group at %s has only one liberty, %s. Pip may capture it next. Look for an escape, connection or capture." % [game.board.label(point), game.board.label(liberty)], "stones": group["stones"]}
    return danger


static func final_capture(game: GoGame) -> Dictionary:
    if not bool(game.result.get("by_capture", false)) or game.moves.is_empty():
        return {}
    var move := game.last_move()
    var captured: PackedInt32Array = move["captured"]
    var before := game.board.cells.duplicate()
    before[int(move["point"])] = GoBoard.EMPTY
    for point in captured:
        before[point] = GoBoard.opponent(int(move["color"]))
    return {"size": game.size(), "before": Array(before), "point": move["point"],
        "color": move["color"], "captured": Array(captured)}


static func review_position(payload: Dictionary, after: bool = false) -> GoGame:
    var size := int(payload.get("size", 0))
    var cells: Array = payload.get("before", [])
    var color := int(payload.get("color", 0))
    if size < 2 or size > 19 or cells.size() != size * size or color not in [1, 2]:
        return null
    for cell in cells:
        if int(cell) < 0 or int(cell) > 2:
            return null
    var game := GoGame.new(size, 0.0)
    game.set_position(PackedByteArray(cells), color)
    game.capture_goal = 1
    if not game.play(int(payload.get("point", -1))) or not bool(game.result.get("by_capture", false)):
        return null
    if not after:
        game.undo()
    return game
