## Matched legal replay for audio comparison; separate from the live Wren gate.
extends "res://src/experiments/table_scene/trial.gd"

func _run() -> void:
    Audio.play_music("theme_battle")
    if Audio.preview != null: Audio.preview.rng.seed = 2026
    game = GoGame.new(9, profile.komi)
    player_color = GoBoard.BLACK
    board_view.set_game(game)
    opponent = HeuristicOpponent.new()
    opponent.setup(profile, game)
    voice = TableTalkVoice.load_voice("wren")
    phase = Phase.PLAYING
    _awaiting = &"move"
    _refresh()
    _set_message("Prepared legal replay for audio comparison.")
    await get_tree().create_timer(2).timeout
    await _shot("table")
    for point: int in TableSceneShowcase.MOVES:
        if not await _move(point): return
    game = GoGame.new(9, profile.komi)
    board_view.set_game(game)
    _set_message("A second prepared position: two stones captured together.")
    await get_tree().create_timer(2).timeout
    for point in [2, 0, 10, 1, 9]:
        if not await _move(point): return
    if game.last_move().captured.size() != 2:
        push_error("Audio replay group fixture did not capture two stones")
        get_tree().quit(1)
        return
    await _shot("group_capture")
    game.pass_turn()
    game.pass_turn()
    _scoring_phase()
    _set_message("Prepared replay complete. These fixtures do not save a result.")
    await _shot("count")
    await get_tree().create_timer(3).timeout
    print("AUDIO REPLAY: 21 legal moves; single and group captures; complete")
    close_trial()

func _move(point: int) -> bool:
    if not game.play(point):
        push_error("Illegal audio replay point: %d" % point)
        get_tree().quit(1)
        return false
    _announce_move(game.last_move())
    _react()
    _refresh()
    _set_message("Prepared replay: %s at %s." % [GoBoard.color_name(game.last_move().color), game.board.label(point)])
    await get_tree().create_timer(1.6).timeout
    return true

func _shot(label: String) -> void:
    await RenderingServer.frame_post_draw
    var folder := OS.get_environment("OUT")
    DirAccess.make_dir_recursive_absolute(folder)
    get_viewport().get_texture().get_image().save_png(folder.path_join(label + ".png"))
