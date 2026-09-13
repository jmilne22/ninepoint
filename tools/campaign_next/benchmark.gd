## Measure real movement and a populated rendered board, without screenshot stalls.
extends Node
var samples: Array[float] = []
var sampling := false
var results: Array[Dictionary] = []
var tracked_player: CharacterBody2D
var moving_frames := 0

func _ready() -> void:
    seed(1526)
    SaveSystem.session_only = true
    GameState.reset()
    GameState.set_flag("opening_seen",true)
    GameState.set_flag("intro_seen",true)
    GameState.set_flag("invited_to_institute",true)
    for map_id in ["de_ketel","ketelsteeg"]:
        GameState.current_map = map_id
        SceneRouter.pending_spawn = "middle" if map_id == "de_ketel" else "from_wassalon"
        var world := preload("res://src/rpg/world.tscn").instantiate()
        get_tree().root.add_child.call_deferred(world)
        await get_tree().process_frame
        get_tree().current_scene = world
        Engine.max_fps = 0
        await get_tree().create_timer(2).timeout
        world.player.position = world.map.stand_position(Vector2i(17,12) if map_id == "ketelsteeg" else Vector2i(8,8))
        tracked_player = world.player
        moving_frames = 0
        samples.clear()
        sampling = true
        for i in 8:
            ProjectedProbe.follow_logical(world.map,Vector2.RIGHT if i%2 == 0 else Vector2.LEFT,true)
            await get_tree().create_timer(.5).timeout
            ProjectedProbe.follow_logical(world.map,Vector2.RIGHT if i%2 == 0 else Vector2.LEFT,false)
        sampling = false
        report(map_id+"_moving")
        if moving_frames < 60:
            push_error("Benchmark did not exercise actual movement")
            get_tree().quit(1)
            return
        tracked_player = null
        world.queue_free()
        await get_tree().process_frame
    get_window().content_scale_size=Vector2i(768,432)
    var game := GoGame.new(19)
    for y in range(1,18,2):
        for x in range(1,18,2):game.play(y*19+x)
    var board := GoBoardView.new()
    var root := Control.new()
    get_tree().root.add_child(root)
    root.add_child(board)
    board.game=game
    var surface := TableSceneBoardSurface.new()
    root.add_child(surface)
    surface.setup(board)
    await get_tree().create_timer(2).timeout
    samples.clear();sampling=true
    await get_tree().create_timer(4).timeout
    sampling=false
    report("nineteen_populated")
    var file := FileAccess.open(OS.get_environment("OUT").path_join("performance.json"),FileAccess.WRITE)
    file.store_string(JSON.stringify(results,"  "))
    Audio.stop_music(0)
    Audio.stop_ambience(0)
    await get_tree().create_timer(.1).timeout
    root.queue_free()
    await get_tree().process_frame
    get_tree().quit()

func _process(delta: float) -> void:
    if sampling:
        samples.append(delta*1000)
        if is_instance_valid(tracked_player) and tracked_player.get_real_velocity().length()>1:moving_frames+=1

func report(label: String) -> void:
    samples.sort()
    var sum := 0.0
    for value in samples:sum+=value
    var result := {"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"scene":label,"moving_frames":moving_frames if is_instance_valid(tracked_player) else 0,"profile":OS.get_environment("NINEPOINT_PRESENTATION"),"frames":samples.size(),"mean_ms":sum/samples.size(),"p95_ms":samples[int(samples.size()*.95)],"renderer":RenderingServer.get_video_adapter_name()}
    results.append(result)
    print("CAMPAIGN PERFORMANCE ",JSON.stringify(result))
