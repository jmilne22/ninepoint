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
const PRIORITY_SIGN := 1
const PRIORITY_PERSON := 2

var enabled: bool = true


func _ready() -> void:
    collision_layer = 4
    collision_mask = 0
    monitorable = true
    monitoring = false


func interact(by: Node) -> void:
    if enabled:
        interacted.emit(by)
