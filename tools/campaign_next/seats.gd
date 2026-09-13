## Inspect the real chair occupants, including post-game activity variations.
extends Node
func _ready() -> void:
    SaveSystem.session_only=true
    GameState.reset()
    for flag in ["opening_seen","intro_seen","invited_to_institute","kesh_match_done"]:GameState.set_flag(flag,true)
    var output := OS.get_environment("OUT")
    var found_kesh := false
    for venue in ["de_ketel","academy_study","academy_novice"]:
        GameState.current_map=venue
        SceneRouter.pending_spawn="middle"
        var world := preload("res://src/rpg/world.tscn").instantiate()
        get_tree().root.add_child.call_deferred(world)
        await get_tree().process_frame
        get_tree().current_scene=world
        world.player.input_locked=true
        await get_tree().create_timer(.8).timeout
        for node in world.get_children():
            if not node is ProjectedWorld:continue
            for ref in node.people.values():
                var person: ExpressivePerson=ref.get_ref() as ExpressivePerson
                if person==null or not person.has_seat:continue
                if person.acting.current!="seated":
                    push_error("Chair occupant stood through seat: "+person.identity)
                    get_tree().quit(1)
                    return
                if person.identity=="kesh":found_kesh=true
                person.set_process(false)
                person.animation.play("seated")
                person.animation.seek(.8,true)
                person.animation.pause()
                var skeleton := KettleNextProps.find_skeleton(person.model)
                for side in ["L","R"]:
                    var pose := skeleton.get_bone_global_pose(skeleton.find_bone("tip1_"+side))
                    var tip := skeleton.global_transform*(pose*Vector3(0,.035,0))
                    print("SEATED CONTACT ",person.identity," ",side," fingertip ",tip)
                if person.identity in ["kesh","sunny","noor"]:
                    var actor := person.source.get_parent() as Node2D
                    world.player.position=actor.position+Vector2(-18,16)
                    node.camera_3d.size=3.8
                    await get_tree().create_timer(.3).timeout
                    await RenderingServer.frame_post_draw
                    get_viewport().get_texture().get_image().save_png(output.path_join(person.identity+"_seated.png"))
        world.queue_free()
        await get_tree().process_frame
    if not found_kesh:
        push_error("Post-game Kesh lost the original chair assignment")
        get_tree().quit(1)
        return
    Audio.stop_music(0);Audio.stop_ambience(0)
    await get_tree().create_timer(.1).timeout
    print("SEATED STATE: original chair occupants remain seated through activity changes")
    get_tree().quit()
