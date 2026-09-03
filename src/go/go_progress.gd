## The shipped GoEvaluator: how the game was going, counted the way a person
## counts it.
##
## Stones on the board, plus the empty points that only one colour surrounds,
## plus komi. No engine, no judgement -- GoScoring.territory_map() already
## answers "whose is this region" by looking at what borders it, and a beginner
## on a 9x9 counts exactly that and nothing more.
##
## Deliberately does NOT run GoScoring.estimate_dead(). A group that is doomed
## but still on the board keeps counting until it is actually taken, so the
## curve falls on the move the stones come off rather than on the move they
## became hopeless. That is the wrong answer for scoring and the right one for
## a review: the move you want to show somebody is the one where it happened to
## them, not the one where an expert would have called it.
class_name GoProgress
extends GoEvaluator

## Below this many points, a swing is noise rather than the turn of a game.
const SWING_THRESHOLD := 6.0

## An empty region larger than this share of the board is not territory, it is
## the rest of the game.
##
## Without this the curve is nonsense for the first few moves, and the nonsense
## is not small: on an empty board the one region has no border at all, and
## after Black's first stone the *entire* remaining board is bordered by Black
## alone -- so a 9x9 reads as 80 points for Black on move one and back to zero
## on move two. worst_swing() then finds an 81-point collapse in every game ever
## played, which is precisely the failure this whole module is written to avoid:
## a review that invents a mistake is worse than one that misses it.
##
## Whole-board scoring says one colour alone owns everything, which is true and
## useless -- the same trap tools/check_lessons.py exists to catch in the
## openings lesson. Territory has to be regional to mean anything.
const SETTLED_SHARE := 2

var _curve := PackedFloat32Array()


func prepare(ctx: Dictionary, komi: float) -> void:
    _curve = compute(ctx, komi)


func available() -> bool:
    return not _curve.is_empty()


func curve() -> PackedFloat32Array:
    return _curve


# --- the arithmetic ----------------------------------------------------------

## `colour`'s lead in points on this board: their stones and the regions only
## they enclose, less the same for the opponent. Komi belongs to White always.
static func settled_lead(board: GoBoard, colour: int, komi: float) -> float:
    var enemy := GoBoard.opponent(colour)
    var mine := float(board.count_color(colour))
    var theirs := float(board.count_color(enemy))
    var cap: int = board.cells.size() / SETTLED_SHARE
    for region in GoScoring.empty_regions(board):
        var borders: Dictionary = region["borders"]
        if borders.size() != 1:
            continue                      # touches both, or nothing: nobody's
        var pts: PackedInt32Array = region["points"]
        if pts.size() > cap:
            continue                      # not walled off, just not reached yet
        if int(borders.keys()[0]) == colour:
            mine += float(pts.size())
        else:
            theirs += float(pts.size())
    if colour == GoBoard.WHITE:
        mine += komi
    else:
        theirs += komi
    return mine - theirs


## The lead after every position the game passed through, from the player's
## side. One entry per ctx["positions"] entry, so index 0 is before move 1.
static func compute(ctx: Dictionary, komi: float) -> PackedFloat32Array:
    var positions: Array = ctx["positions"]
    var colour: int = int(ctx["colour"])
    var out := PackedFloat32Array()
    out.resize(positions.size())
    for k in positions.size():
        out[k] = settled_lead(GoReviewReplay.board_at(ctx, k), colour, komi)
    return out


## What was lost between two positions, in points, or 0 if nothing was. Used to
## price a finding over the window in which its consequence actually landed.
static func cost_of(c: PackedFloat32Array, from_index: int, to_index: int) -> float:
    if c.is_empty():
        return 0.0
    var a := clampi(from_index, 0, c.size() - 1)
    var b := clampi(to_index, 0, c.size() - 1)
    if b <= a:
        return 0.0
    return maxf(c[a] - c[b], 0.0)


## The worst sustained loss of ground in the game, as
## {from: int, to: int, points: float}, or {} when nothing crossed `threshold`.
##
## This is a maximum drawdown -- the largest fall from any high-water mark to
## any later low -- because "when did the game get away from you" is that exact
## question, and it is not the same as the single worst move. A game lost over
## fifteen quiet moves has no worst move and still has a turn.
static func worst_swing(c: PackedFloat32Array,
        threshold: float = SWING_THRESHOLD) -> Dictionary:
    if c.size() < 2:
        return {}
    var peak := 0
    var best := {"from": -1, "to": -1, "points": 0.0}
    for k in c.size():
        if c[k] > c[peak]:
            peak = k
        var drop: float = c[peak] - c[k]
        if drop > float(best["points"]):
            best = {"from": peak, "to": k, "points": drop}
    if float(best["points"]) < threshold:
        return {}
    return best


## "ahead" / "behind" / "close", from the player's side, for the one sentence of
## shape a review opens with.
static func standing(lead: float, margin: float = 4.0) -> String:
    if lead > margin:
        return "ahead"
    if lead < -margin:
        return "behind"
    return "close"
