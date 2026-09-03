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
var _index: int = 0
var _awaiting := false
var _finished := false

var board_view: GoBoardView
var _name_label: Label
var _rank_label: Label
var _progress: Label
var _body: Label
var _hints: Label
var _portrait: TextureRect


func _ready() -> void:
	_payload = MatchBridge.pending_review
	if _payload.is_empty():
		MatchBridge.finish_review()
		return
	_findings = _payload.get("findings", [])
	_voice = GoReviewVoice.load_voice(str(_payload.get("npc_id", "")))
	_build_ui()
	set_process_unhandled_input(true)
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
	_body = UiKit.label(panel, Vector2(10, 80), 172, UiKit.INK, 96)
	_hints = UiKit.label(self, Vector2(188, 196), 190, UiKit.INK_FAINT)
	_hints.text = "[Space] go on   [Esc] skip"


# --- the review itself -------------------------------------------------------

func _run() -> void:
	_show_cells(_payload.get("final_cells", PackedByteArray()), PackedInt32Array())

	# Somebody weaker than you has nothing to teach you about your own game, and
	# the honest ones say so rather than inventing something. Wren's whole
	# character is in that refusal.
	if not bool(_payload.get("qualified", true)):
		for line in _voice.unqualified:
			await _say(line)
			if _stopped():
				return
		_done()
		return

	for line in _voice.intro:
		await _say(line)
		if _stopped():
			return
	for i in _findings.size():
		_index = i
		var f: Dictionary = _findings[i]
		_show_cells(f["cells"], f["points"])
		# The move that was there, picked out from the group it would have saved.
		var detail: Dictionary = f.get("detail", {})
		board_view.mark_point = int(detail.get("save", detail.get("liberty", -1)))
		# "1 of 1" is not progress, it is noise.
		_progress.text = "%d of %d" % [i + 1, _findings.size()] \
			if _findings.size() > 1 else ""
		await _say(_voice.speak(f, _board_for(f)))
		if _stopped():
			return
	_progress.text = ""
	for line in _voice.outro:
		await _say(line)
		if _stopped():
			return
	_done()


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
			else "[Space] go on   [Esc] skip"
		await _wait()


func _show_cells(cells: PackedByteArray, highlight: PackedInt32Array) -> void:
	var size := int(_payload.get("size", 9))
	if cells.size() != size * size:
		return
	var g := GoGame.new(size, 0.5, 0)
	g.set_position(cells, GoBoard.BLACK)
	board_view.set_game(g)
	board_view.highlight = highlight
	board_view.mark_point = -1
	board_view.queue_redraw()


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


func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("interact"):
		Audio.play("ui_confirm")
		_awaiting = false
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_done()
