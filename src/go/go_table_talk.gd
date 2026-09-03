## What just happened at the board, in words a person at the table would use.
##
## Pure rules, like the rest of src/go/: it looks at the position and the last
## move and returns tags. It knows nothing about who is playing or what they
## would say about it -- the lines live in data/banter/ and the picking happens
## in the match scene.
##
## The line this deliberately does not cross: these are OUTCOMES, not judgements.
## A capture landed, a group died, a ko started, the score swung. What the player
## should have played instead is GoReview's job, and saying it here would spoil
## the only thing the review has to offer -- something they had not already seen.
class_name GoTableTalk
extends RefCounted

## A capture worth remarking on at all, and one worth stopping the game for.
const NOTABLE_CAPTURE := 1
const BIG_CAPTURE := 5

## Moves before the edge stops being a mistake and starts being the endgame.
const EARLY_MOVES := 20


## Tags for the move just played, most specific first. `speaker` is the colour of
## the character who would be talking, so the same position reads differently
## depending on which side of the board the voice is sitting on.
static func events(game: GoGame, speaker: int) -> PackedStringArray:
    var out := PackedStringArray()
    if game == null or game.moves.is_empty():
        return out
    var last: Dictionary = game.moves[-1]
    var mover := int(last.get("color", GoBoard.EMPTY))
    var mine := mover == speaker
    var point := int(last.get("point", -1))
    if point < 0:
        return out

    var captured: PackedInt32Array = last.get("captured", PackedInt32Array())
    if captured.size() >= BIG_CAPTURE:
        out.append("i_captured_big" if mine else "you_captured_big")
    elif captured.size() >= NOTABLE_CAPTURE:
        out.append("i_captured" if mine else "you_captured")

    # A ko has been taken when the rules say the point is now forbidden. It is
    # the one shape a beginner notices happening to them without understanding it.
    if game.ko_point >= 0 and captured.size() == 1:
        out.append("ko")

    # Announcing your own atari is a beginner's habit and pure characterisation:
    # it tells the listener nothing the board is not already showing. Whether a
    # given character does it is decided by whether they have a line for it.
    if _puts_enemy_in_atari(game, point, mover):
        out.append("i_atari" if mine else "you_atari")

    if _is_first_line(game, point) and game.move_number() <= EARLY_MOVES:
        out.append("i_edge_early" if mine else "you_edge_early")

    return out


## True when the move leaves at least one enemy chain touching it on one liberty.
static func _puts_enemy_in_atari(game: GoGame, point: int, mover: int) -> bool:
    var enemy := GoBoard.opponent(mover)
    for n in game.board.neighbours(point):
        if game.board.get_idx(n) != enemy:
            continue
        var chain := game.board.chain_at(n)
        if chain["liberties"].size() == 1:
            return true
    return false


static func _is_first_line(game: GoGame, point: int) -> bool:
    var p := game.board.point(point)
    var n := game.size()
    return p.x == 0 or p.y == 0 or p.x == n - 1 or p.y == n - 1


## Who is ahead, by the same crude area count the old flavour line used. Good
## enough for bravado and not offered as anything else -- an honest score needs
## dead stones marked, which cannot happen while the game is still going.
## Returns "winning", "losing" or "level" from the speaker's side.
static func standing(game: GoGame, speaker: int, margin: float = 4.0) -> String:
    var s := GoScoring.score(game.board, {}, game.captures, game.komi, GoScoring.Rule.CHINESE)
    var mine: float = s["black"] if speaker == GoBoard.BLACK else s["white"]
    var theirs: float = s["white"] if speaker == GoBoard.BLACK else s["black"]
    if mine - theirs > margin:
        return "winning"
    if theirs - mine > margin:
        return "losing"
    return "level"
