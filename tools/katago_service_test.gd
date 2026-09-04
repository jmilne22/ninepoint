## Process/service integration gate. Uses the real package for lease lifecycle
## coverage and tiny local GTP fixtures for failures that KataGo cannot emit.
extends SceneTree

var _failed := false
var _service: Node


func _initialize() -> void:
    var profile := load("res://tools/fixtures/katago_trial_9x9.tres") as OpponentProfile
    _service = root.get_node_or_null("KataGoService")
    _check(_service != null, "KataGo service autoload is present")
    if _service == null:
        quit(1)
        return
    await _prewarm_reuse_and_cleanup(profile)
    await _failure_paths(profile)
    print("KataGo service gate: %s" % ("FAILED" if _failed else "passed"))
    quit(1 if _failed else 0)


func _prewarm_reuse_and_cleanup(profile: OpponentProfile) -> void:
    _service.cancel(profile)
    _service.prewarm(profile)
    _service.prewarm(profile)
    var deadline := Time.get_ticks_msec() + 15000
    while _service.state_for(profile) == "warming" and Time.get_ticks_msec() < deadline:
        await process_frame
    _check(_service.state_for(profile) == "ready", "prewarm reaches ready exactly once")
    var leased := _service.take_ready(profile) as GtpOpponent
    _check(leased != null and leased.engine_started, "ready lease is reusable by the match")
    _check(_service.take_ready(profile) == null, "a lease cannot be handed to two scenes")
    if leased != null:
        leased.shutdown()
        _check(leased.shutdown_complete, "scene return shuts down its lease")
    _service.prewarm(profile)
    await process_frame
    _service.cancel(profile)
    _check(_service.state_for(profile) == "none", "cancelled preparation leaves no service lease")


func _failure_paths(base: OpponentProfile) -> void:
    var missing := base.duplicate(true) as OpponentProfile
    missing.gtp_command = "/nonexistent/katago"
    var missing_game := GoGame.new(9, 5.5)
    var safe := OpponentFactory.create(missing, missing_game)
    _check(safe is HeuristicOpponent, "missing package falls back before a match starts")

    var malformed := base.duplicate(true) as OpponentProfile
    malformed.gtp_command = "res://tools/fixtures/gtp_malformed.sh"
    malformed.gtp_time_per_move = 0.2
    var malformed_game := GoGame.new(9, 5.5)
    malformed_game.play_xy(4, 4)
    var corrupt := OpponentFactory.create(malformed, malformed_game) as GtpOpponent
    var corrupt_move: Dictionary = await corrupt.choose_move(malformed_game)
    _check(corrupt.fallback_used and malformed_game.is_legal(int(corrupt_move.get("point", -1))),
        "malformed GTP move uses a legal local fallback")
    corrupt.shutdown()

    var rejected := base.duplicate(true) as OpponentProfile
    rejected.gtp_command = "res://tools/fixtures/gtp_reject.sh"
    var rejected_engine := GtpOpponent.new()
    rejected_engine.setup(rejected, GoGame.new(9, 5.5))
    _check(not await rejected_engine.prewarm(), "rejected GTP warmup fails cleanly")
    rejected_engine.shutdown()

    var handicap := base.duplicate(true) as OpponentProfile
    # These are protocol/setup correctness tests; the calibration gate owns the
    # release two-second latency budget.
    handicap.gtp_time_per_move = 10.0
    var handicap_game := GoGame.new(9, 0.5, 2)
    var engine := OpponentFactory.create(handicap, handicap_game) as GtpOpponent
    _check(await engine.prewarm(), "handicap engine prepares before the match")
    var handicap_move: Dictionary = await engine.choose_move(handicap_game)
    print("  measurement: warmed handicap reply %dms" % engine.last_move_ms)
    _check(not engine.fallback_used and str(handicap_move.get("type", "")) == "move"
        and handicap_game.is_legal(int(handicap_move.get("point", -1))), "handicap setup synchronises")
    engine.shutdown()

    var capture := base.duplicate(true) as OpponentProfile
    capture.board_size = 7
    capture.gtp_time_per_move = 10.0
    var capture_game := GoGame.new(7, 5.5)
    capture_game.capture_goal = 1
    capture_game.play_xy(3, 3)
    var capture_engine := OpponentFactory.create(capture, capture_game) as GtpOpponent
    _check(await capture_engine.prewarm(), "Capture Go engine prepares before the match")
    var capture_move: Dictionary = await capture_engine.choose_move(capture_game)
    print("  measurement: warmed Capture Go reply %dms" % capture_engine.last_move_ms)
    _check(not capture_engine.fallback_used and str(capture_move.get("type", "")) == "move"
        and capture_game.is_legal(int(capture_move.get("point", -1))), "Capture Go board synchronises")
    capture_engine.shutdown()


func _check(condition: bool, message: String) -> void:
    if condition:
        print("  ok: %s" % message)
    else:
        _failed = true
        printerr("  FAIL: %s" % message)
