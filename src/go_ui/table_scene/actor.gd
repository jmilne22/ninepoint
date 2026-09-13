class_name TableSceneActor
extends Control

var viewport: SubViewport
var model: Node3D
var animation: AnimationPlayer
var face: ShaderMaterial
var resting := "idle"
var active := ""
var remaining := 0.0
var clock := 0.0
var identity := ""

func setup(who: String) -> void:
    identity = who
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    viewport = TableSceneStage.viewport(self, Vector2i(size), true)
    model = load("res://art/table_scene/%s.glb" % who).instantiate()
    viewport.add_child(model)
    if who == "sunny":
        model.scale = Vector3.ONE * 0.84
        model.position.y = 0.22
    model.rotation.y = 0.10 if who == "player" else -0.10
    var ink := ShaderMaterial.new()
    ink.shader = preload("res://src/go_ui/table_scene/outline.gdshader")
    face = ShaderMaterial.new()
    face.next_pass = ink
    face.shader = preload("res://src/go_ui/table_scene/face.gdshader")
    face.set_shader_parameter("faces", load("res://art/table_scene/%s_face.png" % who))
    _prepare(model)
    var camera := Camera3D.new()
    viewport.add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 1.65
    camera.position = Vector3(-0.33 if who == "player" else 0.33, 1.6, 4)
    camera.look_at(Vector3(0, 1.43, 0))
    if animation:
        print("CAST CLIPS ", who, ": ", animation.get_animation_list())

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

func perform(clip: String, duration: float) -> void:
    active = clip
    remaining = duration
    _play(clip)

func _play(clip: String) -> void:
    if animation == null or not animation.has_animation(clip):
        return
    if animation.current_animation != clip or not animation.is_playing():
        animation.play(clip, 0.22)

func _process(delta: float) -> void:
    clock += delta
    remaining -= delta
    var clip := active if remaining > 0 else resting
    _play(clip)
    if face:
        var mood := 0
        if clip == "thinking": mood = 1
        elif clip == "pleased" or clip == "greet": mood = 2
        elif clip == "surprise": mood = 3
        elif clip == "concern": mood = 4
        if fmod(clock + (1.2 if identity == "wren" else 0.0), 4.7) < 0.13:
            mood = 5
        face.set_shader_parameter("expression", float(mood))
