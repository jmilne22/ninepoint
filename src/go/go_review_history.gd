## What this player keeps doing, across games rather than within one.
##
## A single review is about one game and forgets it. That is most of what a
## review is for and it is not all of it: the thing a teacher actually notices
## is the pattern -- that you have ignored atari in five games running, that you
## stopped filling your own territory a fortnight ago. The game already keeps
## the record of *results* in GameState.match_records; this reads the record of
## *play* that MatchBridge now writes beside it.
##
## Pure like the rest of src/go/: handed an array of match records, returns a
## dictionary. It knows nothing about GameState, saves or NPCs.
class_name GoReviewHistory
extends RefCounted

## How many games back to look. Roughly a fortnight of play, and short enough
## that a habit you have actually broken stops being mentioned.
const WINDOW := 8

## Times a kind has to appear before it is a habit rather than a bad afternoon.
const HABIT := 3


## {kinds: {kind: count}, streak: {kind: games running}, worst: String,
##  games: int} over the last `window` games that produced a review.
static func habits(records: Array, window: int = WINDOW) -> Dictionary:
	var recent := _recent(records, window)
	var kinds := {}
	for r in recent:
		var seen: Dictionary = r.get("review_summary", {}).get("kinds", {})
		for kind in seen:
			kinds[kind] = int(kinds.get(kind, 0)) + int(seen[kind])
	var streak := _streaks(recent)
	var worst := ""
	var most := 0
	for kind in kinds:
		if int(kinds[kind]) > most:
			most = int(kinds[kind])
			worst = kind
	return {"kinds": kinds, "streak": streak, "worst": worst,
		"games": recent.size()}


## Games in a row, counting back from the most recent.
##
## A streak has to include the latest game or it is not running: a habit you
## broke last week is not a habit you still have, and telling somebody "that is
## three games running" about something they did not just do is the review
## being wrong out loud. So only kinds in the newest game are candidates, and
## the first game missing one ends it.
static func _streaks(recent: Array) -> Dictionary:
	var out := {}
	if recent.is_empty():
		return out
	var alive := {}
	for kind in recent[recent.size() - 1].get("review_summary", {}).get("kinds", {}):
		alive[kind] = true
	for i in range(recent.size() - 1, -1, -1):
		var seen: Dictionary = recent[i].get("review_summary", {}).get("kinds", {})
		for kind in alive.keys():
			if not bool(alive[kind]):
				continue
			if seen.has(kind):
				out[kind] = int(out.get(kind, 0)) + 1
			else:
				alive[kind] = false
	return out


## True when `kind` has happened often enough, recently enough, to be worth
## naming as a pattern rather than an incident.
static func is_habit(habits_dict: Dictionary, kind: String) -> bool:
	var kinds: Dictionary = habits_dict.get("kinds", {})
	return int(kinds.get(kind, 0)) >= HABIT


## "again" text for a finding, or "" -- what the voice fills {again} with.
static func again_for(habits_dict: Dictionary, kind: String) -> String:
	var streak: Dictionary = habits_dict.get("streak", {})
	var runs := int(streak.get(kind, 0))
	if runs >= 3:
		return "That is %d games running." % runs
	if is_habit(habits_dict, kind):
		return "You have done that before."
	return ""


## The lesson this player most needs, or "" -- their commonest habit's concept.
static func recommend(habits_dict: Dictionary) -> String:
	var worst := str(habits_dict.get("worst", ""))
	if worst == "" or not is_habit(habits_dict, worst):
		return ""
	return str(GoReview.CONCEPT.get(worst, ""))


## The games that actually produced a review, most recent last. A game with no
## summary is one nobody reviewed, and counting it would dilute the streak.
static func _recent(records: Array, window: int) -> Array:
	var out: Array = []
	for r in records:
		if not (r is Dictionary):
			continue
		var summary = r.get("review_summary", {})
		if summary is Dictionary and not summary.get("kinds", {}).is_empty():
			out.append(r)
	if out.size() > window:
		out = out.slice(out.size() - window)
	return out
