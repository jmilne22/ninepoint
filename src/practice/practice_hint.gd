class_name PracticeHint
extends RefCounted

static func show(scene: Control) -> void:
    scene.turn_paused = true
    scene.modal_open = true
    scene._sync_mouse()
    var game: GoGame = scene.game.fork()
    var worker: KataGoTeaching = scene._live.worker
    # Hints remain available after automatic coaching has been turned off.
    if not worker.ready:
        if worker.failed or not worker._running:
            await worker.shutdown()
            worker = KataGoTeaching.new()
            scene._live.worker = worker
        worker.start()
        var deadline := Time.get_ticks_msec() + 13000
        scene._set_message("Preparing a hint…")
        while not worker.ready and not worker.failed and Time.get_ticks_msec() < deadline:
            await scene.get_tree().process_frame
    var point := GoGame.RESIGN
    if worker.ready:
        scene._set_message("Looking at this position…")
        worker.prefetch(game)
        var deadline := Time.get_ticks_msec() + 8500
        while not worker.cached_for(game) and not worker.failed and Time.get_ticks_msec() < deadline:
            await scene.get_tree().process_frame
        if worker.cached_for(game): point = game.board.from_label(str(worker._cache.get("best", "")))
    scene.modal_open = false
    if point >= 0 and game.is_legal(point):
        var hint := "The engine suggests %s." % game.board.label(point)
        var after := game.fork()
        after.play(point)
        var taken: PackedInt32Array = after.last_move().get("captured", PackedInt32Array())
        if not taken.is_empty(): hint += " It captures %d stone%s." % [taken.size(), "" if taken.size() == 1 else "s"]
        await scene._teaching.show_text(hint, PackedInt32Array([point]))
    else:
        await scene._teaching.show_text("An engine hint is unavailable for this position. Position help can still show liberties and legal captures.")
    scene.turn_paused = false
    scene._set_message("Choose your move. The hint was %s." % game.board.label(point) if point >= 0 else "H opens position help.")
    scene._refresh()
