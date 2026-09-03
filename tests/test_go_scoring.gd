## Empty regions, territory, Japanese and Chinese scoring, dead-stone estimates.
class_name GoScoringTests
extends RefCounted

const NO_CAPTURES := {GoBoard.BLACK: 0, GoBoard.WHITE: 0}


static func run(t: TestKit) -> void:
    _test_regions(t)
    _test_territory(t)
    _test_japanese(t)
    _test_chinese(t)
    _test_prisoners_and_komi(t)
    _test_dead_estimate(t)


static func _test_regions(t: TestKit) -> void:
    t.section("empty regions")
    var b := GoBoard.from_ascii("""
        .X.O.
        .X.O.
        .X.O.
        .X.O.
        .X.O.
    """)
    var regions := GoScoring.empty_regions(b)
    t.eq(regions.size(), 3, "three empty regions: left, middle, right")
    var sizes := []
    for r in regions:
        sizes.append(r["points"].size())
    sizes.sort()
    t.eq(sizes, [5, 5, 5], "each column is five points")

    var open_board := GoBoard.new(9)
    var open_regions := GoScoring.empty_regions(open_board)
    t.eq(open_regions.size(), 1, "an empty board is one region")
    t.eq(open_regions[0]["borders"].size(), 0, "bordered by nothing")


static func _test_territory(t: TestKit) -> void:
    t.section("territory map")
    var b := GoBoard.from_ascii("""
        .X.O.
        .X.O.
        .X.O.
        .X.O.
        .X.O.
    """)
    var terr := GoScoring.territory_map(b)
    t.eq(terr[b.idx(0, 0)], GoBoard.BLACK, "the left column is black's")
    t.eq(terr[b.idx(4, 0)], GoBoard.WHITE, "the right column is white's")
    t.eq(terr[b.idx(2, 0)], GoBoard.EMPTY, "the middle column is neutral (dame)")


static func _test_japanese(t: TestKit) -> void:
    t.section("japanese scoring")
    var b := GoBoard.from_ascii("""
        .X.O.
        .X.O.
        .X.O.
        .X.O.
        .X.O.
    """)
    var s := GoScoring.score(b, {}, NO_CAPTURES, 0.5, GoScoring.Rule.JAPANESE)
    t.eq(s["black"], 5.0, "black has five points of territory")
    t.eq(s["white"], 5.5, "white has five plus komi")
    t.eq(s["winner"], GoBoard.WHITE, "white wins")
    t.eq(s["margin"], 0.5, "by half a point")
    t.eq(s["text"], "White wins by 0.5", "readable result")
    t.eq(s["detail"]["black_territory"], 5, "detail carries the territory count")


static func _test_chinese(t: TestKit) -> void:
    t.section("chinese scoring")
    var b := GoBoard.from_ascii("""
        .X.O.
        .X.O.
        .X.O.
        .X.O.
        .X.O.
    """)
    var s := GoScoring.score(b, {}, NO_CAPTURES, 0.5, GoScoring.Rule.CHINESE)
    t.eq(s["black"], 10.0, "area counts stones as well as territory")
    t.eq(s["white"], 10.5, "and komi for white")
    t.eq(s["rule"], "chinese", "rule is reported")


static func _test_prisoners_and_komi(t: TestKit) -> void:
    t.section("prisoners and komi")
    var b := GoBoard.from_ascii("""
        .X.O.
        .X.O.
        .X.O.
        .X.O.
        .X.O.
    """)
    var s := GoScoring.score(b, {}, {GoBoard.BLACK: 4, GoBoard.WHITE: 0}, 0.5, GoScoring.Rule.JAPANESE)
    t.eq(s["black"], 9.0, "four prisoners are worth four points")
    t.eq(s["winner"], GoBoard.BLACK, "which flips the result")

    var big_komi := GoScoring.score(b, {}, NO_CAPTURES, 20.5, GoScoring.Rule.JAPANESE)
    t.eq(big_komi["white"], 25.5, "komi is configurable")

    var jigo := GoScoring.score(b, {}, NO_CAPTURES, 0.0, GoScoring.Rule.JAPANESE)
    t.eq(jigo["winner"], GoBoard.EMPTY, "an integer komi allows a draw")
    t.eq(jigo["text"], "Draw (jigo)", "and says so")


static func _test_dead_estimate(t: TestKit) -> void:
    t.section("dead stone estimate")
    # A lone white stone inside a black box is dead.
    var b := GoBoard.from_ascii("""
        XXXXX
        X...X
        X.O.X
        X...X
        XXXXX
    """)
    var dead := GoScoring.estimate_dead(b)
    t.ok(dead.has(b.idx(2, 2)), "the surrounded white stone is judged dead")
    t.ok(not dead.has(b.idx(0, 0)), "the surrounding black wall is not")

    var scored := GoScoring.score(b, dead, NO_CAPTURES, 0.5, GoScoring.Rule.JAPANESE)
    t.eq(scored["black"], 10.0, "black gets nine points of territory plus one prisoner")
    t.eq(scored["winner"], GoBoard.BLACK, "black wins the box")

    # A group with two clear eyes is alive even when surrounded.
    var alive := GoBoard.from_ascii("""
        OOOOOOO
        OXXXXXO
        OX.X.XO
        OXXXXXO
        OOOOOOO
        .......
        .......
    """)
    var dead2 := GoScoring.estimate_dead(alive)
    t.ok(not dead2.has(alive.idx(1, 1)), "a two-eyed group is never marked dead")

    # Nothing is dead on an empty board.
    t.eq(GoScoring.estimate_dead(GoBoard.new(9)).size(), 0, "no stones, nothing dead")
