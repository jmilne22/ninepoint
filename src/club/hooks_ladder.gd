## The brass hooks at the back of De Ketel: the club's own order of precedence,
## in the form of a row of name-cards on hooks.
##
## This is the second half of the argument the city is built on. The Instituut's
## LeagueTable counts rated games, in a round robin, at fixtures pinned to a wall
## in September, and prints a document. The hooks count *everything that happened
## at a table* -- the park, the arches, the back room, a league fixture, an exam
## round, it makes no difference to a hook -- and they are not a document at all.
## Joos has never been near the first and Marguerite has never heard of the
## second, and both of them are telling the truth.
##
## Three rules, and each of them is a design decision rather than an
## implementation detail:
##
## 1. **Only wins move a card, and only upwards.** Beat somebody hanging above
##    you and you take their hook; they and everybody you passed move down one.
##    Losing does nothing, because a ladder where losing costs you something is a
##    ladder nobody challenges up. It cannot be ground, either: the only move is
##    to beat somebody who is currently better placed than you (Pillar 1).
## 2. **Unrated games count.** This is the whole point of the module existing
##    rather than being a second LeagueTable roster -- LeagueTable must go on
##    refusing them (see match_bridge.gd), and Bertie's bench and Joos's crate
##    have been playable and consequence-free since M22.
## 3. **A new card goes on the bottom hook.** Not at your rank: the card says
##    your rank and the hook says where you sit, and the room does not care what
##    the card says until you have beaten somebody in it.
##
## Pure, like LeagueTable.standings() and CupDraw and Exam before it: it is
## handed a record and returns an order, stores nothing, and a save and a reload
## produce the same hooks (Rule 5).
class_name HooksLadder
extends RefCounted

const PLAYER_ID := "player"

## Who has a card here: the salon, the park and the arches. Deliberately not the
## Instituut's roster -- Kesh and Hana are on both because they are the two
## people who cross, which is the same reason they stand in two maps.
const ROSTER := ["hana", "joos", "bertie", "tomas", "kesh", "pip", "wren"]


## The hooks, top first. `roster` is an array of {id, name, rank_label, strength}
## and `records` is GameState.match_records, oldest first -- the order matters,
## because a ladder is a history rather than a total.
static func order(records: Array, roster: Array, player_name: String,
        player_rank: String, ranked: bool) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for entry in roster:
        rows.append({
            "id": str(entry.get("id", "")),
            "name": str(entry.get("name", "?")),
            "rank_label": str(entry.get("rank_label", "?")),
            "strength": int(entry.get("strength", -1)),
            "is_player": false, "taken": false,
        })
    # The hooks start in rank order, because that is how somebody hangs seven
    # cards up on a Tuesday. Everything after that is results.
    rows.sort_custom(_by_strength)

    if not ranked:
        return rows

    var player_row := {
        "id": PLAYER_ID, "name": player_name, "rank_label": player_rank,
        "strength": GoRank.from_string(player_rank),
        "is_player": true, "taken": false,
    }
    rows.append(player_row)

    for record in records:
        if not (record is Dictionary):
            continue
        if not bool(record.get("player_won", false)):
            continue
        var opponent_id := str(record.get("npc_id", ""))
        var mine := _index_of(rows, PLAYER_ID)
        var theirs := _index_of(rows, opponent_id)
        if theirs < 0 or theirs >= mine:
            continue        # not on the hooks, or already below you
        rows[theirs]["taken"] = true
        rows.remove_at(mine)
        rows.insert(theirs, player_row)

    return rows


static func _index_of(rows: Array[Dictionary], id: String) -> int:
    for i in rows.size():
        if str(rows[i]["id"]) == id:
            return i
    return -1


## Stronger first; ties broken by name so a fresh row of hooks is not arbitrary.
static func _by_strength(a: Dictionary, b: Dictionary) -> bool:
    if int(a["strength"]) != int(b["strength"]):
        return int(a["strength"]) > int(b["strength"])
    return str(a["name"]) < str(b["name"])


## Which hook the player's card is on, 1-based. Zero means they have no card,
## which is a different thing from being last and the board says so.
static func position(rows: Array[Dictionary]) -> int:
    for i in rows.size():
        if bool(rows[i].get("is_player", false)):
            return i + 1
    return 0


## How many cards the player has taken. The quest counts these; it is the one
## number that only ever goes up, and only ever because somebody was beaten.
static func taken(rows: Array[Dictionary]) -> int:
    var n := 0
    for row in rows:
        if bool(row.get("taken", false)):
            n += 1
    return n


## Whose card is on the hook directly above the player's -- who to beat next.
## Empty when they have no card, or when there is nothing above them.
static func next_up(rows: Array[Dictionary]) -> Dictionary:
    var place := position(rows)
    if place <= 1:
        return {}
    return rows[place - 2]


## The line the hooks and Tomas both use, so the wall and the man behind the
## counter never disagree about where you are.
static func summary(rows: Array[Dictionary]) -> String:
    var place := position(rows)
    if place == 0:
        return "There is no card with your name on it. Win a rated game and Tomas will write you one."
    if place == 1:
        return "Yours is the top hook. Nobody in this room is above you."
    var above: Dictionary = next_up(rows)
    return "You are %d of %d. %s is on the hook above yours." % [
        place, rows.size(), str(above.get("name", "Somebody"))]


# --- assembling the roster ---------------------------------------------------

## The cards, read off the cast. Joos's rank_label is "?" and always will be, so
## his place is taken from the profile's strength_override -- the real number
## behind the withheld one. He is on the hooks with a blank card, which is
## exactly what a man with no papers and a 3 dan game looks like from the far
## side of the room.
static func roster_rows() -> Array:
    var out: Array = []
    for npc_id in ROSTER:
        var path := "res://data/npcs/%s.tres" % npc_id
        if not ResourceLoader.exists(path):
            continue
        var data: NpcData = load(path)
        var strength := data.strength()
        if strength < 0 and data.opponent_profile != null:
            strength = data.opponent_profile.strength()
        out.append({"id": npc_id, "name": data.display_name,
                    "rank_label": data.rank_label, "strength": strength})
    return out


## The hooks as they stand, for a caller that has GameState to hand.
##
## `state` is passed in rather than looked up. LeagueTable.current_rows() reaches
## for the autoload itself and is the first impure thing in src/academy/ -- its
## own file says so. Injecting it costs the caller one argument and keeps this
## module testable with the rest of the project deleted.
static func rows_for(state) -> Array[Dictionary]:
    if state == null:
        return order([], roster_rows(), "", "", false)
    return order(state.match_records, roster_rows(), state.player_name,
        state.rank_label(), state.is_ranked())
