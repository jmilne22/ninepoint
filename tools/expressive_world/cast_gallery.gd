## Front and three-quarter views of every shipped full-body identity.
extends Control
func _ready() -> void:
    SaveSystem.session_only = true
    var ids: Array[String] = []
    for file in DirAccess.get_files_at("res://art/expressive_world/people"):
        if file.ends_with(".glb"): ids.append(file.get_basename())
    ids.sort()
    var output := OS.get_environment("OUT")
    DirAccess.make_dir_recursive_absolute(output)
    for page in range(ceili(ids.size()/4.0)):
        var holder := Control.new()
        add_child(holder)
        var view := TableSceneStage.viewport(holder,Vector2i(768,432),false)
        for child in holder.get_children():
            if child is TextureRect: child.size = Vector2(384,216)
        for child in view.get_children():
            if child is WorldEnvironment: child.environment.background_color = Color("dfd2b4")
        var camera := Camera3D.new()
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = 2.8
        camera.position = Vector3(0,1,6)
        view.add_child(camera)
        camera.look_at(Vector3(0,1,0))
        var people: Array[ExpressivePerson] = []
        for i in range(4):
            if page*4+i >= ids.size(): break
            var id := ids[page*4+i]
            var source := Node2D.new()
            source.position.x = (-1.86+i*1.24)*20
            holder.add_child(source)
            var sprite := CharacterSprite.new()
            source.add_child(sprite)
            sprite.set_process(false)
            sprite.direction = Facing.Dir.DOWN
            var person := ExpressivePerson.new()
            person.source = sprite
            person.identity = id
            view.add_child(person)
            people.append(person)
            UiKit.label(holder,Vector2(i*96+4,190),88,UiKit.INK,22).text = id.replace("extra_","").capitalize()
        await get_tree().create_timer(1.2).timeout
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(output.path_join("cast_%02d_front.png" % page))
        for person in people:
            person.set_process(false)
            person.model.rotation.y = -.6
        await get_tree().create_timer(.5).timeout
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(output.path_join("cast_%02d_turn.png" % page))
        holder.queue_free()
        await get_tree().process_frame
    print("EXPRESSIVE CAST: ",ids.size()," identities captured")
    get_tree().quit()
