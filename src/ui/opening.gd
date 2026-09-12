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
var _portrait: TextureRect
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
    # The first screen of the game was a flat #14121a rectangle with a portrait
    # and a board floating on it, which reads as a screen that has not finished
    # loading. It is the same dusk as the title card, thirty seconds later and
    # with the rain in it, and it carries no subject of its own: everything on
    # this screen is drawn over it.
    var bg := ColorRect.new()
    bg.color = Color("#14121a")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    const BACKDROP := "res://art/rendered/ui/opening.png"
    if ResourceLoader.exists(BACKDROP):
        var art := TextureRect.new()
        art.texture = load(BACKDROP)
        art.set_anchors_preset(Control.PRESET_FULL_RECT)
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_SCALE
        art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        add_child(art)

    # An empty board, lit from nowhere. It is the only thing on screen at first.
    _board = _draw_board()
    add_child(_board)

    # A frame, for the same reason the board gets a shadow: a 64x64 bust with
    # its own pale background, dropped straight onto the sky, is a sticker.
    _portrait_frame = Control.new()
    _portrait_frame.position = Vector2(22, 32)
    _portrait_frame.modulate.a = 0.0
    add_child(_portrait_frame)
    for spec in [[Vector2(3, 3), Vector2(68, 68), Color(0.08, 0.07, 0.10, 0.55)],
            [Vector2(0, 0), Vector2(68, 68), Color("#2a2633")],
            [Vector2(1, 1), Vector2(66, 66), Color("#8a6023")]]:
        var piece := ColorRect.new()
        piece.position = spec[0]
        piece.size = spec[1]
        piece.color = spec[2]
        _portrait_frame.add_child(piece)

    _portrait = TextureRect.new()
    _portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _portrait.position = Vector2(24, 34)
    _portrait.size = Vector2(64, 64)
    _portrait.modulate.a = 0.0
    var portrait_path := "res://art/portraits/hana.png"
    if ResourceLoader.exists(portrait_path):
        _portrait.texture = PortraitMoods.slice(load(portrait_path), "neutral")
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
    # A shadow first, so the board sits on the evening rather than in front of
    # it. It is the one saturated object in the game (ART_DIRECTION 1) and on a
    # dim backdrop that made it read as a rectangle pasted on.
    var shade := ColorRect.new()
    shade.color = Color(0.08, 0.07, 0.10, 0.55)
    shade.size = Vector2(112, 112)
    shade.position = Vector2(11, 3)
    holder.add_child(shade)
    var slab := TextureRect.new()
    slab.texture = load("res://art/rendered/ui/board_surface.png")
    slab.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    slab.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    slab.size = Vector2(112, 112)
    slab.position = Vector2(8, 0)
    holder.add_child(slab)
    var rim := ColorRect.new()
    rim.color = Color("#a97b3c")
    rim.size = Vector2(112, 2)
    rim.position = Vector2(8, 110)
    holder.add_child(rim)
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
