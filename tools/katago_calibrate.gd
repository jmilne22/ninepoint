## Release calibration for every shipped KataGo opponent profile.
##
## Run with:
##   godot --headless --path . --script res://tools/katago_calibrate.gd
##
## This deliberately samples a fixed, legal opening rather than trying to rate
## engines with noisy self-play. It records the package evidence needed for a
## cast promotion: startup, ordinary reply latency, legality, fallbacks, and
## whether the sample ended in a pass/resignation/capture result.
extends SceneTree

const PROFILE_DIR := "res://data/opponents"
const TURN_SAMPLES := 3
const TURN_LIMIT_MS := 2000

var _rows: Array[Dictionary] = []


func _initialize() -> void:
    var paths := _profiles()
    for path in paths:
        var profile := load(path) as OpponentProfile
        if profile == null or profile.engine != "gtp":
            continue
        var row := await _exercise(profile, path)
        _rows.append(row)
        print(JSON.stringify(row))
    var report := {
        "target": "linux-x64 eigen-avx2",
        "turn_limit_ms": TURN_LIMIT_MS,
        "profiles": _rows,
        "passed": _rows.all(func(row): return bool(row.get("passed", false))),
    }
    var output := ProjectSettings.globalize_path("user://katago-calibration.json")
    var file := FileAccess.open(output, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(report, "  "))
        file.close()
    print("KataGo calibration: %d profiles; report: %s" % [_rows.size(), output])
    quit(0 if bool(report["passed"]) else 1)


func _profiles() -> PackedStringArray:
    var found := PackedStringArray()
    var dir := DirAccess.open(PROFILE_DIR)
    if dir == null:
        return found
    dir.list_dir_begin()
    var name := dir.get_next()
    while name != "":
        if not dir.current_is_dir() and name.ends_with(".tres"):
            found.append(PROFILE_DIR.path_join(name))
        name = dir.get_next()
    found.sort()
    return found


func _exercise(profile: OpponentProfile, path: String) -> Dictionary:
    var game := OpponentFactory.new_game_for(profile)
    game.capture_goal = profile.capture_goal
    _play_opening(game)
    var opponent := GtpOpponent.new()
    opponent.setup(profile, game)
    var warmed := await opponent.prewarm()
    var latencies := PackedInt32Array()
    var passes := 0
    var resignations := 0
    var legal := true
    if warmed:
        for sample in TURN_SAMPLES:
            if game.state != GoGame.State.PLAYING:
                break
            var before := opponent.legal_reply_count
            var move: Dictionary = await opponent.choose_move(game)
            var kind := str(move.get("type", ""))
            if kind == "move":
                var point := int(move.get("point", -1))
                legal = legal and game.is_legal(point)
                if legal:
                    game.play(point)
            elif kind == "pass":
                passes += 1
                game.pass_turn()
            elif kind == "resign":
                resignations += 1
                game.resign(game.to_move)
            else:
                legal = false
            if opponent.legal_reply_count > before:
                latencies.append(opponent.last_move_ms)
            if game.state == GoGame.State.PLAYING:
                _play_first_legal(game)
    var ordinary := true
    for latency in latencies:
        ordinary = ordinary and latency >= 0 and latency < TURN_LIMIT_MS
    var result := "sample_complete"
    if game.state == GoGame.State.FINISHED:
        result = str(game.result.get("text", "finished"))
    elif game.state == GoGame.State.SCORING:
        result = "two passes"
    var row := {
        "profile": str(profile.id), "path": path, "rank": profile.rank_label,
        "style": profile.gtp_style,
        "board_size": game.size(), "capture_goal": profile.capture_goal,
        "startup_ms": opponent.startup_ms, "move_latencies_ms": latencies,
        "legal_replies": opponent.legal_reply_count, "passes": passes,
        "resignations": resignations, "fallbacks": 1 if opponent.fallback_used else 0,
        "result": result, "reason": opponent.unavailable_reason,
        "passed": warmed and legal and not opponent.fallback_used and ordinary
            and opponent.legal_reply_count > 0,
    }
    opponent.shutdown()
    return row


func _play_opening(game: GoGame) -> void:
    var c := game.size() / 2
    var candidates := [Vector2i(c, c), Vector2i(1, 1), Vector2i(game.size() - 2, game.size() - 2),
        Vector2i(1, game.size() - 2), Vector2i(game.size() - 2, 1)]
    for xy in candidates:
        if game.state == GoGame.State.PLAYING and game.board.in_bounds(xy.x, xy.y) \
                and game.is_legal(game.board.idx(xy.x, xy.y)):
            game.play_xy(xy.x, xy.y)
        if game.moves.size() >= 3:
            return


func _play_first_legal(game: GoGame) -> void:
    var legal := game.legal_moves()
    if legal.is_empty():
        game.pass_turn()
    else:
        game.play(legal[0])
