## Pixel coordinates exported from the same camera that renders the room.
class_name RoomPresentation
extends Resource

@export var manifest_path := "res://art/prototype/ketel/layout.json"
var data: Dictionary = {}


func read() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
    assert(parsed is Dictionary, "Room presentation needs a rendered layout")
    data = parsed


func point(value: Array) -> Vector2:
    return Vector2(float(value[0]), float(value[1]))


func polygon(values: Array) -> PackedVector2Array:
    var result := PackedVector2Array()
    for value: Array in values:
        result.append(point(value))
    return result


func walkable(at: Vector2) -> bool:
    if not Geometry2D.is_point_in_polygon(at, polygon(data.bounds)):
        return false
    for shape: Array in data.collision:
        if Geometry2D.is_point_in_polygon(at, polygon(shape)):
            return false
    return true


func texture(file: String) -> Texture2D:
    return load(manifest_path.get_base_dir().path_join(file)) as Texture2D
