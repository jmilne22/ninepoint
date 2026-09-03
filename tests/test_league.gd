## The Institute league: the player's games, plus the term's fixtures between the
## students, which is what makes it a table rather than a record of your afternoon.
class_name LeagueTests
extends RefCounted


static func _roster() -> Array:
    return [
        {"id": "kesh", "name": "Kesh Idowu", "rank_label": "12k"},
        {"id": "ilse", "name": "Ilse Brandt", "rank_label": "9k"},
        {"id": "orla", "name": "Orla Finn", "rank_label": "4k"},
    ]


static func _game(npc: String, won: bool, unrated := false) -> Dictionary:
    return {"npc_id": npc, "player_won": won, "unrated": unrated,
            "context_id": "league_%s" % npc}


static func run(t: TestKit) -> void:
    _test_empty(t)
    _test_counting(t)
    _test_rematches(t)
    _test_ordering(t)
    _test_ignores(t)
    _test_fixtures(t)


static func _test_empty(t: TestKit) -> void:
    t.section("league: nothing played")
    var rows := LeagueTable.standings([], _roster(), "Ro", "22k")
    t.eq(rows.size(), 4, "the player is a row in the table like anyone else")
    var me := rows[LeagueTable.player_position(rows) - 1]
    t.ok(me["is_player"], "the player row is findable")
    t.eq(int(me["played"]), 0, "the player has played nobody")
    # The students have played their fixtures, so a newcomer on nought wins is
    # below all of them -- which is the correct and slightly bleak answer.
    t.eq(str(rows[rows.size() - 1]["id"]), LeagueTable.PLAYER_ID,
        "an unranked newcomer starts at the bottom without crashing")
    t.ok(LeagueTable.summary(rows).contains("no games played"),
        "and the summary says so rather than implying a ranking")


static func _test_counting(t: TestKit) -> void:
    t.section("league: counting")
    # Two games against Kesh, one against Ilse. Only the first Kesh game counts.
    var records := [_game("kesh", true), _game("kesh", false), _game("ilse", true)]
    var rows := LeagueTable.standings(records, _roster(), "Ro", "22k")
    var by_id := {}
    for r in rows:
        by_id[str(r["id"])] = r

    t.eq(int(by_id["player"]["played"]), 2, "one game against each person counts")
    t.eq(int(by_id["player"]["won"]), 2, "both of them won")
    t.eq(int(by_id["player"]["lost"]), 0, "and the rematch loss is not on the table")
    # A three-student roster is two fixtures each, and the player's games are
    # counted on top of those from the opposite end.
    var bare := LeagueTable.standings([], _roster(), "Ro", "22k")
    var base := {}
    for r in bare:
        base[str(r["id"])] = r
    t.eq(int(by_id["kesh"]["played"]), int(base["kesh"]["played"]) + 1,
        "kesh played the newcomer once on top of her fixtures")
    t.eq(int(by_id["kesh"]["lost"]), int(base["kesh"]["lost"]) + 1, "and lost it")
    t.eq(int(by_id["ilse"]["lost"]), int(base["ilse"]["lost"]) + 1, "ilse lost hers")
    t.eq(int(by_id["orla"]["played"]), int(base["orla"]["played"]),
        "orla has not played the newcomer")


## The table is a league, so it counts a league: one game against each person.
##
## Before the exam gated on league position this went unnoticed, because nothing
## read the position. With every rated game counted and a sort that leads on
## wins, somebody who played twenty games and won eight finished above a student
## who went five and nought -- which is grinding past a stronger player, and
## Pillar 1 forbids it. Rank still moves on every game; the table does not.
static func _test_rematches(t: TestKit) -> void:
    t.section("league: a rematch is not a second fixture")
    var grind: Array = []
    for i in 8:
        grind.append(_game("kesh", true))
    var rows := LeagueTable.standings(grind, _roster(), "Ro", "22k")
    var me := {}
    for r in rows:
        if bool(r["is_player"]):
            me = r
    t.eq(int(me["played"]), 1, "eight games against one person is one fixture")
    t.eq(int(me["won"]), 1, "worth one win")
    t.ok(LeagueTable.player_position(rows) > 1,
        "so grinding one opponent cannot top the table")

    # The exam is played against league members and is not a league game: sitting
    # a round must not rewrite the standings that entitled you to sit it.
    var sat := [{"npc_id": "orla", "player_won": true, "unrated": false,
                 "context_id": Exam.context_for(0)}]
    var after := LeagueTable.standings(sat, _roster(), "Ro", "22k")
    for r in after:
        if bool(r["is_player"]):
            t.eq(int(r["played"]), 0, "an exam round is not a league game")


static func _test_ordering(t: TestKit) -> void:
    t.section("league: ordering")
    # Winning moves the newcomer up, and beating the whole roster tops the table
    # -- but it takes beating the whole roster, not one game.
    var swept := LeagueTable.standings(
        [_game("kesh", true), _game("ilse", true), _game("orla", true)],
        _roster(), "Ro", "22k")
    t.eq(str(swept[0]["id"]), LeagueTable.PLAYER_ID,
        "beating everybody in the league puts you top of it")

    var one_win := LeagueTable.standings([_game("ilse", true)], _roster(), "Ro", "22k")
    t.ok(LeagueTable.player_position(one_win) > 1,
        "but a single win does not, which was the bug: one game topped the table")
    t.ok(LeagueTable.player_position(one_win) < 4,
        "and it is still worth something")

    # Losing is the only way down, and it puts you under everyone.
    var losses := LeagueTable.standings(
        [_game("ilse", false), _game("orla", false)], _roster(), "Ro", "22k")
    t.eq(LeagueTable.player_position(losses), 4, "and losing is the only way down")
    t.ok(LeagueTable.summary(losses).contains("2 lost"), "the summary counts losses")


static func _test_ignores(t: TestKit) -> void:
    t.section("league: what does not count")
    # Park games and other unrated games must not touch the league.
    var rows := LeagueTable.standings([_game("kesh", true, true)], _roster(), "Ro", "22k")
    var by_id := {}
    for r in rows:
        by_id[str(r["id"])] = r
    t.eq(int(by_id["player"]["played"]), 0, "an unrated game is not a league game")

    # Neither do games against somebody outside the league.
    var outside := LeagueTable.standings([_game("bertie", true)], _roster(), "Ro", "22k")
    var found := {}
    for r in outside:
        found[str(r["id"])] = r
    t.eq(int(found["player"]["played"]), 0, "beating somebody in the park does not count")
    t.eq(outside.size(), 4, "and does not add them to the table")


static func _test_fixtures(t: TestKit) -> void:
    t.section("league: the students play each other")
    var rows := LeagueTable.standings([], _roster(), "Ro", "22k")
    var by_id := {}
    for r in rows:
        by_id[str(r["id"])] = r

    # Three students is two fixtures each; the player is in none of them.
    for id in ["kesh", "ilse", "orla"]:
        t.eq(int(by_id[id]["played"]), 2, "%s played both the other students" % id)
        t.eq(int(by_id[id]["won"]) + int(by_id[id]["lost"]), 2,
            "%s's fixtures all have a result" % id)
    t.eq(int(by_id["player"]["played"]), 0, "the player is not in the draw twice")

    # Every fixture has exactly one winner, so wins and losses balance.
    var won := 0
    var lost := 0
    for r in rows:
        won += int(r["won"])
        lost += int(r["lost"])
    t.eq(won, lost, "every game played was won by somebody and lost by somebody")

    # The draw is pinned, not rolled: the same roster gives the same table.
    var again := LeagueTable.standings([], _roster(), "Ro", "22k")
    for i in rows.size():
        t.eq(str(again[i]["id"]), str(rows[i]["id"]),
            "the fixture list is the same every time the board is drawn")

    # The strongest student should be doing well out of a term of fixtures.
    t.eq(int(by_id["orla"]["won"]), 2, "the 4 kyu wins her fixtures against weaker players")
