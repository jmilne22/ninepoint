## What a person does when nobody is talking to them.
##
## The policy only: it decides and calls back into the Npc, which owns the body
## and the sprite. Chosen by one optional "idle" key on the map's NPC entry, so
## giving Tomas something to do behind his counter is a data change.
class_name NpcIdle
extends RefCounted

const WANDER_SPEED := 26.0
const TEND_SPEED := 20.0
const BUBBLE := "res://art/props/bubble.png"
## One turn each. Long enough to read as talking, not as semaphore.
const TALK_CYCLE := 3.4
const LEASH := 26.0
## Twice the ordinary glance. "watch" is somebody who saw you come in.
const WATCH_RANGE := 96.0

var mode: String = ""
var arg: String = ""
## Zero means "use the Npc's default". "watch" raises it: Hana and Joos clock
## you from across the room, and that is the whole of their characterisation
## before either of them says a word.
var notice_range: float = 0.0

var _t: float = 0.0
var _dir: Vector2 = Vector2.ZERO
var _bubble: Sprite2D = null
var _partner: Npc = null


## "wander", "study", "tend", "watch", or "converse:<npc_id>".
static func make(spec: String) -> NpcIdle:
    if spec == "":
        return null
    var it := NpcIdle.new()
    var bits := spec.split(":")
    it.mode = bits[0]
    it.arg = bits[1] if bits.size() > 1 else ""
    it._t = randf_range(1.0, 3.0)
    if it.mode == "watch":
        it.notice_range = WATCH_RANGE
    return it


func tick(npc: Npc, delta: float) -> void:
    match mode:
        "wander": _wander(npc, delta)
        "converse": _converse(npc, delta)
        "study": _study(npc, delta)
        "tend": _tend(npc, delta)
        _: npc.stand()


# --- the behaviours ----------------------------------------------------------

## The original random walk, moved here unchanged: a leash back to where they
## were standing, so nobody wanders out of the scene they belong in.
func _wander(npc: Npc, delta: float) -> void:
    _t -= delta
    if _t <= 0.0:
        _t = randf_range(1.4, 3.4)
        if _dir == Vector2.ZERO and randf() < 0.65:
            var choices := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
            _dir = choices[randi() % choices.size()]
            if npc.global_position.distance_to(npc.home) > LEASH:
                _dir = (npc.home - npc.global_position).normalized()
        else:
            _dir = Vector2.ZERO
    if npc.step(_dir, WANDER_SPEED):
        _dir = Vector2.ZERO


func _converse(npc: Npc, _delta: float) -> void:
    npc.stand()
    if _partner == null:
        _partner = npc.find_peer(arg)
        if _partner == null:
            return
    npc.look_at_point(_partner.global_position)
    # Both ends run off the same wall clock and take turns without knowing
    # about each other: whoever's id sorts first gets the first half.
    var phase := fmod(float(Time.get_ticks_msec()) * 0.001, TALK_CYCLE) / TALK_CYCLE
    var mine := phase < 0.5 if npc.npc_id < arg else phase >= 0.5
    _set_bubble(npc, mine)


## Reading a board: mostly still, with the occasional glance away and back.
func _study(npc: Npc, delta: float) -> void:
    npc.stand()
    _t -= delta
    if _t > 0.0:
        return
    _t = randf_range(2.5, 6.0)
    if npc.facing == npc.home_facing:
        npc.set_facing(Facing.Dir.LEFT if randf() < 0.5 else Facing.Dir.RIGHT)
    else:
        npc.set_facing(npc.home_facing)


## Working: a short patrol either side of where they stand.
func _tend(npc: Npc, delta: float) -> void:
    _t -= delta
    if _t <= 0.0:
        _t = randf_range(2.0, 5.0)
        if _dir == Vector2.ZERO:
            _dir = Vector2.LEFT if randf() < 0.5 else Vector2.RIGHT
        else:
            _dir = Vector2.ZERO
    if _dir != Vector2.ZERO and npc.global_position.distance_to(npc.home) > 18.0:
        _dir = (npc.home - npc.global_position).normalized()
    if npc.step(_dir, TEND_SPEED):
        _dir = Vector2.ZERO


# --- the bubble --------------------------------------------------------------

func _set_bubble(npc: Npc, on: bool) -> void:
    if _bubble == null:
        if not on or not ResourceLoader.exists(BUBBLE):
            return
        _bubble = Sprite2D.new()
        _bubble.name = "Bubble"
        _bubble.texture = load(BUBBLE)
        _bubble.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        _bubble.position = Vector2(4, -28)
        _bubble.z_index = 5
        npc.add_child(_bubble)
    _bubble.visible = on


## Dialogue takes the NPC over; the bubble must not survive into it.
func release() -> void:
    if _bubble != null:
        _bubble.visible = false
