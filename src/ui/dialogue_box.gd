## The dialogue box: typewriter text, a portrait, and choices.
##
## Presentation only. It asks DialogueGraph what to show next and hands the
## caller back whatever the conversation ended with.
class_name DialogueBox
extends CanvasLayer

signal finished(exit: Dictionary)

const CHARS_PER_SECOND := 90.0
const BOX_RECT := Rect2(4, 140, 376, 72)
## The same box along the top edge, for when the people talking are standing
## where the bottom one would cover them.
const BOX_TOP_Y := 4.0
## Text rect: 288 px beside a portrait (354 without one) by four rows of the
## font's 11 px line height.
const TEXT_H := 44

## Whoever the box should keep on screen. The World sets it to the player: a
## conversation happens where the player is standing, and a box that covers
## both people talking is a box over the wrong third of the screen.
var anchor: Node2D = null
const EXPRESSIONS := {"neutral": 0, "happy": 1, "annoyed": 2}

var running: bool = false

var _root: Control
var _panel: NinePatchRect
var _portrait: TextureRect
var _name_plate: Label
var _name_label: Label
var _text: Label
var _more: Label
var _choice_box: VBoxContainer
var _choice_index: int = 0
var _choice_nodes: Array[Label] = []

var _revealing := false
var _reveal_t := 0.0
var _awaiting_advance := false
var _awaiting_choice := false
var _chosen := -1


func _ready() -> void:
    layer = 20
    _build()
    hide_box()


func _build() -> void:
    _root = Control.new()
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_root)

    _panel = NinePatchRect.new()
    _panel.texture = load("res://art/ui/panel.png")
    _panel.patch_margin_left = 6
    _panel.patch_margin_top = 6
    _panel.patch_margin_right = 6
    _panel.patch_margin_bottom = 6
    _panel.position = BOX_RECT.position
    _panel.size = BOX_RECT.size
    _panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _root.add_child(_panel)

    _portrait = TextureRect.new()
    _portrait.position = Vector2(8, 6)
    _portrait.size = Vector2(64, 64)
    _portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _panel.add_child(_portrait)

    _name_plate = Label.new()
    _name_plate.position = Vector2(78, 4)
    _name_plate.add_theme_font_size_override("font_size", 9)
    _name_plate.add_theme_color_override("font_color", Color("#8a6023"))
    _panel.add_child(_name_plate)

    _name_label = Label.new()
    _name_label.position = Vector2(78, 3)
    _name_label.add_theme_font_size_override("font_size", 9)
    _name_label.add_theme_color_override("font_color", Color("#2a2633"))
    _panel.add_child(_name_label)

    _text = Label.new()
    _text.position = Vector2(78, 18)
    _text.size = Vector2(288, 44)
    _text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _text.add_theme_font_size_override("font_size", 9)
    _text.add_theme_color_override("font_color", Color("#14121a"))
    _panel.add_child(_text)

    # On the frame, outside the text rect, so a long fourth row cannot run
    # into it.
    _more = Label.new()
    _more.position = Vector2(364, 58)
    _more.text = "▼"
    _more.add_theme_font_size_override("font_size", 9)
    _more.add_theme_color_override("font_color", Color("#8a6023"))
    _panel.add_child(_more)

    _choice_box = VBoxContainer.new()
    _choice_box.position = Vector2(78, 18)
    _choice_box.size = Vector2(288, 44)
    _choice_box.add_theme_constant_override("separation", 1)
    _panel.add_child(_choice_box)


func show_box() -> void:
    _panel.position.y = BOX_TOP_Y if _anchor_is_low() else BOX_RECT.position.y
    _root.visible = true


## Is the anchor standing in the bottom half of the screen, where the box goes?
func _anchor_is_low() -> bool:
    if anchor == null or not is_instance_valid(anchor):
        return false
    var cam := get_viewport().get_camera_2d()
    if cam == null:
        return false
    var top := cam.get_screen_center_position().y - UiKit.VIEW.y * 0.5
    return anchor.global_position.y - top > UiKit.VIEW.y * 0.55


func hide_box() -> void:
    _root.visible = false


## Plays a whole conversation. Returns the exit dictionary of the last node.
func run(graph: DialogueGraph, speaker: Dictionary, start: String = "start") -> Dictionary:
    var node_id := graph.resolve(start)
    if node_id == "":
        # Nothing to say from this entry point -- do not flash an empty box.
        finished.emit({"type": "end"})
        return {"type": "end"}
    running = true
    show_box()
    var exit := {"type": "end"}
    var guard := 128
    while node_id != "" and guard > 0:
        guard -= 1
        var n: Dictionary = graph.node(node_id)
        DialogueGraph.apply(n.get("actions", []))

        var who: Dictionary = speaker
        if n.has("speaker"):
            who = _speaker_for(str(n["speaker"]), speaker)
        _set_speaker(who, str(n.get("portrait", "neutral")))

        for line in n.get("text", []):
            for page in _pages(str(line)):
                await _say(page)

        if n.has("choices"):
            var options: Array = []
            for c in n["choices"]:
                if DialogueGraph.check(c.get("if", [])):
                    options.append(c)
            if options.is_empty():
                node_id = graph.resolve(str(n.get("goto", "")))
                continue
            var picked: Dictionary = await _choose(options)
            DialogueGraph.apply(picked.get("actions", []))
            if picked.has("exit"):
                exit = picked["exit"]
                break
            node_id = graph.resolve(str(picked.get("goto", "")))
            continue

        if n.has("exit"):
            exit = n["exit"]
            break
        node_id = graph.resolve(str(n.get("goto", "")))

    hide_box()
    running = false
    finished.emit(exit)
    return exit


func _speaker_for(key: String, fallback: Dictionary) -> Dictionary:
    if key == "narrator" or key == "":
        return {"name": "", "portrait": null}
    var path := "res://data/npcs/%s.tres" % key
    if ResourceLoader.exists(path):
        var d: NpcData = load(path)
        return {"name": d.display_name, "portrait": d.portrait_texture(), "rank": d.rank_label}
    return fallback


func _set_speaker(who: Dictionary, expression: String) -> void:
    var name_text := str(who.get("name", ""))
    if who.get("rank", "") != "":
        name_text += "   %s" % str(who["rank"])
    _name_label.text = name_text
    _name_plate.text = name_text
    var tex = who.get("portrait", null)
    _portrait.visible = tex != null
    if tex != null:
        var at := AtlasTexture.new()
        at.atlas = tex
        var col: int = int(EXPRESSIONS.get(expression, 0))
        at.region = Rect2(col * 64, 0, 64, 64)
        _portrait.texture = at
    _text.position.x = 78 if tex != null else 12
    _text.size.x = 288 if tex != null else 354
    _choice_box.position.x = _text.position.x
    _choice_box.size.x = _text.size.x


## A line that would run past the fourth row is shown a sentence at a time.
## The writing rules keep lines short enough that this rarely fires; it is here
## so that when it does, the text is paged rather than drawn over the frame.
func _pages(line: String) -> PackedStringArray:
    var width := int(_text.size.x)
    if UiKit.text_height(line, width) <= TEXT_H:
        return PackedStringArray([line])
    var pages := PackedStringArray()
    var current := ""
    for sentence in line.split(". "):
        var piece := sentence if sentence.ends_with(".") else sentence + "."
        var candidate := piece if current == "" else current + " " + piece
        if current != "" and UiKit.text_height(candidate, width) > TEXT_H:
            pages.append(current)
            current = piece
        else:
            current = candidate
    if current != "":
        pages.append(current)
    return pages


func _say(line: String) -> void:
    _choice_box.visible = false
    _text.visible = true
    _text.text = line
    _text.visible_characters = 0
    _revealing = true
    _reveal_t = 0.0
    _more.visible = false
    _awaiting_advance = true
    while _awaiting_advance:
        await get_tree().process_frame


func _choose(options: Array) -> Dictionary:
    _text.visible = false
    _choice_box.visible = true
    _more.visible = false
    for c in _choice_nodes:
        c.queue_free()
    _choice_nodes.clear()
    for o in options:
        var l := Label.new()
        l.text = "  " + str(o.get("text", "..."))
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.add_theme_font_size_override("font_size", 9)
        l.add_theme_color_override("font_color", Color("#45404f"))
        _choice_box.add_child(l)
        _choice_nodes.append(l)
    _choice_index = 0
    _highlight()
    _awaiting_choice = true
    _chosen = -1
    while _awaiting_choice:
        await get_tree().process_frame
    _choice_box.visible = false
    return options[clampi(_chosen, 0, options.size() - 1)]


func _highlight() -> void:
    for i in _choice_nodes.size():
        var selected := i == _choice_index
        _choice_nodes[i].text = ("> " if selected else "  ") + _choice_nodes[i].text.substr(2)
        _choice_nodes[i].add_theme_color_override(
            "font_color", Color("#14121a") if selected else Color("#6b6577"))


func _process(delta: float) -> void:
    if not _revealing:
        return
    var before := _text.visible_characters
    _reveal_t += delta * CHARS_PER_SECOND
    _text.visible_characters = int(_reveal_t)
    # One blip every few characters: per-character is a machine gun.
    if _text.visible_characters > before and _text.visible_characters % 3 == 0:
        Audio.play("blip", 0.12)
    if _text.visible_characters >= _text.text.length():
        _revealing = false
        _text.visible_characters = -1
        _more.visible = true


func _input(event: InputEvent) -> void:
    if not running:
        return
    if _awaiting_choice:
        if event.is_action_pressed("move_down"):
            _choice_index = (_choice_index + 1) % _choice_nodes.size()
            Audio.play("ui_move")
            _highlight()
            get_viewport().set_input_as_handled()
        elif event.is_action_pressed("move_up"):
            _choice_index = (_choice_index - 1 + _choice_nodes.size()) % _choice_nodes.size()
            Audio.play("ui_move")
            _highlight()
            get_viewport().set_input_as_handled()
        elif event.is_action_pressed("interact"):
            _chosen = _choice_index
            Audio.play("ui_confirm")
            _awaiting_choice = false
            get_viewport().set_input_as_handled()
        return
    if _awaiting_advance and event.is_action_pressed("interact"):
        get_viewport().set_input_as_handled()
        if _revealing:
            _revealing = false
            _text.visible_characters = -1
            _more.visible = true
        else:
            _awaiting_advance = false
