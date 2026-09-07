## Prepared-position UI coverage, explicitly separate from the manual playthrough.
class_name PracticePlayProbe
extends RefCounted


static func run(tree: SceneTree, shot: Callable) -> void:
    var scene := tree.current_scene
    var original: GoGame = scene.game
    for own in [false, true]:
        var game := GoGame.new(9)
        var board := GoBoard.new(9)
        board.cells[40] = GoBoard.BLACK if own else GoBoard.WHITE
        for point in [31, 39, 41]:
            board.cells[point] = GoBoard.WHITE if own else GoBoard.BLACK
        game.set_position(board.cells)
        scene.game = game
        scene.board_view.set_game(game)
        scene._refresh()
        await shot.call("practice_atari_prompt" if own else "practice_capture_prompt")
        await ExperienceProbe.press(tree, "go_help")
        if not scene.board_view.liberty_targets.has(40):
            BoardPlayProbe.fail(tree, "Help failed to highlight the actual group")
        var before := ExperienceProbe.fingerprint(game)
        await ExperienceProbe.press(tree, "go_pass")
        if before != ExperienceProbe.fingerprint(game):
            BoardPlayProbe.fail(tree, "Help allowed a pass behind the explanation")
        await shot.call("practice_atari_help" if own else "practice_capture_help")
        await ExperienceProbe.press(tree, "cancel")
    scene.game = original
    scene.board_view.set_game(original)
    scene._refresh()
    await BoardPlayProbe.place(tree, original.board.idx(2, 6))
    await tree.root.get_node("Autopilot")._wait_for_match_player_turn(30)
    await BoardPlayProbe.place(tree, original.board.idx(2, 6))
    var error: String = scene._message.text
    if not error.contains("already a stone"):
        BoardPlayProbe.fail(tree, "Occupied move did not show its legality error")
    await shot.call("practice_rejected_move")
    for point in [57, 55, 47, 65]:
        if original.is_legal(point):
            await BoardPlayProbe.place(tree, point)
            break
    await tree.root.get_node("Autopilot")._wait_for_match_player_turn(30)
    if scene._message.text == error:
        BoardPlayProbe.fail(tree, "Legal action left the previous legality error visible")
    await shot.call("practice_legal_move_clears_error")
