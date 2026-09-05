## Owns the one KataGo analysis that may be running. The match scene asks for
## it and watches progress; the world hears when it lands. A new game outranks
## an old review, and nothing here survives a quit: an unfinished review is
## marked interrupted on the next load rather than resumed.
extends Node

signal progress(record_index: int, done: int, total: int)
signal finished(record_index: int, payload: Dictionary)

var _runner: KataGoAnalysis = null
var _index := -1


func _ready() -> void:
    EventBus.match_started.connect(func(_context: String) -> void: cancel())


func is_running() -> bool:
    return _runner != null


func running_index() -> int:
    return _index


## Fire and forget: the caller listens to `finished` (or reads the payload
## back from GameState.match_analysis) rather than awaiting this.
func start(record_index: int) -> void:
    if record_index < 0 or record_index >= GameState.match_records.size():
        return
    cancel()
    GameState.record_analysis(record_index, MatchAnalysis.pending(record_index))
    _run(record_index)


func cancel() -> void:
    if _runner == null:
        return
    var runner := _runner
    var index := _index
    _runner = null
    _index = -1
    runner.cancel()
    GameState.record_analysis(index, MatchAnalysis.unavailable(index, "cancelled"))


func _run(record_index: int) -> void:
    var record: Dictionary = GameState.match_records[record_index]
    var payload: Dictionary
    if not MatchAnalysis.eligible(record):
        payload = MatchAnalysis.unavailable(record_index, "ineligible")
    elif not KataGoAnalysis.is_available():
        payload = MatchAnalysis.unavailable(record_index, "engine files missing")
    else:
        var runner := KataGoAnalysis.new()
        _runner = runner
        _index = record_index
        runner.progress.connect(func(done: int, total: int) -> void:
            progress.emit(record_index, done, total))
        var started := Time.get_ticks_msec()
        var raw: Dictionary = await runner.run(record)
        print("Review: %d of %d positions in %.1f s on %d threads (%s)" % [
            raw.get("turns", {}).size(), int(raw.get("total", 0)),
            float(Time.get_ticks_msec() - started) / 1000.0, KataGoAnalysis.thread_count(),
            "complete" if bool(raw.get("complete", false)) else str(raw.get("reason", ""))])
        if _runner != runner:
            # Cancelled while the engine ran; cancel() already wrote the record.
            return
        _runner = null
        _index = -1
        payload = MatchAnalysis.from_turns(record_index, record, raw)
        if OS.is_debug_build() and str(payload.get("availability", "")) == "failed":
            print("Review failed (%s)" % str(payload.get("reason", "")))
    GameState.record_analysis(record_index, payload)
    finished.emit(record_index, payload)


func _exit_tree() -> void:
    cancel()
