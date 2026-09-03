## How the game was going, in points, after any given move.
##
## This exists as a seam rather than a function because there are two honest
## answers to it and the review should not care which one it has. The shipped
## answer is GoProgress: stones on the board plus the points only one colour
## surrounds, which is arithmetic on the rules and is how a human counts. The
## other answer is an engine -- KataGo over GTP would give a real score estimate
## through `kata-analyze`, and would be better at it.
##
## The review is built against this interface so that swapping the second in
## later changes the accuracy of the numbers and nothing else: not a detector,
## not a voice line, not a takeaway. An evaluator that cannot answer says so
## through available(), and the review falls back to ordering by severity.
class_name GoEvaluator
extends RefCounted


## Called once per review, before any lead_after(). Implementations that need to
## walk the whole game (or start a subprocess) do it here.
func prepare(_ctx: Dictionary, _komi: float) -> void:
    pass


## False when this evaluator has nothing to say -- an engine that is not
## installed, or a game that could not be replayed. Callers must check it;
## a cost of zero and a cost that is unknown are different things.
func available() -> bool:
    return false


## The player's lead in points after every position the game passed through --
## one entry per GoReview.positions_of() entry, so 0 is before the first move
## and the last is the finished board. Empty when unavailable.
func curve() -> PackedFloat32Array:
    return PackedFloat32Array()


## The lead after position `k`, negative when behind. Concrete on purpose: an
## implementation supplies the curve and gets safe indexing for free.
func lead_after(k: int) -> float:
    var c := curve()
    if c.is_empty():
        return 0.0
    return c[clampi(k, 0, c.size() - 1)]
