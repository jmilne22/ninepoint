## Exercises the real player and its live rig at render rates around the physics rate.
extends Node

var person: ExpressivePerson
var world: Node2D
var sampling := false
var samples := 0
var wrong := 0
var transitions := 0
var last_clip := ""
var active_clip := "walk"
var min_foot := INF
var max_foot := -INF
var skeleton: Skeleton3D
var failures := 0
var output := ""
var caption: Label

func _ready() -> void:
    process_priority = 100
    SaveSystem.session_only = true
    GameState.reset()
    GameState.set_flag("opening_seen",true)
    GameState.set_flag("intro_seen",true)
    GameState.set_flag("invited_to_institute",true)
    GameState.current_map = "ketelsteeg"
    SceneRouter.pending_spawn = "from_wassalon"
    SceneRouter.use_pending_position = false
    output = OS.get_environment("OUT")
    if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
    world = preload("res://src/rpg/world.tscn").instantiate()
    get_tree().root.add_child.call_deferred(world)
    await get_tree().process_frame
    get_tree().current_scene = world
    await get_tree().create_timer(1).timeout
    for node in world.get_children():
        if node is ProjectedWorld:
            person = node.people[world.player.sprite.get_instance_id()].get_ref()
    skeleton = _skeleton(person.model)
    var rates := [30,60,144]
    var filming := "--film" in OS.get_cmdline_user_args()
    if filming:
        rates = [30]
        var overlay := CanvasLayer.new()
        overlay.layer=100
        add_child(overlay)
        var panel := PanelContainer.new()
        panel.position=Vector2(8,8)
        var paper := StyleBoxFlat.new()
        paper.bg_color=Color("f4eddf")
        paper.set_corner_radius_all(4)
        paper.content_margin_left=8;paper.content_margin_right=8
        paper.content_margin_top=4;paper.content_margin_bottom=4
        panel.add_theme_stylebox_override("panel",paper)
        overlay.add_child(panel)
        caption=Label.new()
        caption.add_theme_font_override("font",UiKit.FONT)
        caption.add_theme_font_size_override("font_size",9)
        caption.add_theme_color_override("font_color",Color("213e38"))
        panel.add_child(caption)
    for fps in rates:
        Engine.max_fps = fps
        for running in [false,true]:
            if caption!=null: caption.text="Running" if running else "Walking"
            world.player.position = world.map.stand_position(Vector2i(9,12) if filming else Vector2i(17,12))
            await get_tree().create_timer(.25).timeout
            if filming: ProjectedProbe.follow_logical(world.map,Vector2.RIGHT,true)
            else: Input.action_press("move_right")
            if running: Input.action_press("run")
            await get_tree().create_timer(.25).timeout
            samples=0;wrong=0;transitions=0;last_clip="";min_foot=INF;max_foot=-INF
            active_clip = "run" if running else "walk"
            sampling=true
            for i in (12 if filming else 4):
                await get_tree().create_timer(.15).timeout
                if fps==60 or filming: await _shot(("run" if running else "walk")+"_%s"%i)
            sampling=false
            ProjectedProbe.follow_logical(world.map,Vector2.RIGHT,false)
            Input.action_release("move_right");Input.action_release("run")
            var travel := max_foot-min_foot
            print("MOTION RATE %d %s: %d frames, %d idle frames, %d clip changes, foot travel %.3f" % [fps,active_clip,samples,wrong,transitions,travel])
            if samples<5 or wrong>0 or transitions>0 or travel<.20: failures+=1
            await get_tree().create_timer(.3).timeout
            _check(person.animation.current_animation == "stand", "released input returns to standing")
    if caption!=null: caption.text="Stops at walls and when input is locked"
    await _blocked_movement()
    print("MOTION RATE FAILURES: ",failures)
    get_tree().quit(0 if OS.get_environment("MOTION_BASELINE")=="1" else int(failures>0))

func _process(_delta: float) -> void:
    if not sampling: return
    if not is_instance_valid(world) or not is_instance_valid(person):
        sampling=false
        push_error("Motion route unexpectedly left its world")
        get_tree().quit(1)
        return
    if world.player.get_real_velocity().length()<1: return
    samples+=1
    var clip := str(person.animation.current_animation)
    if clip!=active_clip: wrong+=1
    if last_clip!="" and clip!=last_clip: transitions+=1
    last_clip=clip
    var foot := skeleton.get_bone_global_pose(skeleton.find_bone("foot_L")).origin.z
    min_foot=minf(min_foot,foot);max_foot=maxf(max_foot,foot)

func _skeleton(node: Node) -> Skeleton3D:
    if node is Skeleton3D: return node
    for child in node.get_children():
        var result := _skeleton(child)
        if result!=null: return result
    return null

func _shot(label: String) -> void:
    if output.is_empty(): return
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(output.path_join(label+".png"))

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures+=1
        push_error("MOTION: "+message)
    else: print("MOTION: "+message)

func _blocked_movement() -> void:
    world.player.position = world.map.stand_position(Vector2i(17,12))
    # A temporary wall exercises actual move_and_slide, including held run input.
    var wall := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var box := RectangleShape2D.new()
    box.size = Vector2(14,80)
    shape.shape=box
    wall.add_child(shape)
    wall.position=world.player.position+Vector2(18,-4)
    world.entities.add_child(wall)
    await get_tree().create_timer(.2).timeout
    ProjectedProbe.follow_logical(world.map,Vector2.RIGHT,true)
    Input.action_press("run")
    await get_tree().create_timer(.8).timeout
    _check(world.player.get_real_velocity().length()<.1,"wall actually stops the player")
    _check(person.animation.current_animation=="stand","held input against a wall does not run in place")
    ProjectedProbe.follow_logical(world.map,Vector2.RIGHT,false)
    Input.action_release("run")
    wall.queue_free()
    await get_tree().physics_frame
    Input.action_press("move_right")
    await get_tree().create_timer(.3).timeout
    world.player.input_locked=true
    await get_tree().create_timer(.3).timeout
    _check(person.animation.current_animation=="stand","modal input lock stops locomotion")
    Input.action_release("move_right")
    world.player.input_locked=false
