## The wait between asking somebody to go over the game and seeing the cards.
## It uses the same paper, ink and stone language as the board rather than a
## spinner, says how far along it is, and can be left: a 19x19 game takes the
## engine minutes, and the review waits at the quay for whoever walks off.
class_name ReviewLoading
extends CanvasLayer

var _stones: Array[Label] = []
var _title: Label
var _body: Label
var _who := ""


func setup(who: String) -> void:
    _who = who


func _ready() -> void:
    name = "ReviewLoading"
    layer = 30
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(root)
    var dim := ColorRect.new()
    dim.color = Color(0.05, 0.05, 0.08, 0.76)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(dim)
    var card := UiKit.panel(root, Rect2(66, 56, 252, 104))
    _title = UiKit.label(card, Vector2(14, 12), 224, UiKit.INK, 12)
    _title.text = "%s is going over the game." % _who if _who != "" else "Going over the game."
    _body = UiKit.label(card, Vector2(14, 30), 224, UiKit.INK_SOFT, 24)
    _body.text = "Setting the stones out again."
    for i in 3:
        var stone := UiKit.label(card, Vector2(18 + i * 24, 58), 16, UiKit.GOLD, 11)
        stone.text = "o"
        _stones.append(stone)
    var hint := UiKit.label(card, Vector2(14, 78), 224, UiKit.INK_FAINT, 12)
    hint.text = "[Esc] carry on without waiting"
    _pulse()


func set_progress(done: int, total: int) -> void:
    if is_instance_valid(_body):
        _body.text = "Move %d of %d." % [done, total]


func _pulse() -> void:
    # Staggered, looping stone pulses make progress visible without pretending
    # the engine can estimate an exact remaining time.
    for i in _stones.size():
        var stone := _stones[i]
        var tw := stone.create_tween().set_loops()
        tw.tween_interval(0.22 * i)
        tw.tween_property(stone, "modulate:a", 0.25, 0.32)
        tw.tween_property(stone, "modulate:a", 1.0, 0.32)
        tw.tween_interval(0.66 - 0.22 * i)


func dismiss() -> void:
    queue_free()
