extends Node

func _ready() -> void:
    SaveSystem.session_only = true
    GameState.reset()
    GameState.set_flag("opening_seen",true)
    GameState.set_flag("intro_seen",true)
    GameState.current_map = "de_ketel"
    SceneRouter.pending_spawn = "middle"
    var world := preload("res://src/rpg/world.tscn").instantiate()
    get_tree().root.add_child.call_deferred(world)
    await get_tree().process_frame
    get_tree().current_scene = world
    await get_tree().create_timer(1).timeout
    var person: ExpressivePerson
    for node in world.get_children():
        if node is ProjectedWorld:
            for ref in node.people.values():
                var candidate: Node = ref.get_ref()
                if candidate is ExpressivePerson and candidate.identity == "tomas": person = candidate
    person.set_process(false)
    person.animation.play("counter")
    var failures := 0
    for t in [0.0,1.0,2.0,3.0,4.0]:
        person.animation.seek(t,true)
        person.animation.pause()
        await RenderingServer.frame_post_draw
        print("CONTACT ",t," cloth ",person.working_cloth.global_position," normal ",person.working_cloth.global_basis.y.normalized())
        var point := person.working_cloth.global_position
        var normal := person.working_cloth.global_basis.y.normalized()
        if point.z > 4.78 or point.y < 1.046 or point.y > 1.082 or normal.y < cos(deg_to_rad(15.0)):
            failures += 1
    print("CONTACT FAILURES: ",failures)
    Audio.stop_music(0)
    Audio.stop_ambience(0)
    await get_tree().create_timer(.1).timeout
    world.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame
    get_tree().quit(int(failures > 0))
