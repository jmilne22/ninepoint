## Full production match, both actors and populated board; no engine or mouse driver.
## DISPLAY=:0 godot --path . --resolution 1536x864 --disable-vsync --script res://tools/table_performance.gd
## Use an isolated XDG_DATA_HOME; OUT optionally receives representative screenshots.
extends SceneTree

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    root.get_node("SaveSystem").session_only = true
    BoardControls.shown = true
    var t := TestKit.new()
    for cap in [30, 60, 144, 0]:
        Engine.max_fps = cap
        var request := MatchRequest.new()
        request.npc_id = "wren"
        request.profile = load(OpponentProfile.path_for("wren")).duplicate()
        request.profile.engine = "random"
        request.profile.board_size = 19
        request.profile.colour_rule = "player_black"
        request.opponent_name = "Wren Calloway"
        request.opponent_rank = request.profile.rank_label
        request.unrated = true
        root.get_node("MatchBridge").pending_request = request
        var scene: Control = load(MatchViewRoute.TABLE).instantiate()
        root.add_child(scene)
        current_scene = scene
        var deadline := Time.get_ticks_msec() + 10000
        while not scene.is_player_turn_ready() and Time.get_ticks_msec() < deadline:
            for child in scene.get_children():
                if child is BoardBrief: child._input(MouseActions.event("cancel"))
            await process_frame
        t.ok(scene.is_player_turn_ready(), "production match reached the player's turn")
        t.eq(Engine.max_fps, cap, "production match preserves frame cap")
        for y in range(1, 18, 2):
            for x in range(1, 18, 2):
                if x == 17 and y == 17: continue
                t.ok(scene.game.play(y * 19 + x), "populated fixture is legal")
        scene.board_view.set_game(scene.game)
        scene._refresh()
        await create_timer(1).timeout
        var samples: Array[float] = []
        var started := Time.get_ticks_usec()
        var previous := started
        while Time.get_ticks_usec() - started < 4000000:
            await process_frame
            var now := Time.get_ticks_usec()
            samples.append((now - previous) / 1000.0)
            previous = now
        samples.sort()
        var elapsed := (previous - started) / 1000000.0
        print("TABLE PERFORMANCE ", JSON.stringify({"cap": cap, "frames": samples.size(),
            "seconds": elapsed, "fps": samples.size() / elapsed,
            "p95_ms": samples[int(samples.size() * .95)], "window": str(root.size),
            "renderer": RenderingServer.get_video_adapter_name()}))
        if not OS.get_environment("OUT").is_empty():
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(OS.get_environment("OUT").path_join("table_%d.png" % cap))
        scene.queue_free()
        await process_frame
        current_scene = null
        t.eq(Engine.max_fps, cap, "match exit preserves frame cap")
    print("TABLE PERFORMANCE GATE: ", t.report())
    root.get_node("Audio").stop_music(0)
    root.get_node("Audio").stop_ambience(0)
    await create_timer(.4).timeout
    quit(0 if t.failed == 0 else 1)
