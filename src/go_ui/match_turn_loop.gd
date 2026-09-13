## Shared turn/count lifecycle; setup and completion belong to the host scene.
class_name MatchTurnLoop
extends RefCounted

static func run(scene: Control) -> void:
    while scene.is_inside_tree() and scene.phase != scene.Phase.DONE:
        if scene.turn_paused:
            await scene.get_tree().process_frame
            continue
        if scene.game.state == GoGame.State.PLAYING:
            scene.phase = scene.Phase.PLAYING
            scene._refresh()
            if scene.game.to_move == scene.player_color:
                await scene._ask(&"move")
            else:
                await scene.get_tree().create_timer(scene._think_delay()).timeout
                if not scene.is_inside_tree() or scene.phase == scene.Phase.DONE: return
                await scene._opponent_turn()
        elif scene.game.state == GoGame.State.SCORING:
            await scene._scoring_phase()
            if scene.game.state == GoGame.State.SCORING:
                break
        else:
            break
        if scene.is_inside_tree(): await scene.get_tree().process_frame
    if scene.is_inside_tree() and scene.phase != scene.Phase.DONE:
        await scene._finish()
