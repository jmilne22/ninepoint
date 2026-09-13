## Inspect both reflected cabs with the actual campaign material and back-face culling.
extends Node3D

func _ready() -> void:
    var vehicle: Node3D = load("res://art/expressive_world/tram.glb").instantiate()
    add_child(vehicle)
    ExpressiveSurfaces.apply(vehicle)
    ExpressiveSurfaces.environment(self)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    add_child(camera)
    var ui := CanvasLayer.new()
    add_child(ui)
    var label := Label.new()
    label.position = Vector2(10,10)
    label.add_theme_font_override("font",UiKit.FONT)
    label.add_theme_font_size_override("font_size",9)
    label.add_theme_color_override("font_color",Color("213e38"))
    ui.add_child(label)
    var output := OS.get_environment("OUT")
    if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
    var views := [
        ["west_front",Vector3(-10,3.2,3.4),Vector3(-6.1,1.2,0),4.2],
        ["east_front",Vector3(10,3.2,3.4),Vector3(6.1,1.2,0),4.2],
        ["west_rear_quarter",Vector3(-9,3.2,-3.4),Vector3(-6.1,1.2,0),4.2],
        ["east_rear_quarter",Vector3(9,3.2,-3.4),Vector3(6.1,1.2,0),4.2],
        ["whole_tram",Vector3(8,8,14),Vector3(0,1,0),10.0]]
    for item in views:
        camera.size = float(item[3])
        camera.look_at_from_position(item[1],item[2])
        label.text = str(item[0]).replace("_"," ").capitalize()
        await get_tree().create_timer(2.5).timeout
        await RenderingServer.frame_post_draw
        if not output.is_empty(): get_viewport().get_texture().get_image().save_png(output.path_join(str(item[0])+".png"))
    print("TRAM REVIEW: both ends, both sides, complete vehicle inspected")
    get_tree().quit()
