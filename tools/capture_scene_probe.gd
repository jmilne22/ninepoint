## Launch the real match scene with both installed and deliberately absent engine
## paths. A variant must bypass preparation/fallback, not merely pass a factory test.
extends SceneTree

var failed := false


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    for missing in [false, true]:
        var profile := load("res://data/opponents/pip_capture.tres").duplicate() as OpponentProfile
        # A stale or custom GTP profile must still obey its first-capture objective.
        profile.engine = "gtp"
        if missing:
            profile.gtp_command = "/missing-capture-engine"
            profile.gtp_model_path = "/missing-capture-model"
        var request := MatchRequest.new()
        request.profile = profile
        request.context_id = "pip_capture"
        request.npc_id = "pip"
        request.opponent_name = "Pip Arnesen"
        request.opponent_rank = "18k"
        request.unrated = true
        root.get_node("MatchBridge").pending_request = request
        var scene: Control = load("res://src/go_ui/go_match.tscn").instantiate()
        root.add_child(scene)
        current_scene = scene
        var deadline := Time.get_ticks_msec() + 5000
        while not scene.is_player_turn_ready() and Time.get_ticks_msec() < deadline:
            for child in scene.get_children():
                if child is BoardBrief:
                    child._input(MouseActions.event("cancel"))
            await process_frame
        _check(scene.is_player_turn_ready(), "capture board opens without engine preparation")
        _check(scene.opponent is CaptureOpponent, "real scene uses capture policy, missing=%s" % missing)
        _check(root.get_node("KataGoService")._leases.is_empty(), "capture creates no KataGo lease")
        if scene.is_player_turn_ready():
            scene._mouse_action(&"go_pass")
            deadline = Time.get_ticks_msec() + 3000
            while scene.phase != scene.Phase.DONE and Time.get_ticks_msec() < deadline:
                await process_frame
            _check(scene.phase == scene.Phase.DONE, "passes reach the real result screen")
            _check(scene.game.result.get("practice_ended", false), "no counting or fabricated winner")
        scene.queue_free()
        await process_frame
        current_scene = null
    print("Capture scene gate: %s" % ("FAILED" if failed else "passed"))
    quit(1 if failed else 0)


func _check(ok: bool, message: String) -> void:
    print("  %s %s" % ["ok" if ok else "FAIL", message])
    failed = failed or not ok
