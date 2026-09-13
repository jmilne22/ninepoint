extends Node3D

func _ready() -> void:
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
    camera.position = Vector3(0,2.0,8)
    add_child(camera)
    camera.look_at(Vector3(0,1.2,0))
    var models: Array[Node3D] = []
    var animations: Array[AnimationPlayer] = []
    for i in 4:
        var who: String = KettleNextProfile.PEOPLE[i]
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
        actor._prepare(model)
        actor.prepare_acting()
        for clip in ["stand","walk","run","idle","counter","seated"]:
            if actor.animation.has_animation(clip):
                actor.animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
        actor.animation.play("stand")
        models.append(model)
        animations.append(actor.animation)
        actor.free()
    await get_tree().create_timer(.5).timeout
    var output := OS.get_environment("OUT")
    DirAccess.make_dir_recursive_absolute(output)
    if "--film" in OS.get_cmdline_user_args():
        for model in models:
            create_tween().tween_property(model,"rotation:y",TAU,6.0)
        await get_tree().create_timer(6.0).timeout
        for clip in ["walk","run","greet","thinking"]:
            for model in models: model.rotation_degrees.y = 35
            for a in animations: a.play(clip,.18)
            await get_tree().create_timer(3.0).timeout
        get_tree().quit()
        return
    for angle in [0,45,90,180]:
        for model in models: model.rotation_degrees.y = angle
        await get_tree().create_timer(.25).timeout
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(output.path_join("cast_%d.png" % angle))
    for clip in ["walk","run","greet","thinking","seated","counter"]:
        for model in models: model.rotation_degrees.y = 35
        for a in animations: a.play(clip)
        for f in 8:
            await get_tree().create_timer(.09).timeout
            await RenderingServer.frame_post_draw
            get_viewport().get_texture().get_image().save_png(output.path_join("%s_%d.png" % [clip,f]))
    get_tree().quit()
