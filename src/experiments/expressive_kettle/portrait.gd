## The same full-body model and relaxed acting, framed as a conversation close-up.
class_name ExpressiveKettlePortrait
extends TableSceneActor

func setup(who: String) -> void:
    identity = who
    resting = "listen"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    viewport = TableSceneStage.viewport(self, Vector2i(size), true)
    model = load("res://art/expressive_kettle/%s.glb" % who).instantiate()
    viewport.add_child(model)
    model.scale = Vector3.ONE * .92
    model.rotation.y = -.10
    var ink := ShaderMaterial.new()
    ink.shader = preload("res://src/go_ui/table_scene/outline.gdshader")
    face = ShaderMaterial.new()
    face.next_pass = ink
    face.shader = preload("res://src/go_ui/table_scene/face.gdshader")
    face.set_shader_parameter("faces",load("res://art/table_scene/%s_face.png" % who))
    _prepare(model)
    var camera := Camera3D.new()
    viewport.add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 1.45
    camera.position = Vector3(.25,1.68,4)
    camera.look_at(Vector3(0,1.60,0))
