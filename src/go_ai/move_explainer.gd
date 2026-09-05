## What a move does, said from the stones alone. The engine says how much a
## move was worth; this says why, in the vocabulary the lessons teach, and only
## when the position proves it. If the stones do not show one of these ideas
## the text says so rather than bluffing.
##
## `does` is written for the move the player made ("It joins your stones");
## `changed` for the move they did not ("It would have joined your stones").
class_name MoveExplainer
extends RefCounted


static func describe(size: int, cells: Array, player: int, point: int) -> Dictionary:
    var game := MatchAnalysis.position(size, cells)
    if game == null or point < 0 or point >= size * size or game.board.get_idx(point) != GoBoard.EMPTY:
        return _entry("unknown",
            "It is a local choice the stones do not explain on their own.",
            "It is a different local choice, without a simple forced claim.",
            "Pause and compare one nearby reply.")
    var board := game.board
    var friendly := 0
    var enemy := 0
    var enemy_atari := false
    var short_friend := false
    for neighbour in board.neighbours(point):
        var stone := board.get_idx(neighbour)
        if stone == player:
            friendly += 1
            if board.liberty_count(neighbour) <= 2:
                short_friend = true
        elif stone == GoBoard.opponent(player):
            enemy += 1
            if board.liberty_count(neighbour) == 1:
                enemy_atari = true
    if enemy_atari:
        return _entry("capture",
            "It takes stones that had one liberty left.",
            "It would have taken stones that had one liberty left.",
            "When stones touch, count their liberties before playing elsewhere.")
    if friendly >= 2:
        return _entry("connect",
            "It joins your nearby stones so they share liberties.",
            "It would have joined your nearby stones so they share liberties.",
            "Before a fight, look for the move that connects your stones.")
    if friendly == 1 and short_friend:
        return _entry("defend",
            "It gives your short-of-liberties group room to live.",
            "It would have given your short-of-liberties group room to live.",
            "Check your groups with two or fewer liberties first.")
    if friendly == 1:
        return _entry("extend",
            "It extends from your stone and gives it more room.",
            "It would have extended from your stone and given it more room.",
            "After contact, extend when your stones need room.")
    if enemy > 0:
        return _entry("attack",
            "It leans on a nearby group of theirs.",
            "It would have leaned on a nearby group of theirs.",
            "When you approach a group, check whether it can answer locally.")
    # Nothing touches it: what it claims is a question of where it stands.
    var p := board.point(point)
    var from_edge := mini(mini(p.x, size - 1 - p.x), mini(p.y, size - 1 - p.y))
    var near_corner := mini(p.x, size - 1 - p.x) <= 3 and mini(p.y, size - 1 - p.y) <= 3
    if from_edge == 0:
        return _entry("first_line",
            "It sits on the first line, where a stone makes almost no territory.",
            "It would have stayed off the first line, where a stone makes almost no territory.",
            "Leave the first line alone until the end of the game.")
    if near_corner and from_edge <= 3:
        return _entry("corner",
            "It takes the corner, where territory is cheapest to make.",
            "It would have taken the corner, where territory is cheapest to make.",
            "Corners first, then sides, then the middle.")
    if from_edge <= 3:
        return _entry("side",
            "It stakes out the side.",
            "It would have staked out the side.",
            "Corners first, then sides, then the middle.")
    return _entry("centre",
        "It takes open ground in the middle.",
        "It would have taken open ground in the middle.",
        "Corners first, then sides, then the middle.")


static func _entry(concept: String, does: String, changed: String, habit: String) -> Dictionary:
    return {"concept": concept, "does": does, "changed": changed, "habit": habit}
