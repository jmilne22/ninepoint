## Run before any fixture tool writes a slot. Both languages must resolve the
## same isolated directory, or a harmless-looking test can overwrite a real save.
extends SceneTree


func _initialize() -> void:
    var base := OS.get_environment("XDG_DATA_HOME")
    if base.is_empty():
        base = OS.get_environment("HOME").path_join(".local/share")
    var expected := base.path_join("godot/app_userdata/Ninepoint").simplify_path()
    var actual := OS.get_user_data_dir().simplify_path()
    if expected != actual:
        printerr("User data mismatch: fixture tools use %s, Godot uses %s" % [expected, actual])
        quit(1)
        return
    print("User data verified: %s" % actual)
    quit(0)
