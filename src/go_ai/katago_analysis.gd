## KataGo's analysis engine over a pipe: one query for a whole game, results
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
    var size := int(replay.get("size", 0))
    var board := GoBoard.new(size)
    var moves: Array = []
    for move_value in replay.get("moves", []):
        var move: Dictionary = move_value
        var point := int(move.get("point", GoGame.PASS))
        moves.append(["B" if int(move["color"]) == GoBoard.BLACK else "W",
            "pass" if point < 0 else board.label(point)])
    var turns: Array = []
    for turn in moves.size() + 1:
        turns.append(turn)
    var query := {
        "id": id, "moves": moves, "rules": "japanese", "komi": komi,
        "boardXSize": size, "boardYSize": size, "analyzeTurns": turns,
        "includePolicy": false, "includeOwnership": false,
    }
    var handicap := int(replay.get("handicap", 0))
    if handicap >= 2:
        var stones: Array = []
        for point in GoGame.handicap_points(size, handicap):
            stones.append(["B", board.label(point)])
        query["initialStones"] = stones
        query["initialPlayer"] = "W"
    return query


## One line of KataGo analysis output -> {turn, score_lead, best, best_lead,
## second_lead}. Anything that is not a turn result is {}; an engine error
## comes back as {"error": ...}. Malformed lines never become a lesson.
static func parse_line(line: String) -> Dictionary:
    var text := line.strip_edges()
    if not text.begins_with("{"):
        return {}
    var parsed: Variant = JSON.parse_string(text)
    if not (parsed is Dictionary):
        return {}
    if parsed.has("error"):
        return {"error": str(parsed["error"])}
    if not parsed.has("turnNumber") or not (parsed.get("rootInfo") is Dictionary):
        return {}
    var root: Dictionary = parsed["rootInfo"]
    if not root.has("scoreLead"):
        return {}
    var out := {"turn": int(parsed["turnNumber"]), "score_lead": float(root["scoreLead"]),
        "winrate": float(root.get("winrate", 0.5)), "best": "", "best_lead": float(root["scoreLead"]),
        "second_lead": null}
    var infos: Array = parsed.get("moveInfos", []) if parsed.get("moveInfos") is Array else []
    if infos.size() > 0 and infos[0] is Dictionary:
        out["best"] = str(infos[0].get("move", ""))
        out["best_lead"] = float(infos[0].get("scoreLead", root["scoreLead"]))
    if infos.size() > 1 and infos[1] is Dictionary and infos[1].has("scoreLead"):
        out["second_lead"] = float(infos[1]["scoreLead"])
    return out


## Runs the whole query. Returns {"turns": {turn: {...}}, "total", "complete",
## "reason", "engine_version"}. Never throws, never blocks the scene thread,
## and always leaves no child process behind.
func run(record: Dictionary) -> Dictionary:
    var replay := MatchAnalysis.replay(str(record.get("sgf", "")))
    if replay.is_empty():
        return _finish({}, 0, "malformed sgf")
    var query := query_for(replay, float(record.get("komi", 5.5)))
    var total: int = query["analyzeTurns"].size()
    if not is_available():
        return _finish({}, total, "engine files missing")
    var command := command_override if command_override != "" else COMMAND
    var args := PackedStringArray(["analysis", "-config", CONFIG, "-model", MODEL,
        "-override-config", "numAnalysisThreads=%d" % thread_count()])
    if not _pipe.open(command, args):
        return _finish({}, total, "engine could not start")
    _pipe.write_line(JSON.stringify(query))
    var turns := {}
    var started := Time.get_ticks_msec()
    var last_line := started
    var stall := stall_override if stall_override > 0.0 else STALL_SECONDS
    var startup := minf(STARTUP_SECONDS, stall * 3.0) if stall_override > 0.0 else STARTUP_SECONDS
    var reason := ""
    while not _cancelled and turns.size() < total:
        var read: Dictionary = await _pipe.read_line(0.25)
        var now := Time.get_ticks_msec()
        if not bool(read.get("ready", false)):
            var quiet := float(now - last_line) / 1000.0
            if quiet > (stall if not turns.is_empty() else startup):
                reason = "engine stalled"
                break
            if float(now - started) / 1000.0 > TOTAL_CAP_SECONDS:
                reason = "took too long"
                break
            continue
        var line := str(read.get("line", ""))
        if line.strip_edges() == "" and not _pipe.is_running():
            reason = "engine exited"
            break
        last_line = now
        var parsed := parse_line(line)
        if parsed.has("error"):
            reason = "engine rejected the game: %s" % str(parsed["error"])
            break
        if parsed.is_empty():
            continue
        turns[int(parsed["turn"])] = parsed
        progress.emit(turns.size(), total)
    if _cancelled and reason == "":
        reason = "cancelled"
    return _finish(turns, total, reason)


func cancel() -> void:
    _cancelled = true
    _pipe.close()


func _finish(turns: Dictionary, total: int, reason: String) -> Dictionary:
    _pipe.close()
    return {"turns": turns, "total": total, "complete": total > 0 and turns.size() == total,
        "reason": reason, "engine_version": engine_version()}
