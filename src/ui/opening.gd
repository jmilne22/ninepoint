## The cold open. Hana addresses the player directly, then asks their name.
##
## The Professor Oak position: before the world exists, somebody explains what
## this is and wants to know what to call you. Hana gets it because she is the
## teacher the whole game is walking towards, and planting her here means the
## player recognises her when they finally meet her in Act 1.
extends Control

const LINES := [
    "Hello. I'm Hana. Welcome to Sela.",
    "I help run a small Go club here. Come and learn with us.",
]

const MAX_NAME := 10

var _board: Control
var _portrait: Control
var _portrait_frame: Control
var _text: Label
var _more: Label
var _field: LineEdit
var _hint: Label

var _line := 0
var _revealing := false
var _reveal_t := 0.0
var _awaiting: StringName = &""


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build()
    _run()


func _build() -> void:
    # Keep the room quiet behind Hana and the first empty board.
    var bg := ColorRect.new()
    bg.color = Color("#243b33")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var art := ExpressiveBackdrop.new()
    art.map_id = "de_ketel"
    add_child(art)
    var veil := ColorRect.new()
    veil.color = Color(.13,.23,.20,.55)
    veil.size = UiKit.VIEW
    add_child(veil)
    _board = _draw_board()
    add_child(_board)
    _portrait_frame = Control.new()
    add_child(_portrait_frame)
    var hana := ExpressivePortrait.new()
    hana.position = Vector2(20,0)
    hana.size = Vector2(280,300)
    hana.scale = Vector2(.5,.5)
    hana.modulate.a = 0
    add_child(hana)
    hana.setup("hana")
    hana.perform("greet",2.8)
    _portrait = hana

    var panel := UiKit.panel(self, Rect2(20, 138, 344, 60))
    _text = UiKit.label(panel, Vector2(10, 8), 324, UiKit.INK, 44)
    _more = UiKit.label(panel, Vector2(326, 44), 16, UiKit.GOLD)
    _more.text = "▼"
    _more.visible = false

    _field = LineEdit.new()
    _field.position = Vector2(10, 26)
    _field.size = Vector2(130, 18)
    _field.max_length = MAX_NAME
    _field.text = "Ro"
    _field.alignment = HORIZONTAL_ALIGNMENT_CENTER
    _field.add_theme_font_override("font", UiKit.FONT)
    _field.add_theme_font_size_override("font_size", UiKit.FONT_SIZE)
    _field.add_theme_color_override("font_color", UiKit.INK)
    _field.add_theme_color_override("caret_color", UiKit.GOLD)
    var box := StyleBoxFlat.new()
    box.bg_color = Color("#f2e9d8")
    box.border_color = Color("#926b36")
    box.set_border_width_all(1)
    box.set_content_margin_all(4)
    _field.add_theme_stylebox_override("normal", box)
    _field.add_theme_stylebox_override("focus", box)
    _field.visible = false
    panel.add_child(_field)

    _hint = UiKit.label(panel, Vector2(150, 30), 180, UiKit.INK_FAINT)
    _hint.text = "type, then Enter"
    _hint.visible = false


## The introduction uses the same wooden set as the cast matches.
func _draw_board() -> Control:
    var holder := Control.new()
    holder.position = Vector2(145,16)
    holder.size = Vector2(225,120)
    var view := TableSceneStage.viewport(holder,Vector2i(450,240),true)
    for child in holder.get_children():
        if child is TextureRect:
            child.size = holder.size
    var table: Node3D = load("res://art/table_scene/table.glb").instantiate()
    view.add_child(table)
    _prepare_table(table)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 1.5
    camera.position = Vector3(0,2.2,1.8)
    view.add_child(camera)
    camera.look_at_from_position(camera.position,Vector3.ZERO)
    for i in 9:
        for direction in 2:
            var bar := MeshInstance3D.new()
            var mesh := BoxMesh.new()
            mesh.size = Vector3(.004,.002,.88) if direction == 0 else Vector3(.88,.002,.004)
            bar.mesh = mesh
            bar.position = Vector3(-.44+i*.11,.122,0) if direction == 0 else Vector3(0,.122,-.44+i*.11)
            bar.material_override = TableSceneStage.material(Color("57432b"))
            view.add_child(bar)
    holder.modulate.a = 0
    return holder


func _prepare_table(node: Node) -> void:
    if node is MeshInstance3D:
        for index in node.mesh.get_surface_count():
            var original: Material = node.get_active_material(index)
            if original == null: continue
            if original.resource_name == "Table walnut": node.hide()
            elif original.resource_name in ["Kaya","Board end grain"]:
                var wood := ShaderMaterial.new()
                wood.shader = preload("res://src/go_ui/table_scene/wood.gdshader")
                wood.set_shader_parameter("grain",load("res://art/table_scene/kaya.png"))
                wood.set_shader_parameter("tint",Color.WHITE if original.resource_name == "Kaya" else Color("927247"))
                node.set_surface_override_material(index,wood)
    for child in node.get_children(): _prepare_table(child)


func _run() -> void:
    # the board fades up first, then the woman talking about it
    var tw := create_tween()
    tw.tween_property(_board, "modulate:a", 1.0, 1.1)
    tw.tween_interval(0.3)
    tw.parallel().tween_property(_portrait, "modulate:a", 1.0, 0.7)
    tw.parallel().tween_property(_portrait_frame, "modulate:a", 1.0, 0.7)
    await tw.finished

    for i in LINES.size():
        _line = i
        await _say(LINES[i])
        if not is_inside_tree():
            return

    await _ask_name()
    if not is_inside_tree():
        return

    GameState.reset()
    GameState.player_name = _clean_name(_field.text)
    GameState.set_flag("opening_seen", true)
    SceneRouter.go_to_map(GameState.DEFAULT_MAP, "start")


func _say(line: String) -> void:
    _text.text = line
    _text.visible_characters = 0
    _reveal_t = 0.0
    _revealing = true
    _more.visible = false
    _awaiting = &"line"
    while _awaiting == &"line" and is_inside_tree():
        await get_tree().process_frame


func _ask_name() -> void:
    _text.text = "What should I call you?"
    _text.visible_characters = -1
    _revealing = false
    _more.visible = false
    _field.visible = true
    _hint.visible = true
    _field.grab_focus()
    _field.caret_column = _field.text.length()
    _awaiting = &"name"
    while _awaiting == &"name" and is_inside_tree():
        await get_tree().process_frame
    _field.release_focus()
    Audio.play("ui_confirm")
    _text.text = "Nice to meet you, %s. We can get you ready for your first local Cup." % _clean_name(_field.text)
    _field.visible = false
    _hint.visible = false
    await get_tree().create_timer(1.6).timeout


static func _clean_name(raw: String) -> String:
    var name := raw.strip_edges()
    if name == "":
        return "Ro"
    return name.substr(0, MAX_NAME)


func _process(delta: float) -> void:
    if not _revealing:
        return
    _reveal_t += delta * 90.0
    _text.visible_characters = int(_reveal_t)
    if _text.visible_characters >= _text.text.length():
        _revealing = false
        _text.visible_characters = -1
        _more.visible = true


func _input(event: InputEvent) -> void:
    if _awaiting == &"name":
        # The field owns the keyboard; only the commit is ours.
        if event.is_action_pressed("interact") and _field.text.strip_edges() != "":
            _awaiting = &""
            get_viewport().set_input_as_handled()
        return
    if _awaiting == &"line" and event.is_action_pressed("interact"):
        get_viewport().set_input_as_handled()
        if _revealing:
            _revealing = false
            _text.visible_characters = -1
            _more.visible = true
        else:
            Audio.play("ui_move")
            _awaiting = &""
