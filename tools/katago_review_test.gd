## Real-process gate for the whole-game review: KataGo's analysis mode must
## answer every position of a finished 9x9 and a finished 19x19 game, and a
## wedged engine must fail through the watchdog rather than hang. Prints the
## seconds per position, which is the number the loading card's honesty
## depends on.
##
##   godot --headless --path . --script res://tools/katago_review_test.gd
extends SceneTree

var _failed := false
var _budget_exceeded := false
var _last := -1
var _monotonic := true


func _initialize() -> void:
    _check(KataGoAnalysis.is_available(), "review engine files are present")
    if not KataGoAnalysis.is_available():
        quit(1)
        return
    await _whole_game(9, 120)
    if _budget_exceeded:
        quit(2)
        return
    await _whole_game(19, 240)
    await _detail_failure()
    await _stale_session()
    await _hang()
    print("KataGo review gate: %s" % ("FAILED" if _failed else "passed"))
    quit(1 if _failed else 0)


## Two heuristic players finish a game; the review must account for all of it.
func _whole_game(size: int, cap: int) -> void:
    var game := _play_out(size, cap)
    _check(game.state != GoGame.State.PLAYING, "%dx%d: fixture reached an ending" % [size,size])
    var record := {"sgf": GoSgf.to_sgf(game), "komi": game.komi, "board_size": size,
        "player_color": GoBoard.BLACK, "by_capture": false}
    var runner := KataGoAnalysis.new()
    _last = -1
    _monotonic = true
    runner.progress.connect(_on_progress)
    var started := Time.get_ticks_msec()
    var raw: Dictionary = await runner.run(record, true)
    raw = await runner.run_details(record, raw)
    var seconds := float(Time.get_ticks_msec() - started) / 1000.0
    var total := int(raw.get("total", 0))
    _check(bool(raw.get("complete", false)), "%dx%d: every one of %d positions was analysed (%s)" % [
        size, size, total, str(raw.get("reason", ""))])
    _check(_monotonic and _last == total + int(raw.get("detail_total", 0)), "%dx%d: progress counted up to the end" % [size, size])
    var payload := MatchAnalysis.from_turns(0, record, raw)
    _check(str(payload.get("availability", "")) in ["available", "steady"],
        "%dx%d: the analysis became a review (%s)" % [size, size, str(payload.get("reason", payload.get("availability")))])
    print("KataGo review %dx%d: %d moves, %d positions, %.1f s, %.2f s per position on %d threads, %d findings" % [
        size, size, game.moves.size(), total, seconds, seconds / maxf(total, 1),
        KataGoAnalysis.thread_count(), payload.get("findings", []).size()])

    print("REV-01 %dx%d: pass-1 %.3f s; pass-2 %.3f s; %d detail queries" % [size,size,
        float(raw.get("pass1_seconds",0.0)),float(raw.get("pass2_seconds",0.0)),int(raw.get("detail_total",0))])
    _check(str(raw.get("detail_reason","")) == "", "detail pass completed: " + str(raw.get("detail_reason","")))
    for branches in raw.get("details",{}).values():
        _check(branches.size() == 3, "all three branches returned")
        for branch in branches.values():
            _check(branch.get("ownership",[]).size() == size * size, "branch ownership covers the board")
    var legacy_raw := raw.duplicate(true)
    legacy_raw.erase("details")
    var legacy := MatchAnalysis.from_turns(0, record, legacy_raw)
    var saved := ReviewEnrichment.save_entries({"0":payload})
    var before_bytes := JSON.stringify(legacy, "  ").to_utf8_buffer().size()
    var after_bytes := JSON.stringify(saved["0"], "  ").to_utf8_buffer().size()
    var state := root.get_node("GameState")
    var complete_save: Dictionary = state.to_dict().duplicate(true)
    complete_save["version"] = root.get_node("SaveSystem").SAVE_VERSION
    complete_save["saved_at"] = Time.get_datetime_string_from_system()
    complete_save["match_records"] = [record]
    complete_save["match_analysis"] = {"0":legacy}
    var save_before := JSON.stringify(complete_save, "  ").to_utf8_buffer().size()
    complete_save["match_analysis"] = saved
    var save_after := JSON.stringify(complete_save, "  ").to_utf8_buffer().size()
    print("REV-01 %dx%d saved review: before %d bytes; after %d bytes; delta %+d" % [size,size,before_bytes,after_bytes,after_bytes-before_bytes])
    print("REV-01 %dx%d complete save: before %d bytes; after %d bytes; delta %+d" % [size,size,save_before,save_after,save_after-save_before])
    for finding in payload.get("findings", []):
        if finding.has("facts"):
            _check(ReviewNarrator.valid(finding["facts"],finding["narration"],size), "enriched narration is coordinate-grounded")
    _check(payload.get("findings", []).any(func(f: Dictionary) -> bool: return f.has("facts")), "valid detail comparisons are retained in the payload")
    var evidence_path := "user://review_gate_%d.json" % size
    var evidence := FileAccess.open(evidence_path, FileAccess.WRITE)
    evidence.store_string(JSON.stringify({"record":record,"review":saved["0"]},"  "))
    if size == 9 and float(raw.get("pass2_seconds",0.0)) > 45.0:
        _budget_exceeded = true
        printerr("REV-01 BUDGET EXCEEDED: stop and ask owner before adjusting visits.")


func _on_progress(done: int, _total: int) -> void:
    _monotonic = _monotonic and done > _last
    _last = done


func _play_out(size: int, cap: int) -> GoGame:
    var game := GoGame.new(size, 5.5, 0)
    var players := {}
    for colour in [GoBoard.BLACK, GoBoard.WHITE]:
        var p := OpponentProfile.new()
        p.rank_label = "12k" if colour == GoBoard.BLACK else "9k"
        p.rng_seed = 11 + colour
        p.reading_depth = 1
        var brain := HeuristicOpponent.new()
        brain.setup(p, game)
        players[colour] = brain
    while game.state == GoGame.State.PLAYING and game.moves.size() < cap:
        var move: Dictionary = players[game.to_move].choose_move(game)
        var point := int(move.get("point", GoGame.PASS))
        if str(move.get("type", "")) == "move" and game.is_legal(point):
            game.play(point)
        else:
            game.pass_turn()
    # A move cap bounds the fixture, but an unfinished SGF is not a whole-game gate.
    while game.state == GoGame.State.PLAYING:
        game.pass_turn()
    return game


func _hang() -> void:
    KataGoAnalysis.command_override = "res://tools/fixtures/analysis_hang.sh"
    KataGoAnalysis.stall_override = 2.0
    var runner := KataGoAnalysis.new()
    var started := Time.get_ticks_msec()
    var raw: Dictionary = await runner.run({"sgf": "(;GM[1]SZ[9];B[dd];W[ee])", "komi": 5.5})
    var seconds := float(Time.get_ticks_msec() - started) / 1000.0
    _check(str(raw.get("reason", "")) == "engine stalled", "a silent engine is failed by the watchdog (%s)" % str(raw.get("reason", "")))
    _check(seconds < 15.0, "and within its budget (%.1f s)" % seconds)
    _check(MatchAnalysis.from_turns(0, {"sgf": "(;GM[1]SZ[9];B[dd])"}, raw)["availability"] == "failed",
        "which the payload records as failed")
    KataGoAnalysis.command_override = ""
    KataGoAnalysis.stall_override = -1.0


func _detail_failure() -> void:
    KataGoAnalysis.command_override = "res://tools/fixtures/analysis_detail_error.py"
    var record := {"sgf":"(;GM[1]SZ[9];B[dd];W[ee];B[cc])", "komi":5.5,"player_color":GoBoard.BLACK}
    var runner := KataGoAnalysis.new()
    var raw: Dictionary = await runner.run(record,true)
    var before := MatchAnalysis.from_turns(0,record,raw)
    var detailed: Dictionary = await runner.run_details(record,raw)
    _check(str(detailed["detail_reason"]).contains("detail unavailable"),"a rejected detail query is reported")
    _check(MatchAnalysis.from_turns(0,record,detailed) == before,"detail failure retains the exact old review")
    runner = KataGoAnalysis.new()
    raw = await runner.run(record,true)
    runner.phase_progress.connect(func(phase: String, _done: int, _total: int) -> void:
        if phase == "comparisons":
            runner.cancel())
    detailed = await runner.run_details(record,raw)
    _check(detailed["detail_reason"] == "cancelled","detail cancellation terminates the pipe")
    _check(bool(detailed["complete"]),"cancellation does not erase pass-one coverage")
    KataGoAnalysis.command_override = ""


func _check(ok: bool, what: String) -> void:
    if not ok:
        _failed = true
    print("%s %s" % ["  ok " if ok else "FAIL ", what])


func _stale_session() -> void:
    var state := root.get_node("GameState")
    var service := root.get_node("MatchReviewService")
    KataGoAnalysis.command_override = "res://tools/fixtures/analysis_detail_error.py"
    state.match_records = [{"sgf":"(;GM[1]SZ[9];B[dd];W[ee];B[cc])", "komi":5.5,"player_color":GoBoard.BLACK}]
    var changed := [false]
    var reset_session := func(_index: int, phase: String, _done: int, _total: int) -> void:
        if phase == "comparisons":
            changed[0] = true
            state.reset()
            state.match_records = [{"context_id":"replacement_session"}]
    service.phase_progress.connect(reset_session)
    service.start(0)
    var deadline := Time.get_ticks_msec()+15000
    while service.is_running() and Time.get_ticks_msec()<deadline:
        await process_frame
    await create_timer(0.2).timeout
    _check(changed[0],"session reset happened during pass two")
    _check(state.match_analysis.is_empty(),"stale pass-two results never enter the replacement save")
    service.phase_progress.disconnect(reset_session)
    state.reset()
    KataGoAnalysis.command_override = ""
