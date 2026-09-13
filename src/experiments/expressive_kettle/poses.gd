## Rendered turntable evidence: the actual full-body clips at their playing scale.
extends Control
var actors: Array[ExpressiveKettleActor] = []

func _ready() -> void:
    SaveSystem.session_only = true
    get_window().content_scale_size = Vector2i(768,432)
    Engine.max_fps = 30
    var view := TableSceneStage.viewport(self,Vector2i(768,432),false)
    for child in view.get_children():
        if child is WorldEnvironment:
            child.environment.background_color = Color("e5d6b6")
    var camera := Camera3D.new()
    view.add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.8
    camera.position = Vector3(0,1.3,6)
    camera.look_at(Vector3(0,1.08,0))
    var ids := ["player","wren","kesh","tomas"]
    var names := ["Ro / relaxed", "Wren / attentive", "Kesh / at ease", "Tomas / working"]
    for i in ids.size():
        var actor := ExpressiveKettleActor.new()
        actor.identity = ids[i]
        actor.position = Vector3(-1.86+float(i)*1.24,0,0)
        view.add_child(actor)
        actors.append(actor)
        var label := UiKit.label(self,Vector2(12+i*192,406),186,Color("24382f"),22)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.text = names[i]
    var counter := MeshInstance3D.new()
    var block := BoxMesh.new()
    block.size = Vector3(1.08,.09,.45)
    counter.mesh = block
    counter.position = Vector3(1.86,1.37,.40)
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color("98704c")
    counter.material_override = mat
    view.add_child(counter)
    var title := UiKit.label(self,Vector2(20,12),730,Color("24382f"),22)
    title.add_theme_font_size_override("font_size",18)
    title.text = "THE KETTLE / STANCE STUDY"
    var output := OS.get_environment("OUT")
    DirAccess.make_dir_recursive_absolute(output)
    for i in 4:
        await get_tree().create_timer(1.0).timeout
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(output.path_join("stance_%02d.png" % i))
    for actor in actors: actor.model.rotation.y = -.7
    await get_tree().create_timer(1).timeout
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(output.path_join("stance_three_quarter.png"))
    get_tree().quit()
