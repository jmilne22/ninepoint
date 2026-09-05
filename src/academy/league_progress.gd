## The stateful seam shared by registration, requests, the wall and the exam.
## LeagueAttempt owns the pure competition rules.
class_name LeagueProgress
extends RefCounted


static func active(state: Node) -> Dictionary:
    var index := int(state.active_league)
    return state.league_attempts[index] if index >= 0 and index < state.league_attempts.size() else {}


static func roster(state: Node, division: String) -> Array:
    var out: Array = []
    var ids: Array = LeagueAttempt.NOVICES if division == LeagueAttempt.NOVICE else LeagueAttempt.ACADEMICS
    for id in ids:
        var data := load("res://data/npcs/%s.tres" % id) as NpcData
        out.append({"id": id, "name": data.display_name, "rank_label": data.rank_label})
    out.append({"id": LeagueTable.PLAYER_ID, "name": state.player_name, "rank_label": state.rank_label()})
    return out


static func can_start(state: Node, division: String) -> bool:
    if not state.is_ranked() or (state.has_flag("exam_started") and not state.has_flag("exam_finished")):
        return false
    var current := active(state)
    if division == LeagueAttempt.NOVICE:
        # An old save can take the new route without losing its unfinished league.
        if bool(current.get("legacy", false)):
            return true
        return current.is_empty() or (LeagueAttempt.complete(current) and str(current["division"]) == division)
    return state.has_flag("cup_finished") and (current.is_empty() or LeagueAttempt.complete(current))


static func start(state: Node, division: String) -> bool:
    if not [LeagueAttempt.NOVICE, LeagueAttempt.ACADEMY].has(division) or not can_start(state, division):
        return false
    var number := 1
    for i in state.league_attempts.size():
        var old: Dictionary = state.league_attempts[i]
        if str(old["division"]) != division:
            continue
        if not LeagueAttempt.complete(old):
            state.active_league = i
            state.set_flag("league_changed", int(state.get_flag("league_changed", 0)) + 1)
            return true
        number = maxi(number, int(old["number"]) + 1)
    state.league_attempts.append(LeagueAttempt.create(division, number, roster(state, division)))
    state.active_league = state.league_attempts.size() - 1
    state.set_flag("league_changed", int(state.get_flag("league_changed", 0)) + 1)
    return true


static func next_name(state: Node) -> String:
    var attempt := active(state)
    var id := LeagueAttempt.opponent(LeagueAttempt.next_fixture(attempt))
    for entry in attempt.get("roster", []):
        if str(entry["id"]) == id:
            return str(entry["name"])
    return ""


static func prepare(state: Node, request: MatchRequest) -> bool:
    var attempt := active(state)
    var fixture := LeagueAttempt.fixture_for(attempt, request.npc_id)
    if fixture.is_empty():
        return false
    request.league_division = str(attempt["division"])
    request.league_attempt = int(attempt["number"])
    request.league_fixture = int(fixture["id"])
    return true


static func record(state: Node, index: int) -> void:
    var attempt := active(state)
    if not LeagueAttempt.commit(attempt, state.match_records, index):
        return
    state.set_flag("played_a_league_game", true)
    if str(attempt["division"]) == LeagueAttempt.NOVICE:
        state.set_flag("played_a_novice_game", true)
        if LeagueAttempt.complete(attempt):
            state.set_flag("novice_league_completed", true)
    state.set_flag("league_changed", int(state.get_flag("league_changed", 0)) + 1)


static func academy(state: Node) -> Dictionary:
    # The latest Academy attempt, not a novice standing with coincidentally the
    # same placing. Entry can never be earned from unfinished new standings.
    for i in range(state.league_attempts.size() - 1, -1, -1):
        var attempt: Dictionary = state.league_attempts[i]
        if str(attempt["division"]) == LeagueAttempt.ACADEMY:
            return attempt
    return {}


static func qualifiers(state: Node) -> Array[Dictionary]:
    var attempt := academy(state)
    if attempt.is_empty() or (not bool(attempt.get("legacy", false)) and not LeagueAttempt.complete(attempt)):
        return []
    return LeagueTable.qualifiers(LeagueAttempt.rows(attempt, state.match_records), Exam.FIELD_SIZE, Exam.EXCLUDED)


static func exam_eligible(state: Node) -> bool:
    for row in qualifiers(state):
        if bool(row["is_player"]):
            return true
    return false


static func restore_legacy(state: Node, data: Dictionary) -> void:
    if not data.has("league_attempts"):
        var had_league: bool = state.has_flag("enrolled")
        for record in state.match_records:
            had_league = had_league or str(record.get("context_id", "")).begins_with("league_")
        if had_league:
            state.league_attempts.append(LeagueAttempt.import_legacy(roster(state, LeagueAttempt.ACADEMY), state.match_records))
            state.active_league = 0
    if state.has_flag("cup_entered") and not state.flags.has("cup_colour_rule"):
        state.flags["cup_colour_rule"] = "nigiri" if str(state.get_flag("cup_section", "beginners")) == "beginners" else "by_rank"


static func summary(state: Node, attempt: Dictionary) -> String:
    if attempt.is_empty():
        return "Register with Marguerite for the Novice League."
    var total: int = attempt["roster"].size() - 1
    if attempt != active(state):
        return "Saved attempt: %d/%d fixtures played.\nPlayer results and simulated NPC games are retained." % [LeagueAttempt.played(attempt), total]
    if bool(attempt.get("legacy", false)):
        return "Legacy Academy: %d/%d fixtures. Ask Marguerite about the exam or novice enrolment.\nFirst fixtures and simulated NPC results retained." % [LeagueAttempt.played(attempt), total]
    if not LeagueAttempt.complete(attempt):
        return "%d/%d fixtures played. Next: %s.\nTies: entry rank, then name. NPC results are simulated." % [
            LeagueAttempt.played(attempt), total, _name_in(attempt, LeagueAttempt.opponent(LeagueAttempt.next_fixture(attempt)))]
    if str(attempt["division"]) == LeagueAttempt.NOVICE:
        return "%d/%d fixtures played. Ask Marguerite about the Cup or another attempt.\nTies: entry rank, then name. NPC results are simulated." % [total, total]
    return "6/6 played. %s Ask Marguerite about entry or another attempt.\nTies: entry rank, then name. NPC games are simulated." % [
        "You may enter the exam." if exam_eligible(state) else "You did not make the exam cut."]


static func _name_in(attempt: Dictionary, id: String) -> String:
    for entry in attempt.get("roster", []):
        if str(entry["id"]) == id:
            return str(entry["name"])
    return id
