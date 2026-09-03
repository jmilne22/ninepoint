## Save slots as plain, versioned, human-readable JSON in user://.
extends Node

const SLOT_COUNT := 3
const SAVE_VERSION := 1


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
    EventBus.game_saved.emit(slot)
    return true


func load_game(slot: int = 1) -> bool:
    if not has_save(slot):
        return false
    var text := FileAccess.get_file_as_string(path_for(slot))
    var parsed = JSON.parse_string(text)
    if not (parsed is Dictionary):
        push_error("SaveSystem: slot %d is corrupt" % slot)
        return false
    if int(parsed.get("version", 0)) != SAVE_VERSION:
        push_warning("SaveSystem: slot %d was written by another version" % slot)
    GameState.from_dict(parsed)
    EventBus.game_loaded.emit(slot)
    return true


## One-line description for the title screen's Continue button.
func slot_summary(slot: int) -> String:
    if not has_save(slot):
        return "empty"
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path_for(slot)))
    if not (parsed is Dictionary):
        return "corrupt"
    var rank := GoRank.to_string_rank(int(parsed.get("rank_strength", -1)))
    var mins := int(float(parsed.get("playtime", 0.0)) / 60.0)
    return "%s  -  %s  -  %d min" % [str(parsed.get("player_name", "?")), rank, mins]


func delete_save(slot: int) -> void:
    if has_save(slot):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path_for(slot)))
