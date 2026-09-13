extends Control

var content: VBoxContainer
var tabs: HBoxContainer
var current: Control

func _ready() -> void:
    get_window().content_scale_size = Vector2i(384, 216)
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color("203b36")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, 8)
    add_child(margin)
    content = VBoxContainer.new()
    margin.add_child(content)
    var top := HBoxContainer.new()
    content.add_child(top)
    var title := PracticeUi.label(top, "PRACTICE", true)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    PracticeUi.button(top, "Title", PracticeSession.leave)
    tabs = HBoxContainer.new()
    content.add_child(tabs)
    for tab in ["Play", "Learn", "History"]:
        PracticeUi.button(tabs, tab, show_tab.bind(tab))
    var resume := PracticeUi.button(tabs, "Resume Game", func(): PracticeSession.start_game(true))
    resume.disabled = PracticeSession.store.data.active.is_empty()
    if not PracticeSession.notice.is_empty():
        PracticeUi.paragraph(content, PracticeSession.notice)
    show_tab(PracticeSession.tab)
    Audio.play_music("theme_club")

func show_tab(tab: String) -> void:
    if current != null:
        content.remove_child(current)
        current.queue_free()
    PracticeSession.tab = tab
    match tab:
        "Learn": current = PracticeLibrary.new()
        "History", "Result": current = PracticeHistory.new()
        _: current = PracticeSetupPanel.new()
    current.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(current)
    var first := current.find_next_valid_focus()
    if first != null: first.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("cancel"):
        get_viewport().set_input_as_handled()
        PracticeSession.leave()
