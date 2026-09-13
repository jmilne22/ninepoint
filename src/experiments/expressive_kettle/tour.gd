## Drives real movement and UI input, and survives the match/room scene changes.
extends Node
var output := ""
var checks := 0

func run() -> void:
    output = OS.get_environment("OUT")
    if output.is_empty(): output = ProjectSettings.globalize_path("res://docs/expressive_kettle/screenshots")
    DirAccess.make_dir_recursive_absolute(output)
    await _wait(1)
    await _shot("01_arrival")
    if "--still" in OS.get_cmdline_user_args():
        Audio.stop_music(.1)
        await _wait(.5)
        get_tree().quit()
        return
    await _walk(Vector2(2.1,1.9))
    await _walk(Vector2(-1.3,2.0))
    await _walk(Vector2(-2.40,.60))
    await _shot("02_at_wrens_table")
    await _tap("interact")
    await _wait(1.5)
    await _shot("03_wren_talking")
    var room: ExpressiveKettleRoom = get_tree().current_scene
    var before := room.player_point()
    Input.action_press("move_right")
    await _wait(.5)
    Input.action_release("move_right")
    _check(room.player_point().distance_to(before) < .01, "dialogue blocks movement")
    await _dialogue_choice("Set up")
    await _ready_match()
    var match_scene: TableSceneMatch = get_tree().current_scene
    _check(match_scene.request.npc_id == "wren", "conversation launched Wren's existing match")
    await _shot("04_same_style_match")
    for turn in 2:
        match_scene.board_view.focus_point(20 if turn == 0 else 24)
        await _tap("interact")
        await _ready_match()
    _check(match_scene.game.move_number() >= 4, "two real moves and opponent replies")
    _check(match_scene.opponent is GtpOpponent and not match_scene.opponent.fallback_used, "Wren uses her real engine")
    await _wait(1.0)
    await _shot("05_playing_wren")
    await _tap("go_resign")
    await _tap("cancel")
    _check(match_scene.is_player_turn_ready(), "cancel resignation resumes game")
    await _tap("go_resign")
    await _tap("go_resign")
    await _wait(.8)
    await _shot("06_match_result")
    await _tap("interact")
    await _wait(1.0)
    _check(get_tree().current_scene is ExpressiveKettleRoom, "match returns to expressive room")
    room = get_tree().current_scene
    _check(room.player_point().distance_to(before) < .01, "return keeps the player's position")
    _check(GameState.match_records.size() == 1, "completed match recorded exactly once in disposable session")
    await _wait(1.0)
    await _shot("07_wren_after_game")
    await _drain()
    await _walk(Vector2(-1.3,2.0))
    await _walk(Vector2(2.2,1.9))
    await _walk(Vector2(3.55,-.62))
    await _shot("08_at_the_counter")
    await _tap("interact")
    await _wait(1.3)
    await _shot("09_tomas_talking")
    await _dialogue_choice("How is the bar")
    await _wait(1.3)
    await _shot("10_tomas_work")
    await _drain()
    await _tap("cancel")
    before = room.player_point()
    Input.action_press("move_left")
    await _wait(.6)
    Input.action_release("move_left")
    _check(room.player_point().distance_to(before) < .01, "exit modal blocks walking")
    await _tap("cancel")
    _check(not room.busy, "exit cancel restores walking")
    await _shot("11_back_in_the_room")
    await _drive(Vector3(0,0,-1),1.2)
    _check(room.player.position.z >= -1.21, "counter collision stops the player")
    await _walk(Vector2(2.2,1.9))
    await _walk(Vector2(-2.75,1.8))
    await _tap("interact")
    await _wait(1.2)
    await _shot("12_kesh_talking")
    await _dialogue_choice("head to the club")
    await _drain()
    _check(GameState.rank_label() == "30k", "Kesh's existing novice card is preserved")
    await _walk(Vector2(-1.5,2.8))
    await _drive(Vector3(0,0,1),1.0)
    _check(room.player.position.z <= 3.23, "room boundary stops the player")
    await _walk(Vector2(-1.5,2.4))
    await _shot("13_end_of_visit")
    await _tap("menu")
    _check(room.player_card.open, "player card opens from Tab")
    await _shot("15_player_card")
    await _tap("cancel")
    _check(not room.busy and not room.player_card.open, "card closes and restores movement")
    await _tap("go_zoom")
    _check(room.get_node_or_null("PostMatchReview") != null, "last review remains accessible")
    await _tap("move_up")
    await _tap("interact")
    await _wait(.3)
    var offer := room.get_node_or_null("PostMatchReview")
    var loading: ReviewLoading = offer._loading
    _check(loading.transform.get_scale() == Vector2(2,2), "nested review loading uses full canvas")
    await _shot("16_review_loading")
    await _tap("cancel")
    await _wait(.3)
    _check(not room.busy, "review dismissal restores movement")
    MatchReviewService.cancel()
    Audio.stop_music(.1)
    await _wait(.5)
    print("EXPRESSIVE KETTLE: ",checks," checks passed")
    get_tree().quit()

func _check(value: bool, message: String) -> void:
    if not value:
        push_error("KETTLE: " + message)
        get_tree().quit(1)
    else:
        checks += 1
        print("KETTLE PASS: ",message)

func _ready_match() -> void:
    var deadline := Time.get_ticks_msec() + 60000
    while Time.get_ticks_msec() < deadline:
        var scene := get_tree().current_scene
        if scene is TableSceneMatch:
            if scene.is_player_turn_ready(): return
            for child in scene.get_children():
                if child is BoardBrief or child is TeachingChoice or child is HandicapHelp:
                    await _tap("cancel")
                elif child is NigiriCeremony and not child._awaiting.is_empty():
                    await _tap("interact")
        await _wait(.15)
    _check(false,"match startup/reply timed out")

func _drain() -> void:
    for step in 60:
        var room: ExpressiveKettleRoom = get_tree().current_scene
        var offer := room.get_node_or_null("PostMatchReview")
        if offer != null:
            await _tap("cancel")
        elif room.dialogue.running:
            if room.dialogue._awaiting_choice:
                await _dialogue_choice("Later")
                return
            await _tap("interact")
        elif not room.busy:
            return
        await _wait(.1)
    _check(false,"room conversation did not settle")

func _walk(destination: Vector2) -> void:
    var room: ExpressiveKettleRoom = get_tree().current_scene
    var deadline := Time.get_ticks_msec() + 14000
    while room.player_point().distance_to(destination) > .13 and Time.get_ticks_msec() < deadline:
        var delta := destination - room.player_point()
        var world := Vector3(delta.x,0,delta.y).normalized()
        var right := room.camera.global_basis.x
        var forward := room.camera.global_basis.z
        right.y = 0
        forward.y = 0
        var horizontal := world.dot(right.normalized())
        var vertical := world.dot(forward.normalized())
        _release()
        Input.action_press("move_right" if horizontal > 0 else "move_left", absf(horizontal))
        Input.action_press("move_down" if vertical > 0 else "move_up", absf(vertical))
        await get_tree().physics_frame
    _release()
    if room.player_point().distance_to(destination) > .20:
        push_error("Kettle walk obstructed to %s from %s" % [destination,room.player_point()])
        get_tree().quit(1)
    checks += 1
    await _wait(.3)

func _drive(world: Vector3, duration: float) -> void:
    var room: ExpressiveKettleRoom = get_tree().current_scene
    var right := room.camera.global_basis.x
    var forward := room.camera.global_basis.z
    right.y = 0
    forward.y = 0
    var horizontal := world.dot(right.normalized())
    var vertical := world.dot(forward.normalized())
    _release()
    Input.action_press("move_right" if horizontal > 0 else "move_left", absf(horizontal))
    Input.action_press("move_down" if vertical > 0 else "move_up", absf(vertical))
    await _wait(duration)
    _release()
    await _wait(.1)

func _release() -> void:
    for key in ["move_left","move_right","move_up","move_down"]: Input.action_release(key)

func _dialogue_choice(fragment: String) -> void:
    var room: ExpressiveKettleRoom = get_tree().current_scene
    var d := room.dialogue
    for step in 30:
        if not d.running: return
        for child in room.get_children():
            if child is Hud and child._rank_card != null:
                await _shot("14_novice_card")
                await _tap("interact")
        if d._awaiting_choice:
            for i in d._choice_nodes.size():
                if fragment.to_lower() in d._choice_nodes[i].text.to_lower():
                    while d._choice_index != i: await _tap("move_down")
                    await _tap("interact")
                    return
            print("CHOICES: ",d._choice_nodes.map(func(n: Label) -> String: return n.text))
            return
        await _tap("interact")
        await _wait(.15)

func _tap(action: String) -> void:
    var e := InputEventAction.new()
    e.action = action
    e.pressed = true
    Input.parse_input_event(e)
    await _wait(.08)
    e = InputEventAction.new()
    e.action = action
    e.pressed = false
    Input.parse_input_event(e)
    await _wait(.08)

func _wait(seconds: float) -> void:
    await get_tree().create_timer(seconds).timeout

func _shot(label: String) -> void:
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(output.path_join(label+".png"))
    print("KETTLE SHOT: ",label)
