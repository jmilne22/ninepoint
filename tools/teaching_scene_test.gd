## Synthetic engine and recording opponent exercise the real turn loop without timing noise.
extends SceneTree
var kit := TestKit.new()

class RecordingOpponent extends GoOpponent:
    var received: Array = []
    func choose_move(game: GoGame) -> Dictionary:
        received.append(game.moves.duplicate(true))
        return GoOpponent.point_move(game.board.from_label("D3"))


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    _eligibility()
    for choice in [0, 1]:
        var scene := await _start()
        var fixture := ReviewFactsTests.dying_group()
        var game := GoGame.new(9)
        game.set_position(PackedByteArray(fixture["cells"]), GoBoard.BLACK)
        scene.game = game
        scene.board_view.set_game(game)
        var opponent := RecordingOpponent.new()
        scene.opponent = opponent
        var before := TeachingPosition.key(game)
        await _cache(scene)
        scene._on_point_activated(int(fixture["actual"]))
        var dialog := await _dialog(scene)
        kit.ok(dialog != null, "real scene presents question")
        if dialog == null:
            await _dispose(scene)
            continue
        var pending := TeachingPosition.key(game)
        scene._on_point_activated(0)
        scene._mouse_action(&"go_pass")
        scene._mouse_action(&"go_resign")
        kit.eq(TeachingPosition.key(game), pending, "provisional decision blocks every board action")
        kit.eq(opponent.received.size(), 0, "opponent cannot see provisional move")
        if choice == 0:
            dialog.choose(0)
            await process_frame
            kit.eq(TeachingPosition.key(game), before, "Undo restores complete game")
            kit.eq(scene.board_view.game, game, "Undo restores the live board view")
            kit.eq(opponent.received.size(), 0, "undone move never reaches opponent")
            await _cache(scene)
            scene._on_point_activated(int(fixture["actual"]))
        else:
            # Esc maps to keep, rather than silently undoing a legal decision.
            dialog._input(MouseActions.event(&"cancel"))
        var deadline := Time.get_ticks_msec() + 3000
        while not scene.is_player_turn_ready() and Time.get_ticks_msec() < deadline:
            await process_frame
        kit.ok(scene.is_player_turn_ready(), "opponent replied and player regained input")
        kit.eq(opponent.received.size(), 1, "opponent sees retained move exactly once")
        if not opponent.received.is_empty():
            kit.eq(opponent.received[0].size(), 1, "no extra undo/retry move in opponent history")
        kit.ok(scene._live.last_note.contains("one liberty"), "matching reply creates a verified note")
        kit.ok(scene.find_child("TeachingChoice", true, false) == null, "retry never reopens question")
        game.play(game.board.from_label("C4"))
        game.pass_turn()
        scene._live.passed()
        var later := TeachingPosition.key(game)
        scene._mouse_action(&"go_help")
        var help := await _dialog(scene)
        kit.ok(help.options.has("Last explanation"), "Help exposes opponent note")
        help.choose(help.options.find("Last explanation"))
        await process_frame
        kit.ok(scene._teaching.opened, "Help reopens latest note beside board")
        kit.eq(scene.board_view.game.move_number(), 2, "old explanation shows its original board")
        for child in scene.get_children():
            if child is BoardBrief:
                child._input(MouseActions.event(&"cancel"))
        await process_frame
        kit.eq(TeachingPosition.key(scene.game), later, "reading old explanation preserves current history")
        kit.eq(scene.board_view.game, scene.game, "closing old explanation restores live view")
        await _dispose(scene)
    # Closing while a question is awaiting must kill the worker without committing.
    var cancelled := await _start()
    var fixture := ReviewFactsTests.dying_group()
    cancelled.game.set_position(PackedByteArray(fixture["cells"]), GoBoard.BLACK)
    await _cache(cancelled)
    cancelled._on_point_activated(int(fixture["actual"]))
    await _dialog(cancelled)
    var worker: KataGoTeaching = cancelled._live.worker
    cancelled.queue_free()
    await process_frame
    current_scene = null
    var shutdown_deadline := Time.get_ticks_msec() + 2000
    while worker.closing and Time.get_ticks_msec() < shutdown_deadline:
        await process_frame
    kit.ok(not worker._pipe.is_open(), "scene exit closes worker during question")
    OS.unset_environment("TEACHING_FAKE_MODE")
    print(kit.report())
    quit(1 if kit.failed else 0)


func _eligibility() -> void:
    var request := MatchRequest.new()
    request.profile = load("res://data/opponents/wren_9x9.tres")
    request.npc_id = "wren"
    request.context_id = "wren_first"
    request.unrated = true
    request.practice = true
    var setup := GoMatchSetup.prepare(GoMatchSetup.Rule.PLAYER_BLACK, -1, 10, 9, 5.5)
    kit.ok(LiveTeaching.eligible(request, setup), "Wren first practice is eligible")
    request.unrated = false
    kit.ok(not LiveTeaching.eligible(request, setup), "rated game never qualifies")
    request.unrated = true
    request.context_id = "wren_rematch"
    kit.ok(not LiveTeaching.eligible(request, setup), "ordinary Wren rematch never qualifies")
    request.npc_id = "kesh"
    request.context_id = "practice_kesh"
    kit.ok(not LiveTeaching.eligible(request, setup), "even Kesh practice never qualifies")
    setup.handicap = 5
    kit.ok(LiveTeaching.eligible(request, setup), "Kesh handicap practice qualifies")
    setup.board_size = 13
    kit.ok(not LiveTeaching.eligible(request, setup), "thirteen-line game never qualifies")


func _start() -> Control:
    OS.set_environment("TEACHING_FAKE_MODE", "valid")
    var request := MatchRequest.new()
    request.profile = load("res://data/opponents/wren_9x9.tres").duplicate() as OpponentProfile
    request.profile.engine = "heuristic"
    request.profile.colour_rule = "player_black"
    request.context_id = "wren_first"
    request.npc_id = "wren"
    request.opponent_name = "Wren Calloway"
    request.unrated = true
    request.practice = true
    root.get_node("MatchBridge").pending_request = request
    var scene: Control = load("res://src/go_ui/go_match.tscn").instantiate()
    scene._live.worker.command = "res://tools/fixtures/teaching_engine.py"
    root.add_child(scene)
    current_scene = scene
    var deadline := Time.get_ticks_msec() + 5000
    while not scene.is_player_turn_ready() and Time.get_ticks_msec() < deadline:
        for child in scene.get_children():
            if child is TeachingChoice:
                child.choose(0)
            elif child is BoardBrief:
                child._input(MouseActions.event(&"cancel"))
        await process_frame
    kit.ok(scene.is_player_turn_ready(), "teaching scene started")
    return scene


func _cache(scene: Control) -> void:
    var deadline := Time.get_ticks_msec() + 2000
    while not scene._live.worker.cached_for(scene.game) and Time.get_ticks_msec() < deadline:
        await process_frame
    kit.ok(scene._live.worker.cached_for(scene.game), "scene prefetched current history")


func _dialog(scene: Control) -> TeachingChoice:
    var deadline := Time.get_ticks_msec() + 2500
    while Time.get_ticks_msec() < deadline:
        var found := scene.find_child("TeachingChoice", true, false) as TeachingChoice
        if found != null and not found._closed:
            await process_frame
            return found
        await process_frame
    return null


func _dispose(scene: Control) -> void:
    await scene._live.worker.shutdown()
    scene.queue_free()
    await process_frame
    current_scene = null
