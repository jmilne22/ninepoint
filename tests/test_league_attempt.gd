## Scheduled attempts and migration, including a newcomer who loses every game.
class_name LeagueAttemptTests
extends RefCounted


static func _state() -> Node:
    return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")


static func _result(state: Node, won: bool) -> MatchResult:
    var request := MatchRequest.new()
    request.npc_id = LeagueAttempt.opponent(LeagueAttempt.next_fixture(LeagueProgress.active(state)))
    request.context_id = "league_%s" % request.npc_id
    LeagueProgress.prepare(state, request)
    var result := MatchResult.new()
    result.npc_id = request.npc_id
    result.context_id = request.context_id
    result.league_division = request.league_division
    result.league_attempt = request.league_attempt
    result.league_fixture = request.league_fixture
    result.player_won = won
    result.opponent_strength = (load(OpponentProfile.path_for(request.npc_id)) as OpponentProfile).strength()
    return result


static func run(t: TestKit) -> void:
    var state := _state()
    for division in [LeagueAttempt.NOVICE, LeagueAttempt.ACADEMY]:
        _schedule(t, state, division)
    _journey(t, state)
    _legacy(t, state)
    state.reset()


static func _schedule(t: TestKit, state: Node, division: String) -> void:
    t.section("attempt schedule: %s" % division)
    state.reset()
    state.set_rank("30k")
    state.set_flag("cup_finished", true)
    t.ok(LeagueProgress.start(state, division), "registration succeeds")
    var attempt := LeagueProgress.active(state)
    var entrants: int = attempt["roster"].size()
    t.eq(attempt["fixtures"].size(), entrants * (entrants - 1) / 2, "one fixture per unordered pair")
    var pairs := {}
    var rounds := {}
    for fixture in attempt["fixtures"]:
        var ids := [str(fixture["a"]), str(fixture["b"])]
        ids.sort()
        var pair := ":".join(ids)
        t.ok(not pairs.has(pair), "no repeated pairing: %s" % pair)
        pairs[pair] = true
        var round_index := int(fixture["round"])
        if not rounds.has(round_index):
            rounds[round_index] = []
        for id in ids:
            t.ok(not rounds[round_index].has(id), "each entrant plays at most once in a round")
            rounds[round_index].append(id)
    for row in LeagueAttempt.rows(attempt, state.match_records):
        t.eq(row["played"], 0, "every entrant begins at zero games")
    t.ok(UiKit.text_height(LeagueProgress.summary(state, attempt) + "\nLeft/Right: browse attempts.", 304) <= 66,
        "the unplayed summary and archive controls fit the actual footer")
    if division == LeagueAttempt.ACADEMY:
        t.eq(rounds.size(), 7, "seven Academy rounds accommodate the odd field")
        for ids in rounds.values():
            t.eq(ids.size(), 6, "exactly one bye per Academy round")
        t.ok(LeagueProgress.qualifiers(state).is_empty(), "an unfinished Academy attempt cannot qualify")
    var wrong := MatchRequest.new()
    wrong.npc_id = "not_the_next_opponent"
    t.ok(not LeagueProgress.prepare(state, wrong), "out of order fixtures cannot start")
    while not LeagueAttempt.complete(attempt):
        var result := _result(state, false)
        state.record_match(result)
        var snapshot := JSON.stringify(attempt)
        t.ok(not LeagueAttempt.commit(attempt, state.match_records, state.match_records.size() - 1),
            "the same result cannot settle a fixture twice")
        t.eq(JSON.stringify(attempt), snapshot, "duplicate commit leaves every NPC outcome intact")
        var practice := result.to_dict()
        practice["player_won"] = true
        practice["unrated"] = true
        state.match_records.append(practice)
        t.ok(not LeagueAttempt.commit(attempt, state.match_records, state.match_records.size() - 1),
            "practice cannot replace the loss")
    var wins := 0
    var losses := 0
    for row in LeagueAttempt.rows(attempt, state.match_records):
        t.eq(row["played"], entrants - 1, "every entrant finishes the full round robin")
        wins += int(row["won"])
        losses += int(row["lost"])
        if bool(row["is_player"]):
            t.eq(row["won"], 0, "later practice wins do not replace league losses")
            t.eq(row["rank_label"], "30k", "the entry rank stays frozen")
    t.eq(wins, losses, "each fixture has one winner and one loser")
    t.ok(UiKit.text_height(LeagueProgress.summary(state, attempt) + "\nLeft/Right: browse attempts.", 304) <= 66,
        "the completed summary and archive controls fit the actual footer")
    var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
    var rows_before := LeagueAttempt.rows(attempt, state.match_records)
    state.from_dict(saved)
    t.eq(JSON.stringify(LeagueAttempt.rows(LeagueProgress.active(state), state.match_records)),
        JSON.stringify(rows_before), "reload reproduces the complete table")
    t.ok(LeagueProgress.start(state, division), "even a completely losing attempt permits a retry")
    t.eq(state.league_attempts.size(), 2, "the previous attempt remains archived")
    t.eq(LeagueProgress.active(state)["number"], 2, "a retry has its own identifier")
    for row in LeagueAttempt.rows(LeagueProgress.active(state), state.match_records):
        t.eq(row["played"], 0, "archived games cannot leak into a retry")


static func _journey(t: TestKit, state: Node) -> void:
    t.section("beginner journey with no wins")
    state.reset()
    state.set_rank("30k")
    state.set_flag("enrolled", true)
    t.ok(LeagueProgress.start(state, LeagueAttempt.NOVICE), "30k enrols in novice competition")
    var order: Array = []
    for i in 5:
        var result := _result(state, false)
        order.append(result.npc_id)
        state.record_match(result)
    t.eq(order, LeagueAttempt.NOVICES, "novices are faced in increasing target strength")
    t.ok(state.has_flag("novice_league_completed"), "five losses still earn the Cup invitation")
    t.eq(state.rank_label(), "30k", "five stronger-opponent losses never promote")
    var frozen := LeagueAttempt.rows(LeagueProgress.active(state), state.match_records)
    state.set_rank("15k")
    t.eq(JSON.stringify(LeagueAttempt.rows(LeagueProgress.active(state), state.match_records)), JSON.stringify(frozen),
        "a changed current card cannot change the attempt's entry rank or tie ordering")
    state.set_rank("30k")
    t.ok(not LeagueProgress.can_start(state, LeagueAttempt.ACADEMY), "Academy waits until after the Cup")
    var graph := DialogueGraph.load_graph("res://data/dialogue/marguerite.json")
    t.eq(graph.resolve("cup_desk"), "cup_enter", "the losing beginner can enter the Cup")
    graph.apply(graph.nodes["cup_entered_confirm"].get("actions", []))
    t.eq(state.get_flag("cup_colour_rule"), "by_rank", "new beginner Cups explicitly use handicap")
    state.set_rank("25k")
    t.eq(CupBoard.field()[0]["rank_label"], "30k", "Cup pairings keep the entry rank when the current card changes")
    var cup_records: Array = []
    for round_index in CupDraw.ROUNDS:
        state.set_rank("%dk" % (25 - round_index))
        var draw := CupDraw.run(CupBoard.field(), cup_records, CupDraw.PLAYER_ID)
        var id := str(draw["next_opponent"])
        for fixture in draw["games"]:
            if fixture["a"] == CupDraw.PLAYER_ID or fixture["b"] == CupDraw.PLAYER_ID:
                var opponent := str(fixture["b"]) if fixture["a"] == CupDraw.PLAYER_ID else str(fixture["a"])
                t.eq(opponent, cup_records[int(fixture["round"])]["npc_id"],
                    "a changed card cannot rewrite any earlier Cup pairing")
        cup_records.append({"context_id": CupDraw.context_for(round_index), "npc_id": id, "player_won": round_index % 2 == 0})
    state.set_rank("30k")
    for id in CupDraw.FIELD_BEGINNERS:
        var profile := load(OpponentProfile.path_for(id)) as OpponentProfile
        var request := MatchRequest.new()
        request.profile = profile
        request.player_strength = state.rank_strength
        var setup := GoMatchSetup.prepare(GoMatchSetup.Rule.BY_RANK, request.player_strength, profile.strength(), 9, profile.komi)
        t.ok(setup.handicap > 0, "a 30k receives stones against %s" % id)
        t.eq(setup.player_color, GoBoard.BLACK, "the beginner takes Black")
    state.set_flag("cup_finished", true)
    t.ok(LeagueProgress.start(state, LeagueAttempt.ACADEMY), "finishing the Cup unlocks optional Academy competition")
    while not LeagueAttempt.complete(LeagueProgress.active(state)):
        state.record_match(_result(state, true))
    var qualifying := LeagueProgress.qualifiers(state)
    t.eq(qualifying.size(), 4, "exactly four eligible entrants qualify")
    t.ok(LeagueProgress.exam_eligible(state), "a completed Academy sweep qualifies")
    t.ok(graph.check([["league_position_at_most", 4]]), "dialogue uses the shared eligibility calculation")
    for row in qualifying:
        t.ok(str(row["id"]) != "marguerite", "the registrar is never an examinee")


static func _legacy(t: TestKit, state: Node) -> void:
    t.section("legacy league, Cup, exam and review compatibility")
    state.reset()
    state.set_rank("22k")
    state.set_flag("enrolled", true)
    state.set_flag("cup_entered", true)
    state.set_flag("cup_started", true)
    state.set_flag("exam_started", true)
    state.set_flag("exam_field", ["player", "orla", "nadia", "sunny"])
    state.set_quest("enrolment", 6, true)
    state.give_item("exam_certificate")
    state.match_records = [
        {"npc_id": "kesh", "context_id": "league_kesh", "player_won": false},
        {"npc_id": "kesh", "context_id": "league_kesh", "player_won": true},
        {"npc_id": "ilse", "context_id": "league_ilse", "player_won": true},
        {"npc_id": "wren", "context_id": "cup_r1", "player_won": false}]
    state.match_analysis = {"2": {"availability": "available", "record_index": 2}}
    var roster := LeagueProgress.roster(state, LeagueAttempt.ACADEMY)
    roster.pop_back()
    var before := LeagueTable.standings(state.match_records, roster, "Ro", "22k")
    var data: Dictionary = state.to_dict().duplicate(true)
    data.erase("league_attempts")
    data.erase("active_league")
    state.from_dict(data)
    var attempt := LeagueProgress.active(state)
    t.ok(attempt["legacy"], "old records import as an explicitly legacy Academy attempt")
    t.eq(JSON.stringify(LeagueAttempt.rows(attempt, state.match_records)), JSON.stringify(before),
        "legacy NPC results and first-fixture losses are preserved exactly")
    t.eq(state.match_records, data["match_records"], "migration never reorders or edits player history")
    t.eq(state.match_analysis["2"]["record_index"], 2, "review references retain their stable history indices")
    t.eq(state.rank_label(), "22k", "old rank is never reset to the new provisional rank")
    t.ok(state.quest_done("enrolment"), "completed quests remain complete")
    t.ok(state.has_item("exam_certificate"), "certificates survive")
    t.eq(state.get_flag("exam_field"), data["flags"]["exam_field"], "an active exam keeps its field")
    t.eq(state.get_flag("cup_colour_rule"), "nigiri", "an entered old beginner Cup keeps even games")
    t.ok(not LeagueProgress.start(state, LeagueAttempt.NOVICE), "an active exam cannot be displaced")
    state.set_flag("exam_finished", true)
    t.ok(LeagueProgress.start(state, LeagueAttempt.NOVICE), "legacy players can explicitly enrol in novices")
    t.eq(state.league_attempts.size(), 2, "novice entry preserves unfinished legacy progress")
    t.eq(JSON.stringify(LeagueAttempt.rows(state.league_attempts[0], state.match_records)), JSON.stringify(before),
        "the archived legacy table has not silently reset")
    state.set_flag("cup_finished", true)
    var again: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
    state.from_dict(again)
    t.eq(state.league_attempts.size(), 2, "reload does not import a second legacy attempt")
    t.ok(state.has_flag("cup_finished"), "an existing ending stays complete")
