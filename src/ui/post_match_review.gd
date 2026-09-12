## A world-owned review offer. The result already exists before this opens.
class_name PostMatchReview
extends CanvasLayer

signal closed
var record_index := -1
var opponent_name := ""
var leave_hint := ""
var _awaiting: StringName = &"review"
var _yes := false
var _root: Control
var _text: Label
var _choices: VBoxContainer
var _loading: ReviewLoading
var _waiting := false


func _ready() -> void:
    name = "PostMatchReview"
    layer = 30
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_root)
    var dim := ColorRect.new()
    dim.color = Color(0.05, 0.05, 0.08, 0.76)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.add_child(dim)
    var panel := UiKit.panel(_root, Rect2(42, 55, 300, 104))
    _text = UiKit.label(panel, Vector2(12, 12), 276, UiKit.INK, 70)
    _text.text = "Go over the game with %s?" % opponent_name
    _choices = VBoxContainer.new()
    _choices.position = Vector2(12, 42)
    _choices.size.x = 276
    panel.add_child(_choices)
    for value in [true, false]:
        var button := Button.new()
        button.name = "review_yes" if value else "review_no"
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.focus_mode = Control.FOCUS_NONE
        button.custom_minimum_size = Vector2(276, UiKit.LINE_H * 2)
        button.add_theme_font_override("font", UiKit.FONT)
        button.add_theme_font_size_override("font_size", UiKit.FONT_SIZE)
        for state in ["normal", "hover", "pressed"]:
            var style := StyleBoxFlat.new()
            style.bg_color = Color(0, 0, 0, 0) if state == "normal" else Color("#eccd96")
            style.set_content_margin_all(0)
            button.add_theme_stylebox_override(state, style)
            button.add_theme_color_override("font_" + state + "_color", UiKit.INK)
        button.add_theme_color_override("font_color", UiKit.INK)
        button.mouse_entered.connect(func():
            _yes = value
            _refresh())
        button.pressed.connect(_choose.bind(value))
        _choices.add_child(button)
    _refresh()


func _refresh() -> void:
    (_choices.get_child(0) as Button).text = "> Yes" if _yes else "  Yes"
    (_choices.get_child(1) as Button).text = "  No" if _yes else "> No"


func _unhandled_input(event: InputEvent) -> void:
    if _awaiting == &"cards":
        return
    if event.is_action_pressed("cancel"):
        if _waiting:
            _waiting = false
        else:
            _close()
    elif _awaiting == &"review":
        if event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
            _yes = not _yes
            _refresh()
        elif event.is_action_pressed("interact"):
            _choose(_yes)
    get_viewport().set_input_as_handled()


func _choose(yes: bool) -> void:
    if _awaiting != &"review":
        return
    if not yes:
        _close()
        return
    _awaiting = &"review_wait"
    _root.hide()
    _loading = ReviewLoading.new()
    if not leave_hint.is_empty():
        _loading.leave_hint = leave_hint
    _loading.setup(opponent_name)
    _loading.leave_requested.connect(func(): _waiting = false)
    add_child(_loading)
    _waiting = true
    var progress := func(index: int, done: int, total: int):
        if index == record_index and is_instance_valid(_loading):
            _loading.set_progress(done, total)
    MatchReviewService.progress.connect(progress)
    if not MatchBridge.request_review(record_index):
        _waiting = false
    var payload: Dictionary = {}
    while _waiting:
        payload = GameState.match_analysis.get(str(record_index), {})
        if not payload.is_empty() and payload.get("availability", "") != "pending":
            break
        await get_tree().process_frame
    MatchReviewService.progress.disconnect(progress)
    _loading.dismiss()
    if not _waiting:
        _close()
        return
    _waiting = false
    _awaiting = &"cards"
    var cards := ReviewCards.new()
    cards.setup(payload, opponent_name)
    add_child(cards)
    await cards.closed
    _close()


func _close() -> void:
    _awaiting = &""
    closed.emit()
    queue_free()
