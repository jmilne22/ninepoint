## Map-specific presentation only; logical coordinates stay with the world.
class_name CampaignNextRoom
extends RefCounted

static func setup(view: SubViewport, scenery: Node3D, map_id: String) -> void:
    RenderingServer.directional_shadow_atlas_set_size(4096,false)
    var path := "res://art/campaign_next/maps/%s/room-manifest.json" % map_id
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
    if map_id == "de_ketel":
        KettleNextRoom.setup(view,scenery,false)
        apply(scenery)
        for child in view.get_children():
            if child is DirectionalLight3D:
                child.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
                child.directional_shadow_max_distance=55
                child.directional_shadow_pancake_size=20
                child.shadow_bias=.2
                child.shadow_normal_bias=.35
        return
    apply(scenery)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("30453d") if data.get("indoors",false) else Color("b8d3cf")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("dbe3db")
    env.environment.ambient_light_energy = data.get("ambient",.4)
    view.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,data.get("angle",-25),0)
    sun.light_color = Color("fff0d7")
    sun.light_energy = data.get("sun",.8)
    sun.shadow_enabled = true
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
    sun.directional_shadow_max_distance = 55
    sun.directional_shadow_pancake_size = 20
    sun.shadow_bias = .2
    sun.shadow_normal_bias = .35
    view.add_child(sun)
    for point in data.get("window_fills",[]):
        var fill := OmniLight3D.new()
        fill.position = Vector3(point[0],point[1],point[2])
        fill.light_color = Color("e4eee6")
        fill.light_energy = .16
        fill.omni_range = 3.2
        view.add_child(fill)
    for point in data.get("steam",[]):
        var steam := MeshInstance3D.new()
        var quad := QuadMesh.new()
        quad.size = Vector2(.08,.22)
        steam.mesh = quad
        steam.position = Vector3(point[0],point[1]+.11,point[2])
        steam.rotation.y = PI/4.0
        var mat := ShaderMaterial.new()
        mat.shader = preload("res://src/rpg/kettle_next/steam.gdshader")
        mat.set_shader_parameter("offset",float(point[0]))
        steam.material_override = mat
        steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        view.add_child(steam)

static func apply(node: Node) -> void:
    if node is MeshInstance3D:
        for i in node.mesh.get_surface_count():
            var original: Material = node.get_active_material(i)
            if not original is StandardMaterial3D: continue
            var mat := ShaderMaterial.new()
            mat.shader = preload("res://src/rpg/campaign_next/surface.gdshader")
            var label := original.resource_name
            # Ground receives contact shadows but cannot cast a useful sun shadow.
            # Keeping it out also avoids coplanar self-shadowing along floor joins.
            if label.begins_with("floor") or label.begins_with("paving") or label.begins_with("water") or label.begins_with("asphalt") or label.begins_with("surrounding concrete"):
                node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            var timber := label.begins_with("wood") or label.begins_with("floor") or label.begins_with("board")
            var colour: Color = original.albedo_color.srgb_to_linear()
            if label.begins_with("surrounding concrete"): colour = Color("314b45")
            mat.set_shader_parameter("colour",colour)
            mat.set_shader_parameter("wood",timber)
            mat.set_shader_parameter("leaf",label.begins_with("leaf"))
            mat.set_shader_parameter("water",label.begins_with("water"))
            mat.set_shader_parameter("washer",label.begins_with("washer_glass"))
            mat.set_shader_parameter("metal",label.begins_with("metal"))
            mat.set_shader_parameter("grain",load("res://art/expressive_world/surfaces/%s_grain.png" % ("wood" if timber else "plaster")))
            node.set_surface_override_material(i,mat)
    for child in node.get_children(): apply(child)

static func frame_camera(camera: Camera3D) -> void:
    # Fixed campaign cameras sit 33–36 metres from the floor. A bounded depth
    # range gives their directional shadows useful precision across the room.
    camera.near = 12.0
    camera.far = 55.0

static func seated_identities(map_id: String) -> Array:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/campaign_next/maps/%s/room-manifest.json" % map_id))
    return data.get("seats",[])
