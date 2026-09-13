## Maps a visible board region to the same physical wooden surface at every size.
class_name TableBoardLayout
extends RefCounted
var board_size := 9
var region := Rect2i(0, 0, 9, 9)
var spacing := 0.105
var stone_scale := 1.0

func configure(n: int, visible_region: Rect2i) -> void:
    board_size = n
    region = visible_region
    spacing = 0.84 / float(region.size.x - 1)
    stone_scale = spacing / 0.105

func contains(point: int) -> bool:
    return point >= 0 and point < board_size * board_size and region.has_point(Vector2i(point % board_size, point / board_size))

func world_point(point: int, height: float = 0.143) -> Vector3:
    var local := Vector2i(point % board_size, point / board_size) - region.position
    return Vector3(float(local.x) * spacing - 0.42, height, float(local.y) * spacing - 0.42)

func point_at(hit: Vector3) -> int:
    if absf(hit.x) > 0.42 + spacing * 0.5 or absf(hit.z) > 0.42 + spacing * 0.5: return -1
    var local := Vector2i(roundi((hit.x + 0.42) / spacing), roundi((hit.z + 0.42) / spacing))
    var point := (local.y + region.position.y) * board_size + local.x + region.position.x
    return point if Rect2i(Vector2i.ZERO, region.size).has_point(local) and contains(point) else -1
