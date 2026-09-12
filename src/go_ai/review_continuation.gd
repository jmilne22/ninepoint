## Legal, bounded proof lines. Roles keep colour-mirrored facts identical.
class_name ReviewContinuation
extends RefCounted


static func trace(size: int, cells: Array, player: int, actual: int,
        pv: Array, after_actual: bool) -> Array:
    var game := GoGame.new(size)
    game.set_position(PackedByteArray(cells), player)
    if after_actual and not game.play(actual):
        return []
    var out: Array = []
    for value in pv.slice(0, 4):
        if not value is String:
            return []
        var label := str(value).to_upper()
        var point := game.board.from_label(label)
        var colour := game.to_move
        var captured: Array = []
        if label == "PASS":
            if game.state != GoGame.State.PLAYING:
                return []
            game.pass_turn()
            label = "pass"
        elif point < 0 or not game.play(point):
            return []
        else:
            for stone in game.last_move()["captured"]:
                captured.append(game.board.label(stone))
        out.append({"label":label, "point":point,
            "role":"player" if colour == player else "opponent", "captured":captured})
    return out


static func captured_at(stones: Array, line: Array) -> String:
    var taken: Array = []
    for move in line:
        taken.append_array(move["captured"])
        if stones.all(func(label: String) -> bool: return taken.has(label)):
            return str(move["label"])
    return ""
