## Supplemental scripted answers. Screenshots are evidence of presentation only.
class_name LessonPlayProbe
extends RefCounted


static func run(tree: SceneTree, shot: Callable) -> void:
    var deadline := Time.get_ticks_msec() + 120000
    var seen := false
    var errors_checked := {}
    while Time.get_ticks_msec() < deadline:
        var scene := tree.current_scene
        if scene == null or scene.get("lesson") == null:
            if seen and scene != null and scene.get("map") != null:
                return
            await tree.process_frame
            continue
        seen = true
        var lesson: GoLessonData = scene.lesson
        var stage := str(scene._awaiting)
        var label := "%s_%d" % [lesson.id, scene.step_index + 1]
        if stage in ["card", "feedback"]:
            if stage == "feedback" and scene._overlay.visible:
                BoardPlayProbe.fail(tree, "Lesson result covered the board")
                return
            await shot.call(label + "_" + stage)
            await ExperienceProbe.press(tree, "interact")
        elif stage == "step" and not scene._busy:
            var step: Dictionary = lesson.steps[scene.step_index]
            await shot.call(label + "_instruction")
            match str(step["action"]):
                "play":
                    if step["accept"] != GoLessonData.Accept.ILLEGAL_ATTEMPT and not errors_checked.has(label):
                        for point in scene.game.board.cells.size():
                            if not scene.game.board.is_empty(point):
                                await BoardPlayProbe.place(tree, point)
                                await tree.create_timer(0.1).timeout
                                if scene._message.text == "":
                                    BoardPlayProbe.fail(tree, "Rejected occupied point had no feedback")
                                await shot.call(label + "_refused")
                                break
                        errors_checked[label] = true
                    await BoardPlayProbe.place(tree, answer(lesson, scene.game, scene.step_index))
                    while scene._busy:
                        await tree.process_frame
                    if step["accept"] != GoLessonData.Accept.ILLEGAL_ATTEMPT and scene._message.visible and scene._message.text.contains("occupied"):
                        BoardPlayProbe.fail(tree, "Successful lesson action kept an old legality error")
                "inspect":
                    for target in step["target"]:
                        await BoardPlayProbe.place(tree, int(target))
                        await tree.create_timer(0.1).timeout
                        await shot.call(label + "_inspect")
                "pass":
                    await ExperienceProbe.press(tree, "go_pass")
                    if scene.game.state != GoGame.State.SCORING:
                        BoardPlayProbe.fail(tree, "Lesson passes did not enter scoring")
                "count":
                    if scene.board_view.dead.is_empty():
                        BoardPlayProbe.fail(tree, "Lesson lost its proposed dead marks")
                        return
                    var point := int(scene.board_view.dead.keys()[0])
                    for toggle in 2:
                        await BoardPlayProbe.place(tree, point)
                        await shot.call(label + "_toggle_%d" % toggle)
                    await ExperienceProbe.press(tree, "go_pass")
        await tree.process_frame
    BoardPlayProbe.fail(tree, "Scripted lesson run timed out")


static func answer(lesson: GoLessonData, game: GoGame, index: int) -> int:
    for point in game.board.cells.size():
        var legal := game.legality(point) == GoGame.Legality.LEGAL
        var captured := 0
        if legal:
            captured = game.board.duplicate_board().place(point, game.to_move).size()
        if lesson.step_accepts(index, point, legal, captured):
            return point
    return -1
