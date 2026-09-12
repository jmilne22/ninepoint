## One optional analysis process per teaching match. One reader dispatches every reply.
class_name KataGoTeaching
extends RefCounted

var ready := false
var failed := false
var startup_ms := -1
var comparison_ms := -1
var queries_sent := 0
var timeouts := 0
var command := KataGoAnalysis.COMMAND
var startup_seconds := 12.0
var _pipe := EnginePipe.new()
var _running := false
var _serial := 0
var _pending := {}
var _results := {}
var _cache_key := ""
var _cache := {}
var _generation := 0
var closing := false
var _reading := false


static func search_threads() -> int:
    return clampi((OS.get_processor_count() - 2) / 2, 1, 4)


func start() -> void:
    if _running or failed:
        return
    if not FileAccess.file_exists(command) or not FileAccess.file_exists(KataGoAnalysis.MODEL):
        failed = true
        return
    var args := PackedStringArray(["analysis", "-config", KataGoAnalysis.CONFIG,
        "-model", KataGoAnalysis.MODEL, "-override-config",
        "numAnalysisThreads=2,numSearchThreadsPerAnalysisThread=%d" % search_threads()])
    if not _pipe.open(command, args):
        failed = true
        return
    _running = true
    _pump()
    _warm()


func _warm() -> void:
    var started := Time.get_ticks_msec()
    var id := _send(GoGame.new(9, 5.5))
    var result := await _wait([id], startup_seconds)
    if not _running:
        return
    if result.is_empty():
        _fail()
        return
    startup_ms = Time.get_ticks_msec() - started
    ready = true


func prefetch(game: GoGame) -> void:
    if not ready or failed or game.state != GoGame.State.PLAYING or game.ko_rule != GoGame.KoRule.SIMPLE:
        return
    var key := TeachingPosition.key(game)
    if _cache_key == key:
        return
    invalidate()
    _cache_key = key
    _prefetch(game.fork(), _generation)


func _prefetch(game: GoGame, generation: int) -> void:
    var id := _send(game)
    var values := await _wait([id], 8.0)
    if generation != _generation or not _running:
        return
    if values.is_empty():
        _fail()
    else:
        _cache = values[id]


func cached_for(game: GoGame) -> bool:
    return ready and _cache_key == TeachingPosition.key(game) and not _cache.is_empty()


## The two branches share one wall-clock deadline. Nothing changes the live game.
func compare(before: GoGame, actual: int, seconds: float) -> Dictionary:
    if not cached_for(before) or before.ko_rule != GoGame.KoRule.SIMPLE:
        invalidate()
        return {}
    var cached := _cache.duplicate(true)
    var best := before.board.from_label(str(cached.get("best", "")))
    if best == actual or not before.is_legal(best) or not before.is_legal(actual):
        invalidate()
        return {}
    invalidate()
    var generation := _generation
    var played := before.fork()
    var preferred := before.fork()
    played.play(actual)
    preferred.play(best)
    var started := Time.get_ticks_msec()
    var actual_id := _send(played)
    var best_id := _send(preferred)
    var values := await _wait([actual_id, best_id], maxf(0.0, seconds))
    comparison_ms = Time.get_ticks_msec() - started
    if generation != _generation or not _running:
        return {}
    if values.is_empty():
        timeouts += 1
        return {}
    var a: Dictionary = values[actual_id]
    var b: Dictionary = values[best_id]
    var input := ReviewFacts.player_input({"size": before.size(), "cells": Array(before.board.cells),
        "player": before.to_move, "actual": actual, "best": best,
        "own_actual": a["ownership"], "own_best": b["ownership"],
        "lead_actual": a["score_lead"], "lead_best": b["score_lead"],
        "pv_after_actual": a.get("pv", []), "pv_best": cached.get("pv", [])})
    var facts := ReviewFacts.build(input, before)
    return {"facts": facts, "loss": float(input["lead_best"]) - float(input["lead_actual"])}


func invalidate() -> void:
    _generation += 1
    _cache_key = ""
    _cache.clear()
    for id in _pending.keys():
        _terminate(id)
    _results.clear()


func close() -> void:
    if closing:
        return
    _running = false
    ready = false
    invalidate()
    if _pipe.is_open() and (_reading or _pipe._reader != null):
        closing = true
        # Wake the blocking reader before closing its FileAccess. Healthy shutdown
        # should not generate a pipe error; an unresponsive child still gets killed.
        _pipe.write_line(JSON.stringify({"id": "shutdown", "action": "query_version"}))
        _close_pipe()
        return
    _pipe.close()


func _close_pipe() -> void:
    while _reading:
        await (Engine.get_main_loop() as SceneTree).process_frame
    if _pipe._reader != null:
        await _pipe.read_line(0.2)
    _pipe.close()
    closing = false


func shutdown() -> void:
    close()
    while closing:
        await (Engine.get_main_loop() as SceneTree).process_frame


func _fail() -> void:
    failed = true
    close()


func _send(game: GoGame) -> String:
    _serial += 1
    var id := "teach_%d_%d" % [_generation, _serial]
    _pending[id] = {"size": game.size(), "turn": game.moves.size()}
    _pipe.write_line(JSON.stringify(TeachingPosition.query(game, id)))
    queries_sent += 1
    return id


func _terminate(id: String) -> void:
    if _pending.has(id):
        _pending.erase(id)
        _pipe.write_line(JSON.stringify({"id": "cancel_" + id, "action": "terminate", "terminateId": id}))
    _results.erase(id)


func _wait(ids: Array, seconds: float) -> Dictionary:
    var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
    while _running and Time.get_ticks_msec() < deadline:
        if ids.all(func(id: String) -> bool: return _results.has(id)):
            var out := {}
            for id: String in ids:
                out[id] = _results[id]
                _results.erase(id)
            return out
        if ids.any(func(id: String) -> bool: return not _pending.has(id) and not _results.has(id)):
            break
        await (Engine.get_main_loop() as SceneTree).process_frame
    for id: String in ids:
        _terminate(id)
    return {}


func _pump() -> void:
    while _running:
        if _pending.is_empty():
            await (Engine.get_main_loop() as SceneTree).process_frame
            continue
        _reading = true
        var read: Dictionary = await _pipe.read_line(0.05)
        _reading = false
        if not _running:
            return
        if not read.get("ready", false):
            if not _pipe.is_running():
                _fail()
            continue
        var line := str(read.get("line", ""))
        var json := JSON.new()
        var value: Variant = json.data if json.parse(line) == OK else null
        if not value is Dictionary:
            if line.strip_edges() != "" or not _pipe.is_running():
                _fail()
            continue
        var id := str(value.get("id", ""))
        # Cancelled queries can return partial results after the acknowledgement.
        if not _pending.has(id):
            continue
        if bool(value.get("isDuringSearch", false)):
            continue
        var expected: Dictionary = _pending[id]
        var parsed := KataGoReviewQuery.parse_line(line, int(expected["size"]))
        if not parsed.has("ownership") or not is_finite(float(parsed.get("score_lead", NAN))) \
                or int(parsed.get("turn", -1)) != int(expected["turn"]):
            _fail()
            return
        _pending.erase(id)
        _results[id] = parsed
