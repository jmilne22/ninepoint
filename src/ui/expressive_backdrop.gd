## Title/travel camera over the same live assets the player visits.
class_name ExpressiveBackdrop
extends Control

var map_id := "ketelsteeg"
var view: SubViewport
var camera: Camera3D
var target := Vector3.ZERO
var elapsed := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size = Vector2(384,216)
    view = TableSceneStage.viewport(self,Vector2i(768,432),false)
    for child in get_children():
        if child is TextureRect:
            child.size = size
            child.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    for child in view.get_children():
        if child is WorldEnvironment or child is Light3D: child.queue_free()
    ExpressiveSurfaces.environment(view,false)
    var scenery: Node3D = load("res://art/expressive_world/maps/%s/room.glb" % map_id).instantiate()
    view.add_child(scenery)
    ExpressiveSurfaces.apply(scenery)
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/%s.json" % map_id))
    target = Vector3(float(data.size[0])*.4,0,float(data.size[1])*.4)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 13 if map_id == "ketelsteeg" else 9
    view.add_child(camera)
    _process(0)

func _process(delta: float) -> void:
    if camera == null: return
    elapsed += delta
    var centre := target+Vector3(sin(elapsed*.06)*.6,0,0)
    camera.position = centre+Vector3(20,18,24)
    camera.look_at(centre)
