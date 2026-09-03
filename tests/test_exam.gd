## The qualifying exam: four players, three rounds, a round robin, top two pass.
## Recomputed from the record rather than stored, like the Cup and the league.
class_name ExamTests
extends RefCounted


static func _field() -> Array:
    return [
        {"id": "nadia", "name": "Nadia Ferreira", "rank_label": "2k"},
        {"id": "orla", "name": "Orla Finn", "rank_label": "4k"},
        {"id": "player", "name": "Ro", "rank_label": "8k"},
        {"id": "ilse", "name": "Ilse Brandt", "rank_label": "9k"},
    ]


static func _result(round_index: int, won: bool) -> Dictionary:
    return {"context_id": Exam.context_for(round_index), "npc_id": "someone",
            "player_won": won, "unrated": false}


static func _all_rounds(won: bool) -> Array:
    var out: Array = []
    for r in Exam.ROUNDS:
        out.append(_result(r, won))
    return out


static func _me(rows: Array) -> Dictionary:
    for row in rows:
        if bool(row.get("is_player", false)):
            return row
    return {}


static func run(t: TestKit) -> void:
    _test_before_it_starts(t)
    _test_progress(t)
    _test_round_robin(t)
    _test_pass_mark(t)
    _test_not_entered(t)
    _test_determinism(t)
    _test_short_field(t)
    _test_qualifiers(t)


static func _test_before_it_starts(t: TestKit) -> void:
    t.section("exam: before a stone is played")
    var state := Exam.run(_field(), [], "player")
    t.ok(not state["complete"], "the exam has not happened yet")
    t.ok(not state["passed"], "and nobody has passed it")
    t.eq(int(state["next_round"]), 0, "round one is next")
    t.ok(str(state["next_opponent"]) != "", "there is somebody to play in it")
    t.ok(str(state["next_opponent"]) != "player", "who is not the player")
    for row in state["rows"]:
        t.eq(int(row["played"]), 0, "%s has played nothing" % row["name"])


static func _test_progress(t: TestKit) -> void:
    t.section("exam: a round at a time")
    # The exam stops at the first round the player has no result for, so nobody
    # plays ahead of them.
    var one := Exam.run(_field(), [_result(0, true)], "player")
    t.eq(int(one["next_round"]), 1, "one game played, round two next")
    t.ok(not one["complete"], "and the exam is not over")
    var me := _me(one["rows"])
    t.eq(int(me["played"]), 1, "the player has one game")
    t.eq(int(me["won"]), 1, "and won it")
    # Everybody sat that round, not just the player.
    for row in one["rows"]:
        t.eq(int(row["played"]), 1, "%s also played round one" % row["name"])

    var two := Exam.run(_field(), [_result(0, true), _result(1, false)], "player")
    t.eq(int(two["next_round"]), 2, "two played, round three next")
    var me2 := _me(two["rows"])
    t.eq(int(me2["won"]), 1, "one win")
    t.eq(int(me2["lost"]), 1, "one loss")


static func _test_round_robin(t: TestKit) -> void:
    t.section("exam: everybody meets everybody, once")
    var state := Exam.run(_field(), _all_rounds(true), "player")
    t.ok(bool(state["complete"]), "three rounds is the whole exam")
    var games: Array = state["games"]
    t.eq(games.size(), 6, "four players over three rounds is six games")
    var seen := {}
    for g in games:
        var key: String = str(g["a"]) + "|" + str(g["b"]) if str(g["a"]) < str(g["b"]) \
            else str(g["b"]) + "|" + str(g["a"])
        t.ok(not seen.has(key), "%s is played once" % key)
        seen[key] = true
    t.eq(seen.size(), 6, "which is every pair in the field")
    for row in state["rows"]:
        t.eq(int(row["played"]), 3, "%s played all three" % row["name"])
    # A bye is impossible in a round robin, which is the point of using one.
    for r in Exam.ROUNDS:
        var in_round := 0
        for g in games:
            if int(g["round"]) == r:
                in_round += 1
        t.eq(in_round, 2, "round %d seats everybody" % (r + 1))


static func _test_pass_mark(t: TestKit) -> void:
    t.section("exam: the top two qualify and the others do not")
    var won := Exam.run(_field(), _all_rounds(true), "player")
    t.eq(int(_me(won["rows"])["won"]), 3, "three from three")
    t.eq(Exam.placing(won["rows"], "player"), 1, "which is first")
    t.ok(bool(won["passed"]), "and first passes")

    var lost := Exam.run(_field(), _all_rounds(false), "player")
    t.eq(int(_me(lost["rows"])["won"]), 0, "nought from three")
    t.ok(Exam.placing(lost["rows"], "player") > Exam.PASS_PLACES,
        "which is outside the qualifying places")
    t.ok(not lost["passed"], "and does not pass")

    # Unfinished is never a pass, however well it is going.
    var part := Exam.run(_field(), [_result(0, true)], "player")
    t.ok(not part["passed"], "an exam still being sat has not been passed")


static func _test_not_entered(t: TestKit) -> void:
    t.section("exam: a field the player is not in")
    # Four other people sit it. Nothing stops the simulation, so it runs to the
    # end -- and placing() has nobody to find and returns the bottom of the
    # table. The board must not read that as "you finished fourth of four".
    var others: Array = []
    for entry in _field():
        if str(entry["id"]) != "player":
            others.append(entry)
    others.append({"id": "kesh", "name": "Kesh Idowu", "rank_label": "12k"})
    var state := Exam.run(others, [], "player")
    t.ok(not bool(state["player_in_field"]), "the player is not in the field")
    t.ok(bool(state["complete"]), "and it plays itself out without them")
    t.ok(not bool(state["passed"]), "which is not a pass")
    t.ok(ExamBoard.summary(state).contains("not one of them"),
        "and the list says so rather than inventing a placing")


static func _test_determinism(t: TestKit) -> void:
    t.section("exam: the same exam twice")
    var records := [_result(0, true), _result(1, false)]
    var a := Exam.run(_field(), records, "player")
    var b := Exam.run(_field(), records, "player")
    t.eq(str(a["next_opponent"]), str(b["next_opponent"]),
        "the same opponent is drawn on a reload")
    for i in a["rows"].size():
        t.eq(str(a["rows"][i]["id"]), str(b["rows"][i]["id"]),
            "and the table is in the same order")
        t.eq(int(a["rows"][i]["won"]), int(b["rows"][i]["won"]),
            "with the same results in it")


static func _test_short_field(t: TestKit) -> void:
    t.section("exam: a field of three does not crash")
    # The league can be short of four people who are not staff. Dropping the
    # pairings that cannot be seated is better than refusing to run the exam.
    var three := _field().slice(0, 3)
    var state := Exam.run(three, [], "player")
    t.eq(state["rows"].size(), 3, "three sit it")
    t.ok(not state["complete"], "and it still has rounds in it")


static func _test_qualifiers(t: TestKit) -> void:
    t.section("exam: who is entitled to sit it")
    var rows: Array[Dictionary] = []
    for id in ["nadia", "marguerite", "orla", "player", "ilse", "kesh"]:
        rows.append({"id": id, "name": id, "is_player": id == "player"})
    var picked := LeagueTable.qualifiers(rows, Exam.FIELD_SIZE, Exam.EXCLUDED)
    t.eq(picked.size(), Exam.FIELD_SIZE, "four names come off the board")
    for row in picked:
        t.ok(not Exam.EXCLUDED.has(str(row["id"])),
            "%s is not the registrar" % row["id"])
    t.eq(str(picked[0]["id"]), "nadia", "the top of the table is first")
    # Marguerite sits second on the board and does not sit the exam, so the
    # player in fourth place is still inside the four.
    var ids: Array = []
    for row in picked:
        ids.append(str(row["id"]))
    t.ok(ids.has("player"), "and a player below her is still entered")
