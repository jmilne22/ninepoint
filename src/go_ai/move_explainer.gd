## What a move does, said from the stones alone, with the stones named. The
## engine says how much a move was worth; this says why, in the vocabulary the
## lessons teach, and only when the position proves it.
##
## Each description carries the verb in three forms, so one card can say "It
## takes the white stone at G4" of the move the player made, "Yours took the
## white stone at G4" of the same move on a mistake card, and "D7 would have
## taken the corner" of the move they did not. `flaw` is true when the played
## move is wrong on its face (a first-line stone in the middle of the game, a
## connection that was never needed); then its habit outranks the better
## move's habit, because that is the thing to unlearn. `target` names what
## the move works on, so two moves doing the same job can be told apart.
class_name MoveExplainer
extends RefCounted


## `edge_ok` says a first-line stone is legitimate here -- the endgame, or a
## point the engine itself chose -- and must be described by what it does.
static func describe(size: int, cells: Array, player: int, point: int, edge_ok: bool = false) -> Dictionary:
    var game := MatchAnalysis.position(size, cells)
    if game == null or point < 0 or point >= size * size or game.board.get_idx(point) != GoBoard.EMPTY:
        return _entry("unknown", "", ["is a local choice the stones do not explain",
            "was a local choice the stones do not explain", "been a local choice the stones do not explain"],
            "", false, "Pause and compare one nearby reply.")
    var board := game.board
    var opp := GoBoard.color_name(GoBoard.opponent(player)).to_lower()
    var friends: Array[String] = []
    var fewest_friend_liberties := 99
    var enemies: Array[String] = []
    var atari := -1
    for neighbour in board.neighbours(point):
        var stone := board.get_idx(neighbour)
        if stone == player:
            friends.append(board.label(neighbour))
            fewest_friend_liberties = mini(fewest_friend_liberties, board.liberty_count(neighbour))
        elif stone == GoBoard.opponent(player):
            enemies.append(board.label(neighbour))
            if atari < 0 and board.liberty_count(neighbour) == 1:
                atari = neighbour
    var p := board.point(point)
    var from_edge := mini(mini(p.x, size - 1 - p.x), mini(p.y, size - 1 - p.y))
    var needed := friends.size() == 1 and fewest_friend_liberties <= 2
    if atari >= 0:
        var what := _stones(board, atari, opp)
        return _entry("capture", board.label(atari), ["takes the %s, which had one liberty left" % what,
            "took the %s, which had one liberty left" % what, "taken the %s, which had one liberty left" % what],
            "", false, "When stones touch, count their liberties before playing elsewhere.")
    # A first-line stone that neither captures nor saves anything is the flaw
    # to name, whatever else it touches: it is the beginner's commonest move.
    if from_edge == 0 and not needed and not edge_ok:
        return _entry("first_line", "", ["sits on the first line, where a stone makes almost no territory",
            "sat on the first line, where a stone makes almost no territory",
            "sat on the first line, where a stone makes almost no territory"],
            "", true, "Leave the first line alone until the end of the game.")
    if friends.size() >= 2:
        var safe := fewest_friend_liberties >= 3
        var pair := "%s and %s" % [friends[0], friends[1]]
        return _entry("connect", pair, ["joins your stones at %s so they share liberties" % pair,
            "joined your stones at %s" % pair, "joined your stones at %s" % pair],
            ", which already had %d liberties" % fewest_friend_liberties if safe else "",
            safe, "Connect when a cut would hurt; when it would not, take the bigger point."
                if safe else "Before a fight, look for the move that connects your stones.")
    if needed:
        var libs := "%d %s" % [fewest_friend_liberties, "liberty" if fewest_friend_liberties == 1 else "liberties"]
        return _entry("defend", friends[0], ["gives your group at %s, down to %s, room to live" % [friends[0], libs],
            "gave your group at %s room to live" % friends[0], "given your group at %s room to live" % friends[0]],
            "", false, "Check your groups with two or fewer liberties first.")
    if friends.size() == 1:
        var safe := fewest_friend_liberties >= 3
        return _entry("extend", friends[0], ["extends from your stone at %s and gives it more room" % friends[0],
            "extended from your stone at %s" % friends[0], "extended from your stone at %s" % friends[0]],
            ", which already had %d liberties" % fewest_friend_liberties if safe else "", safe,
            "Extend when a stone needs room; when it has room, take the bigger point."
                if safe else "After contact, extend when your stones need room.")
    if not enemies.is_empty():
        var what := _stones(board, board.from_label(enemies[0]), opp)
        return _entry("attack", enemies[0], ["leans on the %s" % what, "leaned on the %s" % what, "leaned on the %s" % what],
            "", false, "A lone stone of theirs is the biggest thing on a small board; lean on it early.")
    # Nothing touches it: what it claims is a question of where it stands.
    if from_edge == 0:
        return _entry("edge", "", ["takes a point on the edge worth more than it looks",
            "took a point on the edge worth more than it looks", "taken a point on the edge worth more than it looks"],
            "", false, "Edge points look small; count them before passing over them.")
    var near_corner := mini(p.x, size - 1 - p.x) <= 3 and mini(p.y, size - 1 - p.y) <= 3
    if near_corner and from_edge <= 3:
        return _entry("corner", "", ["takes the corner, where territory is cheapest to make",
            "took the corner", "taken the corner"], "", false, "Corners first, then sides, then the middle.")
    if from_edge <= 3:
        return _entry("side", "", ["stakes out the side", "staked out the side", "staked out the side"],
            ", but the board had a bigger point", false, "Corners first, then sides, then the middle.")
    return _entry("centre", "", ["takes open ground in the middle", "took open ground in the middle",
        "taken open ground in the middle"], ", but the board had a bigger point", false,
        "Corners first, then sides, then the middle.")


## When the played move and the better move do the same job on the same
## stones, the difference is the side or the direction, and the card says so.
static func same_job(better_label: String, concept: String) -> Dictionary:
    match concept:
        "attack":
            return {"changed": "%s leans on the same stone from the other side; that side was worth more." % better_label,
                "habit": "When two moves lean on the same stone, take the side that also gains something."}
        "extend":
            return {"changed": "%s extends from the same stone in another direction; that direction was worth more." % better_label,
                "habit": "When two moves extend the same stone, extend towards the open side."}
        "connect", "defend":
            return {"changed": "%s does the same job for the same stones and gains more with it." % better_label,
                "habit": "When two moves save the same stones, pick the one that also gains something."}
        "corner":
            return {"changed": "%s takes a different corner, which was worth more." % better_label,
                "habit": "The empty corner nearest their stones is usually the biggest one."}
        "side":
            return {"changed": "%s stakes out a different side, which was worth more." % better_label,
                "habit": "Take the side between your stones before the side between theirs."}
        "edge":
            return {"changed": "%s takes a different edge point, which was worth more." % better_label,
                "habit": "Edge points look small; count them before passing over them."}
        "centre":
            return {"changed": "%s takes a different point in the middle, which was worth more." % better_label,
                "habit": "In the middle, play where your stones and theirs meet."}
        _:
            return {"changed": "%s does the same job, and the count says it does it better." % better_label,
                "habit": "When two moves do the same job, count which one gains more."}


static func _stones(board: GoBoard, point: int, colour_word: String) -> String:
    var chain: Dictionary = board.chain_at(point)
    var count: int = chain.get("stones", PackedInt32Array()).size()
    return "%s stone at %s" % [colour_word, board.label(point)] if count <= 1 \
        else "%s stones at %s" % [colour_word, board.label(point)]


static func _entry(concept: String, target: String, verbs: Array, note: String,
        flaw: bool, habit: String) -> Dictionary:
    return {"concept": concept, "target": target, "present": verbs[0], "past": verbs[1],
        "participle": verbs[2], "note": note, "flaw": flaw, "habit": habit}
