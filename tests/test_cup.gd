## The Beginner Cup: four rounds paired on score, recomputed from the record
## rather than stored, so a save and a reload is the same tournament.
class_name CupTests
extends RefCounted


static func _field() -> Array:
    return [
        {"id": "player", "name": "Ro", "rank_label": "22k"},
        {"id": "wren", "name": "Wren Calloway", "rank_label": "20k"},
        {"id": "pip", "name": "Pip Arnesen", "rank_label": "18k"},
        {"id": "abel", "name": "Abel Roos", "rank_label": "21k"},
        {"id": "moss", "name": "Moss Lindqvist", "rank_label": "16k"},
        {"id": "dov", "name": "Dov Halevi", "rank_label": "19k"},
    ]


static func _result(round_index: int, won: bool) -> Dictionary:
    return {"context_id": CupDraw.context_for(round_index), "npc_id": "someone",
            "player_won": won, "unrated": false}


static func _all_rounds(won: bool) -> Array:
    var out: Array = []
    for r in CupDraw.ROUNDS:
        out.append(_result(r, won))
    return out


## The open section's field, at the ranks the NpcData carries.
static func _open_field() -> Array:
    return [
        {"id": "player", "name": "Ro", "rank_label": "15k"},
        {"id": "kesh", "name": "Kesh Idowu", "rank_label": "12k"},
        {"id": "ilse", "name": "Ilse Brandt", "rank_label": "9k"},
        {"id": "tomas", "name": "Tomas Beir", "rank_label": "8k"},
        {"id": "sunny", "name": "Sunny Achebe", "rank_label": "6k"},
        {"id": "orla", "name": "Orla Finn", "rank_label": "4k"},
    ]


static func run(t: TestKit) -> void:
    _test_before_it_starts(t)
    _test_progress(t)
    _test_complete(t)
    _test_determinism(t)
    _test_no_rematches(t)
    _test_sections(t)
    _test_open_section_runs(t)


## The two sections, and the fact that which one you are in is a question about
## the save rather than about the code.
static func _test_sections(t: TestKit) -> void:
    t.section("cup: two sections")
    t.eq(CupDraw.SECTIONS.size(), 2, "there are two sections and not three")
    t.eq(CupDraw.board_for(CupDraw.BEGINNERS), 9, "the beginners play nine lines")
    t.eq(CupDraw.board_for(CupDraw.OPEN), 13, "the open section plays thirteen")
    # An unknown section must not silently become a 0x0 board.
    t.eq(CupDraw.board_for("qualifying"), 9, "an unknown section falls back to nine")

    # A save written before there were two sections carries no flag at all, and
    # it is a beginners' entry. So is anything unrecognised.
    t.eq(CupDraw.section_of(""), CupDraw.BEGINNERS,
        "a save from before the open section existed is a beginners' entry")
    t.eq(CupDraw.section_of("qualifying"), CupDraw.BEGINNERS,
        "and so is a section nobody has heard of")
    t.eq(CupDraw.section_of(CupDraw.OPEN), CupDraw.OPEN,
        "but the open section survives the round trip")

    t.ok(not CupDraw.FIELD_BEGINNERS.is_empty(), "the beginners' section has a field")
    t.ok(not CupDraw.FIELD_OPEN.is_empty(), "the open section has a field")
    for npc_id in CupDraw.FIELD_OPEN:
        t.ok(not CupDraw.FIELD_BEGINNERS.has(npc_id),
            "%s is in one section, not both" % npc_id)
    # Joos has no card and no papers, so the federation cannot enter him. This is
    # written down because it is a decision rather than an oversight.
    t.ok(not CupDraw.FIELD_OPEN.has("joos"),
        "Joos cannot be entered: the federation needs a rank written down")

    # The profile the World will ask for at round one, at the section's own board
    # size. A missing one is a push_error in front of the player.
    for section_id in CupDraw.SECTIONS:
        var board: int = CupDraw.board_for(section_id)
        for npc_id in CupDraw.FIELDS[section_id]:
            var path := OpponentProfile.path_for(npc_id, board)
            t.ok(ResourceLoader.exists(path),
                "%s has a profile for the %s section (%s)" % [npc_id, section_id, path])
            var profile: OpponentProfile = load(path)
            t.eq(int(profile.board_size), board,
                "%s's %s profile is actually a %dx%d board" % [npc_id, section_id, board, board])


## The open section is a tournament in its own right, not a relabelled one: the
## same four rounds have to come out of a field of stronger people.
static func _test_open_section_runs(t: TestKit) -> void:
    t.section("cup: the open section runs")
    var swept := CupDraw.run(_open_field(), _all_rounds(true), "player")
    t.ok(bool(swept["complete"]), "four rounds finishes the open section")
    t.eq(CupDraw.placing(swept["rows"], "player"), 1,
        "winning all four wins it, even from the bottom of the field")

    var lost := CupDraw.run(_open_field(), _all_rounds(false), "player")
    t.ok(bool(lost["complete"]), "and losing all four finishes it too")
    t.ok(CupDraw.placing(lost["rows"], "player") > 1, "without winning it")

    # The weakest entrant meeting the strongest in round one would be a bad
    # weekend; McMahon pairing on score is what stops it.
    var first := CupDraw.run(_open_field(), [], "player")
    t.eq(int(first["next_round"]), 0, "the open section starts at round one")
    t.ok(str(first["next_opponent"]) != "", "with somebody to play")

    # A reload is the same tournament, which is the whole reason CupDraw stores
    # nothing -- asserted for the second field as well as the first.
    var records := [_result(0, true), _result(1, false)]
    var a := CupDraw.run(_open_field(), records, "player")
    var b := CupDraw.run(_open_field(), records, "player")
    t.eq(str(a["next_opponent"]), str(b["next_opponent"]),
        "the open draw survives a save and a reload")
    t.eq(str(CupDraw.title_for(CupDraw.OPEN)) != str(CupDraw.title_for(CupDraw.BEGINNERS)),
        true, "and the wall says which section you are looking at")


static func _test_before_it_starts(t: TestKit) -> void:
    t.section("cup: before a stone is played")
    var state := CupDraw.run(_field(), [], "player")
    t.ok(not state["complete"], "the Cup has not happened yet")
    t.eq(int(state["next_round"]), 0, "round one is next")
    t.ok(str(state["next_opponent"]) != "", "and there is somebody to play in it")
    t.ok(str(state["next_opponent"]) != "player", "who is not the player")
    for row in state["rows"]:
        t.eq(int(row["played"]), 0, "%s has played nothing" % row["name"])


static func _test_progress(t: TestKit) -> void:
    t.section("cup: a round at a time")
    # The tournament stops at the first round the player has no result for, so
    # nobody plays ahead of them.
    var one := CupDraw.run(_field(), [_result(0, true)], "player")
    t.eq(int(one["next_round"]), 1, "one game played, round two next")
    t.ok(not one["complete"], "and the Cup is not over")
    var me := _me(one["rows"])
    t.eq(int(me["played"]), 1, "the player has one game")
    t.eq(int(me["won"]), 1, "and won it")

    # Everybody in the draw played that round, not just the player.
    var round_one := 0
    for g in one["games"]:
        if int(g["round"]) == 0:
            round_one += 1
    t.eq(round_one, 3, "six entrants is three games a round")

    # Winning changes who you meet: pairing is on score.
    var won_first := CupDraw.next_opponent(_field(), [_result(0, true)], "player")
    var lost_first := CupDraw.next_opponent(_field(), [_result(0, false)], "player")
    t.ok(won_first != lost_first,
        "winning and losing lead to different second-round opponents")


static func _test_complete(t: TestKit) -> void:
    t.section("cup: the final table")
    var swept := CupDraw.run(_field(), _all_rounds(true), "player")
    t.ok(swept["complete"], "four results is a finished Cup")
    t.eq(int(swept["next_round"]), CupDraw.ROUNDS, "with no round left to play")
    t.eq(CupDraw.placing(swept["rows"], "player"), 1,
        "winning all four wins the Cup from the bottom of the field")

    var lost := CupDraw.run(_field(), _all_rounds(false), "player")
    t.eq(CupDraw.placing(lost["rows"], "player"), swept["rows"].size(),
        "and losing all four finishes last")
    t.eq(int(_me(lost["rows"])["played"]), CupDraw.ROUNDS, "having played every round")

    # Every game has one winner, so the table balances.
    var won := 0
    var lost_total := 0
    for row in swept["rows"]:
        won += int(row["won"])
        lost_total += int(row["lost"])
    t.eq(won, lost_total, "every Cup game was won by somebody and lost by somebody")


static func _test_determinism(t: TestKit) -> void:
    t.section("cup: the draw is pinned")
    var records := _all_rounds(true)
    var a := CupDraw.run(_field(), records, "player")
    var b := CupDraw.run(_field(), records, "player")
    t.eq(a["games"].size(), b["games"].size(), "the same number of games")
    for i in a["games"].size():
        t.eq(str(a["games"][i]["a"]) + str(a["games"][i]["b"]),
            str(b["games"][i]["a"]) + str(b["games"][i]["b"]),
            "and the same pairing each time -- a reload is the same tournament")


static func _test_no_rematches(t: TestKit) -> void:
    t.section("cup: everybody gets a game")
    # Nobody sits a round out. A rematch is allowed as a last resort when the
    # bottom of the table has run out of new opponents, but a bye is not.
    for outcome in [true, false]:
        var state := CupDraw.run(_field(), _all_rounds(outcome), "player")
        for row in state["rows"]:
            t.eq(int(row["played"]), CupDraw.ROUNDS,
                "%s played all four rounds (player %s)" % [
                    row["name"], "won out" if outcome else "lost out"])
        for g in state["games"]:
            t.ok(str(g["a"]) != str(g["b"]), "nobody is drawn against themselves")

    # And in the ordinary case the draw does avoid repeats.
    var swept := CupDraw.run(_field(), _all_rounds(true), "player")
    var seen := {}
    var repeats := 0
    for g in swept["games"]:
        var key: String = (str(g["a"]) + "|" + str(g["b"])) if str(g["a"]) < str(g["b"]) \
            else (str(g["b"]) + "|" + str(g["a"]))
        if seen.has(key):
            repeats += 1
        seen[key] = true
    t.ok(repeats <= 1, "at most one forced rematch in a four-round six-player draw")


static func _me(rows: Array) -> Dictionary:
    for r in rows:
        if bool(r.get("is_player", false)):
            return r
    return {}
