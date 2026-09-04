## How a rank moves: one step at a time, in the direction the result says.
##
## Pillar 1 forbids the player a statistic, and this is not one. It is a record
## of results with a number on it, and the rule fits in one sentence: beat
## somebody at or above your rank and you go up one; lose to somebody at or
## below it and you go down one; anything else changes nothing.
##
## It replaced a rolling performance rating that averaged the opponents'
## strength. From the provisional 22 kyu every opponent in the game was
## stronger, so a 0-3 record *raised* the rank and printed "Rank up". A rule a
## player cannot explain to themselves is a rule they experience as broken.
class_name GoRankLadder
extends RefCounted

## Nobody falls below this. 30 kyu is the scale's zero and nothing in the game
## is that weak.
const FLOOR := 5   # 25k


## What the opponent was worth *in that game*: stones the player took make them
## easier, stones the player gave make them harder, priced at what the board
## says a stone is worth (three ranks on 9x9, two on 13x13, one on 19x19).
static func effective_opponent(record: Dictionary) -> int:
    var opponent := int(record.get("opponent_strength", -1))
    if opponent < 0:
        return -1
    var total := int(record.get("handicap", 0))
    var mine := int(record.get("handicap_taken", 0))
    var per_stone := GoRank.ranks_per_stone(int(record.get("board_size", 9)))
    return opponent + (total - 2 * mine) * per_stone


## The rank after one recorded game. `current` below zero is unranked, and an
## unranked player's games move nothing: the club hands out the first rank.
static func step(current: int, record: Dictionary) -> int:
    if current < 0:
        return current
    if bool(record.get("unrated", false)):
        return current
    var opponent := effective_opponent(record)
    if opponent < 0:
        return current
    var won := bool(record.get("player_won", false))
    if won and opponent >= current:
        return mini(current + 1, GoRank.MAX_STRENGTH)
    if not won and opponent <= current:
        return maxi(current - 1, FLOOR)
    return current


## The rank a record produces from a starting rank, for anyone who wants to
## check the number on the card against the games that earned it.
static func replay(start: int, records: Array) -> int:
    var rank := start
    for r in records:
        if r is Dictionary:
            rank = step(rank, r)
    return rank


## The rule, in the words the league board uses.
static func explain() -> String:
    return "Beat somebody at or above your rank and it goes up one. Lose to somebody at or below it and it goes down one."
