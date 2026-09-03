## Capture Go, and how the colours get decided.
class_name GoSetupTests
extends RefCounted


static func run(t: TestKit) -> void:
    _test_capture_go(t)
    _test_by_rank(t)
    _test_nigiri(t)
    _test_fixed(t)


static func _test_capture_go(t: TestKit) -> void:
    t.section("capture go")
    # The standard beginner game: first capture wins, no scoring at all.
    var g := GoGame.new(7, 0.5, 0)
    g.capture_goal = 1
    g.set_position(GoBoard.from_ascii("""
        OX.....
        .X.....
        .......
        .......
        .......
        .......
        .......
    """).cells, GoBoard.BLACK)
    t.eq(g.board.liberty_count(0), 1, "the white stone is in atari")
    t.eq(g.state, GoGame.State.PLAYING, "the game starts playing")
    t.ok(g.play_xy(0, 1), "black takes the stone in atari")
    t.eq(g.state, GoGame.State.FINISHED, "one capture ends a first-capture game")
    t.eq(g.result["winner"], GoBoard.BLACK, "and black wins it")
    t.ok(g.result["by_capture"], "flagged as won by capture, not by score")
    t.eq(g.result["text"], "Black wins by capturing a stone", "readable result")
    t.ok(not g.play_xy(4, 4), "no more moves once it is over")

    # Three-stone capture go: one capture is not yet enough.
    var g3 := GoGame.new(7, 0.5, 0)
    g3.capture_goal = 3
    g3.set_position(GoBoard.from_ascii("""
        OX.....
        .X.....
        .......
        .......
        .......
        .......
        .......
    """).cells, GoBoard.BLACK)
    g3.play_xy(0, 1)
    t.eq(g3.state, GoGame.State.PLAYING, "one of three does not end it")
    t.eq(g3.captures[GoBoard.BLACK], 1, "but it is counted")

    # A normal game is untouched by any of this.
    var normal := GoGame.new(9, 5.5, 0)
    normal.set_position(GoBoard.from_ascii("""
        OX.......
        .X.......
        .........
        .........
        .........
        .........
        .........
        .........
        .........
    """).cells, GoBoard.BLACK)
    normal.play_xy(0, 1)
    t.eq(normal.state, GoGame.State.PLAYING, "capturing does not end a normal game")
    t.eq(normal.capture_goal, 0, "and the goal defaults to off")


static func _test_by_rank(t: TestKit) -> void:
    t.section("colours by rank")
    # A wide gap is a handicap game: no nigiri, weaker player takes black.
    var wide := GoMatchSetup.prepare(GoMatchSetup.Rule.BY_RANK,
        GoRank.from_string("22k"), GoRank.from_string("12k"), 9)
    t.ok(wide.is_handicap(), "ten ranks apart is a handicap game")
    t.eq(wide.player_color, GoBoard.BLACK, "the weaker player takes black")
    t.eq(wide.komi, 0.5, "handicap games carry half a point of komi")
    t.ok(not wide.uses_nigiri, "and there is no nigiri")
    t.ok(wide.resolved, "so it is settled before the ceremony")
    t.ok(wide.explanation.contains("handicap"), "the player is told why")

    # The other way round: the stronger human gives the stones.
    var reverse := GoMatchSetup.prepare(GoMatchSetup.Rule.BY_RANK,
        GoRank.from_string("2k"), GoRank.from_string("15k"), 9)
    t.eq(reverse.player_color, GoBoard.WHITE, "the stronger player takes white")
    t.ok(reverse.is_handicap(), "and still gives handicap stones")

    # Close ranks are an even game, decided by nigiri.
    var close := GoMatchSetup.prepare(GoMatchSetup.Rule.BY_RANK,
        GoRank.from_string("12k"), GoRank.from_string("12k"), 9)
    t.ok(not close.is_handicap(), "equal ranks play an even game")
    t.ok(close.uses_nigiri, "so the colours go to nigiri")
    t.ok(not close.resolved, "which has not happened yet")
    t.eq(close.komi, 5.5, "with full komi")

    var one_apart := GoMatchSetup.prepare(GoMatchSetup.Rule.BY_RANK,
        GoRank.from_string("12k"), GoRank.from_string("11k"), 9)
    t.ok(one_apart.uses_nigiri, "one rank apart is still an even game")


static func _test_nigiri(t: TestKit) -> void:
    t.section("nigiri")
    var rng := RandomNumberGenerator.new()

    # A right guess wins the choice of colour.
    var win := GoMatchSetup.prepare(GoMatchSetup.Rule.NIGIRI, 10, 10, 9)
    rng.seed = 1
    var grabbed_odd := false
    for attempt in 200:      # find a seed that grabs an odd number
        rng.seed = attempt
        var probe := RandomNumberGenerator.new()
        probe.seed = attempt
        if probe.randi_range(1, GoMatchSetup.MAX_GRAB) % 2 == 1:
            grabbed_odd = true
            break
    t.ok(grabbed_odd, "a seed grabbing an odd handful exists")
    win.run_nigiri(true, rng, GoBoard.BLACK)
    t.ok(win.grabbed % 2 == 1, "the handful was odd")
    t.ok(win.guessed_right, "guessing odd was right")
    t.eq(win.player_color, GoBoard.BLACK, "so the player took the colour they asked for")
    t.ok(win.resolved, "and the setup is settled")
    t.ok(win.explanation.contains(str(win.grabbed)), "the explanation says how many stones")

    # A right guess can also choose white.
    var chose_white := GoMatchSetup.prepare(GoMatchSetup.Rule.NIGIRI, 10, 10, 9)
    var rng2 := RandomNumberGenerator.new()
    rng2.seed = rng.seed
    chose_white.run_nigiri(true, rng2, GoBoard.WHITE)
    t.eq(chose_white.player_color, GoBoard.WHITE, "the winner of nigiri picks either colour")

    # A wrong guess hands black to the opponent.
    var lose := GoMatchSetup.prepare(GoMatchSetup.Rule.NIGIRI, 10, 10, 9)
    var rng3 := RandomNumberGenerator.new()
    rng3.seed = rng.seed
    lose.run_nigiri(false, rng3, GoBoard.BLACK)
    t.ok(not lose.guessed_right, "guessing even against an odd handful is wrong")
    t.eq(lose.player_color, GoBoard.WHITE, "so the opponent takes black and the first move")
    t.ok(lose.explanation.contains("komi"), "and the player is told what they get instead")

    # Over many grabs both colours come up.
    var blacks := 0
    var whites := 0
    for i in 200:
        var s := GoMatchSetup.prepare(GoMatchSetup.Rule.NIGIRI, 10, 10, 9)
        var r := RandomNumberGenerator.new()
        r.seed = i * 7919
        s.run_nigiri(true, r)
        if s.player_color == GoBoard.BLACK: blacks += 1
        else: whites += 1
    t.ok(blacks > 40 and whites > 40, "nigiri is a real coin flip, not a fixed outcome")

    var setup := GoMatchSetup.prepare(GoMatchSetup.Rule.NIGIRI, 10, 10, 9)
    t.ok(setup.nigiri_prompt("Kesh").contains("Kesh"), "the prompt names the opponent")


static func _test_fixed(t: TestKit) -> void:
    t.section("fixed colours")
    var black := GoMatchSetup.prepare(GoMatchSetup.Rule.PLAYER_BLACK, 10, 30, 9)
    t.eq(black.player_color, GoBoard.BLACK, "a scripted match can pin the colour")
    t.ok(black.resolved and not black.uses_nigiri, "with no ceremony")
    t.eq(black.handicap, 0, "and no handicap, whatever the ranks say")

    var white := GoMatchSetup.prepare(GoMatchSetup.Rule.PLAYER_WHITE, 30, 10, 9)
    t.eq(white.player_color, GoBoard.WHITE, "either way round")
    t.eq(white.opponent_color(), GoBoard.BLACK, "the opponent gets the other one")
