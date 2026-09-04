## The town HUD: interaction prompt, toast messages, rank badge, journal line.
class_name Hud
extends CanvasLayer

const TOAST_TIME := 3.0

var _prompt: Label
var _toast: Label
var _toast_panel: NinePatchRect
var _rank: Label
var _journal: Label
var _toast_t := 0.0
var _rank_card: Control
var _root: Control


func _ready() -> void:
    layer = 10
    _root = Control.new()
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_root)

    _prompt = _make_label(_root, Vector2(0, 124), 384, 9, Color("#f2e9d8"))
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
    _root.add_child(_toast_panel)

    _toast = Label.new()
    _toast.position = Vector2(8, 4)
    _toast.size = Vector2(352, 12)
    _toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _toast.add_theme_font_size_override("font_size", 9)
    _toast.add_theme_color_override("font_color", Color("#f2d791"))
    _toast_panel.add_child(_toast)

    _rank = _make_label(_root, Vector2(6, 202), 90, 9, Color("#ddd0b8"))
    # The journal wraps to two lines: quest lines are sentences, and a single
    # right-aligned line ran off the edge of the screen.
    _journal = _make_label(_root, Vector2(100, 191), 278, 9, Color("#bda98c"))
    _journal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _journal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _journal.size.y = 24
    _journal.max_lines_visible = 2
    _journal.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

    EventBus.interaction_available.connect(_on_prompt)
    EventBus.interaction_cleared.connect(func(): _prompt.visible = false)
    EventBus.toast.connect(show_toast)
    EventBus.rank_changed.connect(func(_o, _n): refresh())
    EventBus.flag_changed.connect(_on_flag_changed)
    EventBus.quest_advanced.connect(func(_q, _s, _j): refresh())
    # Completion is not an advance -- QuestTracker emits quest_completed instead
    # of quest_advanced for the last step, so without this the journal keeps
    # displaying the final objective of a finished quest until a rank happened
    # to change. Every quest in the game ended that way; the exam
    # made it visible because finishing it is the last thing that happens.
    EventBus.quest_completed.connect(func(_q): refresh())
    refresh()


func _on_flag_changed(key: String, value: Variant) -> void:
    if key == "ranked_by_club" and bool(value):
        _show_first_rank_card(_root)


func _show_first_rank_card(root: Control) -> void:
    if _rank_card != null:
        return
    _rank_card = Control.new()
    _rank_card.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(_rank_card)
    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.07, 0.1, 0.72)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _rank_card.add_child(dim)
    var panel := UiKit.panel(_rank_card, Rect2(38, 22, 308, 172))
    var text := "FIRST RATING\n\n22k is a beginner rank. Lower kyu numbers are stronger; 1k is followed by 1d.\n\nOnly rated games change rank. Beat an effective opponent at or above your rank to rise one step; lose to one at or below to fall one. Handicap changes the effective strength used for that comparison.\n\n[Space / Esc] continue"
    var label := UiKit.label(panel, Vector2(10, 10), 288, UiKit.INK, 152)
    label.text = text


func _unhandled_input(event: InputEvent) -> void:
    if _rank_card != null and (event.is_action_pressed("interact") or event.is_action_pressed("cancel")):
        _rank_card.queue_free()
        _rank_card = null
        get_viewport().set_input_as_handled()


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
    # Sized to the text: the southbound tram's refusal was 439 px wide on a
    # 384 px screen, and the last three words were off the edge.
    var h := UiKit.text_height(text, 352)
    _toast.size.y = h
    _toast_panel.size.y = h + 8
    _toast_panel.visible = true
    _toast_t = TOAST_TIME


func refresh() -> void:
    _rank.text = "%s   %s" % [GameState.player_name, GameState.rank_label()]
    # Which quest that is, is QuestTracker's decision and is tested there.
    _journal.text = Quests.journal_line(Quests.journal_quest_id())


func _process(delta: float) -> void:
    if _toast_t > 0.0:
        _toast_t -= delta
        if _toast_t <= 0.0:
            _toast_panel.visible = false
