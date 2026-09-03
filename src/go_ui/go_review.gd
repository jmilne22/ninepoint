## The review: somebody stronger than you, pointing at your own board.
##
## Structurally this is the lesson runner with the positions coming from the
## game that was just played instead of from a JSON file, which is why it looks
## like one. GoReview finds the moments; GoReviewVoice supplies the words; this
## draws them and waits for a keypress.
extends Control

var _payload: Dictionary = {}
var _voice: GoReviewVoice
var _findings: Array = []
var _shown: Array = []
var _index: int = 0
var _awaiting := false
var _finished := false

var board_view: GoBoardView
var _name_label: Label
var _rank_label: Label
var _progress: Label
var _body: Label
var _takeaway: Label
var _caption: Label
var _replay := GoReplay.new()
var _try_again: GoPuzzleData = null
var _hints: Label
var _portrait: TextureRect


func _ready() -> void:
	_payload = MatchBridge.pending_review
	if _payload.is_empty():
		MatchBridge.finish_review()
		return
	_findings = _payload.get("findings", [])
	_voice = GoReviewVoice.load_voice(str(_payload.get("npc_id", "")))
	_replay.bind(_payload)
	_voice.habits = _payload.get("habits", {})
	# Back to the quiet bed. A boss theme driving on underneath the review would
	# be arguing with what the review is for: the game is over and this is the
	# part where you think about it.
	Audio.play_music(MatchMusic.DEFAULT)
	_build_ui()
	set_process_unhandled_input(true)
	set_process(true)
	_run()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#2a2633")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	board_view = GoBoardView.new()
	board_view.position = Vector2(8, 24)
	board_view.size = Vector2(168, 168)
	board_view.interactive = false
	add_child(board_view)

	var panel := UiKit.panel(self, Rect2(184, 8, 192, 184))

	_portrait = TextureRect.new()
	_portrait.position = Vector2(10, 8)
	_portrait.size = Vector2(64, 64)
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_child(_portrait)
	var portrait_texture = _payload.get("portrait", null)
	_portrait.visible = portrait_texture != null
	if portrait_texture != null:
		var at := AtlasTexture.new()
		at.atlas = portrait_texture
		at.region = Rect2(0, 0, 64, 64)
		_portrait.texture = at

	_name_label = UiKit.label(panel, Vector2(80, 14), 102, UiKit.GOLD)
	_name_label.text = str(_payload.get("name", ""))
	_rank_label = UiKit.label(panel, Vector2(80, 28), 102, UiKit.INK_FAINT)
	_rank_label.text = str(_payload.get("rank", ""))
	_progress = UiKit.label(panel, Vector2(80, 44), 102, UiKit.INK_FAINT)
	_body = UiKit.label(panel, Vector2(10, 62), 172, UiKit.INK, 76)
	# The rule behind the finding, under it and in the teal the board uses for
	# the move that was there. Different colour because it is a different kind
	# of sentence: what Kesh says is about this game, this is the part you are
	# meant to take to the next one.
	_takeaway = UiKit.label(panel, Vector2(10, 142), 172, UiKit.TEAL, 38)
	# Under the board, where the board is: which move you are looking at.
	_caption = UiKit.label(self, Vector2(8, 196), 172, UiKit.INK_FAINT)
	_hints = UiKit.label(self, Vector2(188, 196), 190, UiKit.INK_FAINT)
	_hints.text = "[Space] on  [<>] step  [Esc] skip"


# --- the review itself -------------------------------------------------------

func _run() -> void:
	_show_cells(_payload.get("final_cells", PackedByteArray()), PackedInt32Array())
	var qualified := bool(_payload.get("qualified", true))

	# Somebody weaker than you has nothing to teach you about your own game, and
	# the honest ones say so rather than inventing something. Wren's whole
	# character is in that refusal.
	#
	# But refusing used to end the review on the spot, which got much worse when
	# rank started moving: a reviewer who could talk to you last week goes silent
	# the moment you pass them, and the review gets rarer exactly as you improve.
	# So the gate is split. Criticism needs somebody stronger. Praise, and where
	# the game turned, do not -- a 20 kyu can see that you took four stones, and
	# saying so costs them no authority they do not have.
	if not qualified:
		for line in _voice.unqualified:
			await _say(line)
			if _stopped():
				return
	else:
		for line in _voice.intro:
			await _say(line)
			if _stopped():
				return

	_shown = _speakable(qualified)
	var shown := _shown
	for i in shown.size():
		_index = i
		var f: Dictionary = shown[i]
		_replay.focus(int(f["move_index"]))
		_redraw_replay()
		# "1 of 1" is not progress, it is noise.
		_progress.text = "%d of %d" % [i + 1, shown.size()] if shown.size() > 1 else ""
		_takeaway.text = _voice.takeaway(f)
		await _say(_voice.speak(f, _board_for(f), _seed()))
		if _stopped():
			return
	_progress.text = ""
	_takeaway.text = ""
	_index = -1

	for line in _voice.outro:
		await _say(line)
		if _stopped():
			return

	# The most useful thing this screen does: hand the position back. A beginner
	# is never more ready to solve a problem than a minute after failing it. It
	# comes after the goodbye rather than before, so the offer is the last thing
	# on screen -- otherwise the outro reads as "off you go" while the hint line
	# is still saying "play it again".
	_try_again = _offer()
	if _try_again != null:
		_replay.focus(int(_try_again.get_meta("move_index", 0)))
		_redraw_replay()
		await _say("One more time, with that position. Your move.")
		if _stopped():
			return
	_done()


## The first finding that makes a sound problem, or null. Praise has no answer,
## and neither has "this is where the game turned" -- most findings are
## descriptions rather than questions, and from_finding() says so by refusing.
func _offer() -> GoPuzzleData:
	for f in _shown:
		var p := GoPuzzleData.from_finding(f, int(_payload.get("size", 9)),
			_voice.takeaway(f))
		if p != null:
			p.set_meta("move_index", int(f["move_index"]))
			return p
	return null


## Which line variant this voice uses. Keyed on games played as well as the
## move, so a player who ignores atari six games running hears six sentences
## rather than one sentence six times.
func _seed() -> int:
	return int(_payload.get("habits", {}).get("games", 0))


## What this person is entitled to say. Everything, if they are stronger than
## you; otherwise only the things that are true without authority -- what you
## did well, and where the game turned, which accuses nobody of anything.
func _speakable(qualified: bool) -> Array:
	if qualified:
		return _findings
	var out: Array = []
	for f in _findings:
		if bool(f.get("good", false)) or str(f.get("kind", "")) == "big_swing":
			out.append(f)
	return out


## Prose is paginated rather than clipped: the words are the product here, so
## nothing may run off the bottom of the panel.
func _say(text: String) -> void:
	if text == "":
		return
	var pages := UiKit.paginate(text, int(_body.size.x), int(_body.size.y))
	for i in pages.size():
		if _stopped():
			return
		_body.text = pages[i]
		_hints.text = "[Space] more" if i < pages.size() - 1 \
			else ("[Space] no  [X] play it again" if _try_again != null \
			else "[Space] on  [<>] step  [Esc] skip")
		await _wait()


func _show_cells(cells: PackedByteArray, highlight: PackedInt32Array,
		last_point: int = -1) -> void:
	var size := int(_payload.get("size", 9))
	if cells.size() != size * size:
		return
	var g := GoGame.new(size, 0.5, 0)
	g.set_position(cells, GoBoard.BLACK)
	# set_position() leaves the move list empty, so GoBoardView -- which draws
	# its last-move marker from game.last_move() -- silently draws nothing, and a
	# replay with no indication of what was just played is worse than no replay.
	# Seeding one move is the whole fix. See MILESTONES on the blank board view.
	if last_point >= 0:
		g.moves.append({"color": int(cells[last_point]), "point": last_point,
			"captured": PackedInt32Array(), "label": g.board.label(last_point)})
	board_view.set_game(g)
	board_view.highlight = highlight
	board_view.mark_point = -1
	board_view.queue_redraw()


## Redraws whatever the replay cursor is on, keeping the current finding's rings.
func _redraw_replay() -> void:
	var rings := PackedInt32Array()
	var mark := -1
	if _index >= 0 and _index < _shown.size() and _replay.cursor == _replay.anchor:
		var f: Dictionary = _shown[_index]
		rings = f["points"]
		var detail: Dictionary = f.get("detail", {})
		mark = int(detail.get("save", detail.get("liberty", -1)))
	_show_cells(_replay.cells(), rings, _replay.last_point())
	board_view.mark_point = mark
	_caption.text = _replay.caption()


func _board_for(f: Dictionary) -> GoBoard:
	var b := GoBoard.new(int(_payload.get("size", 9)))
	b.cells = f["cells"]
	return b


func _wait() -> void:
	_awaiting = true
	while _awaiting and not _stopped():
		await get_tree().process_frame


func _stopped() -> bool:
	return _finished or not is_inside_tree()


func _done() -> void:
	if _finished:
		return
	_finished = true
	_awaiting = false
	# Not awaited: finishing the review frees this scene, and awaiting our own
	# destruction leaves a dead coroutine behind. See the same note in go_match.
	MatchBridge.finish_review()


func _process(delta: float) -> void:
	if _finished or not _replay.available():
		return
	var dir := 0
	if Input.is_action_pressed("move_right"):
		dir = 1
	elif Input.is_action_pressed("move_left"):
		dir = -1
	if _replay.scrub(dir, delta):
		_redraw_replay()


func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	# Arrows step through the game itself. "How did we get here" is the question
	# a beginner is actually asking, and the answer was already in memory.
	if event.is_action_pressed("move_right") or event.is_action_pressed("move_left"):
		get_viewport().set_input_as_handled()
		if _replay.step(1 if event.is_action_pressed("move_right") else -1):
			_redraw_replay()
		return
	if event.is_action_pressed("interact"):
		Audio.play("ui_confirm")
		_awaiting = false
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if _try_again != null:
			_take_the_puzzle()
			return
		_done()


func _take_the_puzzle() -> void:
	if _finished:
		return
	_finished = true
	_awaiting = false
	Audio.play("ui_confirm")
	MatchBridge.finish_review(_try_again)
