## Opt-in ART-10R presentation. The ordinary match controller remains authoritative.
extends "res://src/go_ui/go_match.gd"

var surface: TableSceneBoardSurface
var player_actor: TableSceneActor
var wren_actor: TableSceneActor
var subtitle: Label
var black_info: Label
var white_info: Label
var status: Label
var showcase := false
var checking := false
var closing := false

func _ready() -> void:
    get_tree().auto_accept_quit = false
    showcase = OS.get_cmdline_user_args().has("--showcase") or OS.get_cmdline_user_args().has("--still")
    checking = OS.get_cmdline_user_args().has("--verify-table_scene")
    get_window().content_scale_size = Vector2i(768, 432)
    get_window().size = Vector2i(1536, 864)
    GameState.player_name = "Ro"
    var trial_request := MatchRequest.new()
    trial_request.profile = load(OpponentProfile.path_for("wren", 9)).duplicate()
    # The trial pins colours for composition; strength, stopping and komi are Wren's.
    trial_request.profile.colour_rule = "player_black"
    trial_request.npc_id = "wren"
    trial_request.opponent_name = "Wren Calloway"
    trial_request.opponent_rank = "20k"
    trial_request.context_id = "table_scene_trial"
    trial_request.unrated = true
    trial_request.player_strength = GoRank.from_string("20k")
    MatchBridge.pending_request = trial_request
    super._ready()

func _build_ui() -> void:
    super._build_ui()
    get_child(0).hide()
    _panel.hide()
    surface = TableSceneBoardSurface.new()
    surface.position = Vector2(0, 64)
    add_child(surface)
    surface.setup(board_view)
    player_actor = _actor("player", Vector2(-34, 88))
    wren_actor = _actor("wren", Vector2(532, 88))
    _strip(Rect2(0, 0, 768, 63), Color("202e2d"))
    _strip(Rect2(0, 7, 282, 27), Color("eee4cc"))
    _strip(Rect2(458, 7, 310, 27), Color("eee4cc"))
    _strip(Rect2(0, 34, 282, 3), Color("a97b43"))
    _strip(Rect2(458, 34, 310, 3), Color("a97b43"))
    _strip(Rect2(0, 62, 768, 2), Color("c5ac72"))
    _strip(Rect2(0, 364, 768, 68), Color("202e2d"))
    _strip(Rect2(0, 363, 768, 1), Color("c5ac72"))
    _text("RO", Vector2(22, 10), 210, 18, Color("24332f"))
    _text("WREN CALLOWAY", Vector2(470, 10), 280, 18, Color("24332f"))
    black_info = _text("", Vector2(22, 40), 250, 9, Color("d9c69e"))
    white_info = _text("", Vector2(470, 40), 285, 9, Color("d9c69e"))
    _text("THE KETTLE", Vector2(304, 12), 180, 9, Color("d9c69e"))
    status = _text("A table for two", Vector2(286, 34), 205, 9, Color("efe5cc"))
    subtitle = _text("", Vector2(24, 378), 720, 9, Color("efe5cc"))
    subtitle.size.y = 24
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _text("Arrows / mouse: choose     Space / click: place", Vector2(24, 413), 430, 9, Color("afc2b9"))
    _mouse_controls._bar.position = Vector2(492, 407)
    _mouse_controls._bar.scale = Vector2.ONE
    _navigation.position = Vector2(373, 350)
    _navigation.size = Vector2(100, 11)
    _navigation.z_index = 5
    _overlay.scale = Vector2(2, 2)
    _overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    _overlay.size = Vector2(384, 216)
    _overlay.z_index = 90
    _mouse_controls._bar.z_index = 95
    child_entered_tree.connect(_fit_auxiliary)

func _fit_auxiliary(child: Node) -> void:
    if child is BoardBrief or child is HandicapHelp or child is NigiriCeremony:
        child.scale = Vector2(2, 2)
        child.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
        child.size = Vector2(384, 216)

func _actor(who: String, at: Vector2) -> TableSceneActor:
    var actor := TableSceneActor.new()
    actor.position = at
    actor.size = Vector2(270, 286)
    add_child(actor)
    actor.setup(who)
    return actor

func _strip(rect: Rect2, colour: Color) -> void:
    var strip := ColorRect.new()
    strip.position = rect.position
    strip.size = rect.size
    strip.color = colour
    strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(strip)

func _text(value: String, at: Vector2, width: int, font_size: int, colour: Color) -> Label:
    var label := _label(self, at, width, font_size, colour.to_html())
    label.text = value
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _run() -> void:
    if showcase or checking:
        var route := TableSceneShowcase.new()
        add_child(route)
        route.run(self, checking)
    else:
        super._run()
        if OS.get_cmdline_user_args().has("--live-check"):
            var probe := TableSceneLiveProbe.new()
            add_child(probe)
            probe.run(self)

func _think_delay() -> float:
    return 1.2

func _announce_move(move: Dictionary) -> void:
    super._announce_move(move)
    if move.is_empty() or int(move.get("point", -1)) < 0:
        return
    var by_player := int(move.get("color", 0)) == player_color
    var actor := player_actor if by_player else wren_actor
    var other := wren_actor if by_player else player_actor
    actor.perform("place", 1.6)
    if not move.get("captured", PackedInt32Array()).is_empty():
        other.perform("surprise", 2.0)
        _capture_relief(actor)

func _capture_relief(actor: TableSceneActor) -> void:
    await get_tree().create_timer(0.8).timeout
    if is_instance_valid(actor) and not closing:
        actor.perform("pleased", 2.0)

func _set_message(value: String) -> void:
    super._set_message(value)
    if subtitle != null:
        subtitle.text = value

func _refresh() -> void:
    super._refresh()
    if status == null:
        return
    var ready := game != null and game.to_move == player_color
    player_actor.resting = "idle" if ready else "thinking"
    wren_actor.resting = "thinking" if ready == false else "idle"
    status.text = "Your move  /  Black" if ready else "Wren is thinking..."
    if phase == Phase.PREPARING:
        status.text = "Setting the table..."
    if phase == Phase.SCORING:
        status.text = "Counting together"
    if phase == Phase.DONE:
        status.text = "Thanks for the game"
    var black_captures: int = game.captures[GoBoard.BLACK] if game != null else 0
    var white_captures: int = game.captures[GoBoard.WHITE] if game != null else 0
    black_info.text = "UNRANKED  /  BLACK  /  Captured %d" % black_captures
    white_info.text = "20k  /  WHITE  /  Captured %d  /  Komi 5.5" % white_captures

func _update_scoring_preview() -> void:
    super._update_scoring_preview()
    var score := GoScoring.score(game.board, board_view.dead, game.captures, game.komi)
    _set_message("Black %s   /   White %s (including komi).  Click a group to mark or restore it.  H: help." % [_num(score["black"]), _num(score["white"])])

func _finish() -> void:
    # Reuse the match's scoring/result card, then end this disposable session.
    # The overridden dismissal quits before the world bridge records a result.
    if game.state != GoGame.State.FINISHED:
        game.finish_with_score(GoScoring.score(game.board, board_view.dead, game.captures, game.komi))
    var winner := int(game.result.get("winner", 0))
    player_actor.perform("pleased" if winner == player_color else "concern", 999)
    wren_actor.perform("pleased" if winner != player_color else "concern", 999)
    super._finish()
    UiKit.fit_card(_card, _overlay_text, _overlay_text.text, 184)
    _refresh()

func _input_done(event: InputEvent) -> bool:
    if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        close_trial()
        return true
    return false

func _input_preparing(event: InputEvent) -> bool:
    if event.is_action_pressed("cancel"):
        close_trial()
        return true
    return super._input_preparing(event)

func _prompt_resign() -> void:
    super._prompt_resign()
    UiKit.fit_card(_card, _overlay_text,
        "Resign this casual game to Wren?\n\nThis isolated trial does not save a record.\n\n[R] resign   [Esc] keep playing", 288)

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        close_trial()

func close_trial(exit_code: int = 0) -> void:
    if closing:
        return
    closing = true
    # Let the audio mixer release playback before destroying the disposable tree.
    Audio.stop_music(0.1)
    await get_tree().create_timer(0.4).timeout
    get_tree().quit(exit_code)
