## Actual move intent is separate from scene reconstruction and redraws.
## The surface consumes an intent only when its landing tween finishes.
class_name TableStoneAudio
extends Node

signal stone_landed
signal capture_landed(count: int)
var pending: Dictionary = {}
var offscreen: Dictionary = {}

func request(point: int, captured: int) -> void:
    pending[point] = captured

func land(point: int) -> void:
    if not pending.has(point): return
    var count: int = pending[point]
    pending.erase(point)
    offscreen.erase(point)
    stone_landed.emit()
    if count <= 0: return
    # Child timers die with the presentation, so leaving cannot leak clatters.
    var timer := Timer.new()
    timer.one_shot = true
    timer.wait_time = .085
    add_child(timer)
    timer.timeout.connect(func() -> void:
        capture_landed.emit(count)
        timer.queue_free())
    timer.start()

func wait_offscreen(point: int) -> void:
    if offscreen.has(point): return
    var timer := Timer.new()
    offscreen[point] = timer
    timer.one_shot = true
    timer.wait_time = .18
    add_child(timer)
    timer.timeout.connect(func() -> void:
        land(point)
        timer.queue_free())
    timer.start()

func cancel_offscreen(point: int) -> void:
    if not offscreen.has(point): return
    var timer: Timer = offscreen[point]
    timer.queue_free()
    offscreen.erase(point)
