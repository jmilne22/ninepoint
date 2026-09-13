class_name ExpressiveKettleActor
extends CharacterBody3D

var identity := "player"
var controlled := false
var input_locked := false
var model: Node3D
var animation: AnimationPlayer
var face: ShaderMaterial
var camera: Camera3D
var clock := 0.0
var gesture := ""
var gesture_left := 0.0
var home_angle := 0.0
var moving := false
var resting := "stand"
var cloth: MeshInstance3D

func _ready() -> void:
    collision_layer = 2
    collision_mask = 3
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = .23
    capsule.height = 1.6
    shape.shape = capsule
    shape.position.y = .8
    add_child(shape)
    model = load("res://art/expressive_kettle/%s.glb" % identity).instantiate()
    add_child(model)
    model.scale = Vector3.ONE * .92
    resting = {"wren":"host", "kesh":"relaxed", "tomas":"serve"}.get(identity,"stand")
    var ink := ShaderMaterial.new()
    ink.shader = preload("res://src/go_ui/table_scene/outline.gdshader")
    face = ShaderMaterial.new()
    face.shader = preload("res://src/go_ui/table_scene/face.gdshader")
    face.set_shader_parameter("faces", load("res://art/table_scene/%s_face.png" % identity))
    face.next_pass = ink
    _prepare(model)
    for clip in ["stand", "walk", "host", "relaxed", "serve", "listen"]:
        animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
    _play(resting)
    if identity == "tomas":
        cloth = MeshInstance3D.new()
        var cloth_mesh := BoxMesh.new()
        cloth_mesh.size = Vector3(.22,.012,.17)
        cloth.mesh = cloth_mesh
        var cloth_material := StandardMaterial3D.new()
        cloth_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        cloth_material.albedo_color = Color("ded7bd")
        cloth.material_override = cloth_material
        cloth.position = Vector3(.28*.92,1.405,.46*.92)
        add_child(cloth)
    # A soft grounded footprint stays readable with the same unshaded cast palette.
    var shadow := MeshInstance3D.new()
    var disc := CylinderMesh.new()
    disc.top_radius = .32
    disc.bottom_radius = .32
    disc.height = .005
    shadow.mesh = disc
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(.19, .17, .12, .25)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    shadow.material_override = mat
    shadow.position.y = .046
    shadow.scale.z = .65
    add_child(shadow)

func _prepare(node: Node) -> void:
    if node is AnimationPlayer:
        animation = node
    if node is MeshInstance3D:
        for index in node.mesh.get_surface_count():
            var original: Material = node.get_active_material(index)
            if "Painted" in str(node.name):
                node.set_surface_override_material(index, face)
            elif original is StandardMaterial3D:
                var mat := ShaderMaterial.new()
                mat.shader = preload("res://src/go_ui/table_scene/cel.gdshader")
                mat.set_shader_parameter("colour", original.albedo_color)
                mat.next_pass = face.next_pass
                node.set_surface_override_material(index, mat)
    for child in node.get_children():
        _prepare(child)

func face_towards(at: Vector3) -> void:
    var direction := at - position
    model.rotation.y = atan2(direction.x, direction.z)

func release() -> void:
    input_locked = false
    gesture_left = 0
    model.rotation.y = home_angle

func perform(clip: String, duration: float) -> void:
    gesture = clip
    gesture_left = duration

func _play(clip: String) -> void:
    if animation.current_animation != clip or not animation.is_playing():
        animation.play(clip, .18)

func _physics_process(delta: float) -> void:
    clock += delta
    gesture_left -= delta
    var direction := Vector3.ZERO
    if controlled and not input_locked:
        var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        var right := camera.global_basis.x
        var forward := camera.global_basis.z
        right.y = 0
        forward.y = 0
        direction = (right.normalized() * input.x + forward.normalized() * input.y)
    var speed := 1.30 * (1.65 if Input.is_action_pressed("run") else 1.0)
    velocity = Vector3.ZERO if input_locked else velocity.move_toward(direction * speed, delta * (10.0 if direction.is_zero_approx() else 7.0))
    move_and_slide()
    moving = get_real_velocity().length() > .06
    if moving and not direction.is_zero_approx():
        model.rotation.y = lerp_angle(model.rotation.y, atan2(direction.x, direction.z), minf(1,delta*14))
    var clip := "walk" if moving else (gesture if gesture_left > 0 else resting)
    _play(clip)
    animation.speed_scale = clampf(get_real_velocity().length() / .957,.2,2.5) if moving else 1.0
    if cloth != null and clip == "serve":
        cloth.position.x = (.28+.075*sin(animation.current_animation_position/6.0*TAU))*.92
    var mood := 2 if clip == "greet" or clip == "pleased" else 1 if clip == "thinking" else 0
    if fmod(clock + float(identity.hash() % 40) / 10, 4.7) < .13:
        mood = 5
    face.set_shader_parameter("expression", float(mood))
