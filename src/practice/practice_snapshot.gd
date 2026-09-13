class_name PracticeSnapshot
extends RefCounted

static func capture(game: GoGame, player: int, dead: Dictionary = {}, coaching := false) -> Dictionary:
    var actions: Array = []
    for move in game.moves:
        actions.append({"color": move.color, "point": move.point})
    return {"size": game.size(), "komi": game.komi, "handicap": game.handicap,
        "capture_goal": game.capture_goal, "ko_rule": game.ko_rule,
        "player": player, "actions": actions, "dead": dead.keys(), "coaching": coaching}

static func restore(snapshot: Dictionary) -> GoGame:
    var size := int(snapshot.get("size", 0))
    if size not in PracticeSettings.SIZES: return null
    var handicap := int(snapshot.get("handicap", 0))
    if handicap < 0 or handicap == 1 or handicap > GoRank.max_handicap(size): return null
    if not snapshot.get("actions", []) is Array: return null
    var game := GoGame.new(size, float(snapshot.get("komi", 5.5)), int(snapshot.get("handicap", 0)))
    game.capture_goal = int(snapshot.get("capture_goal", 0))
    game.ko_rule = int(snapshot.get("ko_rule", GoGame.KoRule.SIMPLE))
    for action: Variant in snapshot.get("actions", []):
        if not action is Dictionary or not action.has("point") or not action.has("color"): return null
        if int(action.color) != game.to_move or game.state != GoGame.State.PLAYING: return null
        var point := int(action.point)
        if point == GoGame.PASS: game.pass_turn()
        elif point == GoGame.RESIGN: game.resign(game.to_move)
        elif not game.play(point): return null
    return game

static func take_back(game: GoGame, player: int) -> bool:
    var found := -1
    for i in range(game.moves.size() - 1, -1, -1):
        if int(game.moves[i].color) == player:
            found = i
            break
    if found < 0: return false
    while game.moves.size() > found:
        if not game.undo(): return false
    return true
