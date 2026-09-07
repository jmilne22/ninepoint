## Authored proofs are replayed visibly, each from the same prepared position.
class_name LessonDemonstration
extends RefCounted


static func show_proofs(scene: Control) -> void:
    for proof in scene.lesson.steps[scene.step_index]["proofs"]:
        if not proof.has("caption") or scene._finished or not scene.is_inside_tree():
            continue
        scene.game = scene.lesson.make_game(scene.step_index)
        var outcome := GoLessonActions.demonstrate(scene.game, proof)
        scene.board_view.set_game(scene.game)
        scene.board_view.highlight = outcome["points"]
        await scene._show_feedback(str(proof["caption"]))
