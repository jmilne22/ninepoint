## Session/async regression gate. All writes use the caller's isolated user data.
extends SceneTree
var kit := TestKit.new()

class SlowOpponent extends GoOpponent:
    var thinking := false
    var cancelled := false
    func choose_move(game: GoGame) -> Dictionary:
        thinking = true
        var point := game.legal_moves()[0]
        await (Engine.get_main_loop() as SceneTree).create_timer(0.6).timeout
        return point_move(point)
    func shutdown() -> void:
        cancelled = true

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    var state := root.get_node("GameState")
    var session := root.get_node("PracticeSession")
    var bridge := root.get_node("MatchBridge")
    var service := root.get_node("MatchReviewService")
    var saves := root.get_node("SaveSystem")
    state.set_rank("12k")
    state.set_flag("practice_isolation_sentinel", true)
    for slot in range(1, 4): saves.save_game(slot)
    var before: Dictionary = state.to_dict().duplicate(true)
    var bytes: Array = []
    for slot in range(1, 4): bytes.append(FileAccess.get_file_as_bytes(saves.path_for(slot)))
    session.active = true
    session.settings = PracticeSettings.new()
    session.settings.mode = "teaching"
    session.start_game()
    # Control the opponent at this boundary; no network inference belongs in
    # a race-condition test, and no production request can select this fixture.
    bridge.activity_context.request.profile.engine = "heuristic"
    bridge.activity_context.request.teaching_enabled = false
    await _ready_turn()
    var scene: Control = current_scene
    var slow := SlowOpponent.new()
    slow.setup(scene.profile, scene.game)
    scene.opponent.shutdown()
    scene.opponent = slow
    scene._on_point_activated(scene.game.board.idx(2, 2))
    var deadline := Time.get_ticks_msec() + 2000
    while not slow.thinking and Time.get_ticks_msec() < deadline: await process_frame
    kit.ok(slow.thinking, "fixture caught AI thinking")
    scene._practice_action(&"undo")
    bridge.activity_context.request.profile.engine = "heuristic"
    bridge.activity_context.request.teaching_enabled = false
    await _ready_turn()
    scene = current_scene
    kit.eq(scene.game.moves.size(), 0, "undo while AI thinking restores player decision")
    kit.ok(slow.cancelled, "undo shuts down old opponent")
    await create_timer(0.8).timeout
    kit.eq(scene.game.moves.size(), 0, "stale reply cannot land in resumed game")
    # Reach counting by legal passes, then retain marks across process-style reload.
    var game := GoGame.new(9, 5.5)
    game.play_xy(2, 2)
    game.play_xy(6, 6)
    game.pass_turn()
    game.pass_turn()
    session.checkpoint(game, GoBoard.BLACK, {20: true}, false)
    await scene._stop_turns()
    session.start_game(true)
    bridge.activity_context.request.profile.engine = "heuristic"
    bridge.activity_context.request.teaching_enabled = false
    await _counting()
    scene = current_scene
    kit.ok(scene.board_view.dead.has(20), "counting marks restored")
    scene._practice_action(&"undo")
    bridge.activity_context.request.profile.engine = "heuristic"
    bridge.activity_context.request.teaching_enabled = false
    await _ready_turn()
    scene = current_scene
    kit.eq(scene.game.moves.size(), 2, "undo from counting removes both passes")
    kit.eq(scene.game.state, GoGame.State.PLAYING, "undo counting returns to play")
    # Missing opponent has an explicit, actionable fallback card.
    await scene._stop_turns()
    session.start_game()
    bridge.activity_context.request.profile.gtp_command = "res://missing-practice-engine"
    bridge.activity_context.request.teaching_enabled = false
    var dialog := await _choice()
    kit.ok(dialog.text.contains("cannot represent the selected rank"), "fallback does not claim selected strength")
    dialog.choose(1)
    await _hub()
    kit.ok(not session.store.data.active.is_empty(), "fallback return preserves game")
    # Practice completion and analysis failure cannot enter campaign records.
    var result := MatchResult.new()
    result.context_id = "standalone_practice"
    result.unrated = true
    result.sgf = "(;GM[1]FF[4]SZ[9]KM[5.5];B[cc];W[gg])"
    session.finish_match(result)
    await _hub()
    var count: int = session.store.data.records.size()
    session.finish_match(result)
    await _hub()
    kit.eq(session.store.data.records.size(), count, "duplicate result callbacks record once")
    KataGoAnalysis.command_override = "res://missing-practice-review"
    session.request_review(session.selected_record)
    kit.eq(session.store.data.reviews[str(session.selected_record)].availability, "failed", "missing analysis records explicit failure")
    KataGoAnalysis.command_override = ""
    var value: ActivityContext = session.context()
    value.set_flag("lesson_first_game_rules_done", true)
    value.set_flag("capture_1_solved", true)
    kit.ok(session.store.data.completed.lesson_first_game_rules_done, "practice owns learning completion")
    kit.eq(state.to_dict(), before, "practice leaves all campaign state unchanged")
    for slot in range(1, 4): kit.eq(FileAccess.get_file_as_bytes(saves.path_for(slot)), bytes[slot - 1], "campaign slot bytes unchanged")
    service.cancel()
    session.active = false
    bridge.activity_context = null
    if current_scene != null:
        current_scene.queue_free()
        await process_frame
    for failure in kit.failures: printerr(failure)
    print("PRACTICE SESSION: %d passed, %d failed" % [kit.passed, kit.failed])
    quit(1 if kit.failed else 0)

func _ready_turn() -> void:
    var deadline := Time.get_ticks_msec() + 10000
    while Time.get_ticks_msec() < deadline:
        if current_scene != null and current_scene.name == "PracticeMatch" and current_scene.is_player_turn_ready() and not root.get_node("SceneRouter").is_busy(): return
        await process_frame
    kit.ok(false, "practice player turn ready")

func _counting() -> void:
    var deadline := Time.get_ticks_msec() + 10000
    while Time.get_ticks_msec() < deadline:
        if current_scene != null and current_scene.name == "PracticeMatch" and current_scene.is_counting() and not root.get_node("SceneRouter").is_busy(): return
        await process_frame
    kit.ok(false, "practice counting ready")

func _choice() -> TeachingChoice:
    var deadline := Time.get_ticks_msec() + 10000
    while Time.get_ticks_msec() < deadline:
        if current_scene != null:
            for child in current_scene.get_children():
                if child is TeachingChoice and not child._closed:
                    await process_frame
                    return child
        await process_frame
    return null

func _hub() -> void:
    var deadline := Time.get_ticks_msec() + 10000
    while Time.get_ticks_msec() < deadline:
        if current_scene != null and current_scene.name == "PracticeHub" and not root.get_node("SceneRouter").is_busy(): return
        await process_frame
    kit.ok(false, "practice hub ready")
