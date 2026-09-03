## The Essenveld Instituut's qualifying exam: four players, three rounds, two pass.
##
## Like LeagueTable and CupDraw this stores nothing. The whole crosstable is a
## function of the field and the games the player has actually played -- the
## field follows from the league standings, the results of games the player was
## not in follow from the two ranks, and the player's own results follow from
## match_records. Ask for it twice and it is the same exam, which is what lets it
## survive a save and a reload.
##
## Where the Cup is McMahon, this is a round robin: with four people over three
## rounds everybody meets everybody exactly once, so there is no pairing to
## decide and no bye to avoid. An exam is not a draw. It is the whole field.
class_name Exam
extends RefCounted

const ROUNDS := 3
## Top four of the lower league sit it. Marguerite runs it and is excluded by the
## caller; she is on the board as a player and off it as the registrar.
const FIELD_SIZE := 4
## Top two pass. "An exam most students will not pass" is then literally true.
const PASS_PLACES := 2
## Marguerite runs it, so she does not sit it. She is the only name on the league
## board that is staff, and the exam is the one place that distinction matters.
const EXCLUDED := ["marguerite"]
## The context_id a round's game is recorded under, so the player's own results
## can be found again in GameState.match_records.
const CONTEXT_PREFIX := "exam_r"

## The circle method, written out. Seat 0 is fixed and the other three rotate, so
## every pair of seats meets exactly once across the three rounds. Pinned to the
## field's own order -- which is the league standing -- rather than recomputed,
## because a schedule a player can read off the board beforehand is part of what
## makes it an exam rather than a surprise.
const SCHEDULE := [
    [[0, 1], [2, 3]],
    [[0, 2], [3, 1]],
    [[0, 3], [1, 2]],
]


static func context_for(round_index: int) -> String:
    return "%s%d" % [CONTEXT_PREFIX, round_index + 1]


## Everything about the exam so far.
## `field` is [{id, name, rank_label}] in seating order; `player_records` is
## GameState.match_records. Returns {rows, games, next_round, next_opponent,
## complete, passed}. `next_round` is the round the player has still to play, or
## ROUNDS when the exam is over, and `next_opponent` is who they meet in it.
static func run(field: Array, player_records: Array, player_id: String) -> Dictionary:
    var by_id := {}
    var seats: Array[Dictionary] = []
    for entry in field:
        var row := {
            "id": str(entry.get("id", "")),
            "name": str(entry.get("name", "?")),
            "rank_label": str(entry.get("rank_label", "?")),
            "strength": GoRank.from_string(str(entry.get("rank_label", ""))),
            "played": 0, "won": 0, "lost": 0,
            "is_player": str(entry.get("id", "")) == player_id,
        }
        by_id[row["id"]] = row
        seats.append(row)

    var games: Array = []
    var next_round := ROUNDS
    var next_opponent := ""
    var complete := true

    for r in ROUNDS:
        var pairings := _pairings(seats, r)
        var player_game := {}
        for p in pairings:
            if str(p["a"]) == player_id or str(p["b"]) == player_id:
                player_game = p
                break
        # The player's own game is evidence, not arithmetic: if it is not in the
        # record then this round has not happened and the exam stops here.
        var outcome := _player_outcome(player_records, r)
        if not player_game.is_empty() and outcome == 0:
            next_round = r
            next_opponent = str(player_game["b"]) if str(player_game["a"]) == player_id \
                else str(player_game["a"])
            complete = false
            break
        for p in pairings:
            var a: String = str(p["a"])
            var b: String = str(p["b"])
            var a_won: bool
            if not player_game.is_empty() and a == str(player_game["a"]) and b == str(player_game["b"]):
                var player_won := outcome > 0
                a_won = player_won if a == player_id else not player_won
            else:
                a_won = _fixture_winner_is_first(by_id[a], by_id[b])
            _record(by_id[a], by_id[b], a_won)
            games.append({"round": r, "a": a, "b": b, "a_won": a_won})

    var rows: Array[Dictionary] = seats.duplicate()
    rows.sort_custom(_compare)
    # A field the player is not in runs to the end on its own, because there is
    # no game of theirs to stop it -- so "complete" is true and placing() falls
    # back to the bottom of the table. Without this flag the list cheerfully
    # tells somebody who never sat the exam that they finished fourth of four.
    var in_field: bool = by_id.has(player_id)
    var passed := in_field and complete and placing(rows, player_id) <= PASS_PLACES
    return {"rows": rows, "games": games, "next_round": next_round,
            "next_opponent": next_opponent, "complete": complete,
            "passed": passed, "player_in_field": in_field}


## Round `r`'s games, as seat pairs resolved to ids. A field short of FIELD_SIZE
## simply drops the pairings it cannot seat, which is what happens when the
## league has fewer than four people in it and is better than refusing to run.
static func _pairings(seats: Array[Dictionary], r: int) -> Array:
    var out: Array = []
    for pair in SCHEDULE[r]:
        var i: int = pair[0]
        var j: int = pair[1]
        if i >= seats.size() or j >= seats.size():
            continue
        out.append({"a": str(seats[i]["id"]), "b": str(seats[j]["id"])})
    return out


## 1 for a win, -1 for a loss, 0 when the round has not been played.
static func _player_outcome(records: Array, round_index: int) -> int:
    var context := context_for(round_index)
    for record in records:
        if not (record is Dictionary):
            continue
        if str(record.get("context_id", "")) == context:
            return 1 if bool(record.get("player_won", false)) else -1
    return 0


## Who the player meets next, or "" when the exam is over. The schedule is settled
## by run(), so there is only one place a round is decided.
static func next_opponent(field: Array, player_records: Array, player_id: String) -> String:
    return str(run(field, player_records, player_id).get("next_opponent", ""))


## Where the player finished, 1-based.
static func placing(rows: Array, player_id: String) -> int:
    for i in rows.size():
        if str(rows[i].get("id", "")) == player_id:
            return i + 1
    return rows.size()


static func _record(a: Dictionary, b: Dictionary, a_won: bool) -> void:
    a["played"] += 1
    b["played"] += 1
    if a_won:
        a["won"] += 1
        b["lost"] += 1
    else:
        b["won"] += 1
        a["lost"] += 1


static func _key(a: String, b: String) -> String:
    return (a + "|" + b) if a < b else (b + "|" + a)


## The stronger player takes it, except that close pairings produce upsets --
## pinned to a hash of the two names so a reloaded save plays out identically.
## The same arithmetic as CupDraw and LeagueTable, deliberately: three events in
## one game should not disagree about how likely a two stone upset is.
static func _fixture_winner_is_first(a: Dictionary, b: Dictionary) -> bool:
    var gap: int = int(a["strength"]) - int(b["strength"])
    var stronger_first := gap >= 0
    var upset_chance := maxf(0.0, 0.5 - absi(gap) * 0.12)
    if _pair_roll(str(a["id"]), str(b["id"])) < upset_chance:
        return not stronger_first
    return stronger_first


static func _pair_roll(a: String, b: String) -> float:
    var key := _key(a, b)
    var h := 2166136261
    for i in key.length():
        h = (h ^ key.unicode_at(i)) * 16777619
        h = h & 0xFFFFFFFF
    return float(h % 10000) / 10000.0


## Most wins, then fewest losses, then the stronger rank. Everybody plays the
## same three games, so there is no "has not played" case to special-case the way
## the league table has to.
static func _compare(a: Dictionary, b: Dictionary) -> bool:
    if a["won"] != b["won"]:
        return a["won"] > b["won"]
    if a["lost"] != b["lost"]:
        return a["lost"] < b["lost"]
    if a["strength"] != b["strength"]:
        return a["strength"] > b["strength"]
    return str(a["name"]) < str(b["name"])
