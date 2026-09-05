## The Institute's internal league, computed from games actually played.
##
## This is the honest version of progression the design pillar demands: your
## position in the table is your results and nothing else. There is no hidden
## score, no experience, and no way to climb except by winning games -- which
## means by the human getting better. The insei leagues in Hikaru no Go work
## exactly this way, which is why the game borrows them.
##
## Pure logic; the board in academy_hall draws whatever this returns.
class_name LeagueTable
extends RefCounted

## One row of the table.
## {id, name, rank_label, strength, played, won, lost, is_player}
const PLAYER_ID := "player"

## The students in the league, in rank order. This lived on LeagueBoard until the
## exam needed the same list. "Who is in the league" must have exactly one
## definition, or the board and the thing that gates on it can disagree about who
## it was you beat. Ranks are still read from each NpcData, never duplicated here.
const ROSTER := ["kesh", "ilse", "sunny", "orla", "nadia", "marguerite"]


## Builds the standings. `records` is GameState.match_records; `roster` is an
## array of {id, name, rank_label} for the students in the league.
static func standings(records: Array, roster: Array, player_name: String,
        player_rank: String) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    var by_id := {}

    for entry in roster:
        var row := {
            "id": str(entry.get("id", "")),
            "name": str(entry.get("name", "?")),
            "rank_label": str(entry.get("rank_label", "?")),
            "strength": GoRank.from_string(str(entry.get("rank_label", ""))),
            "played": 0, "won": 0, "lost": 0, "is_player": false,
        }
        by_id[row["id"]] = row
        rows.append(row)

    var player_row := {
        "id": PLAYER_ID, "name": player_name, "rank_label": player_rank,
        "strength": GoRank.from_string(player_rank),
        "played": 0, "won": 0, "lost": 0, "is_player": true,
    }
    rows.append(player_row)

    # The students play each other, not only you. Without this the table ranked
    # the whole Institute on your afternoon: everybody you had not sat down with
    # stayed on nought games, and one win put a beginner above the registrar.
    _play_out_fixtures(rows)

    # Every league game counts once for each side, and only the first game
    # against each person counts at all.
    #
    # The students play a round robin of five. The player used to have every
    # rated game they had ever played counted, against a sort that leads on
    # wins -- so somebody who played twenty games and won eight finished above a
    # student who went five and nought. Pillar 1 forbids grinding past somebody
    # stronger. Rematches are still how rank moves; they are not how the table
    # moves.
    var counted := {}
    for record in records:
        if bool(record.get("unrated", false)):
            continue
        var opponent_id := str(record.get("npc_id", ""))
        if not by_id.has(opponent_id):
            continue        # a game against somebody outside the league
        # Only a league fixture is a league fixture. The exam and the Cup are
        # played against league members and are not; neither is a rematch with
        # Kesh at De Ketel, which used to appear on the Instituut's board
        # because she is on its roster.
        if not str(record.get("context_id", "")).begins_with("league_"):
            continue
        if counted.has(opponent_id):
            continue
        counted[opponent_id] = true
        var opponent: Dictionary = by_id[opponent_id]
        var player_won := bool(record.get("player_won", false))

        player_row["played"] += 1
        opponent["played"] += 1
        if player_won:
            player_row["won"] += 1
            opponent["lost"] += 1
        else:
            player_row["lost"] += 1
            opponent["won"] += 1

    rows.sort_custom(_compare)
    return rows


## The term's fixture list among the students, played out from their ranks.
##
## Deterministic on purpose: it is a draw pinned to the board in September, not a
## simulation running behind the player's back. The stronger player wins, except
## that close pairings produce upsets -- decided by a hash of the two names, so
## the same two people produce the same result every time the board is drawn.
static func _play_out_fixtures(rows: Array[Dictionary]) -> void:
    for i in rows.size():
        var a: Dictionary = rows[i]
        if bool(a.get("is_player", false)):
            continue
        for j in range(i + 1, rows.size()):
            var b: Dictionary = rows[j]
            if bool(b.get("is_player", false)):
                continue
            var a_won := _fixture_winner_is_first(a, b)
            a["played"] += 1
            b["played"] += 1
            if a_won:
                a["won"] += 1
                b["lost"] += 1
            else:
                b["won"] += 1
                a["lost"] += 1


## True when the first of the pair takes the game. A stone of difference is worth
## roughly a game in eight; past about four stones the stronger player does not
## lose this fixture at all.
static func _fixture_winner_is_first(a: Dictionary, b: Dictionary) -> bool:
    var gap: int = int(a["strength"]) - int(b["strength"])
    var stronger_first := gap >= 0
    var upset_chance := maxf(0.0, 0.5 - absi(gap) * 0.12)
    var roll := _pair_roll(str(a["id"]), str(b["id"]))
    if roll < upset_chance:
        return not stronger_first
    return stronger_first


## A stable number in [0, 1) for an unordered pair, so the fixture reads the same
## whichever way round the table is built.
static func _pair_roll(a: String, b: String) -> float:
    var key := (a + "|" + b) if a < b else (b + "|" + a)
    var h := 2166136261
    for i in key.length():
        h = (h ^ key.unicode_at(i)) * 16777619
        h = h & 0xFFFFFFFF
    return float(h % 10000) / 10000.0


## Most wins first; then fewest losses; then the stronger rank; then by name, so
## the order is stable and a fresh table is not arbitrary.
static func _compare(a: Dictionary, b: Dictionary) -> bool:
    # Nobody who has not played is ranked above somebody who has. Without this a
    # newcomer on nought games outranks a student who turned up and lost twice,
    # on the grounds of having fewer losses -- which is not a standing, it is an
    # absence, and the footer already says so.
    var a_played: bool = int(a["played"]) > 0
    var b_played: bool = int(b["played"]) > 0
    if a_played != b_played:
        return a_played
    if a["won"] != b["won"]:
        return a["won"] > b["won"]
    if a["lost"] != b["lost"]:
        return a["lost"] < b["lost"]
    if a["strength"] != b["strength"]:
        return a["strength"] > b["strength"]
    return str(a["name"]) < str(b["name"])


static func player_position(rows: Array[Dictionary]) -> int:
    for i in rows.size():
        if bool(rows[i].get("is_player", false)):
            return i + 1
    return rows.size()


## Who sits the exam: the top `count` of the table, less anybody running it.
## Pure -- it only reads the rows it is handed. Marguerite is excluded by the
## caller rather than by name here, because she is on the board as a player and
## off it as the registrar, and which one she is depends on who is asking.
static func qualifiers(rows: Array[Dictionary], count: int = 4,
        exclude: Array = []) -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for row in rows:
        if exclude.has(str(row.get("id", ""))):
            continue
        out.append(row)
        if out.size() >= count:
            break
    return out


# Autoloads are not resolvable as plain identifiers in a script compiled ahead of
# the scene tree, which is exactly what a `--script` test run is -- the same
# reason DialogueGraph looks GameState up by path. current_rows() is reached from
# a dialogue condition, so it runs in both worlds.
static var _state_node: Node = null


static func _state() -> Node:
    if _state_node != null and is_instance_valid(_state_node):
        return _state_node
    var loop := Engine.get_main_loop()
    if loop is SceneTree:
        _state_node = (loop as SceneTree).root.get_node_or_null(^"GameState")
    return _state_node


## The standings as they stand right now.
##
## standings() above stays pure and is handed everything it needs. This is the
## one impure convenience, and it exists because the board, the exam and the
## dialogue condition that gates on league position must not each build the
## roster in a slightly different way. LeagueBoard already did exactly this; it
## simply had nobody to share it with.
static func current_rows() -> Array[Dictionary]:
    var roster: Array = []
    for npc_id in ROSTER:
        var path := "res://data/npcs/%s.tres" % npc_id
        if not ResourceLoader.exists(path):
            continue
        var data: NpcData = load(path)
        roster.append({"id": npc_id, "name": data.display_name,
                       "rank_label": data.rank_label})
    var state := _state()
    if state == null:
        return standings([], roster, "", "")
    return standings(state.match_records, roster, state.player_name,
        state.rank_label())


## Where the player is on the board right now, 1-based. This is the number
## Marguerite has been quoting since the day you enrolled.
static func current_position() -> int:
    return player_position(current_rows())


## The line the board and Marguerite both use, so they never disagree.
static func summary(rows: Array[Dictionary]) -> String:
    var pos := player_position(rows)
    var total := rows.size()
    var me := {}
    for r in rows:
        if bool(r.get("is_player", false)):
            me = r
            break
    if int(me.get("played", 0)) == 0:
        return "You are listed %d of %d. Play your first league game in the study hall." % [pos, total]
    return "You are %d of %d: %d played, %d won, %d lost." % [
        pos, total, int(me["played"]), int(me["won"]), int(me["lost"])]
