## Generated strips keep the same floor origin and shell in every frame.
class_name GeneratedProp
extends Sprite2D

var _holds := PackedFloat32Array()
var _elapsed := 0.0


func configure(animation: Dictionary) -> void:
    var count := int(animation.get("frames", 1))
    var holds: Array = animation.get("holds", [])
    if count <= 1:
        set_process(false)
        return
    if texture == null or texture.get_width() % count != 0 or holds.size() != count:
        push_error("Invalid generated prop strip")
        set_process(false)
        return
    for hold in holds:
        if float(hold) <= 0.0:
            push_error("Generated prop frame duration must be positive")
            _holds.clear()
            set_process(false)
            return
        _holds.append(float(hold))
    hframes = count
    set_process(true)


func _process(delta: float) -> void:
    if _holds.is_empty():
        return
    _elapsed += delta
    # A long render frame may cross several holds; retain the remainder.
    var duration := 0.0
    for hold in _holds:
        duration += hold
    _elapsed = fmod(_elapsed, duration)
    while _elapsed >= _holds[frame]:
        _elapsed -= _holds[frame]
        frame = (frame + 1) % hframes
