## Real-process gate for the whole-game review: KataGo's analysis mode must
## answer every position of a finished 9x9 and a finished 19x19 game, and a
## wedged engine must fail through the watchdog rather than hang. Prints the
## seconds per position, which is the number the loading card's honesty
## depends on.
##
##   godot --headless --path . --script res://tools/katago_review_test.gd
extends SceneTree

var _failed := false
var _last := -1
var _monotonic := true


func _initialize() -> void:
    _check(KataGoAnalysis.is_available(), "review engine files are present")
    if not KataGoAnalysis.is_available():
        quit(1)
        return
    await _whole_game(9, 120)
    await _whole_game(19, 240)
    await _hang()
    print("KataGo review gate: %s" % ("FAILED" if _failed else "passed"))
    quit(1 if _failed else 0)


## Two heuristic players finish a game; the review must account for all of it.
func _whole_game(size: int, cap: int) -> void:
    var game := _play_out(size, cap)
    var record := {"sgf": GoSgf.to_sgf(game), "komi": game.komi, "board_size": size,
        "player_color": GoBoard.BLACK, "by_capture": false}
    var runner := KataGoAnalysis.new()
    _last = -1
    _monotonic = true
    runner.progress.connect(_on_progress)
    var started := Time.get_ticks_msec()
    var raw: Dictionary = await runner.run(record)
    var seconds := float(Time.get_ticks_msec() - started) / 1000.0
    var total := int(raw.get("total", 0))
    _check(bool(raw.get("complete", false)), "%dx%d: every one of %d positions was analysed (%s)" % [
        size, size, total, str(raw.get("reason", ""))])
    _check(_monotonic and _last == total, "%dx%d: progress counted up to the end" % [size, size])
    var payload := MatchAnalysis.from_turns(0, record, raw)
    _check(str(payload.get("availability", "")) in ["available", "steady"],
        "%dx%d: the analysis became a review (%s)" % [size, size, str(payload.get("reason", payload.get("availability")))])
    print("KataGo review %dx%d: %d moves, %d positions, %.1f s, %.2f s per position on %d threads, %d findings" % [
        size, size, game.moves.size(), total, seconds, seconds / maxf(total, 1),
        KataGoAnalysis.thread_count(), payload.get("findings", []).size()])


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


func _check(ok: bool, what: String) -> void:
    if not ok:
        _failed = true
    print("%s %s" % ["  ok " if ok else "FAIL ", what])
