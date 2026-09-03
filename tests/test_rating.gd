## Rank derived from the record. The point of these tests is that the number is
## always explicable: a player is the strength of the people they beat.
class_name RatingTests
extends RefCounted


static func _game(opponent_rank: String, won: bool, unrated := false,
        handicap := 0, taken := 0) -> Dictionary:
    return {
        "npc_id": "someone", "player_won": won, "unrated": unrated,
        "opponent_strength": GoRank.from_string(opponent_rank),
        "handicap": handicap, "handicap_taken": taken,
    }


static func _repeat(g: Dictionary, n: int) -> Array:
    var out: Array = []
    for i in n:
        out.append(g.duplicate())
    return out


static func run(t: TestKit) -> void:
    _test_provisional(t)
    _test_even_field(t)
    _test_handicap(t)
    _test_ignores(t)
    _test_window(t)


static func _test_provisional(t: TestKit) -> void:
    t.section("rating: not enough evidence")
    t.eq(GoRating.performance([]), -1, "no games is not a rank")
    t.eq(GoRating.performance(_repeat(_game("12k", true), 1)), -1,
        "one game is not a rank either -- Kesh's provisional 22k has to stand")
    t.eq(GoRating.performance(_repeat(_game("12k", true), GoRating.PROVISIONAL_GAMES)) >= 0,
        true, "enough games and there is something to say")


static func _test_even_field(t: TestKit) -> void:
    t.section("rating: you are the strength of the people you beat")
    # An even score against a field is that field's strength. This is the whole
    # idea, and every other case is this one with an adjustment.
    var even := _repeat(_game("9k", true), 4) + _repeat(_game("9k", false), 4)
    t.eq(GoRating.performance(even), GoRank.from_string("9k"),
        "half against 9 kyu is 9 kyu")

    var winning := _repeat(_game("9k", true), 8)
    t.ok(GoRating.performance(winning) > GoRank.from_string("9k"),
        "beating them all puts you above them")
    var losing := _repeat(_game("9k", false), 8)
    t.ok(GoRating.performance(losing) < GoRank.from_string("9k"),
        "losing them all puts you below them")

    # And the swing is bounded, so one good afternoon is not a promotion to dan.
    t.ok(GoRating.performance(winning) - GoRank.from_string("9k") <= int(GoRating.SPREAD),
        "a clean sweep is worth a few stones, not a rank class")
    t.ok(GoRating.performance(losing) >= 0, "and nobody falls off the bottom of the scale")


static func _test_handicap(t: TestKit) -> void:
    t.section("rating: stones count")
    # Beating a 1 dan on nine stones is not a dan performance. The handicap is
    # exactly the difference, which is what a handicap is for.
    var with_stones := _repeat(_game("1d", true, false, 9, 9), 6)
    t.eq(GoRating.performance(with_stones), GoRank.from_string("1d") - 9 + int(GoRating.SPREAD / 2.0),
        "nine stones from a 1 dan is a 10 kyu game, won every time")

    # The same games without the stones say something much stronger.
    var even := _repeat(_game("1d", true), 6)
    t.ok(GoRating.performance(even) > GoRating.performance(with_stones),
        "the same results on an even board are worth more")

    # Giving stones away cuts the other way.
    var giving := _repeat(_game("20k", true, false, 5, 0), 6)
    t.ok(GoRating.performance(giving) > GoRank.from_string("20k") + int(GoRating.SPREAD / 2.0),
        "beating a 20 kyu who was given five stones is worth more than beating a 20 kyu")


static func _test_ignores(t: TestKit) -> void:
    t.section("rating: what does not count")
    var unrated := _repeat(_game("4k", true, true), 8)
    t.eq(GoRating.performance(unrated), -1,
        "the park and the arches never move your rank")

    # Joos withholds his rank, so his games carry no opponent strength.
    var withheld := _repeat({"player_won": true, "unrated": false,
        "opponent_strength": -1, "handicap": 0, "handicap_taken": 0}, 8)
    t.eq(GoRating.performance(withheld), -1,
        "and neither does a game against somebody who will not say what he is")

    var mixed := _repeat(_game("9k", true), 4) + _repeat(_game("9k", false), 4) + unrated
    t.eq(GoRating.performance(mixed), GoRank.from_string("9k"),
        "unrated games alongside rated ones are simply skipped")


static func _test_window(t: TestKit) -> void:
    t.section("rating: a rank is how you are playing now")
    # A good week last month should not hold up a rank forever.
    var old_wins := _repeat(_game("1d", true), GoRating.WINDOW)
    var recent := _repeat(_game("20k", false), GoRating.WINDOW)
    t.ok(GoRating.performance(old_wins + recent) < GoRating.performance(old_wins),
        "the window forgets, which is what makes the rank a record of now")
    t.eq(GoRating.performance(old_wins + recent), GoRating.performance(recent),
        "a full window of new games replaces the old one entirely")

    t.ok(GoRating.explain([]).contains("Not enough"),
        "and there is a sentence Marguerite can say when it is too early to tell")
    t.ok(GoRating.explain(_repeat(_game("9k", true), 4)).contains("4 rated games"),
        "and one she can say when it is not")
