extends "res://src/go_ui/table_scene/match.gd"

var actions: MouseActions
var modal_open := false
var fallback_noted := false
var restored_count: Dictionary = {}

var previous_auto_quit := true
var quitting := false

func _ready() -> void:
    previous_auto_quit = get_tree().auto_accept_quit
    get_tree().auto_accept_quit = false
    super._ready()

func _exit_tree() -> void:
    get_tree().auto_accept_quit = previous_auto_quit
    super._exit_tree()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST and not quitting:
        quitting = true
        _checkpoint()
        await _stop_turns()
        get_tree().quit()

func _build_ui() -> void:
    super._build_ui()
    actions = MouseActions.new()
    actions.position = Vector2(24, 407)
    actions.z_index = 95
    add_child(actions)
    actions.action_selected.connect(_practice_action)
    controls_hint.position = Vector2(250, 413)
    controls_hint.size.x = 230
    controls_hint.text = "Arrows / click: place"

func _run() -> void:
    var saved: Dictionary = PracticeSession.resume_snapshot
    if saved.is_empty():
        await _setup_phase()
        if not is_inside_tree() or phase == Phase.DONE: return
        game = GoGame.new(setup.board_size, setup.komi, setup.handicap)
        game.capture_goal = profile.capture_goal
        player_color = setup.player_color
    else:
        game = PracticeSnapshot.restore(saved)
        player_color = int(saved.player)
        setup.player_color = player_color
        setup.resolved = true
        setup.uses_nigiri = false
    if game != null and game.state == GoGame.State.SCORING: restored_count = saved
    PracticeSession.resume_snapshot = {}
    if game == null:
        PracticeSession.show_hub()
        return
    board_view.set_game(game)
    _checkpoint()
    var warmed: GtpOpponent = await _prepare_opponent()
    _awaiting = &""
    if not is_inside_tree() or phase == Phase.DONE: return
    if profile.engine == "gtp" and warmed == null:
        opponent = HeuristicOpponent.new()
        opponent.setup(profile, game)
        if not await _fallback_notice(): return
    else:
        opponent = OpponentFactory.create(profile, game, warmed)
    await _live.choose_mode()
    if not saved.is_empty() and not bool(saved.get("coaching", false)): _live.close()
    phase = Phase.PLAYING
    _set_message("Hint and Undo are available below. H opens position help." if request.teaching_enabled else "P passes. R offers resignation. Esc saves or leaves.")
    if game.capture_goal > 0: _set_message("First capture wins. H shows liberties and captures. Two passes end without a winner.")
    _refresh()
    _checkpoint()
    await MatchTurnLoop.run(self)

func _scoring_phase() -> void:
    phase = Phase.SCORING
    board_view.dead = GoScoring.estimate_dead(game.board)
    var saved: Dictionary = restored_count
    if not saved.is_empty():
        board_view.dead.clear()
        for point in saved.get("dead", []): board_view.dead[int(point)] = true
        restored_count = {}
    board_view.show_territory = true
    _set_message("Inspect proposed dead groups. Click to change a mark; P accepts the count.")
    _update_scoring_preview()
    _refresh()
    _checkpoint()
    await _ask(&"scoring")

func _answered(value: Variant) -> void:
    super._answered(value)
    _checkpoint()

func _toggle_dead(point: int) -> void:
    super._toggle_dead(point)
    _checkpoint()

func _opponent_turn() -> void:
    await super._opponent_turn()
    if not is_inside_tree() or phase == Phase.DONE: return
    _checkpoint()
    if opponent is GtpOpponent and opponent.fallback_used and not fallback_noted:
        await _fallback_notice()

func _finish() -> void:
    if result_sent: return
    result_sent = true
    _live.close()
    phase = Phase.DONE
    if game.state != GoGame.State.FINISHED:
        game.finish_with_score(GoScoring.score(game.board, board_view.dead, game.captures, game.komi))
    opponent.shutdown()
    await _live.worker.shutdown()
    PracticeSession.finish_match(MatchCompletion.result(self))

func _checkpoint() -> void:
    if game == null or _live.busy or phase == Phase.DONE: return
    if not PracticeSession.checkpoint(game, player_color, board_view.dead, _live.active):
        _set_message(PracticeSession.notice)

func _sync_mouse() -> void:
    super._sync_mouse()
    if actions == null: return
    var enabled := game != null and phase in [Phase.PLAYING, Phase.SCORING] and not modal_open and not _live.busy and not _teaching.opened and _handicap_help == null
    var specs: Array = []
    if enabled:
        if request.allow_undo:
            specs.append(["Hint I", "hint", is_player_turn_ready()])
            specs.append(["Undo U", "undo", not game.moves.is_empty()])
        if PracticeSession.settings.mode == "ordinary": specs.append(["Help H", "help"])
        specs.append(["Leave Esc", "leave"])
    actions.configure(specs)
    if turn_paused:
        board_view.interactive = false
        board_view.inspection = false
    if _mouse_controls != null:
        _mouse_controls._bar.visible = not modal_open

func _unhandled_input(event: InputEvent) -> void:
    if modal_open: return
    if event.is_action_pressed("cancel") and phase in [Phase.PLAYING, Phase.SCORING]:
        get_viewport().set_input_as_handled()
        _practice_action(&"leave")
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_U and request.allow_undo:
            get_viewport().set_input_as_handled()
            _practice_action(&"undo")
            return
        if event.keycode == KEY_I and request.teaching_enabled:
            get_viewport().set_input_as_handled()
            _practice_action(&"hint")
            return
    if turn_paused: return
    if event.is_action_pressed("go_help") and PracticeSession.settings.mode == "ordinary" and is_player_turn_ready():
        get_viewport().set_input_as_handled()
        _practice_action(&"help")
        return
    if event.is_action_pressed("go_help") and request.teaching_enabled and is_player_turn_ready():
        get_viewport().set_input_as_handled()
        PracticeHelp.show(self)
        return
    super._unhandled_input(event)

func _practice_action(action: StringName) -> void:
    if phase not in [Phase.PLAYING, Phase.SCORING]: return
    if modal_open or _live.busy or _teaching.opened or _handicap_help != null: return
    if action == &"help":
        if phase == Phase.SCORING: await _teaching.show_help()
        else: await _teaching.show_text("Click a board point, or use arrows and Space to place a stone. P passes; two consecutive passes begin counting. R asks you to confirm resignation. Esc opens saving and leaving options.\n\nOrdinary games have no hints or takebacks. Choose Teaching in setup for those tools.")
        _refresh()
    elif action == &"hint" and is_player_turn_ready():
        await PracticeHint.show(self)
    elif action == &"undo" and request.allow_undo:
        if not PracticeSnapshot.take_back(game, player_color): return
        board_view.dead.clear()
        _live.worker.invalidate()
        _checkpoint()
        await _stop_turns()
        PracticeSession.start_game(true)
    elif action == &"leave":
        modal_open = true
        turn_paused = true
        _sync_mouse()
        var choice := TeachingChoice.new()
        choice.text = "Leave this practice game?"
        choice.options = ["Save and Return", "Discard Game", "Continue Playing"]
        choice.cancel_index = 2
        add_child(choice)
        var selected: int = await choice.selected
        modal_open = false
        if selected == 0:
            if not PracticeSession.checkpoint(game, player_color, board_view.dead, _live.active):
                turn_paused = false
                _set_message(PracticeSession.notice)
                return
        elif selected == 1: PracticeSession.discard()
        else:
            turn_paused = false
            _sync_mouse()
            return
        await _stop_turns()
        PracticeSession.show_hub()

func _stop_turns() -> void:
    phase = Phase.DONE
    turn_revision += 1
    turn_paused = false
    _awaiting = &""
    _live.close()
    if opponent != null: opponent.shutdown()
    await _live.worker.shutdown()

func _fallback_notice() -> bool:
    fallback_noted = true
    turn_paused = true
    modal_open = true
    var choice := TeachingChoice.new()
    choice.heading = "LOCAL OPPONENT"
    choice.text = "KataGo is unavailable. The local opponent cannot represent the selected rank. Your game can still be saved."
    choice.options = ["Continue locally", "Save and Return"]
    choice.cancel_index = 1
    add_child(choice)
    var selected: int = await choice.selected
    modal_open = false
    turn_paused = false
    if selected == 0: return true
    _checkpoint()
    await _stop_turns()
    PracticeSession.show_hub()
    return false
