## Real-process smoke test for the bundled Linux KataGo package.
extends SceneTree


func _initialize() -> void:
    var profile := _profile(20.0)
    var game := GoGame.new(9, 5.5)
    game.play_xy(3, 5) # D4 in GTP coordinates
    var opponent := OpponentFactory.create(profile, game)
    var move: Dictionary = await opponent.choose_move(game)
    if str(move.get("type", "")) != "move" or not game.is_legal(int(move.get("point", -1))):
        printerr("KataGo smoke failed: %s" % move)
        quit(1)
        return
    var gtp := opponent as GtpOpponent
    opponent.shutdown()
    if gtp == null or not gtp.engine_started or gtp.fallback_used or gtp.legal_reply_count != 1 or not gtp.shutdown_complete:
        printerr("KataGo smoke did not record a clean engine reply.")
        quit(1)
        return
    if not await _negative_fallbacks():
        quit(1)
        return
    print("KataGo smoke: legal %s reply on 9x9" % game.board.label(int(move["point"])))
    quit(0)


func _profile(timeout: float) -> OpponentProfile:
    var profile := OpponentProfile.new()
    profile.id = &"katago_smoke"
    profile.engine = "gtp"
    profile.gtp_command = "res://packaging/katago/katago-gtp.sh"
    profile.gtp_args = PackedStringArray(["gtp", "-config",
        "res://packaging/katago/config/gtp_human_fast.cfg", "-model",
        "res://packaging/katago/models/kata1-b18c384nbt-s9996604416-d4316597426.bin.gz",
        "-human-model", "res://packaging/katago/models/b18c384nbt-humanv0.bin.gz"])
    profile.gtp_time_per_move = timeout
    return profile


## Failure variants stay deterministic enough for CI without changing any
## shipped profile: both return a legal local move and finish their subprocess.
func _negative_fallbacks() -> bool:
    var missing := _profile(1.0)
    missing.gtp_command = "/nonexistent/katago"
    var missing_game := GoGame.new(9, 5.5)
    var missing_opponent := OpponentFactory.create(missing, missing_game)
    var missing_move: Dictionary = missing_opponent.choose_move(missing_game)
    missing_opponent.shutdown()
    if not (missing_opponent is HeuristicOpponent) or not missing_game.is_legal(int(missing_move.get("point", -1))):
        printerr("Missing KataGo artifact did not use the safe fallback.")
        return false

    var tiny_game := GoGame.new(9, 5.5)
    tiny_game.play_xy(3, 5)
    var tiny_opponent := OpponentFactory.create(_profile(0.001), tiny_game)
    var tiny_move: Dictionary = await tiny_opponent.choose_move(tiny_game)
    var tiny_gtp := tiny_opponent as GtpOpponent
    tiny_opponent.shutdown()
    if tiny_gtp == null or not tiny_gtp.fallback_used \
        or not tiny_gtp.shutdown_complete or not tiny_game.is_legal(int(tiny_move.get("point", -1))):
        printerr("Tiny KataGo timeout did not use the safe fallback.")
        return false
    print("KataGo smoke: missing artifact and tiny timeout both fell back safely")
    return true
