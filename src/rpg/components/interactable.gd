## Anything the player can face and press the interact key on.
##
## Emits `interacted`; the owner decides what that means (talk, read, enter).
class_name Interactable
extends Area2D

signal interacted(by: Node)

@export var prompt: String = "Look"
## Higher wins when two interactables overlap the probe.
## (Named to avoid Area2D's own `priority` property.)
@export var interact_priority: int = 0

## The ordering, named here rather than written as bare numbers at the two
## places that set them -- which is how they came to be the wrong way round.
## A sign was 1 and a person was the default 0, so a notice on the wall
## outranked somebody standing in front of you whenever the probe held both.
## Nothing errored: the dialogue box opens for either.
## A doorway sits below both: a notice on a wall beside a door, or somebody
## standing in one, is what you meant to press [Space] on.
const PRIORITY_DOORWAY := 0
const PRIORITY_SIGN := 1
const PRIORITY_PERSON := 2

## Optional area used at the player's feet, independent of their facing probe.
## This is for boarding platforms; ordinary signs and people still require facing.
var standing_size: Vector2 = Vector2.ZERO
var enabled: bool = true


func _ready() -> void:
    collision_layer = 4
    collision_mask = 0
    monitorable = true
    monitoring = false
    if standing_size != Vector2.ZERO:
        add_to_group("standing_interactables")


func interact(by: Node) -> void:
    if enabled:
        interacted.emit(by)


func contains_feet(feet: Vector2) -> bool:
    return (enabled and standing_size != Vector2.ZERO
        and Rect2(-standing_size / 2.0, standing_size).has_point(to_local(feet)))
