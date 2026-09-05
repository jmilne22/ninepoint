## The cold open. Hana addresses the player directly, then asks their name.
##
## The Professor Oak position: before the world exists, somebody explains what
## this is and wants to know what to call you. Hana gets it because she is the
## teacher the whole game is walking towards, and planting her here means the
## player recognises her when they finally meet her in Act 1.
extends Control

const LINES := [
    "Hello. I'm Hana. Welcome to Verhaven.",
    "People play Go all over this city. Come and join us.",
]

const MAX_NAME := 10

var _board: Control
var _portrait: TextureRect
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
    var bg := ColorRect.new()
    bg.color = Color("#14121a")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    # An empty board, lit from nowhere. It is the only thing on screen at first.
    _board = _draw_board()
    add_child(_board)

    _portrait = TextureRect.new()
    _portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _portrait.position = Vector2(24, 34)
    _portrait.size = Vector2(64, 64)
    _portrait.modulate.a = 0.0
    var portrait_path := "res://art/portraits/hana.png"
    if ResourceLoader.exists(portrait_path):
        var at := AtlasTexture.new()
        at.atlas = load(portrait_path)
        at.region = Rect2(0, 0, 64, 64)
        _portrait.texture = at
    add_child(_portrait)

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
    box.border_color = Color("#8a6023")
    box.set_border_width_all(1)
    box.set_content_margin_all(4)
    _field.add_theme_stylebox_override("normal", box)
    _field.add_theme_stylebox_override("focus", box)
    _field.visible = false
    panel.add_child(_field)

    _hint = UiKit.label(panel, Vector2(150, 30), 180, UiKit.INK_FAINT)
    _hint.text = "type, then Enter"
    _hint.visible = false


## A 9x9 board drawn once into a Control, so the opening has something on it
## other than words.
func _draw_board() -> Control:
    var holder := Control.new()
    holder.position = Vector2(232, 26)
    holder.size = Vector2(128, 100)
    var slab := ColorRect.new()
    slab.color = Color("#d9ac66")
    slab.size = Vector2(112, 112)
    slab.position = Vector2(8, 0)
    holder.add_child(slab)
    for i in 9:
        var h := ColorRect.new()
        h.color = Color("#3a2a18")
        h.position = Vector2(16, 8 + i * 12)
        h.size = Vector2(96, 1)
        holder.add_child(h)
        var v := ColorRect.new()
        v.color = Color("#3a2a18")
        v.position = Vector2(16 + i * 12, 8)
        v.size = Vector2(1, 96)
        holder.add_child(v)
    holder.modulate.a = 0.0
    return holder


func _run() -> void:
    # the board fades up first, then the woman talking about it
    var tw := create_tween()
    tw.tween_property(_board, "modulate:a", 1.0, 1.1)
    tw.tween_interval(0.3)
    tw.parallel().tween_property(_portrait, "modulate:a", 1.0, 0.7)
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
    _text.text = "Nice to meet you, %s. See you at the Instituut." % _clean_name(_field.text)
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
