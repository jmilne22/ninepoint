class_name TableSceneStage
extends RefCounted

static func viewport(parent: Control, extent: Vector2i, transparent: bool) -> SubViewport:
    var view := SubViewport.new()
    view.size = extent
    view.transparent_bg = transparent
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    view.msaa_3d = Viewport.MSAA_4X
    parent.add_child(view)
    var image := TextureRect.new()
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.texture = view.get_texture()
    image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    image.size = extent
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(image)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("aa8355")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("e5e8ed")
    env.environment.ambient_light_energy = 0.28
    env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    view.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -25, 0)
    light.light_color = Color("fff8ed")
    light.light_energy = 0.45
    light.shadow_enabled = not transparent
    light.directional_shadow_max_distance = 8
    view.add_child(light)
    return view

static func material(colour: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = colour
    mat.roughness = 0.7
    return mat
