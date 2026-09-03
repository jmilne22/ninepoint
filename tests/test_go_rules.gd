## Board, chains, liberties, capture, suicide, ko, passing, handicap, history.
class_name GoRulesTests
extends RefCounted


static func _game_from(art: String, side := GoBoard.BLACK, komi := 6.5) -> GoGame:
    var b := GoBoard.from_ascii(art)
    var g := GoGame.new(b.size, komi, 0)
    g.set_position(b.cells, side)
    return g


static func run(t: TestKit) -> void:
    _test_geometry(t)
    _test_chains(t)
    _test_capture(t)
    _test_snapback(t)
    _test_suicide(t)
    _test_ko(t)
    _test_superko(t)
    _test_passing(t)
    _test_undo(t)
    _test_handicap(t)
    _test_eyes(t)
    _test_sgf(t)


static func _test_geometry(t: TestKit) -> void:
    t.section("geometry")
    var b := GoBoard.new(9)
    t.eq(b.cells.size(), 81, "9x9 has 81 points")
    t.eq(b.idx(2, 3), 29, "index maths")
    t.eq(b.point(29), Vector2i(2, 3), "index round trip")
    t.eq(b.neighbours(b.idx(0, 0)).size(), 2, "corner has 2 neighbours")
    t.eq(b.neighbours(b.idx(4, 0)).size(), 3, "edge has 3 neighbours")
    t.eq(b.neighbours(b.idx(4, 4)).size(), 4, "centre has 4 neighbours")
    t.eq(b.label(b.idx(0, 8)), "A1", "bottom-left is A1")
    t.eq(b.label(b.idx(8, 0)), "J9", "top-right is J9 (I is skipped)")
    t.ok(b.in_bounds(8, 8) and not b.in_bounds(9, 0), "bounds check")
    t.eq(GoBoard.opponent(GoBoard.BLACK), GoBoard.WHITE, "colours alternate")


static func _test_chains(t: TestKit) -> void:
    t.section("chains and liberties")
    var b := GoBoard.from_ascii("""
        .....
        .XX..
        .X...
        .....
        .....
    """)
    var ch := b.chain_at(b.idx(1, 1))
    t.eq(ch["stones"].size(), 3, "three connected stones form one chain")
    t.eq(ch["liberties"].size(), 7, "bent three has 7 liberties")

    var corner := GoBoard.from_ascii("""
        X....
        .....
        .....
        .....
        .....
    """)
    t.eq(corner.liberty_count(0), 2, "corner stone has 2 liberties")

    var split := GoBoard.from_ascii("""
        X.X..
        .....
        .....
        .....
        .....
    """)
    t.eq(split.chain_at(0)["stones"].size(), 1, "gapped stones are separate chains")
    t.eq(split.all_chains().size(), 2, "all_chains finds both")
    t.eq(split.count_color(GoBoard.BLACK), 2, "stone counting")


static func _test_capture(t: TestKit) -> void:
    t.section("capture")
    # A single white stone in the corner, one liberty left at (0,1).
    var g := _game_from("""
        OX..
        .X..
        ....
        ....
    """)
    t.eq(g.board.liberty_count(0), 1, "the white stone is in atari")
    t.ok(g.play_xy(0, 1), "black plays the capturing move")
    t.eq(g.board.get_at(0, 0), GoBoard.EMPTY, "captured stone is removed")
    t.eq(g.captures[GoBoard.BLACK], 1, "capture is counted for black")
    t.eq(g.moves[0]["captured"].size(), 1, "the move records what it took")

    # A white two-stone chain with a single liberty at (3,1).
    var g2 := _game_from("""
        .XX..
        XOO..
        .XX..
        .....
        .....
    """)
    t.eq(g2.board.chain_at(g2.board.idx(1, 1))["liberties"].size(), 1, "white chain in atari")
    t.ok(g2.play_xy(3, 1), "black fills the last liberty")
    t.eq(g2.board.get_at(1, 1), GoBoard.EMPTY, "first white stone gone")
    t.eq(g2.board.get_at(2, 1), GoBoard.EMPTY, "second white stone gone")
    t.eq(g2.captures[GoBoard.BLACK], 2, "two prisoners")


static func _test_snapback(t: TestKit) -> void:
    t.section("snapback")
    # White surrounds a two-point eye space; black throws in, white takes,
    # black takes the whole ring back.
    var g := _game_from("""
        XXXXXX
        XOOOOX
        XO..OX
        XOOOOX
        XXXXXX
        ......
    """)
    t.eq(g.board.chain_at(g.board.idx(1, 1))["stones"].size(), 10, "white ring is one chain")
    t.eq(g.board.chain_at(g.board.idx(1, 1))["liberties"].size(), 2, "with a two-point eye")
    t.ok(g.play_xy(2, 2), "black throws a stone in")
    t.eq(g.to_move, GoBoard.WHITE, "white to answer")
    t.ok(g.play_xy(3, 2), "white captures the throw-in")
    t.eq(g.captures[GoBoard.WHITE], 1, "one black stone taken")
    t.eq(g.board.chain_at(g.board.idx(1, 1))["liberties"].size(), 1, "but the ring is now in atari")
    t.ok(g.play_xy(2, 2), "black plays back in")
    t.eq(g.captures[GoBoard.BLACK], 11, "the entire white group is captured -- snapback")


static func _test_suicide(t: TestKit) -> void:
    t.section("suicide")
    var g := _game_from("""
        .X..
        X...
        ....
        ....
    """, GoBoard.WHITE)
    t.eq(g.legality(g.board.idx(0, 0)), GoGame.Legality.SUICIDE, "filling your own last liberty is illegal")
    t.ok(not g.play_xy(0, 0), "the move is rejected")
    t.eq(g.legality(g.board.idx(2, 2)), GoGame.Legality.LEGAL, "an open point is fine")
    t.eq(g.legality(g.board.idx(1, 0)), GoGame.Legality.OCCUPIED, "occupied point is rejected")
    t.eq(g.legality(-1), GoGame.Legality.OUT_OF_BOUNDS, "off-board index is rejected")

    # The same shape, but the move captures -- so it is legal after all.
    var g2 := _game_from("""
        .OX.
        OOX.
        XX..
        ....
    """)
    t.eq(g2.board.chain_at(g2.board.idx(1, 0))["liberties"].size(), 1, "white group has one liberty")
    t.eq(g2.legality(0), GoGame.Legality.LEGAL, "a capturing move is not self-capture")
    t.ok(g2.play_xy(0, 0), "black plays it")
    t.eq(g2.captures[GoBoard.BLACK], 3, "three white stones captured")

    # Filling a friendly group's last liberty from the inside is still illegal.
    var g3 := _game_from("""
        .XO..
        XXO..
        OOO..
        .....
        .....
    """)
    t.eq(g3.legality(g3.board.idx(0, 0)), GoGame.Legality.SUICIDE, "black cannot fill its own eye shut")


static func _test_ko(t: TestKit) -> void:
    t.section("ko")
    #  . . . . .
    #  . . X O .    black takes at (3,2), white may not take straight back
    #  . X O . O
    #  . . X O .
    #  . . . . .
    var g := _game_from("""
        .....
        ..XO.
        .XO.O
        ..XO.
        .....
    """)
    t.eq(g.board.liberty_count(g.board.idx(2, 2)), 1, "the white stone has one liberty")
    t.ok(g.play_xy(3, 2), "black takes the ko")
    t.eq(g.captures[GoBoard.BLACK], 1, "exactly one stone captured")
    t.eq(g.ko_point, g.board.idx(2, 2), "the ko point is where the stone stood")
    t.eq(g.to_move, GoBoard.WHITE, "white to move")
    t.eq(g.legality(g.board.idx(2, 2)), GoGame.Legality.KO, "white may not retake immediately")
    t.ok(not g.play_xy(2, 2), "the retake is refused")

    g.play_xy(0, 0)          # white plays a ko threat elsewhere
    t.eq(g.ko_point, -1, "the ko is released after a move elsewhere")
    g.play_xy(4, 4)          # black answers elsewhere
    t.eq(g.legality(g.board.idx(2, 2)), GoGame.Legality.LEGAL, "white may now retake")
    t.ok(g.play_xy(2, 2), "white retakes")
    t.eq(g.captures[GoBoard.WHITE], 1, "and captures one back")
    t.eq(g.ko_point, g.board.idx(3, 2), "a new ko point, the other way round")


static func _test_superko(t: TestKit) -> void:
    t.section("superko")
    var g := _game_from("""
        .....
        ..XO.
        .XO.O
        ..XO.
        .....
    """)
    g.ko_rule = GoGame.KoRule.POSITIONAL_SUPERKO
    g.play_xy(3, 2)                       # black takes
    t.eq(g.legality(g.board.idx(2, 2)), GoGame.Legality.SUPERKO, "retaking repeats a position")
    g.play_xy(0, 0)                       # white elsewhere
    g.play_xy(4, 4)                       # black elsewhere
    t.eq(g.legality(g.board.idx(2, 2)), GoGame.Legality.LEGAL,
        "the same capture is fine once the rest of the board has changed")
    var h := GoZobrist.hash_board(g.board)
    t.ok(h != 0, "a non-empty position hashes to something")
    t.eq(GoZobrist.hash_board(GoBoard.new(9)), 0, "an empty board hashes to zero")


static func _test_passing(t: TestKit) -> void:
    t.section("passing and game end")
    var g := GoGame.new(9, 6.5, 0)
    g.pass_turn()
    t.eq(g.to_move, GoBoard.WHITE, "turn changes on pass")
    t.eq(g.state, GoGame.State.PLAYING, "one pass does not end the game")
    g.pass_turn()
    t.eq(g.state, GoGame.State.SCORING, "two passes move to scoring")
    t.eq(g.legality(0), GoGame.Legality.GAME_OVER, "no moves after the game ends")

    var g2 := GoGame.new(9, 6.5, 0)
    g2.play_xy(4, 4)
    g2.pass_turn()
    g2.play_xy(3, 3)
    t.eq(g2.consecutive_passes, 0, "a move resets the pass counter")

    var g3 := GoGame.new(9, 6.5, 0)
    g3.resign(GoBoard.BLACK)
    t.eq(g3.state, GoGame.State.FINISHED, "resignation ends the game")
    t.eq(g3.result["winner"], GoBoard.WHITE, "the other player wins")
    t.ok(g3.result["by_resignation"], "flagged as a resignation")


static func _test_undo(t: TestKit) -> void:
    t.section("undo")
    var g := _game_from("""
        OX..
        .X..
        ....
        ....
    """)
    g.play_xy(0, 1)
    t.eq(g.captures[GoBoard.BLACK], 1, "captured before undo")
    t.ok(g.undo(), "undo succeeds")
    t.eq(g.board.get_at(0, 0), GoBoard.WHITE, "captured stone is restored")
    t.eq(g.captures[GoBoard.BLACK], 0, "prisoner count restored")
    t.eq(g.to_move, GoBoard.BLACK, "turn restored")
    t.eq(g.moves.size(), 0, "history shortened")
    t.ok(not g.undo(), "undo at the start of a game does nothing")


static func _test_handicap(t: TestKit) -> void:
    t.section("handicap and komi")
    var g := GoGame.new(9, 0.5, 4)
    t.eq(g.board.count_color(GoBoard.BLACK), 4, "four handicap stones placed")
    t.eq(g.to_move, GoBoard.WHITE, "white moves first in a handicap game")
    t.eq(g.board.get_at(2, 2), GoBoard.BLACK, "star point occupied")
    var g5 := GoGame.new(9, 0.5, 5)
    t.eq(g5.board.count_color(GoBoard.BLACK), 5, "five stones includes tengen")
    t.eq(g5.board.get_at(4, 4), GoBoard.BLACK, "tengen occupied at 5 stones")
    var g19 := GoGame.new(19, 0.5, 9)
    t.eq(g19.board.count_color(GoBoard.BLACK), 9, "nine stones on 19x19")
    t.eq(g19.board.get_at(3, 3), GoBoard.BLACK, "19x19 handicap uses the 4-4 points")
    t.eq(GoGame.default_komi(9, 0), 5.5, "9x9 even game komi")
    t.eq(GoGame.default_komi(19, 0), 6.5, "19x19 even game komi")
    t.eq(GoGame.default_komi(9, 4), 0.5, "handicap game komi")
    t.eq(GoGame.new(9, 6.5, 0).board.count_color(GoBoard.BLACK), 0, "no stones in an even game")


static func _test_eyes(t: TestKit) -> void:
    t.section("eye detection")
    var b := GoBoard.from_ascii("""
        .X...
        X.X..
        .X...
        .....
        .....
    """)
    t.ok(b.is_eye_like(b.idx(1, 1), GoBoard.BLACK), "surrounded point is an eye for black")
    t.ok(not b.is_eye_like(b.idx(1, 1), GoBoard.WHITE), "not an eye for white")
    var corner := GoBoard.from_ascii("""
        .X...
        XX...
        .....
        .....
        .....
    """)
    t.ok(corner.is_eye_like(corner.idx(0, 0), GoBoard.BLACK), "corner eye")
    var false_eye := GoBoard.from_ascii("""
        .X...
        XO...
        .....
        .....
        .....
    """)
    t.ok(not false_eye.is_eye_like(false_eye.idx(0, 0), GoBoard.BLACK),
        "a hostile diagonal breaks a corner eye")
    var centre := GoBoard.from_ascii("""
        .....
        .X.X.
        ..X..
        .X.X.
        .....
    """)
    t.ok(not centre.is_eye_like(centre.idx(2, 2), GoBoard.BLACK), "not surrounded is not an eye")


static func _test_sgf(t: TestKit) -> void:
    t.section("sgf")
    var g := GoGame.new(9, 5.5, 0)
    g.play_xy(2, 2)
    g.play_xy(6, 6)
    g.pass_turn()
    var sgf := GoSgf.to_sgf(g, {"PB": "Player", "PW": "Kesh"})
    t.ok(sgf.begins_with("(;GM[1]"), "sgf header")
    t.ok(sgf.contains("SZ[9]"), "board size recorded")
    t.ok(sgf.contains("KM[5.5]"), "komi recorded")
    t.ok(sgf.contains(";B[cc]"), "black move encoded")
    t.ok(sgf.contains(";W[gg]"), "white move encoded")
    t.ok(sgf.contains(";B[]"), "pass encoded")
    t.ok(sgf.contains("PW[Kesh]"), "metadata written")
