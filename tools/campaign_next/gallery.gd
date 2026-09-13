extends Node3D

const IDS := ["player","wren","kesh","tomas","pip","bertie","hana","marguerite","nadia","joos","ilse","sunny","orla","abel","dov","moss","noor","ivo","lea","emil","sora","extra_commuter","extra_shopper","extra_docker","extra_student","extra_kid"]
var output := ""

func _ready() -> void:
    output = OS.get_environment("OUT")
    DirAccess.make_dir_recursive_absolute(output)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("d9d2bc")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_energy = .6
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-30,0)
    sun.light_energy = .65
    sun.shadow_enabled = true
    add_child(sun)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 3.3
    camera.position = Vector3(0,2,8)
    add_child(camera)
    camera.look_at(Vector3(0,1.2,0))
    var overlay := CanvasLayer.new()
    add_child(overlay)
    var caption := Label.new()
    caption.position = Vector2(12,10)
    caption.add_theme_color_override("font_color",Color("30483b"))
    overlay.add_child(caption)
    for page in 7:
        var models: Array[Node3D] = []
        var actors: Array[TableSceneActor] = []
        var names: Array[String] = []
        for i in 4:
            var index := page*4+i
            if index >= IDS.size(): break
            var who: String = IDS[index]
            names.append(who)
            var actor := TableSceneActor.new()
            actor.identity = who
            actor.face = ShaderMaterial.new()
            actor.face.shader = preload("res://src/go_ui/table_scene/face.gdshader")
            actor.face.set_shader_parameter("faces",load("res://art/expressive_world/people/%s_face.png" % who))
            var ink := ShaderMaterial.new()
            ink.shader = preload("res://src/rpg/kettle_next/outline.gdshader") if KettleNextProfile.has_person(who) else preload("res://src/go_ui/table_scene/outline.gdshader")
            actor.face.next_pass = ink
            var model: Node3D = load(KettleNextProfile.person_path(who,"res://art/expressive_world/people/%s.glb" % who)).instantiate()
            add_child(model)
            model.position.x = (i-1.5)*1.65
            if who in ["sunny","extra_kid"]: model.scale *= .78
            actor._prepare(model)
            actor.prepare_acting()
            actor.animation.play("stand")
            models.append(model)
            actors.append(actor)
        caption.text = "  /  ".join(names)
        for angle in [0,90,180]:
            for model in models:model.rotation_degrees.y=angle
            await get_tree().create_timer(.35).timeout
            await shot("body_%02d_%03d" % [page,angle])
        if "--film" in OS.get_cmdline_user_args():
            for model in models:
                model.rotation.y=0
                create_tween().tween_property(model,"rotation:y",TAU,5.0)
            await get_tree().create_timer(5).timeout
        for clip in ["walk","run","greet","thinking","seated"]:
            for model in models:model.rotation_degrees.y=35
            for actor in actors:actor.animation.play(clip,.16)
            await get_tree().create_timer(.65).timeout
            await shot("pose_%02d_%s" % [page,clip])
            if "--film" in OS.get_cmdline_user_args():await get_tree().create_timer(1.35).timeout
        for actor in actors:actor.free()
        for model in models:model.queue_free()
        await get_tree().process_frame
    print("CAMPAIGN CAST: 26 identities, front/side/rear and five moving poses")
    get_tree().quit()

func shot(label: String) -> void:
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(output.path_join(label+".png"))
