## Immediate board effects; the engine preference is a separate judgement.
class_name MoveExplainer
extends RefCounted


static func describe(size: int, cells: Array, player: int, point: int, _edge_ok: bool = false) -> Dictionary:
    var game := MatchAnalysis.position(size, cells)
    if game == null or point < 0 or point >= size * size:
        return _entry("unknown", "", "leaves the position unchanged", "left the position unchanged", "left the position unchanged", "Compare the two positions before choosing a move.")
    game.to_move = player
    if game.legality(point) != GoGame.Legality.LEGAL:
        return _entry("unknown", "", "cannot be replayed in this position", "could not be replayed in this position", "been unavailable in this position", "Inspect the original position.")
    var board := game.board
    var groups: Dictionary = {}
    var targets: Array[String] = []
    var before_liberties: Array[String] = []
    for neighbour in board.neighbours(point):
        if board.get_idx(neighbour) != player:
            continue
        var chain := board.chain_at(neighbour)
        var stones: PackedInt32Array = chain["stones"]
        var anchor: int = stones[0]
        for stone in stones:
            anchor = mini(anchor, stone)
        if groups.has(anchor):
            continue
        groups[anchor] = true
        targets.append(board.label(anchor))
        before_liberties.append(str(chain["liberties"].size()))
    game.play(point)
    var captured: PackedInt32Array = game.last_move()["captured"]
    var liberties := game.board.liberty_count(point)
    var label := board.label(point)
    if not captured.is_empty():
        var count := captured.size()
        var noun := "%d opposing stone%s" % [count, "" if count == 1 else "s"]
        return _entry("capture", label, "captures " + noun, "captured " + noun, "captured " + noun,
            "After a capture, count the liberties of the group you just played in.")
    if groups.size() > 1:
        var joined := ", ".join(targets)
        var effect := "%d groups at %s; the joined group has %d liberties" % [groups.size(), joined, liberties]
        return _entry("connect", joined, "connects " + effect, "connected " + effect, "connected " + effect,
            "Compare the separate groups with the joined group. More liberties alone do not prove safety.")
    if groups.size() == 1:
        var effect := "the group at %s: %s liberties before, %d after" % [targets[0], before_liberties[0], liberties]
        var concept := "defend" if int(before_liberties[0]) <= 2 else "extend"
        return _entry(concept, targets[0], "extends " + effect, "extended " + effect, "extended " + effect,
            "Check which opposing move could take a liberty next. Extra liberties do not guarantee survival.")
    var p := board.point(point)
    var edge := mini(mini(p.x, size - 1 - p.x), mini(p.y, size - 1 - p.y))
    var description := "a stone at %s with %d liberties" % [label, liberties]
    if edge == 0:
        return _entry("first_line", label, "places " + description, "placed " + description, "placed " + description,
            "First-line moves can save stones, capture, or close a boundary. Check what this one changes.")
    for neighbour in board.neighbours(point):
        if board.get_idx(neighbour) == GoBoard.opponent(player):
            return _entry("contact", label, "places " + description + " beside an opponent", "placed " + description + " beside an opponent", "placed " + description + " beside an opponent",
                "Look at the liberties on both sides of the contact.")
    return _entry("space", label, "places " + description, "placed " + description, "placed " + description,
        "Compare the space near each move. A stone does not immediately own the surrounding empty points.")


static func same_job(better_label: String, _concept: String) -> Dictionary:
    return {"changed": "The engine preferred %s. Compare its immediate effect with your move." % better_label,
        "habit": "Use the comparison to inspect what each move changes."}


static func _entry(concept: String, target: String, present: String, past: String,
        participle: String, habit: String) -> Dictionary:
    return {"concept": concept, "target": target, "present": present, "past": past,
        "participle": participle, "note": "", "flaw": false, "habit": habit}
