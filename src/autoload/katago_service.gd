## Owns short-lived KataGo leases outside GoMatch. A lease is keyed by the
## executable/model/config combination and is either handed to one match or
## killed; no engine process is allowed to outlive its scene by accident.
extends Node

var _leases: Dictionary = {}


func prewarm(profile: OpponentProfile) -> void:
    if profile == null or profile.engine != "gtp":
        return
    var key := _key(profile)
    if _leases.has(key):
        return
    var engine := GtpOpponent.new()
    engine.setup(profile, GoGame.new(profile.board_size, profile.komi, 0))
    _leases[key] = {"engine": engine, "state": "warming"}
    _warm.call_deferred(key, engine)


func _warm(key: String, engine: GtpOpponent) -> void:
    var ok := await engine.prewarm()
    if not _leases.has(key) or _leases[key].get("engine") != engine:
        engine.shutdown()
        return
    _leases[key]["state"] = "ready" if ok else "failed"
    _leases[key]["reason"] = engine.unavailable_reason
    if not ok and OS.is_debug_build():
        print("KataGo warmup fallback: %s" % engine.unavailable_reason)


func take_ready(profile: OpponentProfile) -> GtpOpponent:
    var key := _key(profile)
    if not _leases.has(key) or _leases[key].get("state") != "ready":
        return null
    var engine := _leases[key]["engine"] as GtpOpponent
    _leases.erase(key)
    return engine


func state_for(profile: OpponentProfile) -> String:
    var entry: Dictionary = _leases.get(_key(profile), {})
    return str(entry.get("state", "none"))


func cancel(profile: OpponentProfile) -> void:
    var key := _key(profile)
    if not _leases.has(key):
        return
    var engine := _leases[key].get("engine") as GtpOpponent
    _leases.erase(key)
    if engine != null:
        engine.shutdown()


func _exit_tree() -> void:
    for entry in _leases.values():
        var engine := entry.get("engine") as GtpOpponent
        if engine != null:
            engine.shutdown()
    _leases.clear()


func _key(profile: OpponentProfile) -> String:
    return "%s|%s|%s|%s" % [profile.gtp_command, profile.gtp_model_path,
        profile.gtp_config_path, profile.gtp_args]
