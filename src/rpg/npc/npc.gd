## A townsperson. Stands somewhere, does something, and can be talked to.
## Everything specific to them lives in their NpcData; what they do while you
## are not talking to them lives in their NpcIdle.
class_name Npc
extends CharacterBody2D

## How close you have to get before somebody looks up, and how long they keep
## looking after you have gone past.
const NOTICE_RANGE := 42.0
const NOTICE_HOLD := 2.0

signal talk_requested(npc: Npc)

@export var npc_id: String = ""

var data: NpcData
var facing: int = Facing.Dir.DOWN
var busy: bool = false
## What they do when left alone. Null is a person who stands still, which is
## the right answer for a teacher mid-lesson.
var idle: NpcIdle = null
## Where they were put, and which way they were put facing. Both are what an
## idle behaviour returns to.
var home: Vector2
var home_facing: int = Facing.Dir.DOWN

@onready var sprite: CharacterSprite = $Sprite
@onready var interactable: Interactable = $Interact

var _player: Node2D = null
var _noticing: bool = false
var _notice_t: float = 0.0


func _ready() -> void:
    home = global_position
    add_to_group("npc")
    if npc_id != "":
        var path := "res://data/npcs/%s.tres" % npc_id
        if ResourceLoader.exists(path):
            data = load(path)
    if data != null:
        sprite.set_sheet(data.sprite_id if data.sprite_id != "" else npc_id)
        facing = Facing.from_name(data.default_dir)
        interactable.prompt = "Talk to %s" % data.display_name
    else:
        sprite.set_sheet(npc_id)
        push_warning("Npc: no NpcData for '%s'" % npc_id)
    # A person outranks a notice. MapBuilder gives every sign PRIORITY_SIGN and
    # this was left at the default 0, so wherever a readable object and a human
    # being were both inside the probe -- which is a 14x14 box and routinely
    # holds two things -- [Space] read the object. Standing in front of
    # somebody and being handed a paragraph about the furniture behind them is
    # the bug, and it is silent: the dialogue box opens either way.
    #
    # Found in M36, when the autopilot walked up to Abel in the wassalon and
    # got the folding table he was standing beside, then advanced through it
    # under a screenshot captioned with his name.
    interactable.interact_priority = Interactable.PRIORITY_PERSON
    home_facing = facing
    sprite.face(facing)
    interactable.interacted.connect(_on_interacted)


func _physics_process(delta: float) -> void:
    if busy or data == null:
        stand()
        return
    if _notice(delta):
        return
    if idle != null:
        idle.tick(self, delta)
    else:
        stand()


## Somebody walking past you is worth looking up for. Every NPC gets this,
## whatever else they are doing -- before it, you could walk the length of
## Ketelsteeg and nobody in the city would register that you existed.
##
## Returns true while it owns the NPC, so an idle behaviour does not fight it.
func _notice(delta: float) -> bool:
    if _player == null:
        _player = get_tree().get_first_node_in_group("player") as Node2D
        if _player == null:
            return false
    var reach := NOTICE_RANGE
    if idle != null and idle.notice_range > 0.0:
        reach = idle.notice_range
    var near := global_position.distance_to(_player.global_position) < reach
    if near:
        if not _noticing:
            _noticing = true
        _notice_t = NOTICE_HOLD
        look_at_point(_player.global_position)
        stand()
        return true
    if not _noticing:
        return false
    _notice_t -= delta
    if _notice_t > 0.0:
        stand()
        return true
    _noticing = false
    set_facing(home_facing)
    return false


# --- the body, for NpcIdle to drive ------------------------------------------

## Walk one frame in `dir`. Returns true if they hit something, which is an
## idle behaviour's cue to pick a different direction.
func step(dir: Vector2, speed: float) -> bool:
    velocity = dir * speed
    move_and_slide()
    sprite.walking = dir != Vector2.ZERO
    if sprite.walking:
        facing = Facing.from_vector(dir, facing)
        sprite.face(facing)
    return get_slide_collision_count() > 0


func stand() -> void:
    velocity = Vector2.ZERO
    sprite.walking = false


func set_facing(dir: int) -> void:
    facing = dir
    sprite.face(facing)


func look_at_point(point: Vector2) -> void:
    set_facing(Facing.from_vector(point - global_position, facing))


func find_peer(other_id: String) -> Npc:
    for n in get_tree().get_nodes_in_group("npc"):
        if n is Npc and (n as Npc).npc_id == other_id:
            return n
    return null


func _on_interacted(by: Node) -> void:
    busy = true
    stand()
    if idle != null:
        idle.release()
    if by is Node2D:
        look_at_point((by as Node2D).global_position)
    talk_requested.emit(self)


func release() -> void:
    busy = false
