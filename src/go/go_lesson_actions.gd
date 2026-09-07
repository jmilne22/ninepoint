## Non-placement lesson actions use the same game and scoring rules as matches.
class_name GoLessonActions
extends RefCounted

var game: GoGame
var step: Dictionary
var dead: Dictionary = {}
var inspected: Dictionary = {}
var toggles := 0
var count_targets: Dictionary = {}


func setup(value: GoGame, data: Dictionary) -> void:
    game = value
    step = data
    dead.clear()
    inspected.clear()
    toggles = 0
    for xy in step.get("dead", []):
        var point := int(xy[1]) * game.size() + int(xy[0])
        for stone in game.board.chain_at(point)["stones"]:
            dead[stone] = true
    count_targets = dead.duplicate()


func activate(point: int) -> bool:
    if game.board.is_empty(point):
        return false
    var stones: PackedInt32Array = game.board.chain_at(point)["stones"]
    if step["action"] == "inspect":
        for target in step["target"]:
            if stones.has(target):
                inspected[target] = true
        return inspected.size() == step["target"].size()
    if step["action"] == "count":
        var marked := not bool(dead.get(point, false))
        for stone in stones:
            if marked:
                dead[stone] = true
            else:
                dead.erase(stone)
        if count_targets.has(point):
            toggles += 1
    return false


func accept_count() -> bool:
    if toggles < 2:
        return false
    var expected: Array = step.get("expected_score", [])
    var score := current_score()
    if expected.size() != 2 or not is_equal_approx(float(expected[0]), float(score["black"])) \
            or not is_equal_approx(float(expected[1]), float(score["white"])):
        return false
    game.finish_with_score(score)
    return true


func pass_and_reply() -> bool:
    if step["action"] != "pass" or game.state != GoGame.State.PLAYING:
        return false
    game.pass_turn()
    game.pass_turn()
    return game.state == GoGame.State.SCORING


func play_reply() -> bool:
    var reply: Array = step.get("reply", [])
    if reply.is_empty():
        return true
    if int(reply[0]) < 0:
        game.pass_turn()
        return true
    var point := int(reply[1]) * game.size() + int(reply[0])
    if game.legality(point) != GoGame.Legality.LEGAL:
        return false
    game.play(point)
    return true


func current_score() -> Dictionary:
    return GoScoring.score(game.board, dead, game.captures, game.komi)


func score_text() -> String:
    var score := current_score()
    var d: Dictionary = score["detail"]
    return "Black: %d territory + %d prisoners = %s\nWhite: %d territory + %d prisoners + %s komi = %s" % [
        d["black_territory"], d["black_prisoners"], score["black"],
        d["white_territory"], d["white_prisoners"], game.komi, score["white"]]


## A proof may change the side to demonstrate a refusal. Each outcome stays
## observable so validators can check every move, including intermediate ones.
static func demonstrate(position: GoGame, proof: Dictionary) -> Dictionary:
    var outcomes: Array[bool] = []
    var points := PackedInt32Array()
    var captured := 0
    for move in proof["moves"]:
        position.to_move = GoBoard.BLACK if move[0] == "black" else GoBoard.WHITE
        var point := int(move[2]) * position.size() + int(move[1])
        var legal := position.legality(point) == GoGame.Legality.LEGAL
        outcomes.append(legal)
        points.append(point)
        if legal:
            position.play(point)
            captured += position.last_move()["captured"].size()
    return {"legal": outcomes, "points": points, "captured": captured}
