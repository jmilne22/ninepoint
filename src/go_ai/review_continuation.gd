## Legal, bounded proof lines. Roles keep colour-mirrored facts identical.
class_name ReviewContinuation
extends RefCounted


static func trace(size: int, cells: Array, player: int, actual: int,
        pv: Array, after_actual: bool, position: GoGame = null) -> Array:
    var game := position.fork() if position != null else GoGame.new(size)
    if position == null:
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


## An illustration, not a forced line: keep two legal PV moves, then capture in atari.
static func capture_example(input: Dictionary, stones: Array, line: Array) -> Array:
    if line.size() < 2 or stones.is_empty():
        return []
    var game := GoGame.new(int(input["size"]))
    var player := int(input["player"])
    game.set_position(PackedByteArray(input["cells"]), player)
    if not game.play(int(input["actual"])):
        return []
    var pv: Array = []
    for move: Dictionary in line.slice(0,2):
        pv.append(move["label"])
        if move["label"] == "pass":
            game.pass_turn()
        elif not game.play(game.board.from_label(move["label"])):
            return []
    var anchor := game.board.from_label(stones[0])
    if anchor < 0 or game.board.cells[anchor] != player or game.to_move == player:
        return []
    var chain := game.board.chain_at(anchor)
    if chain["liberties"].size() != 1:
        return []
    pv.append(game.board.label(chain["liberties"][0]))
    var example := trace(game.board.size,input["cells"],player,int(input["actual"]),pv,true)
    return example if captured_at(stones,example) != "" else []
