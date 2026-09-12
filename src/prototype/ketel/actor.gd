## Foot-grounded eight-direction actor; visual size never defines collision.
class_name KetelActor
extends CharacterBody2D

var character_id := "player"
var controlled := false
var input_locked := false
var activity := ""
var direction := 0
var home_direction := 0
var facing_vector := Vector2.DOWN
var sprite: Sprite2D
var _clock := 0.0
var _full_sheet := false


func _ready() -> void:
    collision_layer = 2
    collision_mask = 3
    var shape := CollisionShape2D.new()
    var capsule := CircleShape2D.new()
    capsule.radius = 3.0
    shape.shape = capsule
    add_child(shape)
    var shadow := Polygon2D.new()
    var points := PackedVector2Array()
    for i in 16:
        points.append(Vector2(cos(i * TAU / 16.0) * 8, sin(i * TAU / 16.0) * 3))
    shadow.polygon = points
    shadow.color = Color(0.015, 0.012, 0.02, 0.40)
    add_child(shadow)
    sprite = Sprite2D.new()
    var base := "res://art/prototype/ketel/" + character_id
    _full_sheet = ResourceLoader.exists(base + "_sheet.png")
    sprite.texture = load(base + ("_sheet.png" if _full_sheet else "_preview.png"))
    sprite.hframes = 6 if _full_sheet else 1
    sprite.vframes = 8 if _full_sheet else 1
    sprite.position = Vector2(0, -22)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(sprite)
    if controlled:
        add_to_group("player")


func _physics_process(delta: float) -> void:
    _clock += delta
    velocity = Vector2.ZERO
    if controlled and not input_locked:
        var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        velocity = Player.movement_velocity(input, Input.is_action_pressed("run"))
        if input.length_squared() > 0.01:
            face_towards(position + input)
        move_and_slide()
    var frame_index := 0
    if velocity.length_squared() > 1:
        var gait := 1.75 if Input.is_action_pressed("run") else 1.0
        frame_index = [1, 2, 3, 2][int(_clock * 7 * gait) % 4]
    elif not activity.is_empty() and not input_locked:
        frame_index = 4 + int(_clock * 1.6) % 2
    if _full_sheet:
        sprite.frame = direction * 6 + frame_index


func face_towards(at: Vector2) -> void:
    var offset := at - position
    if offset.length_squared() < 0.001:
        return
    facing_vector = offset.normalized()
    direction = posmod(int(round(atan2(offset.x, offset.y) / (PI / 4))), 8)


func release() -> void:
    input_locked = false
    direction = home_direction
