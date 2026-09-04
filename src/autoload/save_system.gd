## Save slots as plain, versioned, human-readable JSON in user://.
extends Node

const SLOT_COUNT := 3
const SAVE_VERSION := 1

## Map display names, read from the map's own JSON the first time a slot asks
## for one. There is no second table of place names to drift out of date.
var _place_names := {}


func path_for(slot: int) -> String:
    return "user://save_%d.json" % slot


func has_save(slot: int) -> bool:
    return FileAccess.file_exists(path_for(slot))


func any_save() -> bool:
    for s in range(1, SLOT_COUNT + 1):
        if has_save(s):
            return true
    return false


func newest_slot() -> int:
    var best := -1
    var best_time := -1
    for s in range(1, SLOT_COUNT + 1):
        if not has_save(s):
            continue
        var t := int(FileAccess.get_modified_time(path_for(s)))
        if t > best_time:
            best_time = t
            best = s
    return best


## The lowest slot with nothing in it, or -1 when all three are taken. New Game
## uses this to take a slot without asking; when it returns -1 it has to ask.
func first_empty_slot() -> int:
    for s in range(1, SLOT_COUNT + 1):
        if not has_save(s):
            return s
    return -1


func save_game(slot: int = 1) -> bool:
    var data := GameState.to_dict()
    data["version"] = SAVE_VERSION
    data["saved_at"] = Time.get_datetime_string_from_system()
    var f := FileAccess.open(path_for(slot), FileAccess.WRITE)
    if f == null:
        push_error("SaveSystem: cannot write slot %d" % slot)
        return false
    f.store_string(JSON.stringify(data, "  "))
    f.close()
    GameState.active_slot = slot
    EventBus.game_saved.emit(slot)
    return true


func load_game(slot: int = 1) -> bool:
    if not has_save(slot):
        return false
    var text := FileAccess.get_file_as_string(path_for(slot))
    var parsed = JSON.parse_string(text)
    if not (parsed is Dictionary):
        # A failed load must leave the running game alone: half-restoring a
        # playthrough from a broken file is worse than refusing.
        push_error("SaveSystem: slot %d is corrupt" % slot)
        return false
    if int(parsed.get("version", 0)) != SAVE_VERSION:
        push_warning("SaveSystem: slot %d was written by another version" % slot)
    GameState.from_dict(parsed)
    GameState.active_slot = slot
    EventBus.game_loaded.emit(slot)
    return true


## Everything a slot list needs, parsed once. `status` is "empty", "corrupt" or
## "ok"; the rest of the keys are only present on "ok".
func slot_info(slot: int) -> Dictionary:
    if not has_save(slot):
        return {"status": "empty"}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path_for(slot)))
    if not (parsed is Dictionary):
        return {"status": "corrupt"}
    var d: Dictionary = parsed
    return {
        "status": "ok",
        "player_name": str(d.get("player_name", "?")),
        "rank": GoRank.to_string_rank(int(d.get("rank_strength", -1))),
        "day": int(d.get("day", 1)),
        "time_block": str(d.get("time_block", "afternoon")),
        "place": _place_name(str(d.get("current_map", ""))),
        "minutes": int(float(d.get("playtime", 0.0)) / 60.0),
        "saved_at": str(d.get("saved_at", "")),
    }


## One-line description for the title screen's Continue button.
func slot_summary(slot: int) -> String:
    var info := slot_info(slot)
    if info["status"] != "ok":
        return str(info["status"])
    return "%s  -  %s  -  %d min" % [info["player_name"], info["rank"], info["minutes"]]


func delete_save(slot: int) -> bool:
    if not has_save(slot):
        return false
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path_for(slot)))
    return not has_save(slot)


func _place_name(map_id: String) -> String:
    if map_id == "":
        return "?"
    if _place_names.has(map_id):
        return _place_names[map_id]
    var name := map_id
    var path := "res://data/maps/%s.json" % map_id
    if FileAccess.file_exists(path):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if parsed is Dictionary:
            name = str(parsed.get("name", map_id))
    _place_names[map_id] = name
    return name
