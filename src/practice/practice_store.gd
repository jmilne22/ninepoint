class_name PracticeStore
extends RefCounted

const PATH := "user://practice/state.json"
var path := PATH
var data := {"version": 1, "settings": {}, "completed": {}, "records": [], "reviews": {}, "active": {}}
var error := ""
var last_write_ok := true

func read() -> void:
    if not FileAccess.file_exists(path): return
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not value is Dictionary or int(value.get("version", 0)) != 1:
        error = "Practice data could not be read. The original file has been kept."
        return
    for key in data:
        if not value.has(key) or typeof(value[key]) != typeof(data[key]) and key != "version":
            error = "Practice data is incomplete. The original file has been kept."
            return
    if not value.records.all(func(record: Variant) -> bool: return record is Dictionary) or not value.reviews.values().all(func(review: Variant) -> bool: return review is Dictionary):
        error = "Practice history is damaged. The original file has been kept."
        return
    data = value
    for key in data.reviews:
        if data.reviews[key].get("availability", "") == "pending":
            data.reviews[key] = MatchAnalysis.unavailable(int(key), "interrupted")

func write() -> bool:
    last_write_ok = false
    if not error.is_empty(): return false
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(data))
    file.flush()
    var write_error := file.get_error()
    file.close()
    if write_error != OK: return false
    last_write_ok = DirAccess.rename_absolute(path + ".tmp", path) == OK
    return last_write_ok

func complete(id: String, record: Dictionary) -> int:
    for i in data.records.size():
        if data.records[i].get("id", "") == id: return i
    var saved := record.duplicate(true)
    saved["id"] = id
    data.records.append(saved)
    data.active = {}
    write()
    return data.records.size() - 1
