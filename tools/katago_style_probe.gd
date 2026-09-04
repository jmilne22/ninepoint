## Records comparable, non-prescriptive Human-SL temperament evidence.
##
## Run with:
##   godot --headless --path . --script res://tools/katago_style_probe.gd
##
## It deliberately uses fixed legal openings, but never asserts a particular
## move: KataGo may vary across supported CPU builds. The output retains the
## move trace and SGF for human comparison while gating only reliability.
extends SceneTree

const ARCHETYPES := {
    "steady": "res://data/opponents/wren_9x9.tres",
    "balanced": "res://data/opponents/abel_9x9.tres",
    "fighting": "res://data/opponents/kesh_9x9.tres",
}
const TURN_SAMPLES := 3

var _rows: Array[Dictionary] = []


func _initialize() -> void:
    for style in ["steady", "balanced", "fighting"]:
        var path := str(ARCHETYPES[style])
        var profile := load(path) as OpponentProfile
        _rows.append(await _probe(style, profile, path))
    var report := {
        "purpose": "Human-SL temperament comparison; move identity is informational, not a gate.",
        "profiles": _rows,
    }
    var output := ProjectSettings.globalize_path("user://katago-style-probe.json")
    var file := FileAccess.open(output, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(report, "  "))
        file.close()
    for row in _rows:
        print(JSON.stringify(row))
    print("KataGo style probe: report: %s" % output)
    quit(0 if _rows.all(func(row): return bool(row.get("reliable", false))) else 1)


func _probe(style: String, profile: OpponentProfile, path: String) -> Dictionary:
    if profile == null:
        return {"style": style, "path": path, "reliable": false, "reason": "profile did not load"}
    var game := OpponentFactory.new_game_for(profile)
    _play_opening(game)
    var opponent := GtpOpponent.new()
    opponent.setup(profile, game)
    var warmed := await opponent.prewarm()
    var trace: Array[String] = []
    var legal := true
    if warmed:
        for sample in TURN_SAMPLES:
            if game.state != GoGame.State.PLAYING:
                break
            var move: Dictionary = await opponent.choose_move(game)
            var kind := str(move.get("type", ""))
            if kind == "move":
                var point := int(move.get("point", -1))
                legal = legal and game.is_legal(point)
                trace.append(game.board.label(point) if legal else "invalid")
                if legal:
                    game.play(point)
            elif kind == "pass":
                trace.append("pass")
                game.pass_turn()
            elif kind == "resign":
                trace.append("resign")
                game.resign(game.to_move)
            else:
                legal = false
                trace.append("invalid")
            if game.state == GoGame.State.PLAYING:
                _play_first_legal(game)
    var row := {
        "style": style, "profile": str(profile.id), "path": path, "rank": profile.rank_label,
        "config": profile.gtp_config_path, "startup_ms": opponent.startup_ms,
        "move_latency_ms": opponent.last_move_ms, "legal_replies": opponent.legal_reply_count,
        "fallbacks": 1 if opponent.fallback_used else 0, "trace": trace,
        "sgf": GoSgf.to_sgf(game, {"PB": "style-probe opening", "PW": profile.display_name}),
        "reason": opponent.unavailable_reason,
        "reliable": warmed and legal and not opponent.fallback_used and opponent.legal_reply_count > 0,
    }
    opponent.shutdown()
    return row


func _play_opening(game: GoGame) -> void:
    var c := game.size() / 2
    var candidates := [Vector2i(c, c), Vector2i(1, 1), Vector2i(game.size() - 2, game.size() - 2)]
    for xy in candidates:
        if game.is_legal(game.board.idx(xy.x, xy.y)):
            game.play_xy(xy.x, xy.y)


func _play_first_legal(game: GoGame) -> void:
    var legal := game.legal_moves()
    if legal.is_empty():
        game.pass_turn()
    else:
        game.play(legal[0])
