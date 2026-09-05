## Rank moves one step at a time, and only in the direction the result says.
## The point of these tests is that a player can always explain the number.
class_name RatingTests
extends RefCounted


static func _game(opponent_rank: String, won: bool, unrated := false,
        handicap := 0, taken := 0, board := 9) -> Dictionary:
    return {
        "npc_id": "someone", "player_won": won, "unrated": unrated,
        "opponent_strength": GoRank.from_string(opponent_rank),
        "handicap": handicap, "handicap_taken": taken, "board_size": board,
    }


static func _k(label: String) -> int:
    return GoRank.from_string(label)


static func run(t: TestKit) -> void:
    _test_direction(t)
    _test_who_counts(t)
    _test_handicap(t)
    _test_ignores(t)
    _test_bounds(t)


static func _test_direction(t: TestKit) -> void:
    t.section("ladder: a loss never raises, a win never lowers")
    for opp in ["30k", "27k", "25k", "22k", "15k", "9k", "1d", "5d"]:
        for stones in [0, 2, 5]:
            var win := _game(opp, true, false, stones, stones)
            var loss := _game(opp, false, false, stones, stones)
            t.ok(GoRankLadder.step(_k("22k"), win) >= _k("22k"),
                "a win against %s on %d stones never lowers the rank" % [opp, stones])
            t.ok(GoRankLadder.step(_k("22k"), loss) <= _k("22k"),
                "a loss to %s on %d stones never raises it" % [opp, stones])


static func _test_who_counts(t: TestKit) -> void:
    t.section("ladder: one step, and only against the right people")
    t.eq(GoRankLadder.step(_k("22k"), _game("12k", true)), _k("21k"),
        "beating somebody stronger is one step up")
    t.eq(GoRankLadder.step(_k("22k"), _game("22k", true)), _k("21k"),
        "beating an equal is one step up")
    t.eq(GoRankLadder.step(_k("15k"), _game("22k", true)), _k("15k"),
        "beating somebody weaker moves nothing -- Wren cannot be farmed")
    t.eq(GoRankLadder.step(_k("22k"), _game("12k", false)), _k("22k"),
        "losing to somebody stronger costs nothing")
    t.eq(GoRankLadder.step(_k("12k"), _game("12k", false)), _k("13k"),
        "losing to an equal is one step down")
    t.eq(GoRankLadder.step(_k("12k"), _game("20k", false)), _k("13k"),
        "losing to somebody weaker is one step down")
    # The bug the ladder replaced: three losses from the provisional rank.
    var three := [_game("12k", false), _game("20k", false), _game("16k", false)]
    t.eq(GoRankLadder.replay(_k("22k"), three), _k("22k"),
        "three losses to stronger players from 22 kyu leave you at 22 kyu, not 18")


static func _test_handicap(t: TestKit) -> void:
    t.section("ladder: a stone is worth what the board says")
    # Five stones from a 4 kyu on 9x9 is fifteen ranks: the 4 kyu plays as a 19 kyu.
    t.eq(GoRankLadder.effective_opponent(_game("4k", true, false, 5, 5, 9)), _k("19k"),
        "five stones on 9x9 price a 4 kyu as a 19 kyu")
    t.eq(GoRankLadder.effective_opponent(_game("4k", true, false, 5, 5, 13)), _k("14k"),
        "the same five on 13x13 buy less")
    t.eq(GoRankLadder.step(_k("22k"), _game("4k", true, false, 5, 5, 9)), _k("21k"),
        "a 22 kyu beating a 4 kyu on five stones goes up one, like any win against a stronger player")
    t.eq(GoRankLadder.step(_k("15k"), _game("4k", false, false, 5, 5, 9)), _k("16k"),
        "a 15 kyu losing to a 4 kyu on five stones lost to a 19 kyu, and goes down")
    # Giving stones away runs the other way.
    t.eq(GoRankLadder.effective_opponent(_game("20k", true, false, 2, 0, 9)), _k("14k"),
        "a 20 kyu given two stones on 9x9 is a 14 kyu opponent")


static func _test_ignores(t: TestKit) -> void:
    t.section("ladder: what does not count")
    t.eq(GoRankLadder.step(_k("22k"), _game("4k", true, true)), _k("22k"),
        "the park and the arches never move your rank")
    var withheld := {"player_won": true, "unrated": false, "opponent_strength": -1,
        "handicap": 0, "handicap_taken": 0}
    t.eq(GoRankLadder.step(_k("22k"), withheld), _k("22k"),
        "and neither does a game against somebody who will not say what he is")
    t.eq(GoRankLadder.step(-1, _game("12k", true)), -1,
        "an unranked player's games move nothing; the club hands out the first rank")


static func _test_bounds(t: TestKit) -> void:
    t.section("ladder: the ends of the scale")
    t.eq(GoRankLadder.step(_k("30k"), _game("30k", false)), _k("30k"),
        "an equal loss at 30 kyu never promotes or falls off the ladder")
    t.eq(GoRankLadder.step(_k("30k"), _game("30k", true)), _k("29k"),
        "an equal win advances exactly one step from 30 kyu")
    t.eq(GoRankLadder.effective_opponent(_game("25k", false, false, 2, 2)), -1,
        "a known 25k receiving two stones has valid 31k-equivalent strength")
    t.eq(GoRankLadder.step(_k("29k"), _game("25k", false, false, 2, 2)), _k("30k"),
        "negative adjusted strength still counts as a weaker opponent")
    t.eq(GoRankLadder.step(_k("29k"), _game("?", false, false, 2, 2)), _k("29k"),
        "unknown raw rank remains unknown despite handicap")
    t.eq(GoRankLadder.step(GoRank.MAX_STRENGTH, _game("9d", true)), GoRank.MAX_STRENGTH,
        "and nobody climbs off the top")
