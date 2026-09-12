## Plain-language coverage and engine tally for the opening review card.
class_name ReviewSummary
extends RefCounted


## The tally comes first: what went right, in numbers a learner can hold on
## to, before the positions where something went wrong.
static func text(review: Dictionary) -> String:
    var tally: Dictionary = review.get("tally", {})
    if tally.is_empty():
        return ""
    var moves := int(tally.get("moves", 0))
    var best := int(tally.get("best", 0))
    var fine := int(tally.get("fine", 0))
    var looked := "You placed %d stone%s." % [moves, "" if moves == 1 else "s"]
    if bool(review.get("partial", false)):
        looked = "The first %d of your %d moves were looked at." % [moves, int(review.get("total_moves", moves))]
    var verdict := ""
    if best > 0 and fine > 0:
        verdict = "%d %s the engine's preferred move, and another %d were close in its estimate." % [
            best, "was" if best == 1 else "were", fine]
    elif best > 0:
        verdict = "%d %s the engine's preferred move." % [best, "was" if best == 1 else "were"]
    elif fine > 0:
        verdict = "None matched its preferred move exactly, but %d were close in its estimate." % fine
    else:
        verdict = "The engine preferred a different move at each turn. Start with one position below."
    var comparison := "Comparisons show immediate changes. The engine score also considers later play."
    if review.get("findings", []).any(func(f: Variant) -> bool: return f is Dictionary and f.has("facts")):
        comparison = "These boards compare the moves. Tint estimates who will keep each point."
    var text := "%s %s\n\nThis compares engine choices, not a beginner pass mark. Move numbers include both players.\n\n%s" % [looked, verdict, comparison]
    var best_moves: Array = tally.get("best_moves", [])
    if not best_moves.is_empty():
        var shown: Array = best_moves.slice(0, 12)
        # A saved review comes back through JSON, where every number is a float.
        var numbers := ", ".join(shown.map(func(n: Variant) -> String: return str(int(n))))
        if best_moves.size() > shown.size():
            numbers += " and %d more" % (best_moves.size() - shown.size())
        text += "\n\nEngine choices you matched: %s." % numbers
    return text
