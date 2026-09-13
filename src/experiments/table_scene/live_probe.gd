## Rendered acceptance against the selected cast engine, with ordinary match input.
class_name TableSceneLiveProbe
extends Node

func run(scene: Control) -> void:
    var t := TestKit.new()
    t.section("table_scene live " + scene.request.opponent_name)
    for turn in 2:
        if not await _ready_turn(scene):
            push_error("TableScene live probe timed out waiting for the opponent")
            get_tree().quit(1)
            return
        var chosen := 20 if turn == 0 else 24
        if not scene.game.is_legal(chosen):
            chosen = scene.game.legal_moves()[0]
        var before: int = scene.game.move_number()
        scene.board_view.focus_point(chosen)
        scene._unhandled_input(MouseActions.event(&"interact"))
        await get_tree().process_frame
        if not await _ready_turn(scene):
            push_error("The opponent did not return a live reply")
            get_tree().quit(1)
            return
        t.eq(scene.game.move_number(), before + 2, "keyboard placement receives a live engine reply")
    t.ok(scene.opponent is GtpOpponent, "trial uses the selected GTP profile")
    if scene.opponent is GtpOpponent:
        t.ok(scene.opponent.engine_started, "KataGo started")
        t.ok(not scene.opponent.fallback_used, "opponent did not use fallback")
        t.eq(scene.opponent.legal_reply_count, 2, "both engine replies were legal")
    await get_tree().create_timer(0.6).timeout
    var output := OS.get_environment("OUT")
    DirAccess.make_dir_recursive_absolute(output)
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(output.path_join("live_%s.png" % scene.request.npc_id))
    scene._unhandled_input(MouseActions.event(&"go_resign"))
    scene._unhandled_input(MouseActions.event(&"cancel"))
    scene._sync_mouse()
    t.ok(scene.is_player_turn_ready(), "cancel resignation resumes the live game")
    scene._unhandled_input(MouseActions.event(&"go_resign"))
    scene._unhandled_input(MouseActions.event(&"go_resign"))
    await get_tree().create_timer(0.5).timeout
    t.ok(scene.result_sent and scene.phase == scene.Phase.DONE, "live resignation reaches the real result card")
    t.eq(GameState.match_records.size(), 0, "live trial does not record a result")
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(output.path_join("live_result.png"))
    print(t.report())
    scene.close_trial(0 if t.failed == 0 else 1)

func _ready_turn(scene: Control) -> bool:
    var deadline := Time.get_ticks_msec() + 45000
    while Time.get_ticks_msec() < deadline:
        if scene.is_player_turn_ready():
            return true
        await get_tree().process_frame
    return false
