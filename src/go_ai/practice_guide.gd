## Observations are facts about the current position, never a strength estimate.
class_name PracticeGuide
extends RefCounted


static func observation(game: GoGame, player: int) -> Dictionary:
    if game.board.count_color(GoBoard.BLACK) + game.board.count_color(GoBoard.WHITE) == 0:
        return {"prompt": "Start away from the edge.\nHelp H: opening guidance.", "text": "The board is empty. Try a starting point away from the edge, leaving room to extend toward nearby empty space.", "stones": PackedInt32Array()}
    var seen := {}
    var endangered: Dictionary = {}
    for point in game.board.cells.size():
        var color := game.board.get_idx(point)
        if color == GoBoard.EMPTY or seen.has(point):
            continue
        var chain := game.board.chain_at(point)
        for stone in chain["stones"]:
            seen[stone] = true
        if chain["liberties"].size() != 1:
            continue
        var liberty: int = chain["liberties"][0]
        if color != player and game.legality(liberty, player) == GoGame.Legality.LEGAL:
            return {"prompt": "Capture at %s available.\nHelp H: inspect the group." % game.board.label(liberty), "text": "The highlighted group has one liberty, at %s. Playing there captures it. Check your own groups too." % game.board.label(liberty), "stones": chain["stones"]}
        if color == player and endangered.is_empty():
            endangered = {"prompt": "Your group has one liberty.\nHelp H: inspect it.", "text": "Your highlighted group has one liberty, at %s. This is called atari. Look for a legal escape, connection or capture; an extra liberty does not always make it safe." % game.board.label(liberty), "stones": chain["stones"]}
    if not endangered.is_empty():
        return endangered
    # Nothing is in atari. Point at the two groups that matter next instead of
    # at "the empty space", which a beginner cannot act on.
    var mine := _fewest_liberties(game.board, player)
    var theirs := _fewest_liberties(game.board, GoBoard.opponent(player))
    var parts: Array[String] = []
    var prompt := "Look for space to extend.\nHelp H: inspect groups."
    if not mine.is_empty():
        parts.append("Your group at %s has the fewest liberties, %d (%s). Extend from it or leave it room." % [
            mine["anchor"], mine["count"], ", ".join(mine["liberties"])])
        prompt = "Fewest liberties: yours at %s (%d).\nHelp H: inspect groups." % [mine["anchor"], mine["count"]]
    if not theirs.is_empty():
        parts.append("%s's group at %s has %d; %s takes one." % [GoBoard.color_name(GoBoard.opponent(player)),
            theirs["anchor"], theirs["count"], theirs["liberties"][0]])
    if parts.is_empty():
        parts.append("Play where your stones can reach the most empty space.")
    return {"prompt": prompt, "text": " ".join(parts), "stones": PackedInt32Array()}


## The group of one colour with the fewest liberties; ties go to the lowest point.
static func _fewest_liberties(board: GoBoard, color: int) -> Dictionary:
    var seen := {}
    var out := {}
    for point in board.cells.size():
        if board.get_idx(point) != color or seen.has(point):
            continue
        var chain := board.chain_at(point)
        for stone in chain["stones"]:
            seen[stone] = true
        var count: int = chain["liberties"].size()
        if not out.is_empty() and count >= int(out["count"]):
            continue
        var liberties: Array = Array(chain["liberties"])
        liberties.sort()
        out = {"anchor": board.label(point), "count": count,
            "liberties": liberties.map(func(i: int) -> String: return board.label(i))}
    return out
