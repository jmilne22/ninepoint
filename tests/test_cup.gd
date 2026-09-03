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


static func run(t: TestKit) -> void:
    _test_before_it_starts(t)
    _test_progress(t)
    _test_complete(t)
    _test_determinism(t)
    _test_no_rematches(t)


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
