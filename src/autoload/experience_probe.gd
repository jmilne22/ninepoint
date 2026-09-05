## State-aware play harness. Inert unless an autopilot route calls it.
class_name ExperienceProbe
extends RefCounted

static func press(tree: SceneTree, action: String) -> void:
    var event := InputEventAction.new()
    event.action = action
    event.pressed = true
    Input.parse_input_event(event)
    await tree.process_frame
    event = InputEventAction.new()
    event.action = action
    Input.parse_input_event(event)
    await tree.create_timer(0.2).timeout


static func set_action(action: String, pressed: bool) -> void:
    if pressed:
        Input.action_press(action)
    else:
        Input.action_release(action)

static func perform(tree: SceneTree, spec: Dictionary, shot: Callable) -> void:
    var mode := str(spec["experience"])
    var deadline := Time.get_ticks_msec() + int(float(spec.get("timeout", 60)) * 1000)
    var seen := {}
    while Time.get_ticks_msec() < deadline:
        var scene := tree.current_scene
        if scene == null:
            await tree.process_frame
            continue
        match mode:
            "run":
                if scene.get("map") != null and str(scene.map.id) == "ketelsteeg":
                    await run_probe(tree, scene, shot)
                    return
            "visit":
                var router := tree.root.get_node("SceneRouter")
                if not bool(spec.get("dispatched", false)) and not router.is_busy():
                    spec["dispatched"] = true
                    router.go_to_map(str(spec["map"]), str(spec.get("spawn", "")))
                elif scene.get("map") != null and str(scene.map.id) == str(spec["map"]) and not router.is_busy():
                    await tree.create_timer(2.0).timeout
                    return
            "opening":
                if scene.get("_field") != null:
                    var state := str(scene.get("_awaiting"))
                    if state == "name":
                        await shot.call("name_exchange")
                        await press(tree, "interact")
                        return
                    if state == "line":
                        await tree.create_timer(0.7).timeout
                        await shot.call("welcome_%s" % str(scene.get("_line")))
                        await press(tree, "interact")
            "map":
                if scene.get("map") != null and str(scene.map.id) == str(spec.get("map", "")):
                    await tree.create_timer(0.5).timeout
                    return
            "setup":
                if scene.has_method("is_player_turn_ready"):
                    if scene.is_player_turn_ready():
                        inspect_setup(scene)
                        return
                    for child in scene.get_children():
                        if child is HandicapHelp or child is BoardBrief:
                            var page := int(child.get("_page")) if child is HandicapHelp else int(child.get("_index"))
                            var label := child.name + "_" + str(page)
                            if not seen.has(label):
                                await tree.create_timer(0.5).timeout
                                await shot.call(label)
                                seen[label] = true
                            await press(tree, "interact")
                        elif child is NigiriCeremony and str(child.get("_awaiting")) != "":
                            await shot.call("nigiri")
                            await press(tree, "interact")
                        elif child is BoardControls:
                            await press(tree, "interact")
                    if str(scene.get("_awaiting")) == "prepare":
                        await press(tree, "interact")
            "help_probe":
                if scene.has_method("is_player_turn_ready") and scene.is_player_turn_ready():
                    var before := fingerprint(scene.game)
                    await press(tree, "go_help")
                    await shot.call("handicap_help_reopened")
                    await press(tree, "go_pass")
                    scene._on_point_activated(scene.game.board.idx(0,0))
                    await tree.create_timer(1.0).timeout
                    if fingerprint(scene.game) != before:
                        push_error("Handicap help changed the position or consumed a turn.")
                    await press(tree, "move_right")
                    await shot.call("handicap_number_explanation")
                    await press(tree, "cancel")
                    await press(tree, "cancel")
                    if fingerprint(scene.game) != before:
                        push_error("Closing handicap help changed the position.")
                    print("EXPERIENCE: help preserved position, next player and move count")
                    return
            "help_during_reply":
                if scene.has_method("is_player_turn_ready") and scene.is_player_turn_ready():
                    for point in scene.game.board.cells.size():
                        if scene.game.is_legal(point):
                            scene._on_point_activated(point)
                            break
                    await tree.process_frame
                    await press(tree, "go_help")
                    var before_reply := fingerprint(scene.game)
                    await tree.create_timer(5.0).timeout
                    await shot.call("opponent_reply_waits_for_help")
                    if fingerprint(scene.game) != before_reply:
                        push_error("Handicap help allowed an opponent move behind the explanation.")
                        tree.quit(1)
                    await press(tree, "cancel")
                    print("EXPERIENCE: opponent reply waited until handicap help closed")
                    return
            "result":
                if scene.has_method("is_counting"):
                    if scene.is_counting():
                        await shot.call("counting")
                        await press(tree, "go_pass")
                    if str(scene.get("_awaiting")) == "dismiss":
                        await shot.call("result")
                        await press(tree, "interact")
                        return
            "review_choice":
                if str(scene.get("_awaiting")) == "review":
                    await shot.call("review_offer")
                    if bool(spec.get("accept", false)) != bool(scene.get("_review_yes")):
                        await press(tree, "move_up")
                    await press(tree, "interact")
                    return
            "lesson_place":
                if str(scene.get("_awaiting")) == "step" and scene.get("lesson") != null:
                    var xy: Array = spec["point"]
                    var board: GoBoardView = scene.board_view
                    var target := Vector2i(int(xy[0]), int(xy[1]))
                    var current: Vector2i = scene.game.board.point(board.cursor)
                    while current != target:
                        if current.x != target.x:
                            await press(tree, "move_right" if current.x < target.x else "move_left")
                        else:
                            await press(tree, "move_down" if current.y < target.y else "move_up")
                        current = scene.game.board.point(board.cursor)
                    await press(tree, "interact")
                    await tree.create_timer(0.3).timeout
                    await shot.call("lesson_feedback")
                    return
            "save":
                var saves := tree.root.get_node("SaveSystem")
                saves.save_game(1)
                return
        await tree.process_frame
    push_error("Experience route timed out waiting for %s." % mode)
    tree.quit(1)


## Measures live CharacterBody2D travel, then holds Shift across the pause-menu
## input lock. Static speed checks cannot prove either of those scene boundaries.
static func run_probe(tree: SceneTree, world: Node, shot: Callable) -> void:
    var player := tree.get_first_node_in_group("player") as Player
    if player == null:
        push_error("Experience run probe could not find the player.")
        tree.quit(1)
        return
    var start := player.global_position
    var frames := 24

    set_action("move_right", true)
    await tree.process_frame
    var walk_start := player.global_position
    for i in frames:
        await tree.physics_frame
    set_action("move_right", false)
    await tree.process_frame
    await tree.physics_frame
    var walk_distance := player.global_position.distance_to(walk_start)

    player.global_position = start
    player.velocity = Vector2.ZERO
    await tree.physics_frame
    set_action("run", true)
    set_action("move_right", true)
    await tree.process_frame
    var run_start := player.global_position
    for i in frames:
        await tree.physics_frame
    set_action("move_right", false)
    set_action("run", false)
    await tree.process_frame
    await tree.physics_frame
    var run_distance := player.global_position.distance_to(run_start)
    var ratio := run_distance / walk_distance if walk_distance > 0.0 else 0.0
    if walk_distance < 10.0 or absf(ratio - Player.RUN_MULTIPLIER) > 0.12:
        push_error("Experience run speed ratio was %.3f (walk %.2f, run %.2f)." % [
            ratio, walk_distance, run_distance])
        tree.quit(1)
        return
    if player.sprite.gait_scale != 1.0:
        push_error("Experience run release did not restore the walking gait.")
        tree.quit(1)
        return

    player.global_position = start
    player.velocity = Vector2.ZERO
    set_action("run", true)
    set_action("move_right", true)
    for i in 10:
        await tree.physics_frame
    await shot.call("running_ketelsteeg")
    set_action("move_right", false)
    set_action("run", false)
    await tree.process_frame
    await tree.physics_frame

    # The solid shop front immediately left of this spawn must stop even the
    # faster body without tunnelling into its tile.
    player.global_position = start
    player.velocity = Vector2.ZERO
    set_action("run", true)
    set_action("move_left", true)
    for i in 20:
        await tree.physics_frame
    set_action("move_left", false)
    set_action("run", false)
    await tree.physics_frame
    if int(player.global_position.x / world.map.tile_size) < 13:
        push_error("Experience run crossed the solid shop front.")
        tree.quit(1)
        return

    player.global_position = start
    player.velocity = Vector2.ZERO
    await press(tree, "menu")
    var locked_start := player.global_position
    set_action("run", true)
    set_action("move_right", true)
    for i in 16:
        await tree.physics_frame
    if player.global_position.distance_to(locked_start) > 0.1:
        push_error("Experience run bypassed the pause-menu input lock.")
        tree.quit(1)
        return
    set_action("move_right", false)
    await press(tree, "cancel")
    set_action("move_right", true)
    for i in 12:
        await tree.physics_frame
    set_action("move_right", false)
    set_action("run", false)
    await tree.physics_frame
    if player.global_position.distance_to(locked_start) < 15.0:
        push_error("Experience held Shift did not resume running after the menu closed.")
        tree.quit(1)
        return
    player.global_position = start
    player.velocity = Vector2.ZERO
    print("EXPERIENCE: run %.3fx; release, collision and menu lock passed" % ratio)

static func fingerprint(game: GoGame) -> String:
    return "%s:%d:%d" % [str(game.board.cells), game.to_move, game.move_number()]

static func inspect_setup(scene: Node) -> void:
    var game: GoGame = scene.game
    var setup: GoMatchSetup = scene.setup
    var black := 0
    for cell in game.board.cells:
        if cell == GoBoard.BLACK:
            black += 1
    if game.move_number() == 0 and black != setup.handicap:
        push_error("The displayed handicap disagrees with the actual starting board.")
    print("EXPERIENCE: %s %dx%d; player %s; handicap %d; komi %.1f; unrated %s" % [
        scene.request.context_id, game.size(), game.size(), GoBoard.color_name(scene.player_color),
        setup.handicap, game.komi, str(scene.request.unrated)])
