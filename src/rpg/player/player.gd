## The player character in the town: free movement, collision, and a probe that
## finds whatever they are facing.
class_name Player
extends CharacterBody2D

const SPEED := 58.0
const PROBE_REACH := 12.0
## One footstep every this many pixels walked, so the cadence follows the legs
## rather than a timer.
const STEP_DISTANCE := 15.0

## What the ground sounds like, by tile name. Anything not listed is the
## default -- stone, which is most of a port city. The whole point is that
## stepping off the pavement into De Ketel is audible.
const SURFACES := {
    "floor_wood_a": "wood", "floor_wood_b": "wood", "floor_mat": "wood",
    "rug": "wood", "plank": "wood",
    "grass_a": "gravel", "grass_b": "gravel", "grass_c": "gravel",
    "grass_flowers": "gravel", "gravel": "gravel", "dirt": "gravel",
}

signal wants_interaction(target: Interactable)

var facing: int = Facing.Dir.DOWN
var input_locked: bool = false
## Set by World at spawn. Only used to ask what is under the player's feet.
var map: MapData = null

@onready var sprite: CharacterSprite = $Sprite
@onready var probe: Area2D = $Probe

var _current_target: Interactable = null
var _distance_walked: float = 0.0


func _ready() -> void:
    sprite.set_sheet("player")
    add_to_group("player")
    _update_probe()


func _physics_process(_delta: float) -> void:
    if input_locked:
        velocity = Vector2.ZERO
        sprite.walking = false
        move_and_slide()
        return

    var dir := Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    )
    if dir.length_squared() > 1.0:
        dir = dir.normalized()

    velocity = dir * SPEED
    move_and_slide()

    sprite.walking = dir.length_squared() > 0.01
    if sprite.walking:
        facing = Facing.from_vector(dir, facing)
        sprite.face(facing)
        _update_probe()
        _distance_walked += velocity.length() * get_physics_process_delta_time()
        if _distance_walked >= STEP_DISTANCE:
            _distance_walked = 0.0
            Audio.play_footstep(_surface())
    else:
        _distance_walked = STEP_DISTANCE      # the next step lands immediately
    _refresh_target()


func _unhandled_input(event: InputEvent) -> void:
    if input_locked:
        return
    if event.is_action_pressed("interact"):
        if _current_target != null:
            get_viewport().set_input_as_handled()
            wants_interaction.emit(_current_target)


## The tile under the feet, not under the centre: the sprite's origin is at
## ground level already, so global_position is the right point to ask about.
func _surface() -> String:
    if map == null:
        return ""
    var t := map.tile_size
    var tile_name := map.tile_name_at(map.ground,
        int(global_position.x / t), int(global_position.y / t))
    return str(SURFACES.get(tile_name, ""))


func face_towards(point: Vector2) -> void:
    facing = Facing.from_vector(point - global_position, facing)
    sprite.face(facing)
    _update_probe()


func _update_probe() -> void:
    probe.position = Facing.to_vector(facing) * PROBE_REACH + Vector2(0, -8)


## The interactable in front of the player, if any. Highest priority wins.
func _refresh_target() -> void:
    var best: Interactable = null
    for area in probe.get_overlapping_areas():
        if area is Interactable and area.enabled:
            if best == null or area.interact_priority > best.interact_priority:
                best = area
    if best == _current_target:
        return
    _current_target = best
    if best == null:
        EventBus.interaction_cleared.emit()
    else:
        EventBus.interaction_available.emit(best.prompt)


func clear_target() -> void:
    _current_target = null
    EventBus.interaction_cleared.emit()
