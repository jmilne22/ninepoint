## Production scene/bridge acceptance. Positions are legally replayed fixtures;
## ordinary campaign and teaching routes separately exercise the shipped engines.
class_name TableAdoptionProbe
extends RefCounted

static func run(tree: SceneTree, shot: Callable) -> void:
    var t := TestKit.new()
    var state := tree.root.get_node("GameState")
    var bridge := tree.root.get_node("MatchBridge")
    var pilot := tree.root.get_node("Autopilot")
    await _check_world_resolution(tree, shot, t)
    for spec in [["pip", 7], ["tomas", 13], ["marguerite", 19], ["joos", 9]]:
        var npc := str(spec[0])
        var n := int(spec[1])
        var request := MatchRequest.new()
        request.npc_id = npc
        request.profile = load(OpponentProfile.path_for(npc, 13 if n == 13 else 9)).duplicate()
        request.profile.board_size = n
        request.profile.engine = "random"
        request.profile.colour_rule = "player_black"
        request.opponent_name = request.profile.display_name
        request.opponent_rank = request.profile.rank_label
        request.unrated = true
        request.context_id = "table_acceptance_fixture"
        var records: int = state.match_records.size()
        var rank: int = state.rank_strength
        var before_resolution := tree.root.content_scale_size
        bridge.start_match(request, state.return_position)
        await ExperienceProbe.perform(tree, {"experience":"setup"}, shot)
        var scene := tree.current_scene as TableSceneMatch
        t.ok(scene != null, npc + " reaches shared match scene")
        if scene == null: break
        t.eq(tree.root.content_scale_size, Vector2i(768,432), "match canvas is sharp")
        t.eq(scene.request, request, "original match request is preserved")
        t.eq(scene.game.size(), n, "requested board size retained")
        t.eq(scene.wren_actor.identity, npc, "opponent identity retained")
        # A legal replay, never hand-assigned board cells. It leaves Black to move.
        for point in TableSceneShowcase.MOVES if n >= 9 else [16,32,3,2,10,40]:
            var p := int(point)
            if n > 9: p = (p / 9 + (n-9)/2) * n + p % 9 + (n-9)/2
            t.ok(scene.game.play(p), "fixture move is legal")
        scene.board_view.set_game(scene.game)
        scene._refresh()
        scene._sync_mouse()
        await tree.create_timer(0.7).timeout
        await shot.call(npc + "_%d_board" % n)
        await BoardPlayProbe.perform(tree, {"click_legal": [n-1,0]})
        await pilot._wait_for_match_player_turn(30)
        await shot.call(npc + "_reply")
        if n == 19:
            await BoardPlayProbe.perform(tree, {"hover": [15,15]})
            await BoardPlayProbe.perform(tree, {"key": "V"})
            await BoardPlayProbe.perform(tree, {"hover": [14,14], "zoomed": true})
            await shot.call("nineteen_close_view")
            await BoardPlayProbe.perform(tree, {"key": "V"})
        scene.game.pass_turn()
        scene.game.pass_turn()
        scene._answered(true)
        for frame in 10: await tree.process_frame
        t.ok(scene.is_counting(), "two legal passes reach counting")
        await BoardPlayProbe.perform(tree, {"toggle_group_mouse": true}, shot)
        await shot.call(npc + "_count")
        await BoardPlayProbe.tap(tree, "go_pass")
        await tree.create_timer(0.4).timeout
        await shot.call(npc + "_result")
        t.eq(state.match_records.size(), records, "result waits for dismissal")
        await BoardPlayProbe.tap(tree, "interact")
        await pilot._wait_for_world(30)
        var deadline := Time.get_ticks_msec() + 15000
        while Time.get_ticks_msec() < deadline:
            var box := tree.root.find_child("DialogueBox", true, false) as DialogueBox
            var flow := tree.root.find_child("PostMatchReview", true, false) as PostMatchReview
            if flow != null and flow._awaiting == &"review":
                await BoardPlayProbe.click_button(tree, "review_no")
            elif box != null and box.running:
                await BoardPlayProbe.tap(tree, "cancel" if box._awaiting_choice else "interact")
            else: break
            await tree.create_timer(0.2).timeout
        t.eq(state.match_records.size(), records + 1, "bridge records exactly once")
        t.eq(state.rank_strength, rank, "fixture remains unrated")
        t.eq(tree.root.content_scale_size, before_resolution, "world resolution restored")
        t.eq(str(state.match_records[-1].get("npc_id", "")), npc, "saved result belongs to opponent")
    print("TABLE ADOPTION: ", t.report())
    if t.failed > 0: tree.quit(1)

static func _check_world_resolution(tree: SceneTree, shot: Callable, t: TestKit) -> void:
    var world: ProjectedWorld
    for child in tree.current_scene.get_children():
        if child is ProjectedWorld: world = child
    t.ok(world != null, "production world has a 3D presentation")
    if world == null: return
    var original := tree.root.size
    for dimensions in [Vector2i(768,432), Vector2i(1920,1080), Vector2i(1600,1200)]:
        tree.root.size = dimensions
        for frame in 4: await tree.process_frame
        var expected := Vector2i(dimensions.x, roundi(dimensions.x * 9.0 / 16.0))
        t.eq(world.view.size, expected, "world render target follows displayed pixels")
        t.ok((world.picture.scale * Vector2(world.view.size)).is_equal_approx(Vector2(384,216)),
            "resizing preserves the logical world footprint")
        await shot.call("world_%dx%d" % [dimensions.x, dimensions.y])
    tree.root.size = original
    for frame in 4: await tree.process_frame
