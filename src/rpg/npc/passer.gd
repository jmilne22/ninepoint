## Somebody going somewhere else.
##
## Traffic, not cast: no NpcData, no dialogue, no Interactable, and no name.
## It walks a route and frees itself at the end of it. GAME_DESIGN P4 asks for
## eight people who have somewhere to be rather than a continent of villagers,
## so these deliberately do not stand around and cannot be spoken to -- they
## are the city those eight people live in.
class_name Passer
extends CharacterBody2D

const SPEED := 34.0
const ARRIVE := 3.0
## Wedged against something for this long and they give up and go. A pedestrian
## permanently jammed in a doorway is worse than no pedestrian.
const STUCK_TIME := 2.5
## Their own collision layer, which the player deliberately does not mask.
##
## They started on layer 1 with the NPCs, and the first autopilot run through a
## populated Ketelsteeg could not reach De Ketel at all: the routes run along
## the pavements, which is also the way the player walks, so somebody was
## always in the way. Being unable to get through a door because an extra is
## standing in it is much worse than the half-second of overlap you get from
## walking through one. They still collide with walls and with the cast.
const LAYER := 16

var route: Array[Vector2] = []

var _sprite: CharacterSprite
var _i: int = 0
var _stuck: float = 0.0


static func spawn(parent: Node2D, sheet: String, points: Array[Vector2]) -> Passer:
    if points.size() < 2:
        return null
    var p := Passer.new()
    p.name = "Passer"
    p.route = points
    p.position = points[0]
    # Collides with the world and the cast (layer 1); invisible to the player's
    # mask, and to other passers, so a crowd can never deadlock.
    p.collision_layer = LAYER
    p.collision_mask = 1

    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(9, 6)
    shape.shape = rect
    shape.position = Vector2(0, -4)
    p.add_child(shape)

    var spr := CharacterSprite.new()
    spr.name = "Sprite"
    p.add_child(spr)
    spr.set_sheet(sheet)
    p._sprite = spr

    parent.add_child(p)
    return p


func _physics_process(delta: float) -> void:
    if _i >= route.size():
        queue_free()
        return
    var target: Vector2 = route[_i]
    var to := target - global_position
    if to.length() <= ARRIVE:
        _i += 1
        if _i >= route.size():
            queue_free()
        return

    var dir := to.normalized()
    velocity = dir * SPEED
    move_and_slide()
    _sprite.walking = true
    _sprite.face(Facing.from_vector(dir, _sprite.direction))

    if get_slide_collision_count() > 0:
        _stuck += delta
        if _stuck > STUCK_TIME:
            queue_free()
    else:
        _stuck = 0.0
