## Make an integer-scale copy for review; retain the original native capture.
extends SceneTree
func _initialize() -> void:
    for path in OS.get_cmdline_user_args():
        var picture := Image.load_from_file(path)
        if picture == null:
            quit(1)
            return
        picture.resize(picture.get_width()*3,picture.get_height()*3,Image.INTERPOLATE_NEAREST)
        picture.save_png(path.trim_suffix(".png")+"_3x.png")
    quit()
