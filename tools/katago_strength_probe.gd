## Measures what the cast actually plays at, in whole 9x9 games.
##
##   godot --headless --path . --script res://tools/katago_strength_probe.gd -- \
##       [--cells=beginners,temperature,anchors,floor,smoke] [--games=8] [--concurrent=2] \
##       [--beginners=abel,wren,dov] [--rungs=20k,15k] [--mem-floor-gb=6] [--tag=before]
##
## M39's calibration proved every profile answers in under two seconds with a
## legal move. It never asked whether a "20 kyu" plays like one, and the owner
## found out at the keyboard that it does not. This script plays each beginner
## profile against a reference ladder -- the same Human-SL model at temperature
## 1.0, which KataGo's own notes call a realistic individual of that rank -- and
## records win rates and score margins, so a profile's effective rank is a
## number and not an impression. GNU Go anchors the ladder from outside it.
##
## Cost, because the first version of this script took the machine down: one
## KataGo process is about a gigabyte, so one process plays BOTH sides of a game
## (kata-set-param switches the Human-SL profile and temperature before each
## move), `--concurrent` is a count of gigabytes as much as of games, and no
## game starts while MemAvailable is under `--mem-floor-gb`. Eight at once with
## nothing else running is about 20 minutes per hundred games.
##
## Everything here is pure (no autoloads), so it runs under --script. The
## report is user://katago-strength-<tag>.json.
extends SceneTree

const BOARD := 9
const KOMI := 5.5
## Twice a long 9x9 game. A game that gets here is scored where it stands.
const MOVE_CAP := 160
const GAMES_DEFAULT := 8
const CONCURRENT_DEFAULT := 2
const MEM_FLOOR_GB_DEFAULT := 6.0
## A reply on a loaded machine; a fallback here would score nothing useful.
const REPLY_TIMEOUT := 60.0
const BASE_CONFIG := "res://packaging/katago/config/gtp_human_fast.cfg"
## Any shipped profile will do as the carrier of the launcher and model paths.
const TEMPLATE_PROFILE := "res://data/opponents/wren_9x9.tres"
## The keys on which the generated configs differ from the base and from each
## other. A side is exactly these values; everything else is the base.
const SIDE_KEYS := ["humanSLProfile", "chosenMoveTemperatureEarly", "chosenMoveTemperature",
    "chosenMoveTemperatureOnlyBelowProb", "staticScoreUtilityFactor",
    "humanSLRootExploreProbWeightless", "humanSLRootExploreProbWeightful"]
const REFERENCE_RANKS := ["20k", "15k", "10k"]
const BEGINNERS := ["abel", "wren", "dov", "pip", "moss", "kesh"]
const TEMPERATURES := [[0.65, 0.45], [0.85, 0.70], [1.0, 1.0], [1.2, 1.2]]

var _games_per_cell := GAMES_DEFAULT
var _concurrent := CONCURRENT_DEFAULT
var _mem_floor_gb := MEM_FLOOR_GB_DEFAULT
var _tag := "probe"
var _beginners := PackedStringArray(BEGINNERS)
var _rungs := PackedStringArray(REFERENCE_RANKS)
var _jobs: Array[Dictionary] = []
var _rows: Array[Dictionary] = []
var _workers := 0
var _started_ms := 0
var _base_values := {}


func _initialize() -> void:
    var wanted := _parse_args()
    _base_values = _config_values(BASE_CONFIG)
    var cells: Array[Dictionary] = []
    if "beginners" in wanted:
        cells.append_array(_beginner_cells())
    if "temperature" in wanted:
        cells.append_array(_temperature_cells())
    if "anchors" in wanted:
        cells.append_array(_anchor_cells())
    if "floor" in wanted:
        cells.append_array(_floor_cells())
    if "smoke" in wanted:
        cells.append(_cell(_shipped("wren_9x9"), _reference("20k")))
        cells.append(_cell(_gnugo(10), _reference("20k")))
        cells.append(_cell(_heuristic("1d", 0.0, 2), _reference("20k")))
    for cell in cells:
        for i in _games_per_cell:
            _jobs.append({"cell": cell, "index": i})
    print("Strength probe: %d cells, %d games, %d at a time (about %d GB), floor %.0f GB, tag %s" % [
        cells.size(), _jobs.size(), _concurrent, _concurrent, _mem_floor_gb, _tag])
    _started_ms = Time.get_ticks_msec()
    for w in _concurrent:
        _workers += 1
        _worker()
    while _workers > 0:
        await process_frame
    var summary := _summarise(cells)
    var report := {
        "tag": _tag, "board": BOARD, "komi": KOMI, "games_per_cell": _games_per_cell,
        "seconds": float(Time.get_ticks_msec() - _started_ms) / 1000.0,
        "cells": summary, "effective": _effective_ranks(summary), "games": _rows,
    }
    var output := ProjectSettings.globalize_path("user://katago-strength-%s.json" % _tag)
    var file := FileAccess.open(output, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(report, "  "))
        file.close()
    _print_summary(report)
    print("Strength probe: %d games in %.0f s; report: %s" % [_rows.size(), report["seconds"], output])
    quit(0)


func _parse_args() -> PackedStringArray:
    var wanted := PackedStringArray(["beginners", "temperature", "anchors"])
    for a in OS.get_cmdline_user_args():
        var arg := str(a)
        if arg.begins_with("--cells="):
            wanted = arg.trim_prefix("--cells=").split(",", false)
        elif arg.begins_with("--games="):
            _games_per_cell = maxi(1, int(arg.trim_prefix("--games=")))
        elif arg.begins_with("--concurrent="):
            _concurrent = maxi(1, int(arg.trim_prefix("--concurrent=")))
        elif arg.begins_with("--mem-floor-gb="):
            _mem_floor_gb = maxf(0.0, float(arg.trim_prefix("--mem-floor-gb=")))
        elif arg.begins_with("--rungs="):
            _rungs = arg.trim_prefix("--rungs=").split(",", false)
        elif arg.begins_with("--beginners="):
            _beginners = arg.trim_prefix("--beginners=").split(",", false)
        elif arg.begins_with("--tag="):
            _tag = arg.trim_prefix("--tag=")
    return wanted


# --- the matrix ---------------------------------------------------------------

## A cell is one subject against one reference for N games, colours alternating.
func _cell(subject: Dictionary, reference: Dictionary) -> Dictionary:
    return {"id": "%s vs %s" % [subject["name"], reference["name"]],
        "subject": subject, "reference": reference}


func _reference(rank: String) -> Dictionary:
    return _human(rank, 1.0, 1.0)


## A Human-SL side: the base config with a rank and a temperature.
func _human(rank: String, early: float, late: float) -> Dictionary:
    var values := _base_values.duplicate()
    values["humanSLProfile"] = "preaz_%s" % rank
    values["chosenMoveTemperatureEarly"] = "%.2f" % early
    values["chosenMoveTemperature"] = "%.2f" % late
    return {"kind": "human", "name": "hsl_%s@%.2f/%.2f" % [rank, early, late],
        "rank": rank, "values": values}


## A shipped profile: its own generated config, read for the keys that matter.
func _shipped(id: String) -> Dictionary:
    var profile := load("res://data/opponents/%s.tres" % id) as OpponentProfile
    return {"kind": "human", "name": id, "rank": profile.rank_label,
        "values": _config_values(profile.gtp_config_path)}


func _gnugo(level: int) -> Dictionary:
    return {"kind": "gnugo", "name": "gnugo_L%d" % level, "level": level}


func _heuristic(rank: String, mistake: float, depth: int) -> Dictionary:
    return {"kind": "heuristic", "name": "heuristic_%s" % rank, "rank": rank,
        "mistake": mistake, "depth": depth}


## The shipped beginner profiles against every rung of the ladder.
func _beginner_cells() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for id in _beginners:
        for rank in _rungs:
            out.append(_cell(_shipped("%s_9x9" % id), _reference(rank)))
    return out


## The one knob, swept: the 20k profile at the shipped steady temperature,
## KataGo's example, its realistic setting, and above it.
func _temperature_cells() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for pair in TEMPERATURES:
        for rank in ["20k", "15k"]:
            out.append(_cell(_human("20k", pair[0], pair[1]), _reference(rank)))
    return out


## Can the model be made weaker than its weakest profile? Temperature normally
## touches only moves under 1% probability, which is why 1.2 measured no
## different from 1.0; applied to every move it flattens the whole policy.
func _floor_cells() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for temp in [1.5, 2.0]:
        var side := _human("20k", temp, temp)
        side["values"]["chosenMoveTemperatureOnlyBelowProb"] = "1.0"
        side["name"] = "hsl_20k@%.2f-all" % temp
        out.append(_cell(side, _reference("20k")))
    return out


## Is the ladder ordered, and where does a program that is not KataGo land on
## it? Plus the heuristic's own labels, which M40 put in doubt.
func _anchor_cells() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for i in REFERENCE_RANKS.size() - 1:
        out.append(_cell(_reference(REFERENCE_RANKS[i + 1]), _reference(REFERENCE_RANKS[i])))
    for rank in REFERENCE_RANKS:
        out.append(_cell(_gnugo(10), _reference(rank)))
    out.append(_cell(_heuristic("1d", 0.0, 2), _reference("20k")))
    out.append(_cell(_heuristic("20k", 0.45, 0), _reference("20k")))
    return out


func _config_values(path: String) -> Dictionary:
    var out := {}
    var re := RegEx.new()
    re.compile("(?m)^(\\w+)\\s*=\\s*(\\S+)")
    for m in re.search_all(FileAccess.get_file_as_string(path)):
        if m.get_string(1) in SIDE_KEYS:
            out[m.get_string(1)] = m.get_string(2)
    return out


# --- the table: one KataGo process for a whole game ---------------------------

## Both Human-SL sides of a game live in one process; the parameters that make
## a side are set before each of its moves and only when they change. The
## process is started on the base config, so a shipped profile is reproduced by
## its values on the keys the generator touches, which are the only ones that
## differ between the generated files.
class Table:
    var pipe := EnginePipe.new()
    var applied := {}
    var ok := true
    var reason := ""
    var reply_ms := 0
    var replies := 0

    func open(template: OpponentProfile) -> bool:
        var args := PackedStringArray()
        for argument in template.gtp_args:
            args.append(str(argument).replace("{model}", template.gtp_model_path)
                .replace("{config}", BASE_CONFIG))
        if not pipe.open(template.gtp_command, args):
            ok = false
            reason = "engine did not start"
            return false
        for text in ["protocol_version", "boardsize %d" % BOARD, "clear_board", "komi %s" % str(KOMI)]:
            await command(text)
        return ok

    func apply(values: Dictionary) -> void:
        for key in values:
            if applied.get(key, "") != values[key]:
                await command("kata-set-param %s %s" % [key, values[key]])
                applied[key] = values[key]

    func genmove(colour: int) -> String:
        var started := Time.get_ticks_msec()
        var reply := (await command("genmove %s" % ("b" if colour == GoBoard.BLACK else "w"))).strip_edges().to_upper()
        reply_ms += Time.get_ticks_msec() - started
        replies += 1
        return reply

    func play(colour: int, where: String) -> void:
        await command("play %s %s" % ["b" if colour == GoBoard.BLACK else "w", where])

    func command(text: String) -> String:
        if not ok or not pipe.is_open():
            return ""
        pipe.write_line(text)
        var reply := ""
        while pipe.is_open():
            var read: Dictionary = await pipe.read_line(REPLY_TIMEOUT)
            if not bool(read.get("ready", false)):
                ok = false
                reason = "engine timed out on %s" % text
                return ""
            var line := str(read.get("line", ""))
            if line.begins_with("="):
                reply = line.substr(1).strip_edges()
            elif line.begins_with("?"):
                ok = false
                reason = "engine rejected %s: %s" % [text, line]
                return ""
            elif line.strip_edges() == "":
                return reply
        ok = false
        reason = "engine closed on %s" % text
        return ""

    func close() -> void:
        pipe.close()


## The other kinds of side: GNU Go in its own small process, the heuristic in
## this one. Both fit GoOpponent, and GtpOpponent replays the game into GNU Go.
func _make_outside(spec: Dictionary, game: GoGame, seed: int) -> GoOpponent:
    if str(spec["kind"]) == "heuristic":
        var p := OpponentProfile.new()
        p.rank_label = str(spec["rank"])
        p.mistake_rate = float(spec["mistake"])
        p.reading_depth = int(spec["depth"])
        p.rng_seed = seed
        var brain := HeuristicOpponent.new()
        brain.setup(p, game)
        return brain
    var profile := (load(TEMPLATE_PROFILE) as OpponentProfile).duplicate() as OpponentProfile
    profile.id = StringName(str(spec["name"]))
    profile.gtp_command = "res://tools/gnugo-gtp.sh"
    profile.gtp_args = PackedStringArray(["--level", str(int(spec["level"]))])
    profile.gtp_time_per_move = REPLY_TIMEOUT
    profile.gtp_startup_timeout = REPLY_TIMEOUT
    var engine := GtpOpponent.new()
    engine.setup(profile, game)
    return engine


# --- one game -----------------------------------------------------------------

func _worker() -> void:
    while not _jobs.is_empty():
        await _wait_for_memory()
        var job: Dictionary = _jobs.pop_front()
        var row := await _play(job["cell"], int(job["index"]))
        _rows.append(row)
        print(JSON.stringify(row))
    _workers -= 1


## The OS's idea of available memory, in GB; -1 where it has none.
static func _available_gb() -> float:
    var info := OS.get_memory_info()
    if not info.has("available") or int(info["available"]) <= 0:
        return -1.0
    return float(info["available"]) / (1024.0 * 1024.0 * 1024.0)


func _wait_for_memory() -> void:
    var warned := false
    while _available_gb() >= 0.0 and _available_gb() < _mem_floor_gb:
        if not warned:
            print("Strength probe: waiting, %.1f GB available is under the %.0f GB floor" % [_available_gb(), _mem_floor_gb])
            warned = true
        for i in 120:
            await process_frame


func _play(cell: Dictionary, index: int) -> Dictionary:
    var game := GoGame.new(BOARD, KOMI, 0)
    var subject_colour := GoBoard.BLACK if index % 2 == 0 else GoBoard.WHITE
    var sides := {subject_colour: cell["subject"], GoBoard.opponent(subject_colour): cell["reference"]}
    var row := {"cell": cell["id"], "index": index,
        "subject_colour": GoBoard.color_name(subject_colour), "ok": true, "reason": ""}
    var started := Time.get_ticks_msec()
    var table := Table.new()
    var outside := {}
    var template := load(TEMPLATE_PROFILE) as OpponentProfile
    if not await table.open(template):
        row["ok"] = false
        row["reason"] = table.reason
    for colour in sides:
        if str(sides[colour]["kind"]) != "human":
            var other := _make_outside(sides[colour], game, 1000 + index + colour)
            outside[colour] = other
            if other is GtpOpponent and not await (other as GtpOpponent).prewarm():
                row["ok"] = false
                row["reason"] = "%s did not start: %s" % [sides[colour]["name"], (other as GtpOpponent).unavailable_reason]
    while row["ok"] and game.state == GoGame.State.PLAYING and game.moves.size() < MOVE_CAP:
        var colour := game.to_move
        var vertex := ""
        if outside.has(colour):
            var move: Dictionary = await outside[colour].choose_move(game)
            var kind := str(move.get("type", ""))
            if outside[colour] is GtpOpponent and (outside[colour] as GtpOpponent).fallback_used:
                row["ok"] = false
                row["reason"] = "%s fell back" % sides[colour]["name"]
                break
            vertex = "PASS" if kind == "pass" else ("RESIGN" if kind == "resign" else game.board.label(int(move["point"])).to_upper())
            if vertex != "RESIGN":
                await table.play(colour, vertex)
        else:
            await table.apply(sides[colour]["values"])
            vertex = await table.genmove(colour)
        if not table.ok:
            row["ok"] = false
            row["reason"] = table.reason
            break
        if vertex == "PASS":
            game.pass_turn()
        elif vertex == "RESIGN":
            game.resign(colour)
        else:
            var point := game.board.from_label(vertex)
            if point >= 0 and game.is_legal(point):
                game.play(point)
            else:
                row["ok"] = false
                row["reason"] = "%s played an illegal move (%s)" % [sides[colour]["name"], vertex]
    row["moves"] = game.moves.size()
    row["sgf"] = GoSgf.to_sgf(game)
    row["ms_per_engine_move"] = table.reply_ms / maxi(table.replies, 1)
    if row["ok"]:
        await _score(game, table, subject_colour, row)
    row["seconds"] = float(Time.get_ticks_msec() - started) / 1000.0
    table.close()
    for colour in outside:
        outside[colour].shutdown()
    return row


## Who won and by how much, from the subject's side. A resignation has a winner
## and no margin. Anything else is the engine's final_score on the position it
## has played every move of, with the game's own heuristic count alongside.
func _score(game: GoGame, table: Table, subject_colour: int, row: Dictionary) -> void:
    if game.state == GoGame.State.FINISHED and bool(game.result.get("by_resignation", false)):
        row["result"] = str(game.result["text"])
        row["subject_won"] = int(game.result["winner"]) == subject_colour
        row["margin"] = null
        return
    var dead := GoScoring.estimate_dead(game.board)
    var own := GoScoring.score(game.board, dead, game.captures, game.komi)
    var own_margin := float(own["margin"]) * (1.0 if int(own["winner"]) == subject_colour else -1.0)
    row["own_count_margin"] = own_margin
    var text := (await table.command("final_score")).strip_edges().to_upper()
    if text.length() >= 2 and (text.begins_with("B+") or text.begins_with("W+")):
        var winner := GoBoard.BLACK if text.begins_with("B") else GoBoard.WHITE
        var amount := float(text.substr(2))
        row["result"] = text
        row["subject_won"] = winner == subject_colour
        row["margin"] = amount if winner == subject_colour else -amount
    elif text == "0":
        row["result"] = "jigo"
        row["subject_won"] = false
        row["margin"] = 0.0
    else:
        row["result"] = "own count %s" % str(own["text"])
        row["subject_won"] = own_margin > 0.0
        row["margin"] = own_margin
        row["reason"] = "engine gave no final_score (%s)" % text


# --- the report ---------------------------------------------------------------

func _summarise(cells: Array[Dictionary]) -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for cell in cells:
        var rows := _rows.filter(func(r): return str(r["cell"]) == str(cell["id"]) and bool(r["ok"]))
        var wins := 0
        var margins: Array[float] = []
        var ms := 0
        for r in rows:
            wins += 1 if bool(r["subject_won"]) else 0
            if r["margin"] != null:
                margins.append(float(r["margin"]))
            ms += int(r["ms_per_engine_move"])
        margins.sort()
        var mean := 0.0
        for m in margins:
            mean += m
        mean = mean / maxf(margins.size(), 1.0)
        out.append({"cell": cell["id"], "subject": cell["subject"]["name"],
            "reference": cell["reference"]["name"],
            "reference_rank": str(cell["reference"].get("rank", "")),
            "games": rows.size(), "discarded": _games_per_cell - rows.size(), "wins": wins,
            "win_rate": float(wins) / maxf(rows.size(), 1.0),
            "scored": margins.size(), "mean_margin": mean,
            "median_margin": margins[int(margins.size() / 2)] if not margins.is_empty() else 0.0,
            "ms_per_engine_move": ms / maxi(rows.size(), 1)})
    return out


## Where on the ladder a subject scores fifty percent, by linear interpolation
## on win rate between the two rungs it crosses. Outside the ladder, the report
## says which end and by how much rather than inventing a number.
func _effective_ranks(summary: Array[Dictionary]) -> Dictionary:
    var by_subject := {}
    for cell in summary:
        if str(cell["reference_rank"]) == "":
            continue
        if not by_subject.has(cell["subject"]):
            by_subject[cell["subject"]] = []
        by_subject[cell["subject"]].append(cell)
    var out := {}
    for subject in by_subject:
        var cells: Array = by_subject[subject]
        cells.sort_custom(func(a, b): return GoRank.from_string(a["reference_rank"]) < GoRank.from_string(b["reference_rank"]))
        if cells.size() < 2:
            continue
        var estimate := ""
        var strength := -1.0
        var first: Dictionary = cells[0]
        var last: Dictionary = cells[-1]
        if float(first["win_rate"]) < 0.5:
            estimate = "below %s (%.0f%% against it)" % [first["reference_rank"], 100.0 * float(first["win_rate"])]
        elif float(last["win_rate"]) >= 0.5:
            estimate = "above %s (%.0f%% against it)" % [last["reference_rank"], 100.0 * float(last["win_rate"])]
        else:
            for i in cells.size() - 1:
                var lo: Dictionary = cells[i]
                var hi: Dictionary = cells[i + 1]
                var wl := float(lo["win_rate"])
                var wh := float(hi["win_rate"])
                if wl >= 0.5 and wh < 0.5:
                    var t := (wl - 0.5) / maxf(wl - wh, 0.0001)
                    strength = float(GoRank.from_string(lo["reference_rank"])) \
                        + t * float(GoRank.from_string(hi["reference_rank"]) - GoRank.from_string(lo["reference_rank"]))
                    estimate = GoRank.to_string_rank(int(round(strength)))
                    break
        out[subject] = {"estimate": estimate, "strength": strength,
            "win_rates": cells.map(func(c): return "%s:%.0f%%" % [c["reference_rank"], 100.0 * float(c["win_rate"])])}
    return out


func _print_summary(report: Dictionary) -> void:
    print("")
    print("%-34s %-18s %5s %5s %8s %8s %6s" % ["cell", "", "games", "wins", "mean", "median", "ms/mv"])
    for c in report["cells"]:
        print("%-34s %-18s %5d %5d %8.1f %8.1f %6d%s" % [c["subject"], c["reference"], c["games"],
            c["wins"], c["mean_margin"], c["median_margin"], c["ms_per_engine_move"],
            "  (%d discarded)" % int(c["discarded"]) if int(c["discarded"]) > 0 else ""])
    print("")
    for subject in report["effective"]:
        var e: Dictionary = report["effective"][subject]
        print("%-28s effective %-24s %s" % [subject, e["estimate"], " ".join(e["win_rates"])])
