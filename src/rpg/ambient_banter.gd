## Brief, non-interactive fragments of a conversation already in progress.
## They never block the player or compete with the dialogue UI.
class_name AmbientBanter
extends Node2D

const SHOW_FOR := 3.2
const GAP_MIN := 7.0
const GAP_MAX := 13.0

var _lines: Array = []
var _npcs: Array = []
var _label: Label
var _timer := 2.0


func setup(lines: Array, npcs: Array) -> void:
    _lines = lines
    _npcs = npcs
    if _lines.is_empty():
        return
    _label = Label.new()
    _label.name = "Overheard"
    _label.visible = false
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _label.add_theme_font_size_override("font_size", 9)
    _label.add_theme_color_override("font_color", Color("f2e9d8"))
    _label.add_theme_color_override("font_outline_color", Color("14121a"))
    _label.add_theme_constant_override("outline_size", 2)
    _label.z_index = 6
    add_child(_label)


func _process(delta: float) -> void:
    if _label == null:
        return
    _timer -= delta
    if _timer > 0.0:
        return
    if _label.visible:
        _label.visible = false
        _timer = randf_range(GAP_MIN, GAP_MAX)
        return
    var entry: Dictionary = _lines[randi() % _lines.size()]
    var npc := _find_npc(str(entry.get("npc", "")))
    if npc == null or bool(npc.get("busy")):
        _timer = 1.0
        return
    _label.text = str(entry.get("text", ""))
    _label.position = npc.position + Vector2(-62, -38)
    _label.visible = _label.text != ""
    _timer = SHOW_FOR


func _find_npc(id: String) -> Node2D:
    for npc in _npcs:
        if npc.npc_id == id:
            return npc
    return null
