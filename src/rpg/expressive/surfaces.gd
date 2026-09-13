class_name ExpressiveSurfaces
extends RefCounted

static func apply(node: Node) -> void:
    if node is MeshInstance3D:
        for i in node.mesh.get_surface_count():
            var original: Material = node.get_active_material(i)
            if not original is StandardMaterial3D: continue
            var mat := ShaderMaterial.new()
            mat.shader = preload("res://src/rpg/expressive/room.gdshader")
            var timber := original.resource_name.begins_with("wood") or original.resource_name.begins_with("floor") or original.resource_name.begins_with("board")
            # The campaign exporter carries palette channels directly; the glTF loader
            # converts them from linear, so recover the authored palette for this shader.
            var colour: Color = original.albedo_color.srgb_to_linear()
            if original.resource_name.begins_with("surrounding concrete"): colour = Color("314b45")
            mat.set_shader_parameter("colour",colour)
            mat.set_shader_parameter("wood",timber)
            mat.set_shader_parameter("water",original.resource_name.begins_with("water"))
            mat.set_shader_parameter("washer",original.resource_name.begins_with("washer_glass"))
            mat.set_shader_parameter("grain_amount",.45 if timber else .16)
            mat.set_shader_parameter("grain",load("res://art/expressive_world/surfaces/%s_grain.png" % ("wood" if timber else "plaster")))
            node.set_surface_override_material(i,mat)
    for child in node.get_children(): apply(child)

static func environment(parent: Node, indoor: bool = false) -> void:
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("253f3c") if indoor else Color("b8d3cf")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("e7e8e2")
    env.environment.ambient_light_energy = .43
    parent.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48,-35,0)
    sun.light_color = Color("fff7e8")
    sun.light_energy = .8
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 70
    parent.add_child(sun)
