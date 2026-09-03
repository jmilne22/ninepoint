## Shared four-direction helper: the sprite sheet row order and the vector maths
## that decides which way a character is looking.
class_name Facing
extends RefCounted

enum Dir { DOWN, LEFT, RIGHT, UP }

const NAMES := ["down", "left", "right", "up"]
const VECTORS := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]


static func from_vector(v: Vector2, fallback: int = Dir.DOWN) -> int:
    if v.length_squared() < 0.001:
        return fallback
    if absf(v.x) > absf(v.y):
        return Dir.RIGHT if v.x > 0 else Dir.LEFT
    return Dir.DOWN if v.y > 0 else Dir.UP


static func from_name(name: String) -> int:
    var i := NAMES.find(name)
    return i if i >= 0 else Dir.DOWN


static func to_vector(dir: int) -> Vector2:
    return VECTORS[clampi(dir, 0, 3)]


static func opposite(dir: int) -> int:
    match dir:
        Dir.DOWN: return Dir.UP
        Dir.UP: return Dir.DOWN
        Dir.LEFT: return Dir.RIGHT
        _: return Dir.LEFT
