## A saved round robin. Player outcomes stay in match_records; only NPC outcomes
## live on fixtures. Drawing a table never simulates or changes a result.
class_name LeagueAttempt
extends RefCounted

const NOVICE := "novice"
const ACADEMY := "academy"
const NOVICES := ["noor", "ivo", "lea", "emil", "sora"]
const ACADEMICS := ["kesh", "ilse", "sunny", "orla", "nadia", "marguerite"]


static func create(division: String, number: int, roster: Array) -> Dictionary:
    var seats: Array = [LeagueTable.PLAYER_ID]
    for i in range(roster.size() - 1, -1, -1):
        if str(roster[i]["id"]) != LeagueTable.PLAYER_ID:
            seats.append(str(roster[i]["id"]))
    if seats.size() % 2 != 0:
        seats.append("")
    var fixtures: Array = []
    for round_index in seats.size() - 1:
        for i in int(seats.size() / 2):
            var a := str(seats[i])
            var b := str(seats[seats.size() - 1 - i])
            if a != "" and b != "":
                fixtures.append(_fixture(fixtures.size(), round_index, a, b))
        seats.insert(1, seats.pop_back())
    return {"division": division, "number": number, "roster": roster.duplicate(true),
        "fixtures": fixtures, "legacy": false}


static func _fixture(id: int, round_index: int, a: String, b: String) -> Dictionary:
    return {"id": id, "round": round_index, "a": a, "b": b,
        "record_index": -1, "winner_id": ""}


static func is_player(fixture: Dictionary) -> bool:
    return str(fixture["a"]) == LeagueTable.PLAYER_ID or str(fixture["b"]) == LeagueTable.PLAYER_ID


static func opponent(fixture: Dictionary) -> String:
    if fixture.is_empty():
        return ""
    return str(fixture["b"]) if str(fixture["a"]) == LeagueTable.PLAYER_ID else str(fixture["a"])


static func next_fixture(attempt: Dictionary) -> Dictionary:
    for fixture in attempt.get("fixtures", []):
        if is_player(fixture) and int(fixture["record_index"]) < 0:
            return fixture
    return {}


static func fixture_for(attempt: Dictionary, npc_id: String) -> Dictionary:
    if bool(attempt.get("legacy", false)):
        for fixture in attempt.get("fixtures", []):
            if is_player(fixture) and opponent(fixture) == npc_id and int(fixture["record_index"]) < 0:
                return fixture
        return {}
    var fixture := next_fixture(attempt)
    return fixture if opponent(fixture) == npc_id else {}


static func complete(attempt: Dictionary) -> bool:
    return not attempt.is_empty() and next_fixture(attempt).is_empty()


static func played(attempt: Dictionary) -> int:
    var count := 0
    for fixture in attempt.get("fixtures", []):
        if is_player(fixture) and int(fixture["record_index"]) >= 0:
            count += 1
    return count


static func commit(attempt: Dictionary, records: Array, index: int) -> bool:
    if index < 0 or index >= records.size() or attempt.is_empty():
        return false
    var record: Dictionary = records[index]
    if bool(record.get("unrated", false)) or str(record.get("league_division", "")) != str(attempt["division"]) \
            or int(record.get("league_attempt", -1)) != int(attempt["number"]):
        return false
    var fixture := fixture_for(attempt, str(record.get("npc_id", "")))
    if fixture.is_empty() or int(record.get("league_fixture", -1)) != int(fixture["id"]):
        return false
    fixture["record_index"] = index
    _settle_rounds(attempt)
    return true


static func _settle_rounds(attempt: Dictionary) -> void:
    var next := next_fixture(attempt)
    var limit := int(next.get("round", 10000))
    var by_id := {}
    for entry in attempt["roster"]:
        by_id[str(entry["id"])] = entry
    for fixture in attempt["fixtures"]:
        if is_player(fixture) or str(fixture["winner_id"]) != "" or int(fixture["round"]) >= limit:
            continue
        var a: Dictionary = by_id[fixture["a"]]
        var b: Dictionary = by_id[fixture["b"]]
        # These are simulated handicap games, not engine measurements. Persist
        # the outcome once, using a seed independent of the player's result.
        var sa := GoRank.from_string(str(a["rank_label"]))
        var sb := GoRank.from_string(str(b["rank_label"]))
        var handicap := GoRank.handicap_between(sa, sb, 9)
        var gap := sa - sb
        gap -= signi(gap) * int(handicap["stones"]) * GoRank.ranks_per_stone(9)
        var seed_key := "%s:%s:%s" % [attempt["division"], attempt["number"], fixture["a"]]
        var chance := clampf(0.5 + gap * 0.12, 0.05, 0.95)
        fixture["winner_id"] = fixture["a"] if LeagueTable._pair_roll(seed_key, str(fixture["b"])) < chance else fixture["b"]


static func rows(attempt: Dictionary, records: Array) -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    var by_id := {}
    for entry in attempt.get("roster", []):
        var row: Dictionary = entry.duplicate(true)
        row.merge({"strength": GoRank.from_string(str(row["rank_label"])),
            "played": 0, "won": 0, "lost": 0,
            "is_player": str(row["id"]) == LeagueTable.PLAYER_ID}, true)
        out.append(row)
        by_id[str(row["id"])] = row
    for fixture in attempt.get("fixtures", []):
        var winner := str(fixture["winner_id"])
        if is_player(fixture):
            var index := int(fixture["record_index"])
            if index < 0 or index >= records.size():
                continue
            winner = LeagueTable.PLAYER_ID if bool(records[index].get("player_won", false)) else opponent(fixture)
        if winner == "" or not by_id.has(winner):
            continue
        var loser := str(fixture["b"]) if winner == str(fixture["a"]) else str(fixture["a"])
        by_id[winner]["played"] += 1
        by_id[loser]["played"] += 1
        by_id[winner]["won"] += 1
        by_id[loser]["lost"] += 1
    out.sort_custom(LeagueTable._compare if bool(attempt.get("legacy", false)) else _compare_entry)
    return out


static func _compare_entry(a: Dictionary, b: Dictionary) -> bool:
    if a["won"] != b["won"]:
        return a["won"] > b["won"]
    if a["strength"] != b["strength"]:
        return a["strength"] > b["strength"]
    return str(a["name"]) < str(b["name"])


## Preserve the exact old five-game NPC baseline and first-player-fixture rule.
static func import_legacy(roster: Array, records: Array) -> Dictionary:
    var attempt := {"division": ACADEMY, "number": 1, "roster": roster.duplicate(true),
        "fixtures": [], "legacy": true}
    var fixtures: Array = attempt["fixtures"]
    for i in roster.size():
        var a: Dictionary = roster[i]
        for j in range(i + 1, roster.size()):
            var b: Dictionary = roster[j]
            var fixture := _fixture(fixtures.size(), 0, str(a["id"]), str(b["id"]))
            if is_player(fixture):
                for index in records.size():
                    var record: Dictionary = records[index]
                    if not bool(record.get("unrated", false)) and str(record.get("context_id", "")).begins_with("league_") \
                            and str(record.get("npc_id", "")) == opponent(fixture):
                        fixture["record_index"] = index
                        break
            else:
                var ar := {"id": a["id"], "strength": GoRank.from_string(str(a["rank_label"]))}
                var br := {"id": b["id"], "strength": GoRank.from_string(str(b["rank_label"]))}
                fixture["winner_id"] = a["id"] if LeagueTable._fixture_winner_is_first(ar, br) else b["id"]
            fixtures.append(fixture)
    return attempt
