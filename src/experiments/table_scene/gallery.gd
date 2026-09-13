extends Control
const IDS := ["player", "wren", "kesh", "pip", "bertie", "nadia", "hana", "tomas", "marguerite", "joos", "ilse", "sunny", "orla", "abel", "dov", "moss", "noor", "ivo", "lea", "emil", "sora"]
func _ready() -> void:
    get_window().content_scale_size = Vector2i(768,432)
    var bg := ColorRect.new()
    bg.color = Color("bd9a6c")
    bg.size = Vector2(768,432)
    add_child(bg)
    _run()
func _run() -> void:
    var out := OS.get_environment("OUT")
    DirAccess.make_dir_recursive_absolute(out)
    for page in 7:
        var group := Control.new()
        add_child(group)
        var actors: Array[TableSceneActor] = []
        for column in 3:
            var who: String = IDS[page * 3 + column]
            var label := Label.new()
            label.text = who.to_upper()
            label.position = Vector2(column * 256 + 30,24)
            label.add_theme_font_size_override("font_size",18)
            group.add_child(label)
            var actor := TableSceneActor.new()
            actor.position = Vector2(column*256 - 7, 62)
            actor.size = Vector2(270,330)
            group.add_child(actor)
            actor.setup(who)
            actors.append(actor)
        await get_tree().create_timer(0.8).timeout
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(out.path_join("cast_%02d.png" % page))
        for actor in actors: actor.perform("thinking", 3)
        await get_tree().create_timer(1.1).timeout
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(out.path_join("gesture_%02d.png" % page))
        group.queue_free()
        await get_tree().process_frame
    print("CAST GALLERY: 21 identities and gestures rendered")
    get_tree().quit()
