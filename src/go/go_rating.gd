## A rank derived from results, and from nothing else.
##
## Pillar 1 forbids the player character a statistic, and Rule 5 forbids a hidden
## score. Both are satisfied by never *storing* a rating: this is a pure function
## of the games actually played, recomputed from the record every time. Delete the
## save file and the rank is gone with the games that earned it, which is correct.
##
## The arithmetic is the conventional performance rating -- the strength you have
## been playing at lately -- expressed on the GoRank scale where one point is one
## stone. Handicap is folded in, because taking five stones from a 1 dan and
## winning makes you a 6 kyu, not a 1 dan, and Go has always counted it that way.
class_name GoRating
extends RefCounted

## Rated games needed before a performance figure means anything. Below this the
## caller keeps whatever provisional rank it was given -- at the club Kesh hands
## out 22k after one game, and one game is not evidence.
const PROVISIONAL_GAMES := 3

## How many recent rated games count. A rank is how you are playing now, not a
## monument to a good week last month.
const WINDOW := 10

## Strength points between playing everybody off the board and losing to all of
## them. Half of it either side of the average opponent, so a 50% score against a
## field is that field's strength -- which is what a rank is.
const SPREAD := 8.0


## The player's strength from their match record, or -1 when there is not yet
## enough evidence to say. `records` is GameState.match_records; unrated games and
## games against anybody whose strength was not recorded are skipped, which is why
## the park and the arches never move your rank.
static func performance(records: Array, window: int = WINDOW) -> int:
    var counted := _recent_rated(records, window)
    if counted.size() < PROVISIONAL_GAMES:
        return -1

    var total_opponent := 0.0
    var wins := 0.0
    for r in counted:
        total_opponent += _effective_strength(r)
        if bool(r.get("player_won", false)):
            wins += 1.0

    var average_opponent := total_opponent / float(counted.size())
    var score := wins / float(counted.size())
    var perf := average_opponent + (score - 0.5) * SPREAD
    return clampi(int(roundf(perf)), 0, GoRank.MAX_STRENGTH)


## The most recent `window` rated games that carry an opponent strength, oldest
## first. Records are appended in play order, so this is the tail of the array.
static func _recent_rated(records: Array, window: int) -> Array:
    var usable: Array = []
    for r in records:
        if not (r is Dictionary):
            continue
        if bool(r.get("unrated", false)):
            continue
        if int(r.get("opponent_strength", -1)) < 0:
            continue
        usable.append(r)
    if usable.size() > window:
        usable = usable.slice(usable.size() - window)
    return usable


## What the opponent was worth *in that game*. Stones given away make an opponent
## easier by exactly their number -- that is what a handicap is for -- and stones
## taken make them harder by the same arithmetic.
static func _effective_strength(record: Dictionary) -> float:
    var opponent := float(int(record.get("opponent_strength", 0)))
    var total := int(record.get("handicap", 0))
    var mine := int(record.get("handicap_taken", 0))
    return opponent - float(mine) + float(total - mine)


## The one sentence Marguerite uses at the desk, so the game never has to explain
## a number the player cannot check.
static func explain(records: Array, window: int = WINDOW) -> String:
    var counted := _recent_rated(records, window)
    if counted.size() < PROVISIONAL_GAMES:
        return "Not enough rated games yet. %d of %d." % [counted.size(), PROVISIONAL_GAMES]
    var wins := 0
    for r in counted:
        if bool(r.get("player_won", false)):
            wins += 1
    return "%d rated games, %d won. That is %s." % [
        counted.size(), wins, GoRank.to_string_rank(performance(records, window))]
