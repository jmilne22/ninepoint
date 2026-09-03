## GoProgress: the running count the review prices its findings against.
##
## Every number here is checkable by hand on a small board, which is the point:
## if a review says a mistake cost eleven points, the eleven has to come from
## somewhere a person can verify.
class_name GoProgressTests
extends RefCounted


static func run(t: TestKit) -> void:
	_test_settled_lead(t)
	_test_curve(t)
	_test_cost_of(t)
	_test_worst_swing(t)
	_test_standing(t)


static func _test_settled_lead(t: TestKit) -> void:
	t.section("progress: counting the board")

	# An empty board is worth nothing to Black and komi to White.
	var empty := GoBoard.new(9)
	t.eq(GoProgress.settled_lead(empty, GoBoard.BLACK, 5.5), -5.5,
		"an empty board is komi behind for Black")
	t.eq(GoProgress.settled_lead(empty, GoBoard.WHITE, 5.5), 5.5,
		"and komi ahead for White")

	# Countable by hand, which is the whole point of this evaluator:
	#   Black  5 stones + the 2x2 corner it sealed       =  9
	#   White  7 stones + the 9 points down the right    = 16
	# so Black is seven behind. Nothing here is an estimate.
	var b := GoBoard.from_ascii("""
		..XO.
		..XO.
		XXXO.
		OOOO.
		.....
	""")
	var lead := GoProgress.settled_lead(b, GoBoard.BLACK, 0.0)
	t.eq(lead, -7.0, "stones plus the region only you enclose")
	t.eq(GoProgress.settled_lead(b, GoBoard.WHITE, 0.0), 7.0,
		"and it is the same number from the other side")

	# The trap this module is written around. With one colour on the board every
	# empty point is bordered by that colour alone, so whole-board scoring hands
	# it the lot -- true, useless, and it used to make the curve read +80 on move
	# one and 0 on move two, i.e. an invented collapse in every game.
	var lone := GoBoard.from_ascii("""
		X....
		.....
		.....
		.....
		.....
	""")
	t.eq(GoProgress.settled_lead(lone, GoBoard.BLACK, 0.0), 1.0,
		"an unenclosed region is not territory, however few colours touch it")

	# And the same on a real board: one stone is one point, not eighty.
	var first := GoBoard.new(9)
	first.set_idx(40, GoBoard.BLACK)
	t.eq(GoProgress.settled_lead(first, GoBoard.BLACK, 0.0), 1.0,
		"move one is worth one stone")


static func _test_curve(t: TestKit) -> void:
	t.section("progress: the curve")
	var g := GoGame.new(9, 5.5, 0)
	for p in [40, 30, 41, 31, 42, 32]:
		g.play(p)
	var ctx := {"size": g.size(), "colour": GoBoard.BLACK,
		"enemy": GoBoard.WHITE, "moves": g.moves,
		"positions": GoReview.positions_of(g)}
	var c := GoProgress.compute(ctx, g.komi)
	t.eq(c.size(), g.moves.size() + 1, "one reading per position, including the start")
	t.eq(c[0], -5.5, "starting from komi")

	# The instance side of the same thing, which is what detectors are handed.
	var ev := GoProgress.new()
	t.ok(not ev.available(), "an evaluator says so before it is prepared")
	ev.prepare(ctx, g.komi)
	t.ok(ev.available(), "and after")
	t.eq(ev.lead_after(0), c[0], "lead_after indexes the curve")
	t.eq(ev.lead_after(999), c[c.size() - 1], "and clamps rather than crashing")

	# A game that cannot be replayed has no curve and must not fake one.
	var bare := GoProgress.new()
	t.eq(bare.lead_after(3), 0.0, "an unavailable evaluator answers zero")


static func _test_cost_of(t: TestKit) -> void:
	t.section("progress: what a mistake cost")
	var c := PackedFloat32Array([0.0, 4.0, 4.0, -6.0, -6.0])
	t.eq(GoProgress.cost_of(c, 1, 3), 10.0, "the fall between two positions")
	t.eq(GoProgress.cost_of(c, 3, 1), 0.0, "never negative time")
	t.eq(GoProgress.cost_of(c, 0, 1), 0.0, "gaining ground costs nothing")
	t.eq(GoProgress.cost_of(c, 1, 99), 10.0, "and the window clamps to the game")
	t.eq(GoProgress.cost_of(PackedFloat32Array(), 0, 3), 0.0, "no curve, no cost")


static func _test_worst_swing(t: TestKit) -> void:
	t.section("progress: where the game turned")

	# Two falls: 3 points early and 12 late. The late one is the game, even
	# though the early one comes first and the low point is not the end.
	var c := PackedFloat32Array([0.0, 3.0, 0.0, 5.0, -7.0, -4.0])
	var s := GoProgress.worst_swing(c, 6.0)
	t.ok(not s.is_empty(), "a real collapse is found")
	t.eq(int(s["from"]), 3, "measured from the high-water mark")
	t.eq(int(s["to"]), 4, "to the low after it")
	t.eq(float(s["points"]), 12.0, "and priced at the whole fall")

	# A game that never gave anything away has no turn in it, and inventing one
	# would be the review's worst failure mode: a mistake that did not happen.
	t.ok(GoProgress.worst_swing(PackedFloat32Array([0.0, 1.0, 2.0, 3.0]), 6.0).is_empty(),
		"a game only ever won has no swing")
	t.ok(GoProgress.worst_swing(PackedFloat32Array([0.0, -2.0, 0.0]), 6.0).is_empty(),
		"and a small wobble is below the threshold")
	t.ok(GoProgress.worst_swing(PackedFloat32Array([4.0]), 6.0).is_empty(),
		"one position is not a curve")


static func _test_standing(t: TestKit) -> void:
	t.section("progress: ahead, behind or close")
	t.eq(GoProgress.standing(9.0), "ahead", "clearly ahead")
	t.eq(GoProgress.standing(-9.0), "behind", "clearly behind")
	t.eq(GoProgress.standing(1.0), "close", "within the margin is close")
	t.eq(GoProgress.standing(-1.0), "close", "on either side of it")
