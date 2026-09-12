## Opt-in rendered room. Ordinary map data and the normal launch stay untouched.
extends Node2D

const SCENE := "res://src/prototype/ketel/room.tscn"
const Dialogue := preload("res://src/prototype/ketel/dialogue.gd")
const Conversation := preload("res://src/prototype/ketel/conversation.gd")

var presentation: RoomPresentation = preload("res://src/prototype/ketel/presentation.tres").duplicate()
# Autopilot uses existence of `map` to discover the world's dialogue, not to render it.
var map: RoomPresentation
var player: KetelActor
var people: Dictionary = {}
var dialogue: DialogueBox
var conversation: Node
var busy := false
var _prompt: Label
var _target := ""
var _entities: Node2D
var _exit_panel: Control


func _ready() -> void:
    if SceneRouter.session_world_scene != SCENE:
        SaveSystem.session_only = true
        GameState.reset()
        SceneRouter.session_world_scene = SCENE
        GameState.current_map = "de_ketel"
        for flag in ["intro_seen", "carrying_board", "pip_taught_capture", "knows_the_rules",
                "wren_asked_experience", "finishing_skipped", "opening_plan_skipped"]:
            GameState.set_flag(flag, true)
    presentation.read()
    map = presentation
    var backdrop := Sprite2D.new()
    backdrop.texture = presentation.texture(str(presentation.data.background))
    backdrop.centered = false
    add_child(backdrop)
    _entities = Node2D.new()
    _entities.y_sort_enabled = true
    add_child(_entities)
    for layer: Dictionary in presentation.data.layers:
        var item := Node2D.new()
        item.position = presentation.point(layer.foot)
        _entities.add_child(item)
        var art := Sprite2D.new()
        art.texture = presentation.texture(str(layer.image))
        art.centered = false
        art.position = -item.position
        item.add_child(art)
    _build_collision()
    for spec: Dictionary in presentation.data.people:
        var actor := KetelActor.new()
        actor.character_id = str(spec.id)
        actor.position = presentation.point(spec.foot)
        actor.activity = str(spec.activity)
        _entities.add_child(actor)
        people[str(spec.id)] = actor
        actor.face_towards(presentation.point(spec.seat))
        actor.home_direction = actor.direction
    player = KetelActor.new()
    player.controlled = true
    var spawn := SceneRouter.take_spawn()
    player.position = spawn.position if spawn.use_position else presentation.point(presentation.data.spawn)
    if not presentation.walkable(player.position):
        player.position = presentation.point(presentation.data.spawn)
    _entities.add_child(player)
    var camera := Camera2D.new()
    camera.position = presentation.point(presentation.data.camera)
    add_child(camera)
    camera.make_current()
    dialogue = Dialogue.new()
    add_child(dialogue)
    conversation = Conversation.new()
    conversation.room = self
    add_child(conversation)
    _build_ui()
    Audio.play_music("theme_club")
    await get_tree().process_frame
    conversation.returned()


func _build_collision() -> void:
    var body := StaticBody2D.new()
    body.collision_layer = 1
    add_child(body)
    for values: Array in presentation.data.collision:
        var shape := CollisionPolygon2D.new()
        shape.polygon = presentation.polygon(values)
        body.add_child(shape)
    var bounds := presentation.polygon(presentation.data.bounds)
    for i in bounds.size():
        var a := bounds[i]
        var b := bounds[(i + 1) % bounds.size()]
        var shape := CollisionShape2D.new()
        var segment := SegmentShape2D.new()
        segment.a = a
        segment.b = b
        shape.shape = segment
        body.add_child(shape)


func _build_ui() -> void:
    var hud := CanvasLayer.new()
    add_child(hud)
    var title := UiKit.shadow_label(hud, Vector2(12, 9), 320, Color("#d6b777"))
    title.text = "DE KETEL"
    var subtitle := UiKit.shadow_label(hud, Vector2(12, 22), 340, Color("#a29988"))
    subtitle.text = "A room below the street"
    _prompt = UiKit.shadow_label(hud, Vector2(8, 202), 370, Color("#e5dbc1"))
    _prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _exit_panel = UiKit.panel(hud, Rect2(42, 60, 300, 96), true)
    var text := UiKit.label(_exit_panel, Vector2(12, 12), 276, Color("#e5dbc1"), 72)
    text.text = "Leave the De Ketel experiment?\nThis visit is not saved.\n\n[Enter] Leave     [Esc] Keep looking"
    _exit_panel.hide()


func set_busy(value: bool) -> void:
    busy = value
    player.input_locked = value
    _prompt.visible = not value


func target_at(at: Vector2) -> String:
    var best := ""
    var distance := 22.0
    for spec: Dictionary in presentation.data.people:
        var id := str(spec.id)
        var actor: KetelActor = people[id]
        var near_person := at.distance_to(actor.position)
        var near_seat := at.distance_to(presentation.point(spec.seat))
        var d := minf(near_person, near_seat)
        if d < distance:
            best = id
            distance = d
    if not best.is_empty():
        return best
    if at.distance_to(presentation.point(presentation.data.door)) < 16:
        return "door"
    return ""


func _process(_delta: float) -> void:
    if player == null or busy:
        return
    _target = target_at(player.position)
    if _target in people:
        var data: NpcData = load("res://data/npcs/%s.tres" % _target)
        _prompt.text = "[Space] " + data.display_name
    elif _target == "door":
        _prompt.text = "[Space] Leave De Ketel"
    else:
        _prompt.text = "Move WASD  |  Run Shift  |  Leave Esc"
    if not GameState.match_records.is_empty() and _target.is_empty():
        _prompt.text = "[V] Last game review  |  Leave Esc"


func _unhandled_input(event: InputEvent) -> void:
    if _exit_panel.visible:
        if event.is_action_pressed("cancel"):
            _exit_panel.hide()
            set_busy(false)
        elif event.is_action_pressed("interact"):
            get_tree().quit()
        get_viewport().set_input_as_handled()
        return
    if busy or SceneRouter.is_busy():
        return
    if event.is_action_pressed("cancel"):
        _exit_panel.show()
        set_busy(true)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("interact"):
        if _target in people:
            conversation.talk(_target)
        elif _target == "door":
            _exit_panel.show()
            set_busy(true)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("go_zoom") and not GameState.match_records.is_empty():
        conversation.offer_review(GameState.match_records.size() - 1)
        get_viewport().set_input_as_handled()
