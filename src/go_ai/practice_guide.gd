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
    return {"prompt": "Look for space to extend.\nHelp H: inspect groups.", "text": "Look at the empty space near your stones. You can leave room for later moves instead of drawing a complete wall.", "stones": PackedInt32Array()}
