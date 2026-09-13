class_name ExpressiveKettleRoom
extends Node3D

const SCENE := "res://src/experiments/expressive_kettle/room.tscn"
const Dialogue := preload("res://src/experiments/expressive_kettle/dialogue.gd")
const Conversation := preload("res://src/experiments/expressive_kettle/conversation.gd")
var player: ExpressiveKettleActor
var people: Dictionary = {}
var dialogue: DialogueBox
var conversation: Node
var camera: Camera3D
var busy := false
var layout: Dictionary
var prompt: Label
var target := ""
var exit_panel: Control
var player_card: PauseMenu

func _ready() -> void:
    get_window().content_scale_size = Vector2i(768,432)
    Engine.max_fps = 30
    get_viewport().msaa_3d = Viewport.MSAA_4X
    SaveSystem.session_only = true
    if SceneRouter.session_world_scene != SCENE:
        GameState.reset()
        GameState.player_name = "Ro"
        SceneRouter.session_world_scene = SCENE
        GameState.current_map = "de_ketel"
        for flag in ["intro_seen", "carrying_board", "pip_taught_capture", "knows_the_rules",
                "wren_asked_experience", "finishing_skipped", "opening_plan_skipped"]:
            GameState.set_flag(flag, true)
    layout = JSON.parse_string(FileAccess.get_file_as_string("res://art/expressive_kettle/layout.json"))
    var room: Node3D = load("res://art/expressive_kettle/room.glb").instantiate()
    add_child(room)
    _materials(room)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("233a36")
    env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    add_child(env)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 8.9
    camera.position = Vector3(6.2, 8.4, 12.3)
    add_child(camera)
    camera.look_at(Vector3(0,1.10,0))
    camera.make_current()
    for rect: Array in layout.collision:
        _obstacle(Vector3(float(rect[0]),1,float(rect[1])), Vector3(float(rect[2]),2,float(rect[3])))
    for wall: Array in [[0,-3.5,11,.2],[0,3.55,11,.2],[-5.25,0,.2,8],[5.25,0,.2,8]]:
        _obstacle(Vector3(wall[0],1,wall[1]), Vector3(wall[2],2,wall[3]))
    for spec: Dictionary in layout.people:
        var actor := ExpressiveKettleActor.new()
        actor.identity = str(spec.id)
        actor.position = Vector3(spec.at[0],0,spec.at[1])
        add_child(actor)
        people[actor.identity] = actor
        actor.face_towards(Vector3(3,0,7))
        actor.home_angle = actor.model.rotation.y
    player = ExpressiveKettleActor.new()
    player.controlled = true
    player.camera = camera
    var spawn := SceneRouter.take_spawn()
    var at: Vector2 = spawn.position if spawn.use_position else Vector2(layout.spawn[0],layout.spawn[1])
    player.position = Vector3(at.x,0,at.y)
    add_child(player)
    player.face_towards(Vector3(0,0,0))
    dialogue = Dialogue.new()
    add_child(dialogue)
    conversation = Conversation.new()
    conversation.room = self
    add_child(conversation)
    _ui()
    add_child(preload("res://src/experiments/expressive_kettle/hud.gd").new())
    player_card = preload("res://src/experiments/expressive_kettle/card.gd").new()
    add_child(player_card)
    player_card.opened.connect(func(): set_busy(true))
    player_card.closed.connect(func(): set_busy(false))
    Audio.play_music("theme_club")
    await get_tree().process_frame
    conversation.returned()
    if "--tour" in OS.get_cmdline_user_args() and not SceneRouter.has_meta("kettle_tour_started"):
        SceneRouter.set_meta("kettle_tour_started", true)
        var tour: Node = load("res://src/experiments/expressive_kettle/tour.gd").new()
        get_tree().root.add_child(tour)
        tour.call_deferred("run")

func _materials(node: Node) -> void:
    if node is MeshInstance3D:
        for i in node.mesh.get_surface_count():
            var original: Material = node.get_active_material(i)
            if original is StandardMaterial3D:
                var mat := ShaderMaterial.new()
                mat.shader = preload("res://src/go_ui/table_scene/cel.gdshader")
                mat.set_shader_parameter("colour", original.albedo_color)
                node.set_surface_override_material(i, mat)
    for child in node.get_children(): _materials(child)

func _obstacle(at: Vector3, extent: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = at
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = extent
    shape.shape = box
    body.add_child(shape)
    add_child(body)

func player_point() -> Vector2:
    return Vector2(player.position.x,player.position.z)

func set_busy(value: bool) -> void:
    busy = value
    player.input_locked = value
    prompt.visible = not value

func _ui() -> void:
    var hud := CanvasLayer.new()
    add_child(hud)
    var header := ColorRect.new()
    header.size = Vector2(768,56)
    header.color = Color("20332f")
    hud.add_child(header)
    var title := UiKit.label(hud, Vector2(20,14), 420, Color("f0dfb6"), 24)
    title.add_theme_font_size_override("font_size",18)
    title.text = "THE KETTLE"
    var subtitle := UiKit.label(hud, Vector2(21,39), 440, Color("b9c8b2"), 16)
    subtitle.text = "Sela / a table and an afternoon"
    var strip := ColorRect.new()
    strip.position = Vector2(0,400)
    strip.size = Vector2(768,32)
    strip.color = Color("20332f")
    hud.add_child(strip)
    prompt = UiKit.label(hud,Vector2(12,410),744,Color("eee2c2"),16)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    exit_panel = UiKit.panel(hud, Rect2(188,158,392,114),true)
    var message := UiKit.label(exit_panel,Vector2(20,20),352,Color("e5dbc1"),80)
    message.text = "Leave this visit to The Kettle?\nThis prototype uses disposable saves.\n\n[Enter] Leave     [Esc] Keep looking"
    exit_panel.hide()

func target_at(at: Vector3) -> String:
    var nearest := ""
    var distance := 1.40
    for id: String in people:
        var person: ExpressiveKettleActor = people[id]
        var d := at.distance_to(person.position)
        # Tomás can be addressed from the customer side of his counter.
        if id == "tomas": d = minf(d, at.distance_to(Vector3(3.6,0,-.75)))
        if d < distance:
            nearest = id
            distance = d
    return nearest

func _process(_delta: float) -> void:
    if player == null or busy: return
    target = target_at(player.position)
    if not target.is_empty():
        var npc: NpcData = load("res://data/npcs/%s.tres" % target)
        prompt.text = "[Space] Talk to %s / %s" % [npc.display_name,npc.rank_label]
    else:
        prompt.text = "WASD / arrows: walk   Shift: run   Space: talk   Tab: card   V: review   Esc: leave"

func _unhandled_input(event: InputEvent) -> void:
    if exit_panel.visible:
        if event.is_action_pressed("cancel"):
            exit_panel.hide()
            set_busy(false)
        elif event.is_action_pressed("interact"): get_tree().quit()
        get_viewport().set_input_as_handled()
        return
    if busy or SceneRouter.is_busy(): return
    if event.is_action_pressed("cancel"):
        exit_panel.show()
        set_busy(true)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("interact") and not target.is_empty():
        conversation.talk(target)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("menu"):
        player_card.show_menu()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("go_zoom") and not GameState.match_records.is_empty():
        conversation.offer_review(GameState.match_records.size() - 1)
        get_viewport().set_input_as_handled()
