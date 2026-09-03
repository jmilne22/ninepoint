## Loads every script, scene and resource in the project and reports failures.
##
## The import log is not a reliable gate: a patch that deleted half of
## go_match.gd produced a clean "all scripts compile" line and a broken game.
## Loading each file is the only check that actually proves it parses.
extends SceneTree

const ROOTS := ["res://src", "res://tests", "res://data", "res://art"]
const EXTS := ["gd", "tscn", "tres", "fnt"]


func _initialize() -> void:
    var failures: Array[String] = []
    var checked := 0
    for root in ROOTS:
        checked += _walk(root, failures)
    if failures.is_empty():
        print("load check: %d files, all load" % checked)
        quit(0)
        return
    printerr("load check: %d of %d files FAILED" % [failures.size(), checked])
    for f in failures:
        printerr("  " + f)
    quit(1)


func _walk(path: String, failures: Array[String]) -> int:
    var count := 0
    var d := DirAccess.open(path)
    if d == null:
        return 0
    d.list_dir_begin()
    var name := d.get_next()
    while name != "":
        if name.begins_with("."):
            name = d.get_next()
            continue
        var full := path.path_join(name)
        if d.current_is_dir():
            count += _walk(full, failures)
        else:
            var clean := name.trim_suffix(".remap")
            if EXTS.has(clean.get_extension()):
                count += 1
                var res = ResourceLoader.load(path.path_join(clean))
                if res == null:
                    failures.append(path.path_join(clean))
                elif res is GDScript and not (res as GDScript).can_instantiate() \
                        and (res as GDScript).get_instance_base_type() == "":
                    failures.append(path.path_join(clean) + " (does not compile)")
        name = d.get_next()
    d.list_dir_end()
    return count
