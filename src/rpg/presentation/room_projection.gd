## Presentation coordinates only. Physics, save positions and map services stay logical.
class_name RoomProjection
extends RefCounted

const OCCLUSION := preload("res://src/rpg/presentation/ground_occlusion.gdshader")
var source_sha256 := ""
var origin := Vector2.ZERO
var size := Vector2.ZERO
var basis := 1.0
var span := 1.0
var image: Texture2D
var depth: Texture2D

static func load_room(id: String) -> RoomProjection:
    var root := "res://art/rendered/maps/%s/" % id
    if not FileAccess.file_exists(root + "layout.json"):
        return null
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root + "layout.json"))
    var room := RoomProjection.new()
    room.source_sha256 = str(data.get("source_sha256", ""))
    room.origin = Vector2(data.origin[0], data.origin[1])
    room.size = Vector2(data.size[0], data.size[1])
    room.basis = float(data.basis)
    room.span = float(data.span)
    room.image = load(root + "scene.png")
    room.depth = load(root + "depth.png")
    return room

func project(point: Vector2) -> Vector2:
    return origin + project_vector(point)

func project_vector(vector: Vector2) -> Vector2:
    return Vector2(vector.x - vector.y, (vector.x + vector.y) * 0.5) * basis

func unproject_vector(vector: Vector2) -> Vector2:
    var scaled := vector / basis
    return Vector2(scaled.x * 0.5 + scaled.y, scaled.y - scaled.x * 0.5)

func ground_depth(point: Vector2) -> float:
    return (point.x + point.y) / span

func material_for_actor() -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    mat.shader = OCCLUSION
    mat.set_shader_parameter("depth_map", depth)
    mat.set_shader_parameter("room_size", size)
    return mat
