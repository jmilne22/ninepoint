## The full retained history is both the query and the cache identity.
class_name TeachingPosition
extends RefCounted


static func query(game: GoGame, id: String) -> Dictionary:
    var initial := game.initial_position()
    var stones: Array = []
    for point in game.board.cells.size():
        var colour := int(initial["cells"][point])
        if colour != GoBoard.EMPTY:
            stones.append(["B" if colour == GoBoard.BLACK else "W", game.board.label(point)])
    var moves: Array = []
    for move in game.moves:
        moves.append(["B" if move["color"] == GoBoard.BLACK else "W", move["label"]])
    return {"id": id, "initialStones": stones,
        "initialPlayer": "B" if initial["player"] == GoBoard.BLACK else "W",
        "moves": moves, "rules": "japanese", "komi": game.komi,
        "boardXSize": game.size(), "boardYSize": game.size(),
        "analyzeTurns": [moves.size()], "maxVisits": 30,
        "includeOwnership": true, "includePolicy": false}


static func key(game: GoGame) -> String:
    var value := query(game, "")
    value["ko_rule"] = game.ko_rule
    value["ko_point"] = game.ko_point
    value["to_move"] = game.to_move
    value["cells"] = Array(game.board.cells)
    return JSON.stringify(value)
