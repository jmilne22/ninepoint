## Actual worker, recorded Wren history and colour/handicap variants. No saves touched.
extends SceneTree
var failures := 0
var completed := 0


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var worker := KataGoTeaching.new()
    worker.start()
    var deadline := Time.get_ticks_msec() + 15000
    while not worker.ready and not worker.failed and Time.get_ticks_msec() < deadline:
        await process_frame
    if not worker.ready:
        printerr("Teaching worker failed to warm")
        await worker.shutdown()
        quit(1)
        return
    print("TEACHING STARTUP ms=%d search_threads=%d" % [worker.startup_ms, worker.search_threads()])
    var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/review/wren-played.json"))
    var replay := MatchAnalysis.replay(record["sgf"])
    for mirrored in [false, true]:
        for ply in [25, 29]:
            var game := GoGame.new(9, -5.5 if mirrored else 5.5)
            if mirrored:
                game.pass_turn()
            for move: Dictionary in replay["moves"].slice(0, ply - 1):
                game.play(int(move["point"]))
            await _measure(worker, game, int(replay["moves"][ply-1]["point"]), "wren_%d_white_%s" % [ply, mirrored])
    # Kesh's real five-stone initial setup, plus a reproducible legal developing position.
    var handicap := GoGame.new(9, 0.5, 5)
    handicap.play_xy(1,1)
    await _measure(worker, handicap, handicap.board.from_label("A1"), "kesh_five_stones")
    for label in ["D3", "D2", "C2", "E3", "E2", "B2", "F3", "F2"]:
        var point := handicap.board.from_label(label)
        if handicap.is_legal(point):
            handicap.play(point)
    if handicap.to_move == GoBoard.WHITE:
        handicap.pass_turn()
    var actual := handicap.board.from_label("J9")
    await _measure(worker, handicap, actual, "kesh_developing")
    await worker.shutdown()
    print("TEACHING BENCHMARK completed comparisons=%d timeouts=%d failures=%d" % [completed, worker.timeouts, failures])
    quit(1 if failures > 0 else 0)


func _measure(worker: KataGoTeaching, game: GoGame, point: int, label: String) -> void:
    worker.prefetch(game)
    var deadline := Time.get_ticks_msec() + 10000
    while not worker.cached_for(game) and not worker.failed and Time.get_ticks_msec() < deadline:
        await process_frame
    var value := await worker.compare(game, point, 2.0)
    print("TEACHING SAMPLE " + JSON.stringify({"case": label, "milliseconds": worker.comparison_ms,
        "completed": not value.is_empty(), "loss": value.get("loss"), "memory_kib": _memory(worker),
        "groups_lost": value.get("facts", {}).get("group_died", []).size()}))
    if not value.is_empty():
        completed += 1
    if label.begins_with("wren") and value.get("facts", {}).get("group_died", []).is_empty():
        failures += 1


func _memory(worker: KataGoTeaching) -> int:
    var output: Array = []
    var code := OS.execute("python3", [ProjectSettings.globalize_path("res://tools/process_memory.py"), str(worker._pipe._pid)], output)
    return int(output[0]) if code == 0 and not output.is_empty() else -1
