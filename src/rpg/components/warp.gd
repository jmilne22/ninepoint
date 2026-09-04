## A doorway. Steps the player from one map to another.
class_name Warp
extends Area2D

@export var target_map: String = ""
@export var target_spawn: String = ""
## When set, the doorway stays shut until this flag is true.
@export var required_flag: String = ""
@export_multiline var blocked_text: String = ""

var armed: bool = true


func _ready() -> void:
    collision_layer = 8
    collision_mask = 2
    monitoring = true
    armed = false
    body_entered.connect(_on_body_entered)
    _arm_when_clear()


## Somebody standing in the doorway as the map loads is stepping *out* of it.
## Arming immediately sends them straight back where they came from.
func _arm_when_clear() -> void:
    await get_tree().physics_frame
    await get_tree().physics_frame
    while is_inside_tree() and _player_inside():
        await get_tree().physics_frame
    armed = true


func _player_inside() -> bool:
    for b in get_overlapping_bodies():
        if b is Player:
            return true
    return false


func _on_body_entered(body: Node2D) -> void:
    if not armed or not (body is Player):
        return
    if SceneRouter.is_busy():
        return
    if required_flag != "" and not GameState.has_flag(required_flag):
        # Say why, once, rather than silently refusing to work.
        if blocked_text != "":
            EventBus.toast.emit(blocked_text)
        return
    armed = false
    (body as Player).input_locked = true
    SceneRouter.go_to_map(target_map, target_spawn)
