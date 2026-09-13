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
    if KettleNextProfile.campaign(): _clean_panel()

func _clean_panel() -> void:
    var panel := Panel.new()
    panel.position = Vector2(8,153)
    panel.size = Vector2(368,61)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color("eee5d2")
    style.border_color = Color("587263")
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    panel.add_theme_stylebox_override("panel",style)
    add_child(panel)
    move_child(panel,0)
    _headline.position = Vector2(17,159)
    _headline.size = Vector2(350,12)
    _subline.position = Vector2(17,173)
    _subline.size = Vector2(350,22)
    for label in [_headline,_subline,_call,_count]:
        label.add_theme_color_override("font_color",Color("344c40"))
    _call.hide()
    _count.position = Vector2(335,195)
    _count.add_theme_font_size_override("font_size",9)
    _actions.position = Vector2(145,194)

func _slam(text: String) -> void:
    if not KettleNextProfile.campaign():
        await super._slam(text)
        return
    _call.text = text
    Audio.play("ui_confirm")
    await get_tree().process_frame

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

func _play_drop_audio() -> void:
    if not AudioPreview.requested(): super._play_drop_audio()

func _drop_stone(index: int, _total: int) -> void:
    var stone: Node3D = load("res://art/table_scene/white_stone.glb").instantiate()
    match_scene.surface.viewport.add_child(stone)
    match_scene.surface._stone_material(stone, GoBoard.WHITE)
    var column := index % 7
    var row := index / 7
    stone.position = Vector3((column - 3) * 0.10, 0.30, -0.08 + row * 0.12)
    revealed.append(stone)
    var landing := create_tween()
    landing.tween_property(stone, "position:y", 0.143, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    if AudioPreview.requested(): landing.tween_callback(Audio.play_stone)

func _kick(_power: float) -> void:
    pass

func _refresh_call() -> void:
    super._refresh_call()
    if KettleNextProfile.campaign(): _highlight_choice()

func _refresh_actions() -> void:
    super._refresh_actions()
    if KettleNextProfile.campaign(): _highlight_choice()

func _highlight_choice() -> void:
    var chosen := "black" if _pick_black else "white"
    if _awaiting == &"guess": chosen = "odd" if _pick_odd else "even"
    for child in _actions.get_children():
        if not child is Button: continue
        var selected: bool = str(child.name) == chosen
        var style := child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
        style.bg_color = Color("527362") if selected else Color("f5eddf")
        style.border_color = Color("294d3b") if selected else Color("91a394")
        child.add_theme_stylebox_override("normal",style)
        child.add_theme_color_override("font_color",Color("fff6e5") if selected else Color("344c40"))
