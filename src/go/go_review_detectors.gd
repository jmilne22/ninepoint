## The detectors GoReview runs. Split out because the conventions cap a script
## at ~300 lines and because these are the part most likely to grow: every new
## thing a teacher can notice is one more static function here.
##
## Each detector appends findings of the shape:
##   {kind, move_index, cells, points, severity, good, detail}
## where `cells` is the board to draw and `points` is what to ring on it.
##
## All of them are deliberately conservative. A review that invents a mistake is
## far worse than one that misses it -- the whole point is that the teacher has
## actually read the game, and one fabricated claim undoes every true one.
class_name GoReviewDetectors
extends RefCounted


static func run_all(ctx: Dictionary, out: Array) -> void:
	var reported := {}
	good_capture(ctx, out)
	good_save(ctx, out)
	atari_ignored(ctx, out, reported)
	died_savable(ctx, out, reported)
	own_eye_filled(ctx, out)
	self_atari(ctx, out)
	capture_missed(ctx, out)
	first_line_early(ctx, out)
	ladder_failed(ctx, out)


# --- the mistakes ------------------------------------------------------------

## A group the opponent put in atari, that the player answered somewhere else,
## and that died for it. The first thing anybody learns and the last thing
## anybody stops doing.
static func atari_ignored(ctx: Dictionary, out: Array, reported: Dictionary) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) == colour or int(m["point"]) < 0:
			continue
		if k + 1 >= moves.size():
			continue
		var reply: Dictionary = moves[k + 1]
		if int(reply["color"]) != colour or int(reply["point"]) < 0:
			continue
		# A reply that captured something may well have been the answer.
		if reply["captured"].size() > 0:
			continue
		var before := GoReview.board_at(ctx, k)
		var after := GoReview.board_at(ctx, k + 1)
		# Only a group next to the stone just played can have been put in atari
		# by it, which is also why this does not scan the whole board.
		for nb in after.neighbours(int(m["point"])):
			if after.get_idx(nb) != colour:
				continue
			var ch := after.chain_at(nb)
			if ch["liberties"].size() != 1:
				continue
			var stones: PackedInt32Array = ch["stones"]
			if GoReview.already_reported(reported, stones):
				continue
			# If it was already in atari, the opponent did not create the
			# problem and the player has been told about it once already.
			# The chain may have grown since, so ask about a stone that was
			# actually on the board then rather than about stones[0].
			var was := GoReview.representative(before, stones, colour)
			if was >= 0 and before.chain_at(was)["liberties"].size() == 1:
				continue
			var liberty: int = ch["liberties"][0]
			if int(reply["point"]) == liberty:
				continue        # they answered
			var died := GoReview.captured_at(ctx, k + 1, stones)
			if died < 0:
				continue        # it survived; no harm done
			GoReview.mark_group(reported, stones)
			var pts := PackedInt32Array(stones)
			pts.append(liberty)
			out.append(GoReview.finding("atari_ignored", k, ctx["positions"][k + 1], pts,
				float(stones.size()) + 3.0, false,
				{"stones": stones.size(), "liberty": liberty,
				 "played": int(reply["point"]), "died_at": died}))


## A group that died when a move existed that would have saved it. Distinct
## from atari_ignored: here the player did answer, and answered wrongly.
static func died_savable(ctx: Dictionary, out: Array, reported: Dictionary) -> void:
	var colour: int = int(ctx["colour"])
	var enemy: int = int(ctx["enemy"])
	var moves: Array = ctx["moves"]
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) != enemy or m["captured"].is_empty():
			continue
		var stones: PackedInt32Array = m["captured"]
		if stones.size() < 2:
			continue
		if GoReview.already_reported(reported, stones):
			continue
		var j := k - 1
		while j >= 0 and int(moves[j]["color"]) != colour:
			j -= 1
		if j < 0:
			continue
		var before := GoReview.board_at(ctx, j)
		var rep := GoReview.representative(before, stones, colour)
		if rep < 0:
			continue
		var ch := before.chain_at(rep)
		if ch["liberties"].size() != 1:
			continue
		var liberty: int = ch["liberties"][0]
		if int(moves[j]["point"]) == liberty:
			continue        # they did play there; it simply was not enough
		var probe := GoReview.mutable_at(ctx, j)
		probe.place(liberty, colour)
		if probe.chain_at(liberty)["liberties"].size() < 2:
			continue        # there was no save; dying was not a mistake
		GoReview.mark_group(reported, stones)
		var pts := PackedInt32Array(ch["stones"])
		pts.append(liberty)
		out.append(GoReview.finding("died_savable", j, ctx["positions"][j], pts,
			float(stones.size()) + 1.0, false,
			{"stones": stones.size(), "save": liberty,
			 "played": int(moves[j]["point"])}))


## Filling in one's own eye. Almost always a beginner throwing away a life.
static func own_eye_filled(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or int(m["point"]) < 0:
			continue
		if m["captured"].size() > 0:
			continue
		var p: int = int(m["point"])
		var before := GoReview.board_at(ctx, k)
		if not before.is_eye_like(p, colour):
			continue
		# Filling an eye to connect a group that was about to die is not a
		# mistake, it is the only move. Only say anything when nothing was at
		# stake -- the eye point is itself a liberty, hence 2 rather than 1.
		var urgent := false
		for nb in before.neighbours(p):
			if before.get_idx(nb) == colour \
					and before.chain_at(nb)["liberties"].size() <= 2:
				urgent = true
				break
		if urgent:
			continue
		out.append(GoReview.finding("own_eye_filled", k, ctx["positions"][k],
			PackedInt32Array([p]), 5.0))


## Playing a group of your own down to one liberty, for nothing.
static func self_atari(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or int(m["point"]) < 0:
			continue
		if m["captured"].size() > 0:
			continue
		var after := GoReview.board_at(ctx, k + 1)
		var ch := after.chain_at(int(m["point"]))
		if ch["liberties"].size() != 1:
			continue
		# A lone stone on one liberty is often a throw-in and a real technique.
		# Two or more is the blunder this is looking for.
		if ch["stones"].size() < 2:
			continue
		out.append(GoReview.finding("self_atari", k, ctx["positions"][k + 1],
			ch["stones"], float(ch["stones"].size()) + 1.0, false,
			{"stones": ch["stones"].size()}))


## An enemy group sitting on one liberty that the player never took.
static func capture_missed(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var enemy: int = int(ctx["enemy"])
	var moves: Array = ctx["moves"]
	var seen := {}
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or int(m["point"]) < 0:
			continue
		var before := GoReview.board_at(ctx, k)
		for ch in before.all_chains():
			if int(ch["color"]) != enemy or ch["liberties"].size() != 1:
				continue
			# One-stone ataris are usually ko, where not taking is correct.
			if ch["stones"].size() < 2:
				continue
			var liberty: int = ch["liberties"][0]
			if int(m["point"]) == liberty:
				continue
			var key := GoReview.group_key(ch["stones"])
			if seen.has(key):
				continue
			if GoReview.captured_at(ctx, k, ch["stones"]) >= 0:
				continue        # it died in the end anyway
			seen[key] = true
			var pts := PackedInt32Array(ch["stones"])
			pts.append(liberty)
			out.append(GoReview.finding("capture_missed", k, ctx["positions"][k], pts,
				float(ch["stones"].size()), false,
				{"stones": ch["stones"].size(), "liberty": liberty}))


## Opening moves on the first line. Corner, side, centre -- the openings class
## teaches this by making you count the walls; here it is caught in the wild.
static func first_line_early(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var size: int = int(ctx["size"])
	var moves: Array = ctx["moves"]
	if size < 9:
		return
	for k in mini(moves.size(), 20):
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or int(m["point"]) < 0:
			continue
		if m["captured"].size() > 0:
			continue
		var p: int = int(m["point"])
		var x: int = p % size
		var y: int = p / size
		if mini(mini(x, y), mini(size - 1 - x, size - 1 - y)) != 0:
			continue
		out.append(GoReview.finding("first_line_early", k, ctx["positions"][k + 1],
			PackedInt32Array([p]), 2.0, false, {"move": k + 1}))


## Running from atari, again and again, and dying anyway. Pip does this in the
## park on purpose; the player does it by accident.
static func ladder_failed(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var enemy: int = int(ctx["enemy"])
	var moves: Array = ctx["moves"]
	var streak := 0
	var first := -1
	var running := PackedInt32Array()
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) == colour and int(m["point"]) >= 0:
			var before := GoReview.board_at(ctx, k)
			var ran := false
			for nb in before.neighbours(int(m["point"])):
				if before.get_idx(nb) == colour \
						and before.chain_at(nb)["liberties"].size() == 1:
					ran = true
					break
			if not ran:
				streak = 0
				continue
			if streak == 0:
				first = k
			streak += 1
			running = GoReview.board_at(ctx, k + 1).chain_at(int(m["point"]))["stones"]
		elif int(m["color"]) == enemy and streak >= 2 \
				and GoReview.intersects(m["captured"], running):
			out.append(GoReview.finding("ladder_failed", first, ctx["positions"][first],
				running, float(running.size()) + 2.0, false,
				{"stones": running.size(), "tries": streak}))
			streak = 0


# --- the things that went right ----------------------------------------------

## Three stones or more taken at once. A beginner remembers this for a week.
static func good_capture(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or m["captured"].size() < 3:
			continue
		var pts := PackedInt32Array(m["captured"])
		pts.append(int(m["point"]))
		out.append(GoReview.finding("good_capture", k, ctx["positions"][k], pts,
			float(m["captured"].size()), true,
			{"stones": m["captured"].size()}))


## A group taken off one liberty and out to safety, that then lived.
static func good_save(ctx: Dictionary, out: Array) -> void:
	var colour: int = int(ctx["colour"])
	var moves: Array = ctx["moves"]
	for k in moves.size():
		var m: Dictionary = moves[k]
		if int(m["color"]) != colour or int(m["point"]) < 0:
			continue
		var before := GoReview.board_at(ctx, k)
		var was_atari := false
		for nb in before.neighbours(int(m["point"])):
			if before.get_idx(nb) == colour \
					and before.chain_at(nb)["liberties"].size() == 1:
				was_atari = true
				break
		if not was_atari:
			continue
		var ch := GoReview.board_at(ctx, k + 1).chain_at(int(m["point"]))
		if ch["liberties"].size() < 3:
			continue
		if GoReview.captured_at(ctx, k + 1, ch["stones"]) >= 0:
			continue        # it died later after all
		out.append(GoReview.finding("good_save", k, ctx["positions"][k + 1],
			ch["stones"], float(ch["stones"].size()) + 1.0, true,
			{"stones": ch["stones"].size()}))
