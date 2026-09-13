## Disposable launcher for the approved presentation.
extends "res://src/go_ui/table_scene/match.gd"
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
    var who := "wren"
    var board_size := 9
    if not showcase and not checking:
        for arg in OS.get_cmdline_user_args():
            if arg.begins_with("--opponent="): who = arg.get_slice("=", 1)
            if arg.begins_with("--board="): board_size = int(arg.get_slice("=", 1))
    var path := OpponentProfile.path_for(who, board_size)
    if not ResourceLoader.exists(path) or not ResourceLoader.exists("res://art/table_scene/%s.glb" % who):
        push_error("No cast match profile for %s on %d lines" % [who, board_size])
        get_tree().quit(2)
        return
    trial_request.profile = load(path).duplicate()
    # The trial pins colours for composition; strength, stopping and komi remain the chosen profile's.
    trial_request.profile.colour_rule = "player_black"
    trial_request.npc_id = who
    trial_request.opponent_name = trial_request.profile.display_name
    trial_request.opponent_rank = trial_request.profile.rank_label
    trial_request.context_id = "table_scene_trial"
    trial_request.unrated = true
    trial_request.player_strength = trial_request.profile.strength()
    MatchBridge.pending_request = trial_request
    super._ready()

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
        "Resign this casual game to %s?\n\nThis isolated trial does not save a record.\n\n[R] resign   [Esc] keep playing" % request.opponent_name, 288)

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
