## The hooks at De Ketel: a ladder derived from the record and stored nowhere.
##
## The interesting assertions are the ones about what it *refuses* to do -- move
## on a loss, move on a win against somebody already below you, and count a game
## as rated. Each of those was broken on purpose and watched to fail.
class_name HooksTests
extends RefCounted


static func _roster() -> Array:
    # The real cast's strengths, written out rather than loaded, so this suite
    # runs with the rest of the project deleted.
    return [
        {"id": "hana", "name": "Hana Oyelaran", "rank_label": "5d", "strength": 34},
        {"id": "joos", "name": "Joos", "rank_label": "?", "strength": 32},
        {"id": "bertie", "name": "Bertie Vale", "rank_label": "4k", "strength": 26},
        {"id": "tomas", "name": "Tomas Beir", "rank_label": "8k", "strength": 22},
        {"id": "kesh", "name": "Kesh Idowu", "rank_label": "12k", "strength": 18},
        {"id": "pip", "name": "Pip Arnesen", "rank_label": "18k", "strength": 12},
        {"id": "wren", "name": "Wren Calloway", "rank_label": "20k", "strength": 10},
    ]


static func _game(npc_id: String, won: bool, unrated: bool = false) -> Dictionary:
    return {"npc_id": npc_id, "player_won": won, "unrated": unrated}


static func _order(records: Array) -> Array[Dictionary]:
    return HooksLadder.order(records, _roster(), "Ro", "22k", true)


static func _ids(rows: Array[Dictionary]) -> Array:
    var out: Array = []
    for r in rows:
        out.append(str(r["id"]))
    return out


static func run(t: TestKit) -> void:
    _test_initial_order(t)
    _test_climbing(t)
    _test_refusals(t)
    _test_unrated_counts(t)
    _test_a_cup_round_moves_a_hook(t)
    _test_summary(t)
    _test_roster_loads(t)


static func _test_initial_order(t: TestKit) -> void:
    t.section("hooks: the row as it hangs")
    var cold := HooksLadder.order([], _roster(), "Ro", "22k", false)
    t.eq(cold.size(), 7, "unranked, there are seven cards and none of them is yours")
    t.eq(HooksLadder.position(cold), 0, "no card is position zero, not last")
    t.eq(_ids(cold), ["hana", "joos", "bertie", "tomas", "kesh", "pip", "wren"],
        "the cards start in rank order")

    var rows := _order([])
    t.eq(rows.size(), 8, "a ranked player has a card")
    t.eq(HooksLadder.position(rows), 8, "and it goes on the bottom hook")
    t.eq(HooksLadder.taken(rows), 0, "having taken nothing")
    # A 22 kyu is weaker than everybody on the wall, so the bottom hook is also
    # where rank order would put them -- which is exactly why the next test
    # matters: it has to stay the bottom hook when rank order disagrees.
    var strong := HooksLadder.order([], _roster(), "Ro", "1d", true)
    t.eq(HooksLadder.position(strong), 8,
        "a 1 dan's new card still goes on the bottom hook; the room does not care what it says")


static func _test_climbing(t: TestKit) -> void:
    t.section("hooks: taking a hook")
    var one := _order([_game("wren", true)])
    t.eq(HooksLadder.position(one), 7, "beating the man above you takes his hook")
    t.eq(_ids(one)[6], "player", "and you are standing where he was")
    t.eq(_ids(one)[7], "wren", "and he is underneath you")
    t.eq(HooksLadder.taken(one), 1, "one card taken")

    # Straight to the top of the wall from the bottom of it. A ladder lets you
    # challenge as far up as you like; that is what makes it a ladder and not a
    # rating.
    var leap := _order([_game("hana", true)])
    t.eq(HooksLadder.position(leap), 1, "beat the top card and you take the top hook")
    t.eq(_ids(leap), ["player", "hana", "joos", "bertie", "tomas", "kesh", "pip", "wren"],
        "everybody you passed moves down exactly one")

    var climb := _order([_game("wren", true), _game("pip", true), _game("kesh", true)])
    t.eq(HooksLadder.position(climb), 5, "three challenges up the wall, three hooks")
    t.eq(HooksLadder.taken(climb), 3, "three cards taken")

    var next: Dictionary = HooksLadder.next_up(climb)
    t.eq(str(next.get("id", "")), "tomas", "next_up names who to beat next")
    t.eq(str(HooksLadder.next_up(leap).get("id", "")), "",
        "and nobody, once you are on the top hook")


static func _test_refusals(t: TestKit) -> void:
    t.section("hooks: what does not move a card")
    t.eq(HooksLadder.position(_order([_game("hana", false)])), 8,
        "losing costs you nothing -- a ladder you can fall down is a ladder nobody climbs")
    t.eq(HooksLadder.position(_order([_game("wren", true), _game("wren", true)])), 7,
        "beating somebody already below you moves nothing")
    t.eq(HooksLadder.taken(_order([_game("wren", true), _game("wren", true)])), 1,
        "and does not count twice")
    t.eq(HooksLadder.position(_order([_game("ilse", true), _game("orla", true)])), 8,
        "the Instituut is not on this wall, so beating it moves nothing here")
    t.eq(HooksLadder.position(_order([_game("", true)])), 8,
        "a game against nobody is not a game")
    # Order is history, not a total: the same three wins in the other order still
    # end at the same hook, but only because each of them was a climb when it
    # happened. Beating Wren *after* passing her is the case above.
    t.eq(HooksLadder.position(_order([_game("kesh", true), _game("pip", true), _game("wren", true)])), 5,
        "beating three people below you after the first climb leaves you where the first climb put you")


static func _test_unrated_counts(t: TestKit) -> void:
    t.section("hooks: the arches count")
    # The whole reason this module exists rather than being a second LeagueTable
    # roster. Joos's games are unrated and the league never sees them.
    var arches := _order([_game("joos", true, true)])
    t.eq(HooksLadder.position(arches), 2,
        "an unrated win under the arches moves your card, because the hooks do not know what rated means")
    var bench := _order([_game("bertie", true, true), _game("pip", true, true)])
    t.eq(HooksLadder.position(bench), 3, "and so does the bench in the park")
    t.eq(HooksLadder.taken(bench), 1,
        "beating Pip afterwards takes nothing; he was already below you")


## The deliberate asymmetry with LeagueTable, asserted so that nobody "fixes" it
## later by symmetry. The league had to learn to ignore a Cup round, because a
## tournament at the Bondszaal is not a fixture in the Instituut's term. The
## hooks must not learn the same lesson: the docstring on HooksLadder says they
## count everything that happened at a table -- "a league fixture, an exam round,
## it makes no difference to a hook" -- and a Cup round is a game of Go that
## Tomas lost, which is the only fact a brass hook has ever been interested in.
static func _test_a_cup_round_moves_a_hook(t: TestKit) -> void:
    t.section("hooks: a tournament game is still a game")
    var cup := [{"npc_id": "tomas", "player_won": true, "unrated": false,
                 "context_id": CupDraw.context_for(0)}]
    var rows := _order(cup)
    var mine := HooksLadder.position(rows)
    var theirs := 0
    for i in rows.size():
        if str(rows[i]["id"]) == "tomas":
            theirs = i + 1
    t.ok(mine < theirs, "beating Tomas in the Cup takes his hook")
    t.eq(HooksLadder.taken(rows), 1, "and counts as a card taken")

    # The league's exclusion and the hooks' inclusion are the same two facts read
    # by two systems that are supposed to disagree.
    var plain := _order([_game("tomas", true)])
    t.eq(HooksLadder.position(plain), mine,
        "the hook does not care whether it was a Tuesday or a tournament")


static func _test_summary(t: TestKit) -> void:
    t.section("hooks: what the wall says")
    var none := HooksLadder.order([], _roster(), "Ro", "22k", false)
    t.ok(HooksLadder.summary(none).contains("no card"),
        "with no card, the wall says so rather than calling you eighth")
    t.ok(HooksLadder.summary(_order([])).contains("Wren Calloway"),
        "otherwise it names the person on the hook above yours")
    t.ok(HooksLadder.summary(_order([_game("hana", true)])).contains("top hook"),
        "and says so when there is nobody above you")


static func _test_roster_loads(t: TestKit) -> void:
    t.section("hooks: the cast behind the cards")
    var rows := HooksLadder.roster_rows()
    t.eq(rows.size(), HooksLadder.ROSTER.size(), "every name on the roster has an NpcData")
    for row in rows:
        t.ok(int(row["strength"]) >= 0,
            "%s has a real strength behind the card" % str(row["id"]))
    # Joos's card is blank and his strength is not. If rank_label were trusted
    # here he would sort to the bottom of the wall, which is the opposite of the
    # truth and the one place a withheld label could quietly lie.
    for row in rows:
        if str(row["id"]) == "joos":
            t.eq(str(row["rank_label"]), "?", "Joos's card is still blank")
            t.ok(int(row["strength"]) > GoRank.from_string("1k"),
                "and the strength behind it is a dan one")
