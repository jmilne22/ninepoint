## Synthetic protocol failures are deliberately separate from the real benchmark.
extends SceneTree
var kit := TestKit.new()


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var fixture := ReviewFactsTests.dying_group()
    var game := GoGame.new(9)
    game.set_position(PackedByteArray(fixture["cells"]), GoBoard.BLACK)
    for mode in ["valid", "stale", "partial", "hang", "malformed", "exit", "startup_hang", "missing"]:
        OS.set_environment("TEACHING_FAKE_MODE", mode)
        var worker := KataGoTeaching.new()
        worker.command = "res://tools/fixtures/teaching_engine.py" if mode != "missing" else "/missing-teaching-engine"
        worker.startup_seconds = 0.2
        worker.start()
        var deadline := Time.get_ticks_msec() + 1000
        while not worker.ready and not worker.failed and Time.get_ticks_msec() < deadline:
            await process_frame
        if mode in ["missing", "startup_hang"]:
            kit.ok(worker.failed, mode + " disables optional worker")
            await worker.shutdown()
            continue
        kit.ok(worker.ready, mode + " warmed")
        worker.prefetch(game)
        deadline = Time.get_ticks_msec() + 1000
        while not worker.cached_for(game) and Time.get_ticks_msec() < deadline:
            await process_frame
        var started := Time.get_ticks_msec()
        var value := await worker.compare(game, int(fixture["actual"]), 0.08)
        kit.ok(Time.get_ticks_msec() - started < 250, mode + " shared deadline is bounded")
        if mode == "valid":
            kit.ok(not value.get("facts", {}).get("group_died", []).is_empty(), "valid responses produce evidence")
        else:
            kit.ok(value.is_empty(), mode + " falls back to normal play")
        if mode == "stale":
            worker.prefetch(game)
            await create_timer(0.35).timeout
            kit.eq(worker._pending.size(), 0, "late cancelled branches do not remain pending")
            kit.eq(worker._results.size(), 0, "late cancelled branches cannot poison next cache")
            kit.ok(worker.cached_for(game), "new position query survives old replies")
        if mode in ["malformed", "exit"]:
            kit.ok(worker.failed, mode + " remains disabled for the match")
        await worker.shutdown()
        kit.ok(not worker._pipe.is_open(), mode + " closes the child pipe")
    OS.unset_environment("TEACHING_FAKE_MODE")
    print(kit.report())
    quit(1 if kit.failed else 0)
