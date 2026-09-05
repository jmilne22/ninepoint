## Brief, non-interactive fragments of a conversation already in progress.
## They never block the player or compete with the dialogue UI.
class_name AmbientBanter
extends Node2D

const SHOW_FOR := 3.2
const GAP_MIN := 7.0
const GAP_MAX := 13.0

var _lines: Array = []
var _npcs: Array = []
var _bubble: NinePatchRect
var _label: Label
var _timer := 4.0
var _cursor := 0
var _paused: Callable
var _suspended := false

const BUBBLE_W := 136
const BUBBLE_MIN_W := 48
const BUBBLE_PAD := 6
## Keep the bottom of the bubble above an NPC's head, rather than over its
## sprite. The label used to be only one line high; a framed line needs this
## extra clearance.
const BUBBLE_CLEARANCE := 24


func setup(lines: Array, npcs: Array, exchanges: Array = [], paused: Callable = Callable()) -> void:
    _paused = paused
    _lines = []
    for group in exchanges:
        _lines.append_array(group)
        _lines.append({"gap": true})
    for line in lines:
        _lines.append(line)
        _lines.append({"gap": true})
    _npcs = npcs
    if _lines.is_empty():
        return
    # Overheard lines travel across every surface in a map: pale pavement,
    # dark water, purple roofs. An outline alone disappears against the busy
    # ones, so give the words the same small dark frame used by the title card.
    _bubble = UiKit.panel(self, Rect2(Vector2.ZERO, Vector2(BUBBLE_W, 28)), true)
    _bubble.name = "OverheardBubble"
    _bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _bubble.visible = false
    _bubble.z_index = 6

    _label = UiKit.label(_bubble, Vector2(BUBBLE_PAD, BUBBLE_PAD),
        BUBBLE_W - BUBBLE_PAD * 2, UiKit.PAPER)
    _label.name = "Overheard"
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _label.add_theme_color_override("font_outline_color", Color("14121a"))
    _label.add_theme_constant_override("outline_size", 1)


func _process(delta: float) -> void:
    if _bubble == null:
        return
    if _paused.is_valid() and _paused.call():
        _suspended = _suspended or _bubble.visible
        _bubble.visible = false
        return
    if _suspended:
        _bubble.visible = true
        _timer = SHOW_FOR
        _suspended = false
    _timer -= delta
    if _timer > 0.0:
        return
    if _bubble.visible:
        _bubble.visible = false
        _timer = 0.6
        return
    if _cursor >= _lines.size():
        return
    var entry: Dictionary = _lines[_cursor]
    if entry.get("gap", false):
        _cursor += 1
        _timer = GAP_MAX
        return
    var npc := _find_npc(str(entry.get("npc", "")))
    if npc == null or bool(npc.get("busy")):
        _timer = 1.0
        return
    _cursor += 1
    _label.text = str(entry.get("text", ""))
    # Hug short lines instead of drawing a fixed, character-covering banner.
    # Longer prose wraps at the same compact maximum width.
    var measured: Vector2 = UiKit.FONT.get_string_size(_label.text,
        HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE)
    var bubble_w: int = clampi(int(ceil(measured.x)) + BUBBLE_PAD * 2,
        BUBBLE_MIN_W, BUBBLE_W)
    var inner_w := bubble_w - BUBBLE_PAD * 2
    _label.size.x = inner_w
    var text_h: int = maxi(UiKit.LINE_H, UiKit.text_height(_label.text, inner_w))
    _label.size.y = text_h
    _bubble.size.x = bubble_w
    _bubble.size.y = text_h + 12
    _bubble.position = npc.position + Vector2(-_bubble.size.x * 0.5,
        -_bubble.size.y - BUBBLE_CLEARANCE)
    _bubble.visible = _label.text != ""
    _timer = SHOW_FOR


func _find_npc(id: String) -> Node2D:
    for npc in _npcs:
        if npc.npc_id == id:
            return npc
    return null
