## The existing nigiri choice and timing, presented at the shared table.
class_name TableNigiri
extends NigiriCeremony
var match_scene: TableSceneMatch
var revealed: Array[Node3D] = []

func _ready() -> void:
    super._ready()
    for child in get_children():
        if child is CanvasItem: child.hide()
    for label in [_headline, _subline, _call, _count]:
        label.reparent(self)
        label.show()
    _headline.position = Vector2(12, 182)
    _headline.size = Vector2(360, 11)
    _subline.position = Vector2(12, 194)
    _subline.size = Vector2(360, 22)
    _call.position = Vector2(170, 144)
    _call.size = Vector2(80, 14)
    _call.add_theme_color_override("font_color", Color("51402c"))
    _count.position = Vector2(180, 54)
    _count.add_theme_font_size_override("font_size", 18)
    _count.add_theme_color_override("font_color", Color("51402c"))
    _count.hide()
    _actions.position = Vector2(145, 165)
    _actions.show()
    z_index = 80

func wipe_in() -> void:
    await get_tree().create_timer(0.35).timeout

func wipe_out() -> void:
    await get_tree().create_timer(0.35).timeout
    for stone in revealed:
        if is_instance_valid(stone): stone.queue_free()
    finished.emit()

func plunge() -> void:
    match_scene.wren_actor.perform("place", 1.6)
    await super.plunge()

func set_expression(mood: String) -> void:
    match_scene.wren_actor.perform("pleased" if mood == "happy" else "thinking", 1.6)

func _drop_stone(index: int, _total: int) -> void:
    var stone: Node3D = load("res://art/table_scene/white_stone.glb").instantiate()
    match_scene.surface.viewport.add_child(stone)
    match_scene.surface._stone_material(stone, GoBoard.WHITE)
    var column := index % 7
    var row := index / 7
    stone.position = Vector3((column - 3) * 0.10, 0.30, -0.08 + row * 0.12)
    revealed.append(stone)
    create_tween().tween_property(stone, "position:y", 0.143, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _kick(_power: float) -> void:
    pass
