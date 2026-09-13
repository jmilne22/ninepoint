## Actual campaign views in disposable state. This does not replace play-through gates.
extends Node

func _ready() -> void:
    SaveSystem.session_only = true
    GameState.reset()
    GameState.set_flag("opening_seen",true)
    GameState.set_flag("intro_seen",true)
    GameState.set_flag("invited_to_institute",true)
    var output := OS.get_environment("OUT")
    DirAccess.make_dir_recursive_absolute(output)
    var maps := ["academy_class","academy_dorm","academy_hall","academy_novice","academy_study","attic","bondszaal","de_ketel","ketelsteeg","onderbrug","quay","wassalon"]
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--map="): maps = [arg.trim_prefix("--map=")]
    for id in maps:
        GameState.current_map = id
        GameState.spawn_point = "start"
        var map := MapData.load_map(id)
        if not map.spawns.has("start"): GameState.spawn_point = str(map.spawns.keys()[0])
        SceneRouter.pending_spawn = GameState.spawn_point
        SceneRouter.use_pending_position = false
        var world := preload("res://src/rpg/world.tscn").instantiate()
        get_tree().root.add_child.call_deferred(world)
        await get_tree().process_frame
        get_tree().current_scene = world
        await get_tree().create_timer(1.0).timeout
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))
        world.queue_free()
        await get_tree().process_frame
        await get_tree().process_frame
    print("EXPRESSIVE GALLERY: ",maps.size()," campaign areas captured")
    get_tree().quit()
