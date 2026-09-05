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
