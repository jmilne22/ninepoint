## A legally replayed demonstration, explicitly separate from live Wren play.
class_name TableSceneShowcase
extends Node

const MOVES := [20, 60, 1, 0, 24, 59, 9, 71, 80, 79, 29, 51, 30, 50, 39, 42]
var scene: Control
var output := ""

func run(value: Control, verify: bool = false) -> void:
    scene = value
    output = OS.get_environment("OUT")
    if output.is_empty():
        output = ProjectSettings.globalize_path("res://docs/table_scene/screenshots")
    DirAccess.make_dir_recursive_absolute(output)
    scene.game = GoGame.new(9, scene.profile.komi)
    scene.player_color = GoBoard.BLACK
    scene.board_view.set_game(scene.game)
    scene.opponent = HeuristicOpponent.new()
    scene.opponent.setup(scene.profile, scene.game)
    scene.voice = TableTalkVoice.load_voice("wren")
    scene.phase = scene.Phase.PLAYING
    scene._awaiting = &"move"
    scene._refresh()
    scene._set_message("A short, prepared game at Wren's table.  9 x 9 / Casual game")
    await get_tree().process_frame
    if verify:
        await TableSceneVerification.run(scene)
        return
    await _wait(1.0)
    await _shot("01_table_for_two")
    if OS.get_cmdline_user_args().has("--still"):
        await scene.close_trial()
        return
    await _wait(2.0)
    for index in MOVES.size():
        var point: int = MOVES[index]
        var player_turn: bool = scene.game.to_move == scene.player_color
        if player_turn:
            scene._awaiting = &"move"
            scene._on_point_activated(point)
        else:
            if not scene.game.play(point):
                push_error("TableScene showcase contains an illegal move: %d" % point)
                get_tree().quit(1)
                return
            scene._announce_move(scene.game.last_move())
            scene._react()
            scene._refresh()
        var count: int = scene.game.last_move()["captured"].size()
        if count > 0:
            scene._set_message("%s captures one stone." % ("Ro" if player_turn else "Wren"))
        else:
            scene._set_message("%s plays %s." % ["Ro" if player_turn else "Wren", scene.game.board.label(point)])
        await _wait(0.35)
        var shot_delay := 0.0
        if index == 0:
            shot_delay = 0.45
            await _wait(shot_delay)
            await _shot("02_placing_a_stone")
        if index == 4:
            scene.wren_actor.perform("thinking", 1.6)
            await _wait(0.35)
            await _shot("03_thinking")
        if index == 6:
            await _shot("04_wren_surprised")
        if index == 9:
            shot_delay = 0.75
            await _wait(shot_delay)
            await _shot("05_wren_relief")
        await _wait(1.30 + (0.7 if count > 0 else 0.0) - shot_delay)
    scene.game.pass_turn()
    Audio.play("pass")
    scene._set_message("Ro passes.")
    await _wait(1.0)
    scene.game.pass_turn()
    Audio.play("pass")
    scene._scoring_phase()
    await _wait(1.5)
    await _shot("06_counting_together")
    await _wait(1.5)
    scene._answered(true)
    scene._finish()
    await _wait(3.0)
    Audio.stop_music(0.35)
    await _wait(0.6)
    print("EXPRESSIVE SHOWCASE: 16 legal moves, both capture reactions, count and result; complete")
    get_tree().quit()

func _wait(seconds: float) -> void:
    await get_tree().create_timer(seconds).timeout

func _shot(label: String) -> void:
    await RenderingServer.frame_post_draw
    var error := get_viewport().get_texture().get_image().save_png(output.path_join(label + ".png"))
    if error != OK:
        push_error("TableScene capture failed: " + label)
        get_tree().quit(1)
    print("EXPRESSIVE SHOT: " + label)
