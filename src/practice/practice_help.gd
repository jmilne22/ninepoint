class_name PracticeHelp
extends RefCounted

static func show(scene: Control) -> void:
    scene.turn_paused = true
    scene.modal_open = true
    scene._sync_mouse()
    var choice := TeachingChoice.new()
    choice.text = "Choose the help you want."
    choice.options = ["This position", "Hide liberties" if scene.board_view.show_liberties else "Show liberties",
        "Turn coaching off" if scene._live.active else "Turn coaching on", "Back"]
    choice.cancel_index = 3
    scene.add_child(choice)
    var selected: int = await choice.selected
    scene.modal_open = false
    if selected == 0: await scene._teaching.show_help()
    elif selected == 1:
        scene.board_view.show_liberties = not scene.board_view.show_liberties
        scene.board_view.queue_redraw()
    elif selected == 2:
        if scene._live.active:
            scene._live.close()
        else:
            await scene._live.worker.shutdown()
            scene._live.worker = KataGoTeaching.new()
            scene._live.worker.start()
            scene._live.active = true
        scene._checkpoint()
    scene.turn_paused = false
    scene._refresh()
