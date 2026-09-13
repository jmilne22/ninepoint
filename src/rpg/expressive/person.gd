## A presentation-only follower. Existing 2D actors own movement and interactions.
class_name ExpressivePerson
extends Node3D

var source: CharacterSprite
var model: Node3D
var animation: AnimationPlayer
var face: ShaderMaterial
var identity := "player"
var clock := 0.0
var previous := Vector2.ZERO
var initialized := false

func _ready() -> void:
    model = load("res://art/expressive_world/people/%s.glb" % identity).instantiate()
    model.scale = Vector3.ONE * .78
    if identity in ["sunny", "extra_kid"]: model.scale *= .78
    add_child(model)
    var ink := ShaderMaterial.new()
    ink.shader = preload("res://src/go_ui/table_scene/outline.gdshader")
    face = ShaderMaterial.new()
    face.shader = preload("res://src/go_ui/table_scene/face.gdshader")
    face.set_shader_parameter("faces", load("res://art/expressive_world/people/%s_face.png" % identity))
    face.next_pass = ink
    _prepare(model)
    for clip in ["stand", "walk", "host", "relaxed", "serve", "listen", "table_rest", "thinking", "seated", "counter"]:
        animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR

func _prepare(node: Node) -> void:
    if node is AnimationPlayer: animation = node
    if node is MeshInstance3D:
        for i in node.mesh.get_surface_count():
            var original: Material = node.get_active_material(i)
            if "Painted" in str(node.name): node.set_surface_override_material(i, face)
            elif original is StandardMaterial3D:
                var mat := ShaderMaterial.new()
                mat.shader = preload("res://src/go_ui/table_scene/cel.gdshader")
                mat.set_shader_parameter("colour", original.albedo_color)
                mat.next_pass = face.next_pass
                node.set_surface_override_material(i, mat)
    for child in node.get_children(): _prepare(child)

func _process(delta: float) -> void:
    if not is_instance_valid(source):
        queue_free()
        return
    var actor := source.get_parent() as Node2D
    var feet := actor.global_position
    var speed := feet.distance_to(previous) * .05 / maxf(delta,.001) if initialized else 0.0
    initialized = true
    previous = feet
    position = Vector3(feet.x*.05, .025, feet.y*.05)
    visible = actor.visible
    source.hide()
    var direction := source.motion_vector if not source.motion_vector.is_zero_approx() else Facing.to_vector(source.direction)
    var angle := atan2(direction.x,direction.y)
    model.rotation.y = lerp_angle(model.rotation.y,angle,minf(1,delta*12))
    var seated: bool = actor is Npc and actor.idle != null and actor.idle.mode == "play"
    if seated and identity in ["sunny","extra_kid"]: position.y += .09
    var clip := "stand"
    if identity == "wren": clip = "host"
    elif identity in ["kesh", "pip", "orla", "extra_docker"]: clip = "relaxed"
    if source.activity == "read" and identity in ["ilse", "bertie", "marguerite"]: clip = "thinking"
    if source.activity == "wipe": clip = "counter"
    if seated: clip = "seated"
    if actor is Npc and actor.busy and not seated: clip = "listen"
    if speed > .05: clip = "walk"
    if animation.current_animation != clip: animation.play(clip,.18)
    animation.speed_scale = clampf(speed / (.78*1.04),.2,4.5) if clip == "walk" else 1.0
    clock += delta
    var mood := 5 if fmod(clock+float(identity.hash()%40)/10,4.7)<.13 else 0
    face.set_shader_parameter("expression",float(mood))
