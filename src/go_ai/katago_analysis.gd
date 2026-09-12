## KataGo's analysis engine over one pipe: scores, then selected comparisons, results
## arriving one turn at a time. It knows a match record and nothing about the
## town; MatchAnalysis turns what comes back into cards.
##
## Cost, measured on the bundled CPU build: about one core-second per
## position, at one visit or eight. A 9x9 game is fifty-odd positions and a
## 19x19 game three hundred, so the caller streams progress rather than
## promising a deadline. See MILESTONES.md M40.
class_name KataGoAnalysis
extends RefCounted

signal progress(done: int, total: int)
signal phase_progress(phase: String, done: int, total: int)

const COMMAND := "res://packaging/katago/katago-gtp.sh"
const MODEL := "res://packaging/katago/models/kata1-b18c384nbt-s9996604416-d4316597426.bin.gz"
const CONFIG := "res://packaging/katago/config/analysis.cfg"
const MANIFEST := "res://packaging/katago-linux-x64.json"
## The network takes a few seconds to load before the first result can exist.
const STARTUP_SECONDS := 90.0
## No new turn for this long means the engine is wedged, not slow.
const STALL_SECONDS := 30.0
const TOTAL_CAP_SECONDS := 600.0
const MAX_THREADS := 8

## Development hooks, in the same class as Autopilot: a fixture points the
## runner at a script that hangs, and shortens the watchdog so the test ends.
static var command_override := ""
static var stall_override := -1.0

var _pipe := EnginePipe.new()
var _cancelled := false
var _started := 0


static func is_available() -> bool:
    var command := command_override if command_override != "" else COMMAND
    return FileAccess.file_exists(command) and FileAccess.file_exists(MODEL) \
        and FileAccess.file_exists(CONFIG)


static func engine_version() -> String:
    var text := FileAccess.get_file_as_string(MANIFEST)
    var parsed: Variant = JSON.parse_string(text) if text != "" else null
    if parsed is Dictionary and parsed.get("binary") is Dictionary:
        return "KataGo %s" % str(parsed["binary"].get("version", "")).split(" ")[0]
    return "KataGo"


## One analysis thread per core, minus one for the game itself. Threads here
## are independent positions, not a deeper search, so this is what shortens
## the wait on a machine with more cores.
static func thread_count() -> int:
    return clampi(OS.get_processor_count() - 1, 1, MAX_THREADS)


## The query KataGo's analysis mode takes: every position of the game, so the
## value before and after each move is known. Handicap stones are setup, not
## moves, and then White moves first.
static func query_for(replay: Dictionary, komi: float, id: String = "review") -> Dictionary:
    return KataGoReviewQuery.query_for(replay, komi, id)


static func parse_line(line: String, size: int = 0) -> Dictionary:
    return KataGoReviewQuery.parse_line(line, size)


## Runs the whole query. Returns {"turns": {turn: {...}}, "total", "complete",
## "reason", "engine_version"}. Never throws, never blocks the scene thread,
## and closes the child unless keep_open is requested for run_details().
func run(record: Dictionary, keep_open: bool = false) -> Dictionary:
    var replay := MatchAnalysis.replay(str(record.get("sgf", "")))
    if replay.is_empty():
        return _result({}, 0, "malformed sgf")
    var query := query_for(replay, float(record.get("komi", 5.5)))
    var total: int = query["analyzeTurns"].size()
    if not is_available():
        return _result({}, total, "engine files missing")
    var command := command_override if command_override != "" else COMMAND
    var args := PackedStringArray(["analysis", "-config", CONFIG, "-model", MODEL,
        "-override-config", "numAnalysisThreads=%d" % thread_count()])
    if not _pipe.open(command, args):
        return _result({}, total, "engine could not start")
    _started = Time.get_ticks_msec()
    var collected: Dictionary = await _collect([query], int(replay["size"]), "positions", 0, true)
    var turns := {}
    for parsed in collected["results"].values():
        turns[int(parsed["turn"])] = parsed
    var out := _result(turns, total, str(collected["reason"]))
    out["pass1_seconds"] = float(Time.get_ticks_msec() - _started) / 1000.0
    if not keep_open or not out["complete"] or _cancelled:
        close()
    return out


## The service chooses pass-one cards before asking for details. A failed second
## pass never discards the already usable first pass. Raw detail maps are ephemeral.
func run_details(record: Dictionary, raw: Dictionary) -> Dictionary:
    var out := raw.duplicate(true)
    out.merge({"details": {}, "pass2_seconds": 0.0, "detail_total": 0, "detail_reason": ""}, true)
    if not _pipe.is_open() or _cancelled or not bool(raw.get("complete", false)):
        close()
        return out
    var payload := MatchAnalysis.from_turns(0, record, raw)
    var findings: Array = payload.get("findings", [])
    var replay := MatchAnalysis.replay(str(record.get("sgf", "")))
    var queries := KataGoReviewQuery.detail_queries(replay, float(record.get("komi", 5.5)), findings)
    out["detail_total"] = queries.size()
    var started := Time.get_ticks_msec()
    var collected: Dictionary = await _collect(queries, int(replay["size"]), "comparisons", int(raw["total"]))
    out["pass2_seconds"] = float(Time.get_ticks_msec() - started) / 1000.0
    out["detail_reason"] = collected["reason"]
    var details := {}
    for n in findings.size():
        var branches := {}
        for branch in ["actual", "best", "pass"]:
            var id := "f%d_%s" % [n, branch]
            var key := "%s:%d" % [id, int(findings[n]["move_number"])]
            if collected["results"].has(key):
                branches[branch] = collected["results"][key]
        details[int(findings[n]["move_number"])] = branches
    out["details"] = details
    close()
    return out


func _collect(queries: Array, size: int, phase: String, offset: int,
        startup_allowed: bool = false) -> Dictionary:
    var expected := {}
    for query in queries:
        for turn in query["analyzeTurns"]:
            expected["%s:%d" % [query["id"], int(turn)]] = true
        _pipe.write_line(JSON.stringify(query))
    var results := {}
    var last_line := Time.get_ticks_msec()
    var stall := stall_override if stall_override > 0.0 else STALL_SECONDS
    var startup := minf(STARTUP_SECONDS, stall * 3.0) if stall_override > 0.0 else STARTUP_SECONDS
    var reason := ""
    phase_progress.emit(phase, 0, expected.size())
    while not _cancelled and results.size() < expected.size():
        var read: Dictionary = await _pipe.read_line(0.25)
        var now := Time.get_ticks_msec()
        if float(now - _started) / 1000.0 > TOTAL_CAP_SECONDS:
            reason = "took too long"
            break
        if not bool(read.get("ready", false)):
            var quiet := float(now - last_line) / 1000.0
            if quiet > (startup if startup_allowed and results.is_empty() else stall):
                reason = "engine stalled"
                break
            continue
        var line := str(read.get("line", ""))
        if line.strip_edges() == "" and not _pipe.is_running():
            reason = "engine exited"
            break
        var parsed := parse_line(line, size)
        if parsed.has("error"):
            reason = "engine rejected the game: %s" % str(parsed["error"])
            break
        if parsed.is_empty():
            continue
        var key := "%s:%d" % [parsed["id"], parsed["turn"]]
        if not expected.has(key) or results.has(key):
            continue
        last_line = now
        results[key] = parsed
        progress.emit(offset + results.size(), offset + expected.size())
        phase_progress.emit(phase, results.size(), expected.size())
    if _cancelled:
        reason = "cancelled"
    return {"results": results, "reason": reason}


func cancel() -> void:
    _cancelled = true
    close()


func close() -> void:
    _pipe.close()


func _result(turns: Dictionary, total: int, reason: String) -> Dictionary:
    return {"turns": turns, "total": total, "complete": total > 0 and turns.size() == total,
        "reason": reason, "engine_version": engine_version()}
