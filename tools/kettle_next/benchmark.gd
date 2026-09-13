## Same room, camera and actor workload in each profile. No screenshot stalls in samples.
extends Node

var samples: Array[float] = []
var sampling := false

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
    Engine.max_fps = 0
    await get_tree().create_timer(2).timeout
    sampling = true
    await get_tree().create_timer(5).timeout
    sampling = false
    samples.sort()
    var total := 0.0
    for value in samples: total += value
    var result := {"profile":"prototype" if KettleNextProfile.enabled() else "baseline",
        "frames":samples.size(),"mean_ms":total/samples.size(),
        "p95_ms":samples[int(samples.size()*.95)],"p99_ms":samples[int(samples.size()*.99)],
        "renderer":RenderingServer.get_video_adapter_name()}
    print("KETTLE PERFORMANCE ",JSON.stringify(result))
    var output := OS.get_environment("OUT")
    if not output.is_empty():
        DirAccess.make_dir_recursive_absolute(output)
        var file := FileAccess.open(output.path_join(str(result.profile)+"-performance.json"),FileAccess.WRITE)
        file.store_string(JSON.stringify(result,"  ")+"\n")
    get_tree().quit()

func _process(delta: float) -> void:
    if sampling: samples.append(delta*1000.0)
