## A brief view through the tram window. Space or Escape continues immediately.
class_name TramArrival
extends CanvasLayer
signal finished
var destination := ""
var _leaving := false

func _ready() -> void:
    layer = 120
    var art := TextureRect.new()
    art.texture = load("res://art/props/arrival_%s.png" % destination)
    art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(art)
    var card := UiKit.panel(art, Rect2(28, 180, 328, 29), true)
    var label := UiKit.label(card, Vector2(8, 8), 312, UiKit.PAPER, 11)
    label.text = "%s   Space: continue" % ("Essenveld Instituut" if destination == "academy_hall" else "The Bondszaal")
    await get_tree().create_timer(3.0).timeout
    _finish()

func _input(event: InputEvent) -> void:
    get_viewport().set_input_as_handled()
    if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        _finish()

func _finish() -> void:
    if _leaving:
        return
    _leaving = true
    finished.emit()
    queue_free()
