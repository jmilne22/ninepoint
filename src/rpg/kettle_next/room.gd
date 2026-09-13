class_name KettleNextRoom
extends RefCounted

static func setup(view: SubViewport, scenery: Node3D, prepare_materials: bool = true) -> void:
    if prepare_materials: _materials(scenery)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color("30453d")
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color("d0dfd9")
    environment.environment.ambient_light_energy = .37
    view.add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-58,-24,0)
    sun.light_color = Color("fff0d3")
    sun.light_energy = .85
    sun.shadow_enabled = true
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
    sun.directional_shadow_max_distance = 28
    sun.shadow_bias = .035
    sun.shadow_normal_bias = .65
    view.add_child(sun)
    for x in [7.1,12.0]:
        var fill := OmniLight3D.new()
        fill.position = Vector3(x,1.65,2.7)
        fill.light_color = Color("f5e6c6")
        fill.light_energy = .28
        fill.omni_range = 4.0
        view.add_child(fill)
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/kettle_next/room-manifest.json"))
    for point in manifest.get("steam",[]):
        var at := Vector3(point[0],point[1],point[2])
        var steam := MeshInstance3D.new()
        var quad := QuadMesh.new()
        quad.size = Vector2(.095,.25)
        steam.mesh = quad
        steam.position = at + Vector3(0,.12,0)
        steam.rotation.y = PI/4.0
        var mat := ShaderMaterial.new()
        mat.shader = preload("res://src/rpg/kettle_next/steam.gdshader")
        mat.set_shader_parameter("offset",at.x)
        steam.material_override = mat
        steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        view.add_child(steam)

static func _materials(node: Node) -> void:
    if node is MeshInstance3D:
        for i in node.mesh.get_surface_count():
            var original: Material = node.get_active_material(i)
            if not original is StandardMaterial3D: continue
            var mat := ShaderMaterial.new()
            mat.shader = preload("res://src/rpg/kettle_next/surface.gdshader")
            var name: String = original.resource_name
            var timber := name.begins_with("wood") or name.begins_with("floor") or name.begins_with("board")
            mat.set_shader_parameter("colour",original.albedo_color.srgb_to_linear())
            mat.set_shader_parameter("wood",timber)
            mat.set_shader_parameter("leaf",name.begins_with("leaf"))
            mat.set_shader_parameter("grain",load("res://art/expressive_world/surfaces/%s_grain.png" % ("wood" if timber else "plaster")))
            node.set_surface_override_material(i,mat)
    for child in node.get_children(): _materials(child)
