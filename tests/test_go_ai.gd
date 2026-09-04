## Opponent interface, legality under self-play, and profile-driven behaviour.
class_name GoAiTests
extends RefCounted


static func _profile(engine := "heuristic", seed_value := 4242) -> OpponentProfile:
    var p := OpponentProfile.new()
    p.id = &"test"
    p.engine = engine
    p.board_size = 9
    p.komi = 5.5
    p.mistake_rate = 0.0
    p.reading_depth = 1
    p.rng_seed = seed_value
    return p


## Plays a whole game between two opponents. Returns the finished GoGame.
static func _self_play(a: GoOpponent, b: GoOpponent, game: GoGame, t: TestKit, tag: String) -> GoGame:
    var guard := game.size() * game.size() * 3
    while game.state == GoGame.State.PLAYING and guard > 0:
        guard -= 1
        var who: GoOpponent = a if game.to_move == GoBoard.BLACK else b
        var mv: Dictionary = who.choose_move(game)
        match mv["type"]:
            "pass":
                game.pass_turn()
            "resign":
                game.resign(game.to_move)
            _:
                if not game.play(mv["point"]):
                    t.ok(false, "%s: opponent proposed an illegal move at %d" % [tag, mv["point"]])
                    return game
    t.ok(guard > 0, "%s: the game terminated without hitting the move guard" % tag)
    return game


static func run(t: TestKit) -> void:
    _test_interface(t)
    _test_random_legality(t)
    _test_heuristic_tactics(t)
    _test_selfplay(t)
    _test_profiles(t)
    _test_plausible_mistakes(t)
    _test_reading_depth(t)
    _test_styles(t)
    _test_endgame(t)
    _test_rank_maths(t)


static func _test_interface(t: TestKit) -> void:
    t.section("opponent interface")
    var game := GoGame.new(9, 5.5, 0)
    var p := _profile()
    var o := OpponentFactory.create(p, game)
    t.ok(o is HeuristicOpponent, "the factory builds the heuristic opponent by default")
    t.ok(OpponentFactory.create(_profile("random"), game) is RandomOpponent, "and a random one on request")
    var gtp_profile := _profile("gtp")
    gtp_profile.gtp_command = "/nonexistent/katago"
    t.ok(OpponentFactory.create(gtp_profile, game) is HeuristicOpponent,
        "a missing GTP engine falls back instead of crashing")
    t.eq(GtpOpponent._parse_vertex(game.board, "D4"), game.board.idx(3, 5), "GTP vertices parse")
    t.eq(GtpOpponent._parse_vertex(game.board, "J9"), game.board.idx(8, 0), "and skip the letter I")


static func _test_random_legality(t: TestKit) -> void:
    t.section("random opponent")
    var game := GoGame.new(9, 5.5, 0)
    var a := OpponentFactory.create(_profile("random", 7), game)
    var b := OpponentFactory.create(_profile("random", 8), game)
    _self_play(a, b, game, t, "random self-play")
    t.eq(game.state, GoGame.State.SCORING, "random self-play ends in two passes")
    t.ok(game.move_number() > 10, "and takes a plausible number of moves")


static func _test_heuristic_tactics(t: TestKit) -> void:
    t.section("heuristic tactics")
    # A white stone in atari: the opponent should simply take it.
    var g := GoGame.new(5, 5.5, 0)
    g.set_position(GoBoard.from_ascii("""
        OX...
        .X...
        .....
        .....
        .....
    """).cells, GoBoard.BLACK)
    var o := OpponentFactory.create(_profile(), g)
    var mv: Dictionary = o.choose_move(g)
    t.eq(mv["point"], g.board.idx(0, 1), "it plays the capture")

    # Its own group in atari: it should extend rather than let it die.
    var g2 := GoGame.new(5, 5.5, 0)
    g2.set_position(GoBoard.from_ascii("""
        .O...
        XO...
        .....
        .....
        .....
    """).cells, GoBoard.WHITE)
    # White chain (1,0)+(1,1) has liberties (0,0),(2,0),(2,1),(1,2): not in atari,
    # so instead check the opponent never fills one of its own eyes.
    var g3 := GoGame.new(5, 5.5, 0)
    g3.set_position(GoBoard.from_ascii("""
        .X.X.
        XXXXX
        .....
        OOOOO
        .O.O.
    """).cells, GoBoard.BLACK)
    var o3 := OpponentFactory.create(_profile(), g3)
    for n in 12:
        var m: Dictionary = o3.choose_move(g3)
        if m["type"] != "move":
            break
        t.ok(m["point"] != g3.board.idx(0, 0) and m["point"] != g3.board.idx(2, 0)
            and m["point"] != g3.board.idx(4, 0), "it never fills its own eye")
        if not g3.play(m["point"]):
            t.ok(false, "illegal move from the heuristic opponent")
            break
        g3.pass_turn()


static func _test_selfplay(t: TestKit) -> void:
    t.section("heuristic self-play")
    var finished := 0
    var black_wins := 0
    for n in 8:
        var game := GoGame.new(9, 5.5, 0)
        var a := OpponentFactory.create(_profile("heuristic", 100 + n), game)
        var b := OpponentFactory.create(_profile("heuristic", 900 + n), game)
        _self_play(a, b, game, t, "self-play %d" % n)
        if game.state == GoGame.State.SCORING:
            finished += 1
            var dead := GoScoring.estimate_dead(game.board)
            var s := GoScoring.score(game.board, dead, game.captures, game.komi, GoScoring.Rule.JAPANESE)
            game.finish_with_score(s)
            if s["winner"] == GoBoard.BLACK:
                black_wins += 1
        t.ok(game.board.count_color(GoBoard.BLACK) + game.board.count_color(GoBoard.WHITE) > 20,
            "self-play %d filled a reasonable part of the board" % n)
    t.eq(finished, 8, "all eight games reached scoring")
    t.ok(black_wins > 0 and black_wins < 8, "neither colour wins every game")


static func _test_profiles(t: TestKit) -> void:
    t.section("profiles")
    # The same seed and no mistakes must reproduce the same game exactly.
    var moves_a := _play_and_record(_profile("heuristic", 55))
    var moves_b := _play_and_record(_profile("heuristic", 55))
    t.eq(moves_a, moves_b, "a fixed seed reproduces the game move for move")

    var noisy := _profile("heuristic", 55)
    noisy.mistake_rate = 0.9
    var moves_c := _play_and_record(noisy)
    t.ok(moves_a != moves_c, "a high mistake rate produces different play")

    var strong := _profile("heuristic", 3)
    strong.rank_label = "4k"
    t.eq(strong.strength(), GoRank.from_string("4k"), "a profile reports its own strength")


static func _play_and_record(p: OpponentProfile) -> PackedInt32Array:
    var game := GoGame.new(9, 5.5, 0)
    var a := OpponentFactory.create(p, game)
    var b := OpponentFactory.create(p, game)
    var out := PackedInt32Array()
    var guard := 200
    while game.state == GoGame.State.PLAYING and guard > 0:
        guard -= 1
        var mv: Dictionary = (a if game.to_move == GoBoard.BLACK else b).choose_move(game)
        out.append(mv["point"])
        if mv["type"] == "pass":
            game.pass_turn()
        elif mv["type"] == "resign":
            game.resign(game.to_move)
        else:
            game.play(mv["point"])
    return out


## Where the opponent stops, and what it refuses to play on the way there.
##
## Before M29 it passed only in reply to a pass, and only when its best move
## scored under a threshold -- so against anybody who kept playing it filled the
## dame, then its own territory, then invaded settled ground and died there one
## stone at a time. A 13x13 self-play ran to 298 moves and three games in
## twenty-four never ended at all.
static func _test_endgame(t: TestKit) -> void:
    t.section("ai: the endgame")

    # The opening is not territory. An empty region borders one colour from the
    # first move onwards, and on a handicap board it does so before either
    # player has moved -- read as "settled" that is the whole board, and the
    # opponent passes on move two. What stops it is the size of the region, so
    # these two are the cap being asked the easiest question there is.
    var opening := GoGame.new(9, 5.5, 0)
    opening.play(opening.board.idx(4, 4))
    var first := HeuristicOpponent.new()
    first.setup(_profile(), opening)
    t.eq(str(first.choose_move(opening)["type"]), "move",
        "one stone on the board is not a settled position")

    var handi := GoGame.new(9, 0.5, 5)
    var second := HeuristicOpponent.new()
    second.setup(_profile(), handi)
    t.eq(str(second.choose_move(handi)["type"]), "move",
        "and neither are five handicap stones with White still to play")

    # Black's four-point corner, walled off and alive. Neither player has any
    # business inside it: Black would be handing back a point a move under
    # Japanese scoring, White would be feeding stones to a wall that holds.
    var sealed := GoGame.new(9, 5.5, 0)
    sealed.set_position(GoBoard.from_ascii("""
        ..X......
        ..X......
        XXX......
        .........
        ....O....
        .........
        .........
        .........
        ....O....
    """).cells, GoBoard.BLACK)
    var inside := [sealed.board.idx(0, 0), sealed.board.idx(1, 0),
        sealed.board.idx(0, 1), sealed.board.idx(1, 1)]
    for colour in [GoBoard.BLACK, GoBoard.WHITE]:
        var settled: Dictionary = GoEndgame.settled_points(sealed.board, int(colour))
        for p in inside:
            t.ok(settled.has(p), "the walled corner is settled, seen from %s"
                % GoBoard.color_name(colour))

    var never_inside := true
    for n in 30:
        var g := GoGame.new(9, 5.5, 0)
        g.set_position(sealed.board.cells, GoBoard.BLACK if n % 2 == 0 else GoBoard.WHITE)
        var ai := HeuristicOpponent.new()
        ai.setup(_profile("heuristic", 700 + n), g)
        var mv: Dictionary = ai.choose_move(g)
        if str(mv["type"]) == "move" and inside.has(int(mv["point"])):
            never_inside = false
    t.ok(never_inside, "and neither colour plays a stone into it, in 30 tries")

    # A wall on one liberty is not a wall. The three-point corner below is
    # enclosed by Black and by nobody else, and Black's stones are alive by every
    # other measure -- but the stone at the top of the wall has one liberty, and
    # it is inside the region it is supposed to be enclosing.
    #
    # The first position written for this had Black outnumbered as well, so the
    # dead-wall clause was answering and the atari clause was never asked. It
    # passed, and it was measuring the wrong thing: deleting the clause it named
    # broke nothing.
    var breached := GoGame.new(9, 5.5, 0)
    breached.set_position(GoBoard.from_ascii("""
        ..XO.....
        .XO......
        X........
        .........
        .........
        .........
        .........
        .........
        .........
    """).cells, GoBoard.BLACK)
    t.eq(breached.board.chain_at(breached.board.idx(2, 0))["liberties"].size(), 1,
        "the wall stone really is in atari")
    t.eq(GoEndgame.settled_points(breached.board, GoBoard.BLACK).size(), 0,
        "a region whose wall is in atari is not settled")

    # And a wall the scorer already reads as dead is not enclosing anything --
    # the four points inside are a life-and-death problem, not territory.
    var doomed := GoGame.new(9, 5.5, 0)
    doomed.set_position(GoBoard.from_ascii("""
        ..XO.....
        ..XO.....
        XXXO.....
        OOOO.....
        .........
        .........
        .........
        .........
        .........
    """).cells, GoBoard.BLACK)
    var white_view: Dictionary = GoEndgame.settled_points(doomed.board, GoBoard.WHITE)
    for p in [doomed.board.idx(0, 0), doomed.board.idx(1, 0),
            doomed.board.idx(0, 1), doomed.board.idx(1, 1)]:
        t.ok(not white_view.has(p),
            "a dead wall encloses nothing, so the eyespace is still there to be taken")

    # And the cap on your own territory. Black is alive in the corner with two
    # eyes, so both eyes are settled and White has nothing else to play except
    # the sixty-six empty points that are "enclosed by White and nobody else" --
    # which is not territory, it is the rest of the board.
    #
    # The first position written for this had a dead Black group in the corner,
    # so White always had its eyespace to play in and passed nothing up. Same
    # mistake as the atari one above: the test agreed with the code for a reason
    # that had nothing to do with the clause it was named after.
    var wide := GoGame.new(9, 5.5, 0)
    wide.set_position(GoBoard.from_ascii("""
        .X.XO....
        XXXXO....
        OOOOO....
        .........
        .........
        .........
        .........
        .........
        .........
    """).cells, GoBoard.WHITE)
    var eyes := [wide.board.idx(0, 0), wide.board.idx(2, 0)]
    var white_ground: Dictionary = GoEndgame.settled_points(wide.board, GoBoard.WHITE)
    for e in eyes:
        t.ok(white_ground.has(e), "Black's two eyes are settled, and White knows it")
    t.ok(not white_ground.has(wide.board.idx(8, 8)),
        "but the open board is not White's territory just because only White is near it")
    var reader := HeuristicOpponent.new()
    reader.setup(_profile(), wide)
    t.eq(str(reader.choose_move(wide)["type"]), "move",
        "so there is still a game on, and White plays it")

    # The mercy rule, both directions. The opponent has stopped; whether there is
    # anything left to settle decides whether stopping too is courtesy or a
    # forfeit of the points that make the count mean something.
    var decided := GoGame.new(9, 5.5, 0)
    decided.set_position(GoBoard.from_ascii("""
        XXXXXXXXX
        XXXXXXXXX
        XXXXXXXXX
        .........
        .........
        .........
        .........
        ....O....
        .........
    """).cells, GoBoard.BLACK)
    decided.pass_turn()
    var loser := HeuristicOpponent.new()
    loser.setup(_profile(), decided)
    t.eq(str(loser.choose_move(decided)["type"]), "pass",
        "they passed and the game is not in doubt, so it counts rather than plays on")

    var close := GoGame.new(9, 5.5, 0)
    close.set_position(GoBoard.from_ascii("""
        XXXXXXXXX
        .........
        .........
        .........
        .........
        .........
        .........
        .........
        OOOOOOOOO
    """).cells, GoBoard.BLACK)
    close.pass_turn()
    var contender := HeuristicOpponent.new()
    contender.setup(_profile(), close)
    t.eq(str(contender.choose_move(close)["type"]), "move",
        "they passed in a close game, so the points that are left still get played")

    # The positional term is an opening heuristic and it used to be applied to
    # the whole game: the third line scored +4 and the first line -4 on move 150
    # exactly as on move 1. It fades with the open board instead now, which is
    # what lets the last boundary points be worth taking. Reaching into
    # _score_move is deliberate -- the fade only changes the ORDER of candidates,
    # never whether there are any, so choose_move cannot show it, and a break of
    # this clause left every other assertion in this file green.
    var late := GoGame.new(9, 5.5, 0)
    late.set_position(GoBoard.from_ascii("""
        .........
        .XXXXXXX.
        .X.....X.
        .XOOOOOX.
        .XO...OX.
        .XOOOOOX.
        .X.....X.
        .XXXXXXX.
        .........
    """).cells, GoBoard.BLACK)
    var scorer := HeuristicOpponent.new()
    scorer.setup(_profile(), late)
    var edge: int = late.board.idx(0, 4)
    var centre: int = late.board.idx(4, 4)
    var open_gap := 0.0
    var closed_gap := 0.0
    for n in 8:
        open_gap += scorer._score_move(late, centre, GoBoard.BLACK, 1.0) \
            - scorer._score_move(late, edge, GoBoard.BLACK, 1.0)
        closed_gap += scorer._score_move(late, centre, GoBoard.BLACK, 0.1) \
            - scorer._score_move(late, edge, GoBoard.BLACK, 0.1)
    t.ok(closed_gap < open_gap,
        "the first line stops being a mistake once there is no board left to divide")

    # The regression guard for the 477-move game. Both board sizes, because the
    # bigger board is where it was worst: 1.76 moves per point at 13x13.
    for board in [9, 13]:
        var size: int = int(board)
        for n in 3:
            var game := GoGame.new(size, 5.5, 0)
            var a := OpponentFactory.create(_profile("heuristic", 31 + n), game)
            var b := OpponentFactory.create(_profile("heuristic", 91 + n), game)
            var cap: int = int(float(size * size) * 1.4)
            var guard: int = size * size * 6
            while game.state == GoGame.State.PLAYING and guard > 0:
                guard -= 1
                var who: GoOpponent = a if game.to_move == GoBoard.BLACK else b
                var mv: Dictionary = who.choose_move(game)
                match str(mv["type"]):
                    "pass": game.pass_turn()
                    "resign": game.resign(game.to_move)
                    _: game.play(int(mv["point"]))
            t.eq(game.state, GoGame.State.SCORING,
                "%dx%d self-play %d stops on its own" % [size, size, n])
            t.ok(game.moves.size() < cap,
                "%dx%d self-play %d finished in %d moves, under %d"
                    % [size, size, n, game.moves.size(), cap])


static func _test_rank_maths(t: TestKit) -> void:
    t.section("ranks")
    t.eq(GoRank.from_string("20k"), 10, "20 kyu")
    t.eq(GoRank.from_string("1k"), 29, "1 kyu")
    t.eq(GoRank.from_string("1d"), 30, "1 dan follows 1 kyu")
    t.eq(GoRank.from_string("5d"), 34, "5 dan")
    t.eq(GoRank.to_string_rank(10), "20k", "round trip kyu")
    t.eq(GoRank.to_string_rank(30), "1d", "round trip dan")
    t.eq(GoRank.to_string_rank(-1), "unranked", "unranked")
    t.eq(GoRank.from_string("unranked"), -1, "unranked parses back")

    var h := GoRank.handicap_between(GoRank.from_string("22k"), GoRank.from_string("12k"))
    t.eq(h["stones"], 9, "a ten-stone gap is capped at nine stones")
    t.eq(h["black"], "player", "the weaker player takes black")
    var even := GoRank.handicap_between(GoRank.from_string("12k"), GoRank.from_string("12k"))
    t.eq(even["stones"], 0, "equal ranks play an even game")
    t.eq(even["komi"], 5.5, "with full komi")
    t.eq(GoRank.describe_gap(GoRank.from_string("20k"), GoRank.from_string("12k")), "far beyond you",
        "rank gaps are described in words, never as difficulty labels")

    # A stone is worth more on a small board, so the same gap costs fewer of them.
    var small := GoRank.handicap_between(
        GoRank.from_string("22k"), GoRank.from_string("12k"), 9)
    t.eq(small["stones"], 3, "ten ranks is three stones on 9x9, not ten")
    var medium := GoRank.handicap_between(
        GoRank.from_string("22k"), GoRank.from_string("12k"), 13)
    t.eq(medium["stones"], 5, "and five on 13x13")
    t.ok(small["stones"] < medium["stones"], "the smaller the board, the fewer the stones")

    # And a board never carries more stones than it has star points.
    var hopeless := GoRank.handicap_between(
        GoRank.from_string("30k"), GoRank.from_string("5d"), 9)
    t.eq(hopeless["stones"], GoRank.max_handicap(9),
        "a 9x9 tops out at its five star points however wide the gap")
    t.eq(GoRank.max_handicap(9), 5, "which is four corners and tengen")
    t.eq(GoRank.max_handicap(19), 9, "a full board carries nine")

    # The placement table has to be able to honour whatever the arithmetic asks.
    for size in [9, 13, 19]:
        var cap: int = GoRank.max_handicap(size)
        var pts := GoGame.handicap_points(size, cap)
        t.eq(pts.size(), cap, "%dx%d can place its %d handicap stones" % [size, size, cap])


## A weak player picks a bad move, not a random point. The distinction is the
## whole difference between an opponent you can learn from and dice.
static func _test_plausible_mistakes(t: TestKit) -> void:
    t.section("ai: mistakes are plausible")
    var weak := _profile()
    weak.mistake_rate = 0.9        # blunders almost every move
    var game := GoGame.new(9, 5.5, 0)
    var ai := HeuristicOpponent.new()
    ai.setup(weak, game)

    # Two hundred openings from a weak profile. Every one of them must still be
    # a move somebody could have meant: never the first line while the board is
    # empty, and never a point it has already refused as self-atari.
    var first_line := 0
    for i in 200:
        var g := GoGame.new(9, 5.5, 0)
        var fresh := HeuristicOpponent.new()
        var p := _profile("heuristic", 100 + i)
        p.mistake_rate = 0.9
        fresh.setup(p, g)
        var mv: Dictionary = fresh.choose_move(g)
        t.ok(str(mv["type"]) == "move", "a weak opening is still a move")
        var pt := int(mv["point"])
        var xy := g.board.point(pt)
        if xy.x == 0 or xy.y == 0 or xy.x == 8 or xy.y == 8:
            first_line += 1
    t.eq(first_line, 0,
        "200 blundering openings and not one on the first line -- the old version played there constantly")


## reading_depth 2 must actually cost something to walk into.
static func _test_reading_depth(t: TestKit) -> void:
    t.section("ai: two plies")
    # Black has a stone on two liberties. White to play; one of the two moves
    # leaves White's own new stone able to be taken straight back.
    var shallow := _profile()
    shallow.reading_depth = 1
    var deep := _profile()
    deep.reading_depth = 2

    var seen_difference := false
    for seed_value in range(20):
        var g := GoGame.new(9, 5.5, 0)
        g.set_position(GoBoard.from_ascii(
            ".........\n" +
            "..XXX....\n" +
            "..X.X....\n" +
            "..XXX....\n" +
            ".........\n" +
            ".........\n" +
            ".........\n" +
            ".........\n" +
            ".........").cells, GoBoard.WHITE)
        var a := HeuristicOpponent.new()
        var pa := _profile("heuristic", seed_value + 1)
        pa.reading_depth = 2
        a.setup(pa, g)
        var mv: Dictionary = a.choose_move(g)
        # The one point inside that eye is a stone White loses immediately.
        if str(mv["type"]) == "move":
            t.ok(int(mv["point"]) != g.board.idx(3, 2),
                "a two-ply reader does not step into a point that is captured at once")
            seen_difference = true
    t.ok(seen_difference, "the position produced moves to judge")


## The cast play the way their blurbs say they do.
static func _test_styles(t: TestKit) -> void:
    t.section("ai: style shows at the board")
    # Ilse's book: the first move of a book player is a corner star point.
    var booked := _profile()
    booked.book_moves = 6
    var g := GoGame.new(9, 5.5, 0)
    var ilse := HeuristicOpponent.new()
    ilse.setup(booked, g)
    var mv: Dictionary = ilse.choose_move(g)
    var corners := Array(GoGame.handicap_points(9, 4))
    t.ok(corners.has(int(mv["point"])),
        "a player with a book opens in a corner, every time")

    # And off the page she is on her own again: past book_moves the habit stops.
    var late := GoGame.new(9, 5.5, 0)
    for i in 8:
        late.play(late.board.idx(1 + i % 3, 5 + i / 3))
    var off_book := HeuristicOpponent.new()
    off_book.setup(booked, late)
    t.ok(str(off_book.choose_move(late)["type"]) == "move",
        "and she still has to find a move once the book runs out")

    # Pip chases. A white stone on two liberties can be put in atari and will then
    # run -- that is a ladder, and it is the move Pip cannot leave alone.
    var chased := ".........\n....X....\n...XO....\n.........\n" + \
        ".........\n.........\n.........\n.........\n........."
    var chases := {"happy": 0, "calm": 0}
    for seed_value in range(40):
        for kind in ["happy", "calm"]:
            var run := GoGame.new(9, 5.5, 0)
            run.set_position(GoBoard.from_ascii(chased).cells, GoBoard.BLACK)
            var prof := _profile("heuristic", seed_value + 1)
            prof.mistake_rate = 0.0
            # Aggression off for both, so the ordinary pull towards atari and
            # contact is out of the way and the only thing that can send a player
            # after a running stone is the chase itself.
            prof.aggression = 0.0
            prof.ladder_happy = 2.0 if kind == "happy" else 0.0
            var chaser := HeuristicOpponent.new()
            chaser.setup(prof, run)
            var pick: Dictionary = chaser.choose_move(run)
            if str(pick["type"]) != "move":
                continue
            # The two points that put the white stone on one liberty.
            if int(pick["point"]) == run.board.idx(5, 2) or int(pick["point"]) == run.board.idx(4, 3):
                chases[kind] += 1
    t.ok(chases["happy"] > chases["calm"],
        "the chase, and only the chase, sends a ladder-happy player after a running stone (%d vs %d)"
            % [chases["happy"], chases["calm"]])
    t.eq(chases["calm"], 0, "a player without the habit leaves it alone entirely")

    var calm := _profile()
    t.eq(calm.cut_bias, 0.0, "and style defaults to off, so nobody gains a habit by accident")
    t.eq(calm.ladder_happy, 0.0, "including the chase")
    t.eq(calm.book_moves, 0, "and the book")
