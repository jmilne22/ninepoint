## Exercises actual surface drops and destruction, without running an engine.
extends SceneTree

var t := TestKit.new()
var events: Array[Dictionary] = []

func _initialize() -> void:
    _run.call_deferred()

func _record(kind: String, count: int = 0) -> void:
    events.append({"kind":kind, "count":count, "ms":Time.get_ticks_msec()})

func _surface() -> TableSceneBoardSurface:
    var board := GoBoardView.new()
    root.add_child(board)
    board.set_game(GoGame.new(9))
    var surface := TableSceneBoardSurface.new()
    root.add_child(surface)
    surface.setup(board)
    surface.contacts.stone_landed.connect(_record.bind("stone"))
    surface.contacts.stone_landed.connect(func() -> void:
        var stone: Node3D = surface.stones.get(40)
        t.ok(stone != null, "landing belongs to a visible stone")
        if stone != null:
            t.ok(absf(stone.position.y - (.122 + .02 * surface.layout.stone_scale)) < .0001,
                "sound is emitted at the grounded visual position"))
    surface.contacts.capture_landed.connect(func(n: int) -> void: _record("capture", n))
    return surface

func _run() -> void:
    await process_frame
    t.ok(AudioPreview.requested(), "preview explicitly enabled")
    for fps in [30, 60, 144]:
        Engine.max_fps = fps
        var surface := _surface()
        await create_timer(.1).timeout
        events.clear()
        var started := Time.get_ticks_msec()
        surface.contacts.request(40, 3)
        t.ok(surface.board.game.play(40), "legal placement")
        surface.board.animate_placement(40)
        await create_timer(.4).timeout
        t.eq(events.size(), 2, "one landing followed by one capture")
        if events.size() == 2:
            var delay: int = events[0].ms - started
            var gap: int = events[1].ms - events[0].ms
            t.ok(delay >= 150 and delay <= 180 + 3000/fps, "sound waits for visual landing")
            t.ok(gap >= 65 and gap <= 85 + 3000/fps, "capture leaves impact clear")
            t.eq(events[1].count, 3, "capture count survives presentation")
            print("AUDIO CONTACT: fps=%d landing_ms=%d capture_gap_ms=%d" % [fps,delay,gap])
        surface.contacts.land(40)
        surface._rebuild_grid()
        await create_timer(.35).timeout
        t.eq(events.size(), 2, "duplicate callback and redraw are silent")
        events.clear()
        t.ok(surface.board.game.play(41), "restored position legal")
        await create_timer(.3).timeout
        t.eq(events.size(), 0, "restoring a board does not produce a placement")
        surface.contacts.request(41, 0)
        await create_timer(.35).timeout
        t.eq(events.size(), 1, "commit announced after visual update still lands once")
        events.clear()
        surface.contacts.request(42, 2)
        surface.board.game.play(42)
        surface.board.animate_placement(42)
        await process_frame
        surface.queue_free()
        await create_timer(.4).timeout
        t.eq(events.size(), 0, "leaving before landing cancels pending sounds")
    var contact := TableStoneAudio.new()
    root.add_child(contact)
    contact.capture_landed.connect(func(n: int) -> void: _record("capture", n))
    contact.request(7, 5)
    contact.land(7)
    contact.queue_free()
    await create_timer(.2).timeout
    t.eq(events.size(), 0, "leaving after impact cancels capture timer")
    contact = TableStoneAudio.new()
    root.add_child(contact)
    contact.stone_landed.connect(_record.bind("offscreen"))
    contact.request(100, 0)
    contact.wait_offscreen(100)
    contact.wait_offscreen(100)
    await create_timer(.3).timeout
    t.eq(events.size(), 1, "offscreen actual move still sounds once")
    contact.queue_free()
    var rebuilt := _surface()
    await create_timer(.1).timeout
    events.clear()
    rebuilt.contacts.request(40, 0)
    rebuilt.board.game.play(40)
    await create_timer(.05).timeout
    rebuilt._rebuild_grid()
    await create_timer(.4).timeout
    t.eq(events.size(), 1, "rebuilding during descent preserves exactly one landing")
    rebuilt.queue_free()
    # Let the final one-shot release its mixer playback before test shutdown.
    await create_timer(.4).timeout
    print("AUDIO PREVIEW: ", t.report())
    quit(0 if t.failed == 0 else 1)
