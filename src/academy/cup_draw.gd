## The Steenbeek Beginner Cup: four rounds, paired on score.
##
## Like LeagueTable this stores nothing. The whole crosstable is a function of
## the field and the games the player has actually played -- pairings follow from
## the scores, the scores follow from the results, and the results of games the
## player was not in follow from the two ranks. Ask for it twice and it is the
## same tournament, which is what lets it survive a save and a reload.
##
## McMahon-ish: sort on score, pair down the list, never repeat a pairing. With a
## small field that is what a real four-round weekend looks like.
class_name CupDraw
extends RefCounted

const ROUNDS := 4

## The two sections, and the whole of the difference between them.
##
## Beginners are 15k and weaker on nine lines; open uses thirteen lines.
## Both new sections use rank-based handicap. The entry flag freezes the colour
## policy so an already-entered legacy beginner Cup retains its even games.
const BEGINNERS := "beginners"
const OPEN := "open"
const SECTIONS := [BEGINNERS, OPEN]

## Which board a section is played on. Written once, here: World reads it to
## choose the opponent's profile and nothing else in a round has to know.
const BOARD := {BEGINNERS: 9, OPEN: 13}
const COLOUR_RULE := {BEGINNERS: "by_rank", OPEN: "by_rank"}


static func colour_rule_for(section_id: String) -> String:
    return str(COLOUR_RULE.get(section_id, "by_rank"))

## The beginners' section: fifteen kyu and below. Wren and Pip are the only two
## in the club weak enough to enter; the rest came in off the street, which is
## what a city tournament is for.
const FIELD_BEGINNERS := ["wren", "pip", "abel", "dov", "moss"]

## The open section: no ceiling, so for the first time the Instituut and De Ketel
## register for the same event. The Bondszaal is the federation and therefore
## neutral ground, which is the only place in the city these two halves meet
## across a board with a result form on it.
##
## Joos is not here and cannot be: the federation needs a rank written down and
## he has never had one. Bertie has never registered for anything either. Wren
## and Pip are in the other section, where they belong.
const FIELD_OPEN := ["kesh", "ilse", "tomas", "sunny", "orla"]

const FIELDS := {BEGINNERS: FIELD_BEGINNERS, OPEN: FIELD_OPEN}

## The rank at which the beginners' section closes. Marguerite reads it off the
## card; `cup_outgrown` used to be the end of the conversation and is now a
## redirection, because a player who improves must not be locked out of the only
## ending Act 2 has.
const CEILING := "15k"

## The id of the player's own row, the way LeagueTable.PLAYER_ID is. On the pure module, so a test can reach it: the
## panel is a CanvasLayer that touches autoloads and therefore does not compile
## in a `--script` run at all.
const PLAYER_ID := "player"


## Normalises whatever the save is carrying. A save written before there were two
## sections carries no flag, and that is the beginners' section -- which is also
## what an unrecognised value has to mean, because the alternative is a board
## size of zero.
static func section_of(name: String) -> String:
    return name if SECTIONS.has(name) else BEGINNERS


static func board_for(section_id: String) -> int:
    return int(BOARD.get(section_id, BOARD[BEGINNERS]))


static func title_for(section_id: String) -> String:
    return "STEENBEEK CUP -- OPEN SECTION" if section_id == OPEN \
        else "STEENBEEK BEGINNER CUP -- 15k AND BELOW"

## The context_id a round's game is recorded under, so the player's own results
## can be found again in GameState.match_records.
const CONTEXT_PREFIX := "cup_r"


static func context_for(round_index: int) -> String:
    return "%s%d" % [CONTEXT_PREFIX, round_index + 1]


## Everything about the tournament so far.
## `field` is [{id, name, rank_label}]; `player_records` is GameState.match_records.
## Returns {rows, games, next_round, next_opponent, complete}. `next_round` is the
## round the player has still to play, or ROUNDS when the Cup is over, and
## `next_opponent` is who they meet in it.
static func run(field: Array, player_records: Array, player_id: String) -> Dictionary:
    var by_id := {}
    var rows: Array[Dictionary] = []
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
        rows.append(row)

    var played_pairs := {}
    var games: Array = []
    var next_round := ROUNDS
    var next_opponent := ""
    var complete := true

    for r in ROUNDS:
        var pairings := _pair(rows, played_pairs)
        var player_game := {}
        for p in pairings:
            if str(p["a"]) == player_id or str(p["b"]) == player_id:
                player_game = p
                break
        # The player's own game is evidence, not arithmetic: if it is not in the
        # record then this round has not happened and the tournament stops here.
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
            played_pairs[_key(a, b)] = true
            games.append({"round": r, "a": a, "b": b, "a_won": a_won})

    rows.sort_custom(_compare)
    return {"rows": rows, "games": games, "next_round": next_round,
            "next_opponent": next_opponent, "complete": complete}


## 1 for a win, -1 for a loss, 0 when the round has not been played.
static func _player_outcome(records: Array, round_index: int) -> int:
    var context := context_for(round_index)
    for record in records:
        if not (record is Dictionary):
            continue
        if str(record.get("context_id", "")) == context:
            return 1 if bool(record.get("player_won", false)) else -1
    return 0


## Who the player meets next, or "" when the Cup is over. The draw is settled by
## run(), so there is only one place pairings are decided.
static func next_opponent(field: Array, player_records: Array, player_id: String) -> String:
    return str(run(field, player_records, player_id).get("next_opponent", ""))


## The line the board and Marguerite both use, so they never disagree. The
## section is an argument rather than a second copy of this function, for the
## same reason: two of these would drift.
static func summary(state: Dictionary, section_id: String = BEGINNERS) -> String:
    var rows: Array = state["rows"]
    var place := placing(rows, PLAYER_ID)
    if bool(state["complete"]):
        if place == 1:
            if section_id == OPEN:
                return "Four rounds played. You won the Steenbeek Cup, open section."
            return "Four rounds played. You won the Steenbeek Beginner Cup."
        return "Four rounds played. You finished %d of %d." % [place, rows.size()]
    var round_number: int = int(state["next_round"]) + 1
    var who := str(state["next_opponent"])
    for r in rows:
        if str(r["id"]) == who:
            who = str(r["name"])
            break
    if who == "":
        return "Round %d of %d." % [round_number, ROUNDS]
    return "Round %d of %d. You are drawn against %s.\nSee Marguerite when you are ready." % [
        round_number, ROUNDS, who]


## Where the player finished, 1-based.
static func placing(rows: Array, player_id: String) -> int:
    for i in rows.size():
        if str(rows[i].get("id", "")) == player_id:
            return i + 1
    return rows.size()


## Pairs the field on score, strongest score first, skipping repeats. An odd
## field leaves somebody out, which is a bye and costs them the round.
static func _pair(rows: Array[Dictionary], played_pairs: Dictionary) -> Array:
    var order := rows.duplicate()
    order.sort_custom(_compare)
    var taken := {}
    var out: Array = []
    for i in order.size():
        var a: Dictionary = order[i]
        if taken.has(a["id"]):
            continue
        for j in range(i + 1, order.size()):
            var b: Dictionary = order[j]
            if taken.has(b["id"]):
                continue
            if played_pairs.has(_key(str(a["id"]), str(b["id"]))):
                continue
            taken[a["id"]] = true
            taken[b["id"]] = true
            out.append({"a": str(a["id"]), "b": str(b["id"])})
            break

    # Pairing greedily from the top can strand the bottom of the table: everybody
    # left has already met everybody else left. A tournament you entered must not
    # answer that with a bye, so the leftovers are paired anyway and a rematch is
    # the price. Small weekend events do exactly this, and grumble about it.
    var spare: Array = []
    for row in order:
        if not taken.has(row["id"]):
            spare.append(row)
    for i in range(0, spare.size() - 1, 2):
        out.append({"a": str(spare[i]["id"]), "b": str(spare[i + 1]["id"])})
    return out


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


## Most wins, then fewest losses, then the stronger rank -- ordinary seeding. It
## is tempting to break ties the other way, on the grounds that the weaker player
## did it from further back, but then an untouched draw lists the weakest entrant
## first and the board appears to say they are winning.
static func _compare(a: Dictionary, b: Dictionary) -> bool:
    if a["won"] != b["won"]:
        return a["won"] > b["won"]
    if a["lost"] != b["lost"]:
        return a["lost"] < b["lost"]
    if a["strength"] != b["strength"]:
        return a["strength"] > b["strength"]
    return str(a["name"]) < str(b["name"])
