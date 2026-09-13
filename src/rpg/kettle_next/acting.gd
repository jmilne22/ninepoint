## One owner for clip playback. Gestures finish once, then settle into a loop.
class_name KettleNextActing
extends RefCounted

const LOOPS := ["stand", "host", "relaxed", "listen", "counter", "seated", "walk", "run", "idle", "table_rest", "thinking", "serve"]
var animation: AnimationPlayer
var current := ""
var gesture := ""
var remaining := 0.0
var serial := 0
var time := 0.0
var blink_at := 2.4
var blink_left := 0.0
var identity := ""

func setup(player: AnimationPlayer, who: String) -> void:
    animation = player
    identity = who
    blink_at += float(absi(who.hash()) % 19) * .11
    for clip in animation.get_animation_list():
        animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if clip in LOOPS else Animation.LOOP_NONE

func perform(clip: String) -> void:
    if not animation.has_animation(clip): return
    serial += 1
    gesture = clip
    remaining = animation.get_animation(clip).length
    _play(clip, true)

func update(delta: float, resting: String, rate: float = 1.0) -> int:
    time += delta
    remaining = maxf(0.0, remaining - delta)
    if remaining == 0.0: gesture = ""
    var selected := gesture if not gesture.is_empty() else resting
    _play(selected)
    animation.speed_scale = rate if selected in ["walk", "run"] else 1.0
    blink_left = maxf(0.0, blink_left - delta)
    if time >= blink_at:
        blink_left = .12
        blink_at = time + 3.3 + fmod(time * .731 + float(absi(identity.hash()) % 13), 2.5)
    if blink_left > 0.0: return 5
    if selected == "thinking": return 1
    if selected in ["pleased", "greet"]: return 2
    if selected == "surprise": return 3
    if selected == "concern": return 4
    return 0

func cancel() -> void:
    serial += 1
    gesture = ""
    remaining = 0.0

func _play(clip: String, restart: bool = false) -> void:
    if not animation.has_animation(clip): return
    if current == clip and not restart: return
    var phase := -1.0
    if clip in ["walk", "run"] and current in ["walk", "run"]:
        phase = animation.current_animation_position / animation.current_animation_length
    animation.play(clip, .16 if clip in LOOPS else .12)
    if phase >= 0.0: animation.seek(phase * animation.get_animation(clip).length)
    elif current.is_empty() and KettleNextProfile.campaign() and clip in LOOPS and clip not in ["walk","run"]:
        animation.seek(float(absi(identity.hash()) % 71) / 100.0 * animation.get_animation(clip).length)
    current = clip
