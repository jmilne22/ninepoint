## The town HUD: interaction prompt, toast messages, rank badge, journal line.
class_name Hud
extends CanvasLayer

const TOAST_TIME := 3.0

var _prompt: Label
var _toast: Label
var _toast_panel: NinePatchRect
var _rank: Label
var _day: Label
var _journal: Label
var _toast_t := 0.0


func _ready() -> void:
    layer = 10
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    _prompt = _make_label(root, Vector2(0, 124), 384, 9, Color("#f2e9d8"))
    _prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _prompt.add_theme_color_override("font_shadow_color", Color("#14121a"))
    _prompt.add_theme_constant_override("shadow_offset_y", 1)
    _prompt.add_theme_constant_override("shadow_offset_x", 1)
    _prompt.visible = false

    _toast_panel = NinePatchRect.new()
    _toast_panel.texture = load("res://art/ui/panel_dark.png")
    for m in ["left", "top", "right", "bottom"]:
        _toast_panel.set("patch_margin_%s" % m, 5)
    _toast_panel.position = Vector2(8, 6)
    _toast_panel.size = Vector2(368, 18)
    _toast_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _toast_panel.visible = false
    root.add_child(_toast_panel)

    _toast = Label.new()
    _toast.position = Vector2(8, 4)
    _toast.size = Vector2(352, 12)
    _toast.add_theme_font_size_override("font_size", 9)
    _toast.add_theme_color_override("font_color", Color("#f2d791"))
    _toast_panel.add_child(_toast)

    _rank = _make_label(root, Vector2(6, 202), 90, 9, Color("#ddd0b8"))
    # Top left, under the toast and clear of the journal, which is right-aligned
    # along the bottom and wraps into anything sharing its row. It says nothing
    # at all until Wren has mentioned the Cup: a countdown to a thing the player
    # has not heard of is a spoiler with a number on it.
    _day = _make_label(root, Vector2(6, 26), 200, 9, Color("#e0cfa8"))
    # The journal wraps to two lines: quest lines are sentences, and a single
    # right-aligned line ran off the edge of the screen.
    _journal = _make_label(root, Vector2(100, 191), 278, 9, Color("#bda98c"))
    _journal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _journal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _journal.size.y = 24
    _journal.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

    EventBus.interaction_available.connect(_on_prompt)
    EventBus.interaction_cleared.connect(func(): _prompt.visible = false)
    EventBus.toast.connect(show_toast)
    EventBus.rank_changed.connect(func(_o, _n): refresh())
    EventBus.quest_advanced.connect(func(_q, _s, _j): refresh())
    EventBus.day_changed.connect(func(_d): refresh())
    EventBus.time_block_changed.connect(func(_b): refresh())
    refresh()


func _make_label(parent: Node, pos: Vector2, width: int, size: int, colour: Color) -> Label:
    var l := Label.new()
    l.position = pos
    l.size = Vector2(width, size + 4)
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", colour)
    l.add_theme_color_override("font_shadow_color", Color("#14121a"))
    l.add_theme_constant_override("shadow_offset_y", 1)
    l.add_theme_constant_override("shadow_offset_x", 1)
    parent.add_child(l)
    return l


func _on_prompt(text: String) -> void:
    _prompt.text = "%s   [Space]" % text
    _prompt.visible = true


func show_toast(text: String) -> void:
    if text.strip_edges() == "":
        return
    _toast.text = text
    _toast_panel.visible = true
    _toast_t = TOAST_TIME


func refresh() -> void:
    _rank.text = "%s   %s" % [GameState.player_name, GameState.rank_label()]
    _day.text = _day_line()
    var ids: Array = Quests.active_quest_ids()
    _journal.text = Quests.journal_line(str(ids[0])) if not ids.is_empty() else ""


## "Day 3, afternoon" once there is a calendar worth showing, with the Cup
## counted down beside it once somebody has told the player it exists.
func _day_line() -> String:
    if not GameState.has_flag("wren_told_about_cup"):
        return ""
    var days := GameState.days_until_cup()
    if days <= 0:
        return "Day %d, %s   the Cup" % [GameState.day, GameState.time_block]
    return "Day %d, %s   Cup in %d" % [GameState.day, GameState.time_block, days]


func _process(delta: float) -> void:
    if _toast_t > 0.0:
        _toast_t -= delta
        if _toast_t <= 0.0:
            _toast_panel.visible = false
