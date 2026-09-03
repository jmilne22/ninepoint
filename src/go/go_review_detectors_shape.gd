## Detectors that need to see the whole game rather than one exchange.
##
## The others in this family read a move and its neighbours: a group had one
## liberty, a stone was added, the group came off. These ask questions that only
## have answers at the scale of a game -- where it turned, whether it was over,
## whether stones were still being spent after it was over -- and so they all
## depend on the GoEvaluator's curve rather than on the board alone.
##
## Same conservatism as everywhere else in the review: each one is arithmetic on
## the rules, and where the arithmetic is ambiguous the detector says nothing.
class_name GoReviewDetectorsShape
extends RefCounted

## A game is "decided" once one side leads by this share of the board. A third
## of a 9x9 is 27 points, which at beginner strength is genuinely unrecoverable
## and is roughly where an honest opponent would offer you the resignation.
const DECIDED_SHARE := 3.0

## Stones spent after the game was already decided, before it is worth saying
## anything. Two or three is playing it out; a dozen is not knowing it is over.
const POINTLESS_MOVES := 4

## Points of your own territory you have to fill before it is worth mentioning.
const WASTED_POINTS := 3

## The smallest gain worth calling somebody's best moment. Deliberately tiny:
## this is the last-resort compliment, and its job is to exist.
const GOOD_MOMENT := 1.0


static func run_all(ctx: Dictionary, out: Array) -> void:
	big_swing(ctx, out)
	best_moment(ctx, out)
	dead_group_fed(ctx, out)
	filled_own_territory(ctx, out)
	cut_ignored(ctx, out)
	should_have_passed(ctx, out)


## Where the game got away from you.
##
## The largest fall from any high-water mark to any later low -- a maximum
## drawdown, not the single worst move. Those are different questions and this
## is the one a beginner asks: a game lost over fifteen quiet moves has no worst
## move and still has a turn, and being shown the turn is the difference between
## "I lost again" and "I lose when big groups die".
##
## Not a mistake, and it does not accuse anybody of anything. It is the spine
## the other findings hang off, which is why it names the finding that happened
## inside its window as the cause where one did.
static func big_swing(ctx: Dictionary, out: Array) -> void:
	var ev: GoEvaluator = ctx.get("evaluator", null)
	if ev == null or not ev.available():
		return
	var c := ev.curve()
	var swing := GoProgress.worst_swing(c)
	if swing.is_empty():
		return
	var from_k: int = int(swing["from"])
	var to_k: int = int(swing["to"])
	var positions: Array = ctx["positions"]
	out.append(GoReview.finding("big_swing", from_k,
		positions[clampi(to_k, 0, positions.size() - 1)], PackedInt32Array(),
		float(swing["points"]), false,
		{"points": int(roundf(float(swing["points"]))), "until": to_k + 1,
		 # price() reads died_at as "where the consequence landed", which for a
		 # swing is the bottom of it rather than a fixed lookahead.
		 "died_at": maxi(to_k - 1, from_k)}))


## Stones added to a group that was already lost.
##
## Distinct from ladder_failed, which is about running and being chased: this is
## adding to a group that stays on one liberty however many stones go into it.
## Beginners do it constantly and it is the most expensive habit they have,
## because every stone spent is a prisoner handed over as well as a move lost.
static func dead_group_fed(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	var fed := {}                # group key -> {at: int, stones: int}
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or int(m["point"]) < 0:
			continue
		if m["captured"].size() > 0:
			continue             # a move that takes something is never feeding
		var before := GoReviewReplay.board_at(ctx, k)
		var joined := false
		for nb in before.neighbours(int(m["point"])):
			if before.get_idx(nb) == colour \
					and before.chain_at(nb)["liberties"].size() == 1:
				joined = true
				break
		if not joined:
			continue
		# Still on one liberty after the stone went in: it bought nothing.
		var after := GoReviewReplay.board_at(ctx, k + 1)
		var ch := after.chain_at(int(m["point"]))
		if ch["liberties"].size() != 1:
			continue
		var fell := GoReviewReplay.captured_at(ctx, k + 1, ch["stones"])
		if fell < 0:
			continue             # it lived; the arithmetic was wrong, not the player
		# Keyed on the capture, not on the stones. The chain grows by one every
		# time it is fed, so a set-of-stones key makes four separate findings of
		# one stone each and the count never accumulates -- the same mistake M15
		# found in two detectors that identified a group by stones[0]. To the
		# person who lost it, a group that grew between the atari and the capture
		# is one group, and everything taken in one move died together.
		var key := str(fell)
		var seen: Dictionary = fed.get(key,
			{"at": k, "stones": 0, "died": fell, "group": ch["stones"]})
		seen["stones"] = int(seen["stones"]) + 1
		seen["group"] = ch["stones"]        # the chain as it last stood
		fed[key] = seen
	for key in fed:
		var rec: Dictionary = fed[key]
		if int(rec["stones"]) < 2:
			continue
		var gone: int = int(rec["died"])
		# Shown as it stood one move from coming off: the whole group, including
		# every stone that was spent on it after it was already lost.
		out.append(GoReview.finding("dead_group_fed", int(rec["at"]),
			ctx["positions"][gone], rec["group"],
			float(rec["stones"]) + 2.0, false,
			{"stones": int(rec["stones"]), "died_at": gone},
			int(rec["stones"])))


## Playing inside your own finished territory.
##
## Under Japanese scoring every one of these is a point handed back, and it is
## the single most common way a beginner loses a game they had already won. Only
## counted in the last third, when the region really was settled, and never when
## there was a group of yours in trouble next to it -- answering an atari inside
## your own area is correct and looks identical from the outside.
static func filled_own_territory(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	var start := int(float(moves.size()) * 2.0 / 3.0)
	var first := -1
	var count := 0
	for k in range(start, moves.size()):
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or int(m["point"]) < 0:
			continue
		if m["captured"].size() > 0:
			continue
		var before := GoReviewReplay.board_at(ctx, k)
		if GoScoring.territory_map(before)[int(m["point"])] != colour:
			continue
		var urgent := false
		for nb in before.neighbours(int(m["point"])):
			if before.get_idx(nb) == colour \
					and before.chain_at(nb)["liberties"].size() <= 2:
				urgent = true
				break
		if urgent:
			continue
		if first < 0:
			first = k
		count += 1
	if count < WASTED_POINTS:
		return
	out.append(GoReview.finding("filled_own_territory", first,
		ctx["positions"][first + 1],
		PackedInt32Array([int(moves[first]["point"])]),
		float(count), false, {"stones": count}, count))


## The opponent played between two of your groups, and you let them.
##
## A cut is only a cut if the two halves were genuinely relying on that one
## point to connect, so this asks the board rather than guessing at shape: two
## distinct friendly chains touching an empty point, an enemy stone on it, and
## the halves still distinct afterwards. It only reports when one half then
## died, because a cut you got away with taught nobody anything.
static func cut_ignored(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) == colour or int(m["point"]) < 0:
			continue
		if k + 1 >= moves.size():
			continue
		var p: int = int(m["point"])
		var before := GoReviewReplay.board_at(ctx, k)
		var halves: Array = []
		var keys := {}
		for nb in before.neighbours(p):
			if before.get_idx(nb) != colour:
				continue
			var ch := before.chain_at(nb)
			var key := GoReviewReplay.group_key(ch["stones"])
			if keys.has(key):
				continue
			keys[key] = true
			halves.append(ch["stones"])
		if halves.size() < 2:
			continue
		var reply: Dictionary = moves[k + 1]
		if int(reply["color"]) != colour or int(reply["point"]) < 0:
			continue
		# Answering next to the cutting stone counts as answering the cut.
		if GoReviewReplay.intersects(PackedInt32Array(before.neighbours(p)),
				PackedInt32Array([int(reply["point"])])):
			continue
		for stones in halves:
			var died := GoReviewReplay.captured_at(ctx, k + 1, stones)
			if died < 0:
				continue
			var pts := PackedInt32Array(stones)
			pts.append(p)
			out.append(GoReview.finding("cut_ignored", k, ctx["positions"][k + 1],
				pts, float(stones.size()) + 2.0, false,
				{"stones": stones.size(), "played": int(reply["point"]),
				 "liberty": p, "died_at": died}))
			break


## Still playing after it was over.
##
## The counterpart to the AI's weak endgame: once the board is decided, a
## beginner who does not know how to stop keeps placing stones and gives the
## points back. Reported at the move the game stopped being in doubt, which is
## the move they should have counted at.
static func should_have_passed(ctx: Dictionary, out: Array) -> void:
	var ev: GoEvaluator = ctx.get("evaluator", null)
	if ev == null or not ev.available():
		return
	var c := ev.curve()
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	var size: int = int(ctx["size"])
	var decided := float(size * size) / DECIDED_SHARE
	for k in c.size():
		if absf(c[k]) < decided:
			continue
		var spent := 0
		for j in range(k, moves.size()):
			if int(moves[j]["color"]) == colour and int(moves[j]["point"]) >= 0:
				spent += 1
		if spent < POINTLESS_MOVES:
			return
		var lost := c[k] - c[c.size() - 1]
		if lost < float(WASTED_POINTS):
			return
		out.append(GoReview.finding("should_have_passed", k,
			ctx["positions"][c.size() - 1], PackedInt32Array(),
			lost, false,
			{"stones": spent, "points": int(roundf(lost)),
			 "died_at": c.size() - 2}))
		return


## The best thing the player did all game, measured rather than recognised.
##
## The other three compliments need something to have happened -- a capture, a
## rescue, an atari answered. A game can contain none of those and still not be
## a clean game, and that combination used to break the one rule the review is
## not allowed to break: 44 of 60 measured games opened on a criticism, because
## nothing_broke only covers games where nothing went wrong and these were games
## where plenty did.
##
## So this is the floor. Every game has a move after which the player was better
## off than before it, and saying which one it was is both true and useful --
## it is the only line in the review that points at something to do more of
## rather than something to stop doing.
static func best_moment(ctx: Dictionary, out: Array) -> void:
	var ev: GoEvaluator = ctx.get("evaluator", null)
	if ev == null or not ev.available():
		return
	# Same guard as the other consolation prize: below this there was no game to
	# have played a best move in, and MatchBridge skips the review entirely when
	# nothing was found -- which is how somebody who sits down and immediately
	# resigns is not walked through one.
	var positions: Array = ctx["positions"]
	if positions.size() <= GoReview.ENOUGH_GAME:
		return
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	var best := -1
	var gain := 0.0
	for k in moves.size():
		if int(moves[k]["color"]) != colour or int(moves[k]["point"]) < 0:
			continue
		# Two plies: the move and the answer to it, so a gain that the opponent
		# immediately took back is not credited to the player.
		var won: float = ev.lead_after(k + 2) - ev.lead_after(k)
		if won > gain:
			gain = won
			best = k
	if best < 0 or gain < GOOD_MOMENT:
		return
	# Flat severity on purpose. A capture or a rescue is a better thing to open
	# with than an arithmetic high point, so this must never outrank them; it is
	# here for the games that have neither.
	out.append(GoReview.finding("best_moment", best, ctx["positions"][best + 1],
		PackedInt32Array([int(moves[best]["point"])]), 0.5, true,
		{"points": int(roundf(gain))}))
