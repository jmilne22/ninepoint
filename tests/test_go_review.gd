## The post-game review: does the teacher describe the game that was played?
##
## Every fixture here is *played*, move by legal move, rather than written out
## as a diagram. That is deliberate. tools/check_lessons.py exists because three
## hand-drawn capture lessons turned out to have two liberties instead of one,
## and a review that invents a mistake is worse than one that misses it -- so
## _play() asserts each move was legal, and a fixture that drifts fails loudly
## instead of quietly testing a position nobody meant.
class_name GoReviewTests
extends RefCounted


static func run(t: TestKit) -> void:
	_test_replay(t)
	_test_atari_ignored(t)
	_test_own_eye_filled(t)
	_test_self_atari(t)
	_test_capture_missed(t)
	_test_good_capture(t)
	_test_good_save(t)
	_test_died_savable(t)
	_test_ladder_failed(t)
	_test_first_line_early(t)
	_test_selection(t)
	_test_degenerate(t)
	_test_voices(t)


# --- fixtures ----------------------------------------------------------------

## Plays `points` alternately from Black, asserting every move is legal.
static func _play(t: TestKit, points: Array, size: int = 9) -> GoGame:
	var g := GoGame.new(size, 5.5, 0)
	for i in points.size():
		var p: int = int(points[i])
		if not g.play(p):
			t.ok(false, "fixture move %d at %s is illegal (%s)" % [
				i, g.board.label(p), g.legality_reason(g.legality(p))])
			return g
	return g


## The raw detector output, before rank filtering and before the cap, so a test
## for one detector is not perturbed by what the others happened to find.
static func _raw(g: GoGame, colour: int = GoBoard.BLACK) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var positions := GoReview.positions_of(g)
	if positions.is_empty():
		return out
	GoReviewDetectors.run_all({
		"size": g.size(), "colour": colour,
		"enemy": GoBoard.opponent(colour),
		"moves": g.moves, "positions": positions,
	}, out)
	return out


static func _find(raw: Array[Dictionary], kind: String) -> Dictionary:
	for f in raw:
		if f["kind"] == kind:
			return f
	return {}


static func _has(raw: Array[Dictionary], kind: String) -> bool:
	return not _find(raw, kind).is_empty()


# --- the replay --------------------------------------------------------------

static func _test_replay(t: TestKit) -> void:
	t.section("review: replay")
	# 9x9: B(0,0) W(1,0) B(4,4) W(0,1) -- the last move takes the corner stone.
	var g := _play(t, [0, 1, 40, 9])
	var positions := GoReview.positions_of(g)
	t.eq(positions.size(), 5, "one position per move, plus the empty board")
	var start_cells: PackedByteArray = positions[0]
	var final_cells: PackedByteArray = positions[4]
	t.eq(start_cells.count(GoBoard.BLACK), 0, "position 0 is before move 0")
	t.eq(final_cells, g.board.cells, "the replay ends where the game did")
	var mid := GoBoard.new(9)
	mid.cells = positions[2]
	t.eq(mid.get_idx(0), GoBoard.BLACK, "position 2 is the board after move 1")
	t.eq(mid.get_idx(9), GoBoard.EMPTY, "and not after move 3")

	# A handicap game starts with stones already on the board and none in the
	# move list, so a replay that ignored them would review a different game.
	var h := GoGame.new(9, 0.5, 4)
	h.play(40)
	var hp := GoReview.positions_of(h)
	t.ok(not hp.is_empty(), "a handicap game replays")
	var handicap_cells: PackedByteArray = hp[0]
	t.eq(handicap_cells.count(GoBoard.BLACK), 4, "the handicap stones are there at move 0")

	# A position set wholesale cannot be rebuilt from a move list. Reviewing the
	# wrong board is worse than reviewing nothing, so it must refuse.
	var puzzle := GoGame.new(9, 5.5, 0)
	var art := GoBoard.from_ascii("""
		.........
		..X......
		.XOX.....
		..X......
		.........
		.........
		.........
		.........
		.........
	""")
	puzzle.set_position(art.cells, GoBoard.BLACK)
	puzzle.play(puzzle.board.idx(2, 3))
	t.ok(GoReview.positions_of(puzzle).is_empty(), "a set position refuses to replay")
	t.eq(GoReview.findings(puzzle, GoBoard.BLACK, 20).size(), 0, "and yields no findings")


# --- the mistakes ------------------------------------------------------------

static func _test_atari_ignored(t: TestKit) -> void:
	t.section("review: atari ignored")
	# B(0,0); W(1,0) puts it in atari; B plays the centre; W(0,1) takes it.
	var g := _play(t, [0, 1, 40, 9])
	var raw := _raw(g)
	var f := _find(raw, "atari_ignored")
	t.ok(not f.is_empty(), "a group left in atari and lost is reported")
	if not f.is_empty():
		t.eq(int(f["move_index"]), 1, "it points at the move that made the atari")
		t.eq(int(f["detail"]["liberty"]), 9, "and names the liberty that was free")
		t.eq(int(f["detail"]["stones"]), 1, "and how big the group was")
		t.ok(not bool(f["good"]), "it is not good news")

	# The same position, answered. Nothing to say.
	var saved := _play(t, [0, 1, 9])
	t.ok(not _has(_raw(saved), "atari_ignored"), "answering the atari reports nothing")

	# Left in atari but never actually captured: no harm, no finding.
	var survived := _play(t, [0, 1, 40, 60])
	t.ok(not _has(_raw(survived), "atari_ignored"),
		"a group that lived is not a mistake")


static func _test_own_eye_filled(t: TestKit) -> void:
	t.section("review: own eye filled")
	# Black surrounds (4,4) on all four sides, then fills it.
	var g := _play(t, [39, 80, 41, 79, 31, 78, 49, 77, 40])
	var raw := _raw(g)
	var f := _find(raw, "own_eye_filled")
	t.ok(not f.is_empty(), "filling one's own eye is reported")
	if not f.is_empty():
		t.eq(int(f["move_index"]), 8, "at the move that filled it")
		t.eq(f["points"], PackedInt32Array([40]), "pointing at the eye")

	# The same four stones, playing somewhere else entirely.
	var fine := _play(t, [39, 80, 41, 79, 31, 78, 49, 77, 60])
	t.ok(not _has(_raw(fine), "own_eye_filled"), "not filling it reports nothing")


static func _test_self_atari(t: TestKit) -> void:
	t.section("review: self-atari")
	# B(0,0); W(1,0); B centre; W(0,2); B(0,1) joins two stones on one liberty.
	var g := _play(t, [0, 1, 40, 18, 9])
	var f := _find(_raw(g), "self_atari")
	t.ok(not f.is_empty(), "playing a group down to one liberty is reported")
	if not f.is_empty():
		t.eq(int(f["detail"]["stones"]), 2, "and counts the stones put at risk")

	# One stone on one liberty is a throw-in as often as it is a blunder, and
	# the review has no reading with which to tell them apart, so it says
	# nothing rather than risk calling a real technique a mistake.
	var throw_in := _play(t, [60, 31, 62, 39, 20, 41, 40])
	t.ok(not _has(_raw(throw_in), "self_atari"),
		"a lone stone on one liberty goes unremarked")


static func _test_capture_missed(t: TestKit) -> void:
	t.section("review: capture missed")
	# White builds a two-stone group with one liberty at (0,1); Black never takes it.
	var g := _play(t, [2, 0, 10, 1, 40, 80])
	var f := _find(_raw(g), "capture_missed")
	t.ok(not f.is_empty(), "a group left standing on one liberty is reported")
	if not f.is_empty():
		t.eq(int(f["detail"]["stones"]), 2, "with the size of the group missed")
		t.eq(int(f["detail"]["liberty"]), 9, "and where the capture was")

	# The same game, but Black takes it. Nothing missed.
	var taken := _play(t, [2, 0, 10, 1, 9])
	t.ok(not _has(_raw(taken), "capture_missed"), "taking it reports nothing")


static func _test_ladder_failed(t: TestKit) -> void:
	t.section("review: ladder failed")
	# White walls off row 0 and row 2 first, so Black's only escape each turn is
	# straight along row 1 -- a ladder that was lost before it started.
	var g := _play(t, [10, 9, 40, 1, 42, 2, 43, 20, 48, 3, 50, 21, 52, 19,
		11, 78, 12, 13])
	var raw := _raw(g)
	var f := _find(raw, "ladder_failed")
	t.ok(not f.is_empty(), "running from atari and dying anyway is reported")
	if not f.is_empty():
		t.eq(int(f["move_index"]), 14, "pointing at where the running started")
		t.ok(int(f["detail"]["tries"]) >= 2, "having counted the attempts")
	t.ok(_has(raw, "self_atari"), "and each extension is self-atari in its own right")


static func _test_first_line_early(t: TestKit) -> void:
	t.section("review: first line early")
	var g := _play(t, [0, 40, 60, 42])
	var f := _find(_raw(g), "first_line_early")
	t.ok(not f.is_empty(), "an opening move on the first line is reported")

	var sane := _play(t, [30, 40, 60, 42])
	t.ok(not _has(_raw(sane), "first_line_early"), "the fourth line is not")


static func _test_died_savable(t: TestKit) -> void:
	t.section("review: died when it could have been saved")
	# The corner group goes into atari on move 9. Black's reply *captures* a
	# stone elsewhere, so the atari detector stands down -- and then Black
	# forgets about the corner entirely and loses it, with the save still there.
	var g := _play(t, [0, 50, 9, 1, 41, 79, 49, 78, 51, 18, 59, 77, 70, 10])
	var raw := _raw(g)
	t.ok(not _has(raw, "atari_ignored"),
		"a reply that captured something is not called ignoring the atari")
	var f := _find(raw, "died_savable")
	t.ok(not f.is_empty(), "a group lost with a save available is reported")
	if not f.is_empty():
		t.eq(int(f["move_index"]), 12, "at the player's last chance")
		t.eq(int(f["detail"]["save"]), 10, "naming the move that would have saved it")
		t.eq(int(f["detail"]["stones"]), 2, "and the size of what was lost")


# --- the things that went right ----------------------------------------------

static func _test_good_capture(t: TestKit) -> void:
	t.section("review: a capture worth mentioning")
	# Black takes three white stones off the top edge in one move.
	var g := _play(t, [0, 1, 4, 2, 10, 3, 11, 80, 12])
	var f := _find(_raw(g), "good_capture")
	t.ok(not f.is_empty(), "taking three stones at once is worth saying")
	if not f.is_empty():
		t.ok(bool(f["good"]), "and it is good news")
		t.eq(int(f["detail"]["stones"]), 3, "with the count")
	t.ok(not _has(_raw(g), "capture_missed"),
		"a capture that was taken is not also a capture that was missed")

	# Two stones is not yet a story.
	var small := _play(t, [0, 1, 3, 2, 10, 80, 11])
	t.ok(not _has(_raw(small), "good_capture"), "two stones goes unremarked")


static func _test_good_save(t: TestKit) -> void:
	t.section("review: a group saved")
	# White takes three of the centre stone's liberties; Black runs out and lives.
	var g := _play(t, [40, 31, 60, 39, 20, 41, 49])
	var f := _find(_raw(g), "good_save")
	t.ok(not f.is_empty(), "escaping atari into open space is worth saying")
	if not f.is_empty():
		t.ok(bool(f["good"]), "and it is good news")
	t.ok(not _has(_raw(g), "atari_ignored"), "and it is not also a loss")


# --- filtering and choosing --------------------------------------------------

static func _test_selection(t: TestKit) -> void:
	t.section("review: what gets said")
	var all: Array[Dictionary] = [
		{"kind": "atari_ignored", "move_index": 4, "severity": 5.0, "good": false},
		{"kind": "own_eye_filled", "move_index": 8, "severity": 5.0, "good": false},
		{"kind": "self_atari", "move_index": 2, "severity": 9.0, "good": false},
		{"kind": "first_line_early", "move_index": 1, "severity": 2.0, "good": false},
		{"kind": "good_capture", "move_index": 6, "severity": 4.0, "good": true},
	]
	# 25k: unranked or nearly, so only the two most basic mistakes and the praise.
	var beginner := GoReview.select(all, 5)
	var kinds := []
	for f in beginner:
		kinds.append(f["kind"])
	t.eq(kinds.size(), 3, "never more than three things are said")
	t.eq(kinds[0], "good_capture", "and the first of them is what went well")
	t.ok(not kinds.has("self_atari"), "22k advice is withheld from a 25k")
	t.ok(not kinds.has("first_line_early"), "and so is 15k advice")

	# 10k: everything unlocks, and the worst mistake leads.
	var stronger := GoReview.select(all, 20)
	t.eq(str(stronger[0]["kind"]), "good_capture", "praise still comes first")
	t.eq(stronger.size(), 3, "still three")
	t.eq(str(stronger[1]["kind"]), "self_atari", "then the worst of it")
	t.ok(int(stronger[1]["move_index"]) < int(stronger[2]["move_index"]),
		"and after the compliment the game is retold in order")

	# An unranked player is treated as a beginner, not as an error.
	t.ok(GoReview.select(all, -1).size() > 0, "unranked still gets a review")

	# Four ataris ignored is one mistake made four times. The review says it
	# once, with the worst instance, and spends the other two slots on
	# something the player has not already been told.
	var repetitive: Array[Dictionary] = [
		{"kind": "atari_ignored", "move_index": 4, "severity": 3.0, "good": false},
		{"kind": "atari_ignored", "move_index": 10, "severity": 8.0, "good": false},
		{"kind": "atari_ignored", "move_index": 22, "severity": 5.0, "good": false},
		{"kind": "own_eye_filled", "move_index": 30, "severity": 5.0, "good": false},
	]
	var varied := GoReview.select(repetitive, 20)
	t.eq(varied.size(), 2, "three ataris and an eye make two things to say")
	t.eq(str(varied[0]["kind"]), "atari_ignored", "the worst comes first")
	t.eq(int(varied[0]["move_index"]), 10, "and it is the worst instance of it")
	t.eq(str(varied[1]["kind"]), "own_eye_filled", "then something different")

	# Nothing to criticise: the praise fills the space rather than the review
	# ending after one line.
	var only_good: Array[Dictionary] = [
		{"kind": "good_capture", "move_index": 1, "severity": 4.0, "good": true},
		{"kind": "good_save", "move_index": 3, "severity": 3.0, "good": true},
	]
	t.eq(GoReview.select(only_good, 20).size(), 2, "a clean game is all praise")


static func _test_degenerate(t: TestKit) -> void:
	t.section("review: nothing to say")
	t.eq(GoReview.findings(null, GoBoard.BLACK, 10).size(), 0, "no game, no findings")
	var empty := GoGame.new(9, 5.5, 0)
	t.eq(GoReview.findings(empty, GoBoard.BLACK, 10).size(), 0, "no moves, no findings")

	# Resigning on move six must not produce a review that talks about move
	# fourteen -- which is exactly what the hard-coded dialogue used to do.
	var short_game := GoGame.new(9, 5.5, 0)
	short_game.play(40)
	short_game.play(31)
	short_game.play(60)
	short_game.resign(GoBoard.BLACK)
	var found := GoReview.findings(short_game, GoBoard.BLACK, 20)
	t.ok(found.size() <= GoReview.MAX_FINDINGS, "a resignation reviews cleanly")
	for f in found:
		t.ok(int(f["move_index"]) < short_game.moves.size(),
			"and never points past the end of the game")

	# Both passes and a resignation are in the move list; none of them is a
	# point on the board and none may be treated as one.
	var passed := GoGame.new(9, 5.5, 0)
	passed.play(40)
	passed.pass_turn()
	passed.pass_turn()
	t.ok(not GoReview.positions_of(passed).is_empty(), "passes replay")
	t.eq(GoReview.findings(passed, GoBoard.BLACK, 10).size(), 0, "and say nothing")


# --- the words ---------------------------------------------------------------

static func _test_voices(t: TestKit) -> void:
	t.section("review: voices")
	var kinds := GoReview.MIN_STRENGTH.keys()
	for who in ["default", "kesh", "hana", "wren", "joos"]:
		var v := GoReviewVoice.load_voice(who)
		t.ok(not v.lines.is_empty(), "%s has something to say" % who)
		for kind in kinds:
			t.ok(v.lines.has(kind), "%s has a line for %s" % [who, kind])

	# A character who writes no file at all still speaks, because default.json
	# is merged underneath every voice.
	var stranger := GoReviewVoice.load_voice("nobody_at_all")
	t.eq(stranger.lines.size(), kinds.size(), "an unwritten character borrows the default voice")

	# Substitution has to reach the board, or the review says "{liberty}".
	var board := GoBoard.new(9)
	var finding := {
		"kind": "atari_ignored", "move_index": 13,
		"detail": {"stones": 4, "liberty": 9, "played": 40},
	}
	var said := GoReviewVoice.load_voice("default").speak(finding, board)
	t.ok(said.find("{") < 0, "no placeholder survives into the sentence")
	t.ok(said.find("14") >= 0, "move numbers are said the way people count")
	# Which point a given line names depends on the line, so check that some
	# coordinate made it in rather than assuming which one.
	t.ok(said.find(board.label(9)) >= 0 or said.find(board.label(40)) >= 0,
		"and points are named as the board names them")

	# The same game must read the same way twice. A teacher who says something
	# different about the same board the second time is not a teacher.
	t.eq(GoReviewVoice.load_voice("default").speak(finding, board), said,
		"the same finding gives the same sentence")

	# Wren is 20k and knows it. Once you pass her she has to say so rather than
	# invent something, which is why she carries both halves.
	var wren := GoReviewVoice.load_voice("wren")
	t.ok(not wren.unqualified.is_empty(), "Wren can refuse to review you")
	t.ok(not wren.lines.is_empty(), "and can still review a beginner")

	# Joos says almost nothing, on purpose, and it must still be something.
	var joos := GoReviewVoice.load_voice("joos")
	for kind in kinds:
		t.ok(joos.speak({"kind": kind, "move_index": 0, "detail":
			{"stones": 3, "liberty": 9, "save": 9, "played": 40, "tries": 2}},
			board) != "", "Joos has a line for %s" % kind)
