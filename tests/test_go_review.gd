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
	_test_atari_answered(t)
	_test_dead_group_fed(t)
	_test_filled_own_territory(t)
	_test_big_swing(t)
	_test_cut_ignored(t)
	_test_should_have_passed(t)
	_test_always_opens_well(t)
	_test_cost_ranking(t)
	_test_instances(t)
	_test_concepts(t)
	_test_history(t)
	_test_from_finding(t)


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
	var ctx := {
		"size": g.size(), "colour": colour,
		"enemy": GoBoard.opponent(colour),
		"moves": g.moves, "positions": positions,
	}
	var ev := GoProgress.new()
	ev.prepare(ctx, g.komi)
	ctx["evaluator"] = ev
	GoReviewDetectors.run_all(ctx, out)
	GoReviewDetectorsShape.run_all(ctx, out)
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

	# Left in atari and never actually taken. Still the same mistake -- the
	# player did not look -- so it is still reported, but it cost nothing and
	# says so, which is what keeps it below a real loss in the ranking.
	var survived := _play(t, [0, 1, 40, 60])
	var lucky := _find(_raw(survived), "atari_ignored")
	t.ok(not lucky.is_empty(), "a group left in atari is reported even if it lived")
	if not lucky.is_empty():
		t.ok(bool(lucky["detail"].get("survived", false)), "and is marked as having got away")
		t.ok(not lucky["detail"].has("died_at"), "with no death to point at")
		t.ok(float(lucky["severity"]) < 3.0, "and ranks below a group that died")


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


## The review used to say this and no longer does: GoTableTalk says it at the
## table, on the move, and the two fired on identical conditions -- first line,
## within twenty moves. Said on move eight it is a nudge you can still act on;
## repeated on the result screen it is a lecture about a game already over.
static func _test_first_line_early(t: TestKit) -> void:
	t.section("review: the first line belongs to the table")
	var g := _play(t, [0, 40, 60, 42])
	t.ok(not _has(_raw(g), "first_line_early"),
		"the review no longer reports an opening move on the first line")
	t.ok(not GoReview.MIN_STRENGTH.has("first_line_early"),
		"and does not reserve a strength for it")

	# The banter still has it, so nothing was simply lost. It reads the move
	# just played rather than the whole game, so ask it on the move itself.
	var edge := _play(t, [0])
	t.ok(GoTableTalk.events(edge, GoBoard.WHITE).has("you_edge_early"),
		"GoTableTalk still notices the edge, on the move")


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

	# Two stones is a story. The threshold was three, which almost never fires
	# in a beginner's game -- and a game with no praise in it opens on a
	# criticism, which is the one thing the review is not allowed to do.
	var small := _play(t, [0, 1, 3, 2, 10, 80, 11])
	var two := _find(_raw(small), "good_capture")
	t.ok(not two.is_empty(), "two stones is worth saying")
	if not two.is_empty():
		t.eq(int(two["detail"]["stones"]), 2, "with the count")

	# One stone still is not.
	var one := _play(t, [0, 1, 9, 80])
	t.ok(not _has(_raw(one), "good_capture"), "a single stone goes unremarked")


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


# --- what the redesign added -------------------------------------------------

## The plainest thing a beginner can be praised for, and the reason the opening
## compliment can now be honoured in almost every game.
static func _test_atari_answered(t: TestKit) -> void:
	t.section("review: the atari you did answer")
	# Black plays the corner, White ataris it, Black takes the liberty.
	var g := _play(t, [0, 1, 9, 40, 18])
	var f := _find(_raw(g), "atari_answered")
	t.ok(not f.is_empty(), "answering an atari is worth saying")
	if not f.is_empty():
		t.ok(bool(f["good"]), "and it is good news")
		t.eq(int(f["move_index"]), 2, "pointing at the answer, not the atari")
		t.eq(int(f["detail"]["liberty"]), 9, "and naming the point that saved it")
	# Playing the liberty when it buys nothing is not an answer, it is feeding.
	t.ok(not _has(_raw(_play(t, [0, 1, 40, 9])), "atari_answered"),
		"a group nobody put in atari is not a rescue")


## Adding stones to a group that is already gone: the most expensive habit a
## beginner has, because every stone is a prisoner as well as a wasted move.
static func _test_dead_group_fed(t: TestKit) -> void:
	t.section("review: feeding a dead group")
	# White builds the whole of row 2 first, so every Black stone along row 1
	# joins a chain that is on one liberty and is still on one liberty after
	# it -- four stones bought nothing at all -- and then White takes the lot.
	#   B0 starts the chain (not feeding: nothing was in atari yet)
	#   B1 B2 B3 B4 each extend a one-liberty chain to a one-liberty chain
	#   W5 fills the last liberty and five stones come off
	var g := _play(t, [40, 9, 41, 10, 42, 11, 43, 12, 44, 13,
		0, 80, 1, 79, 2, 78, 3, 77, 4, 5])
	var raw := _raw(g)
	var f := _find(raw, "dead_group_fed")
	t.ok(not f.is_empty(), "stones poured into a lost group are reported")
	if not f.is_empty():
		t.eq(int(f["detail"]["stones"]), 4, "with how many stones were wasted")
		t.ok(f["detail"].has("died_at"), "and when the group finally came off")
		t.ok(int(f["instances"]) >= 2, "counted as one habit, not many findings")
	# A group that got out was not being fed, whatever it looked like.
	t.ok(not _has(_raw(_play(t, [0, 1, 9, 40, 18])), "dead_group_fed"),
		"a group that lived is not a group that was fed")


## Filling in your own finished territory: every one of these is a point handed
## straight back, and it is how a beginner loses a game they had already won.
static func _test_filled_own_territory(t: TestKit) -> void:
	t.section("review: filling your own territory")
	# Black walls off the top-left 4x4 -- sixteen points of its own -- while
	# White builds down the bottom. Then Black spends the end of the game
	# filling in the middle of its own corner, one point given back per stone.
	# The four fill moves are picked from the centre of the region so no chain
	# of Black's is ever short of liberties: answering an atari inside your own
	# area is correct and must not be reported as this.
	var g := _play(t, [
		4, 60, 13, 61, 22, 62, 31, 63, 36, 64, 37, 65, 38, 66, 39, 67,
		10, 68, 19, 69, 11, 70, 20, 71])
	var f := _find(_raw(g), "filled_own_territory")
	t.ok(not f.is_empty(), "playing inside your own area is reported")
	if not f.is_empty():
		t.ok(int(f["detail"]["stones"]) >= GoReviewDetectorsShape.WASTED_POINTS,
			"with how many points went back")


## Where the game turned. Not a mistake and it accuses nobody -- it is the
## spine the rest of the review hangs off.
static func _test_big_swing(t: TestKit) -> void:
	t.section("review: where it turned")
	# Black builds a large group along the top and then loses the lot.
	var g := _play(t, [0, 40, 1, 41, 2, 42, 3, 43, 4, 44, 9, 45,
		13, 46, 12, 5, 22, 14, 21, 11, 30, 10, 39, 20])
	var raw := _raw(g)
	var f := _find(raw, "big_swing")
	if not f.is_empty():
		t.ok(not bool(f["good"]), "a swing is not praise")
		t.ok(int(f["detail"]["points"]) > 0, "and is priced in points")
		t.ok(int(f["detail"]["until"]) > int(f["move_index"]),
			"running forward from where it started")
	# A game with no fall in it must not have one invented.
	var steady := _play(t, [40, 80, 41, 79, 42, 78, 30, 77])
	t.ok(not _has(_raw(steady), "big_swing"),
		"a game that never gave anything away has no turn")


## Kesh's whole game, and the one her dialogue has always claimed to review.
static func _test_cut_ignored(t: TestKit) -> void:
	t.section("review: the cut you played away from")
	# Black has stones at C8 and E8 with one empty point between them; White
	# plays it, Black answers in the far corner, and White takes the half that
	# was left on its own.
	var g := _play(t, [10, 1, 12, 9, 40, 11, 80, 19])
	var raw := _raw(g)
	var f := _find(raw, "cut_ignored")
	t.ok(not f.is_empty(), "a cut answered elsewhere, that then cost a group, is reported")
	if not f.is_empty():
		t.eq(int(f["move_index"]), 5, "reported at the cutting move")
		t.ok(f["detail"].has("played"), "naming where they went instead")
		t.ok(f["detail"].has("died_at"), "and which half it cost")
	# Answering the cut is not ignoring it.
	t.ok(not _has(_raw(_play(t, [10, 1, 12, 11, 20])), "cut_ignored"),
		"a cut that was answered is not reported")


## Playing on after it was over -- the counterpart to the AI's weak endgame.
static func _test_should_have_passed(t: TestKit) -> void:
	t.section("review: knowing when to stop")
	t.ok(GoReview.MIN_STRENGTH["should_have_passed"] >= 15,
		"held back until the player can act on it")
	# Nothing to detect in a short even game, and nothing may be invented.
	var g := _play(t, [40, 30, 41, 31, 42, 32])
	t.ok(not _has(_raw(g), "should_have_passed"),
		"a game still in progress is not a game that should have stopped")


## The rule that P5 turns on: a review always opens with something the player
## did. It used to be conditional on there being any praise to give, which meant
## the games it was written for were the likeliest to open on a criticism.
static func _test_always_opens_well(t: TestKit) -> void:
	t.section("review: it always opens with something you did")
	# A long, undistinguished game: nothing captured, nothing rescued.
	var moves := []
	for i in range(24):
		moves.append(20 + i * 2)
		moves.append(21 + i * 2)
	var g := _play(t, moves)
	var found := GoReview.findings(g, GoBoard.BLACK, 8)
	if not found.is_empty():
		t.ok(bool(found[0]["good"]), "the first thing said is always good news")

	# And never after a resignation. Somebody who has just given up does not want
	# to hear the game was clean -- it either calls them a coward or calls the
	# review a liar. best_moment still fills the slot.
	var quit_game := GoGame.new(9, 5.5, 0)
	for p in [40, 30, 41, 31, 42, 32, 43, 33, 44, 34, 50, 35, 51, 36]:
		quit_game.play(p)
	quit_game.resign(GoBoard.BLACK)
	var after_quit := GoReview.findings(quit_game, GoBoard.BLACK, 8)
	t.ok(not _has(after_quit, "nothing_broke"),
		"a resigned game is never called a clean one")
	if not after_quit.is_empty():
		t.ok(bool(after_quit[0]["good"]), "and it still opens with something you did")

	# But a game too short to have gone well must not be given a consolation
	# prize: MatchBridge skips the review when there are no findings, and that
	# is how a three-move resignation avoids being walked through one.
	var stub := GoGame.new(9, 5.5, 0)
	stub.play(40)
	stub.play(30)
	stub.resign(GoBoard.BLACK)
	t.ok(not _has(GoReview.findings(stub, GoBoard.BLACK, 8), "nothing_broke"),
		"a resignation gets no consolation prize")


## Findings are ranked by what they cost, not by an ad-hoc per-detector scalar.
static func _test_cost_ranking(t: TestKit) -> void:
	t.section("review: ranked by what it cost")
	var all: Array[Dictionary] = [
		GoReview.finding("self_atari", 5, PackedByteArray(), PackedInt32Array(), 90.0),
		GoReview.finding("atari_ignored", 9, PackedByteArray(), PackedInt32Array(), 1.0),
	]
	all[0]["cost"] = 2.0
	all[1]["cost"] = 30.0
	var picked := GoReview.select(all, 30)
	t.eq(picked.size(), 2, "both survive the gate at 1d")
	t.eq(str(picked[0]["kind"]), "atari_ignored",
		"the expensive one leads, whatever its severity")

	# With no evaluator, cost is zero everywhere and the old severity ordering
	# is exactly what is left -- so a review still works without a curve.
	var unpriced: Array[Dictionary] = [
		GoReview.finding("self_atari", 5, PackedByteArray(), PackedInt32Array(), 90.0),
		GoReview.finding("atari_ignored", 9, PackedByteArray(), PackedInt32Array(), 1.0),
	]
	t.eq(str(GoReview.select(unpriced, 30)[0]["kind"]), "self_atari",
		"and severity still decides when nothing has been priced")


## Every finding carries the count of how many times its kind happened, so the
## review can say "four times" rather than saying the same sentence four times.
static func _test_instances(t: TestKit) -> void:
	t.section("review: one mistake, made four times")
	var all: Array[Dictionary] = [
		GoReview.finding("self_atari", 1, PackedByteArray(), PackedInt32Array(), 1.0),
		GoReview.finding("self_atari", 4, PackedByteArray(), PackedInt32Array(), 1.0),
		GoReview.finding("self_atari", 7, PackedByteArray(), PackedInt32Array(), 1.0),
		GoReview.finding("good_save", 2, PackedByteArray(), PackedInt32Array(), 1.0, true),
	]
	GoReview.tally(all)
	t.eq(int(all[0]["instances"]), 3, "three of a kind are counted")
	t.eq(int(all[3]["instances"]), 1, "and a lone finding is one")

	# A detector that folded its own instances together keeps its own count.
	var folded: Array[Dictionary] = [
		GoReview.finding("dead_group_fed", 3, PackedByteArray(),
			PackedInt32Array(), 1.0, false, {}, 6),
	]
	GoReview.tally(folded)
	t.eq(int(folded[0]["instances"]), 6, "a folded count is not overwritten")


## Every kind names the lesson that covers it, and every id it names exists.
static func _test_concepts(t: TestKit) -> void:
	t.section("review: what to go and study")
	for kind in GoReview.CONCEPT:
		var id := str(GoReview.CONCEPT[kind])
		t.ok(GoReview.MIN_STRENGTH.has(kind), "%s is a real finding kind" % kind)
		t.ok(FileAccess.file_exists("res://data/lessons/%s.json" % id),
			"%s points at a lesson that exists (%s)" % [kind, id])
	for kind in ["good_capture", "good_save", "atari_answered", "nothing_broke"]:
		t.ok(str(GoReview.finding(kind, 0, PackedByteArray(),
			PackedInt32Array(), 1.0, true)["concept"]) == "",
			"%s recommends no homework" % kind)


# --- across games ------------------------------------------------------------

static func _record(kinds: Dictionary) -> Dictionary:
	return {"npc_id": "kesh", "player_won": false,
		"review_summary": {"kinds": kinds, "worst": "", "swing_move": -1}}


## The thing a single review cannot do: notice that this is the fifth time.
static func _test_history(t: TestKit) -> void:
	t.section("review: what you keep doing")
	var records := [
		_record({"atari_ignored": 2, "good_capture": 1}),
		_record({"atari_ignored": 1}),
		_record({"atari_ignored": 3, "self_atari": 1}),
	]
	var h := GoReviewHistory.habits(records)
	t.eq(int(h["games"]), 3, "three reviewed games")
	t.eq(int(h["kinds"]["atari_ignored"]), 6, "instances add up across games")
	t.eq(str(h["worst"]), "atari_ignored", "and the commonest is the habit")
	t.ok(GoReviewHistory.is_habit(h, "atari_ignored"), "three or more is a habit")
	t.ok(not GoReviewHistory.is_habit(h, "self_atari"), "one is an afternoon")
	t.eq(GoReviewHistory.recommend(h), "liberties", "pointing at the right lesson")

	# A streak is games in a row, counting back from the most recent. One clean
	# game ends it -- otherwise a habit broken last week is still a habit.
	t.eq(GoReviewHistory.again_for(h, "atari_ignored"), "That is 3 games running.",
		"and it is said out loud")
	var broken := [
		_record({"own_eye_filled": 1}),
		_record({"own_eye_filled": 1}),
		_record({"own_eye_filled": 1}),
		_record({"good_save": 1}),
	]
	var hb := GoReviewHistory.habits(broken)
	t.eq(int(hb["streak"].get("own_eye_filled", 0)), 0,
		"a clean game ends the streak")
	t.ok(GoReviewHistory.is_habit(hb, "own_eye_filled"),
		"though it is still remembered as a habit")

	# Games nobody reviewed must not dilute anything.
	var mixed := [{"npc_id": "wren"}, _record({"self_atari": 1}), {"npc_id": "pip"}]
	t.eq(int(GoReviewHistory.habits(mixed)["games"]), 1,
		"an unreviewed game is not counted")
	t.eq(GoReviewHistory.habits([])["worst"], "", "and no games is not a habit")
	t.eq(GoReviewHistory.recommend(GoReviewHistory.habits([])), "",
		"with nothing to recommend")


## Handing the position back: the mistake you just made, as a problem to solve.
static func _test_from_finding(t: TestKit) -> void:
	t.section("review: play it again")
	var g := _play(t, [0, 1, 40, 60])
	var f := _find(_raw(g), "atari_ignored")
	t.ok(not f.is_empty(), "there is a finding to hand back")
	if not f.is_empty():
		var p := GoPuzzleData.from_finding(f, 9, "Count your liberties.")
		t.ok(p != null, "a finding with a single right move becomes a puzzle")
		if p != null:
			t.eq(p.size, 9, "on the same board")
			t.eq(p.solutions.size(), 1, "with one answer")
			t.ok(p.is_solution(int(f["detail"]["liberty"])),
				"and the answer is the move that was there")
			t.eq(p.explanation, "Count your liberties.", "carrying the takeaway")
			t.ok(p.make_game() != null, "and it builds a real game")

	# Praise is not a problem, and neither is a description of the whole game.
	var praise := GoReview.finding("good_capture", 3, PackedByteArray(),
		PackedInt32Array(), 1.0, true)
	t.eq(GoPuzzleData.from_finding(praise, 9), null, "praise has no answer")
	var swing := GoReview.finding("big_swing", 3, PackedByteArray(),
		PackedInt32Array(), 1.0, false, {"points": 20})
	t.eq(GoPuzzleData.from_finding(swing, 9), null,
		"and neither has where the game turned")
