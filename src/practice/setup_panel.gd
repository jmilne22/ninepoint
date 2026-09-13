class_name PracticeSetupPanel
extends HBoxContainer

var settings: PracticeSettings
var summary: Label
var portrait: TextureRect
var rank_slider: HSlider
var rank_choice: OptionButton
var capture_disabled: Array[Control] = []
var board_choice: OptionButton
var handicap_choice: OptionButton
var stone_choice: SpinBox
var player_choice: OptionButton
var colour_choice: OptionButton
var komi_choice: SpinBox

func _ready() -> void:
    settings = PracticeSession.settings
    add_theme_constant_override("separation", 10)
    var left := PracticeUi.scroll(self)
    left.get_parent().custom_minimum_size.x = 218
    var right := VBoxContainer.new()
    right.custom_minimum_size.x = 132
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(right)
    PracticeUi.choice(left, "Game", ["Ordinary", "Teaching", "Capture Go"], ["ordinary", "teaching", "capture"].find(settings.mode), func(i: int):
        settings.mode = ["ordinary", "teaching", "capture"][i]; refresh())
    board_choice = PracticeUi.choice(left, "Board", ["7×7", "9×9", "13×13", "19×19"], PracticeSettings.SIZES.find(settings.board_size), func(i: int):
        settings.board_size = PracticeSettings.SIZES[i]; refresh())
    capture_disabled.append(board_choice)
    var ranks: Array = []
    for i in 35: ranks.append(GoRank.to_string_rank(i) + (" (approx.)" if i < 10 else ""))
    rank_choice = PracticeUi.choice(left, "AI rank", ranks, settings.rank, func(i: int): settings.rank = i; refresh())
    capture_disabled.append(rank_choice)
    rank_slider = HSlider.new()
    rank_slider.min_value = 0
    rank_slider.max_value = 34
    rank_slider.step = 1
    rank_slider.value = settings.rank
    rank_slider.custom_minimum_size.y = 12
    left.add_child(rank_slider)
    rank_slider.value_changed.connect(func(value: float): settings.rank = int(value); refresh())
    capture_disabled.append(rank_slider)
    capture_disabled.append(PracticeUi.choice(left, "Style", ["Steady", "Balanced", "Fighting"], ["steady", "balanced", "fighting"].find(settings.style), func(i: int):
        settings.style = ["steady", "balanced", "fighting"][i]; refresh()))
    colour_choice = PracticeUi.choice(left, "Your colour", ["Black", "White", "Nigiri"], ["black", "white", "nigiri"].find(settings.colour), func(i: int):
        settings.colour = ["black", "white", "nigiri"][i]; refresh())
    capture_disabled.append(colour_choice)
    handicap_choice = PracticeUi.choice(left, "Handicap", ["None", "Automatic", "Manual"], ["none", "auto", "manual"].find(settings.handicap_mode), func(i: int):
        settings.handicap_mode = ["none", "auto", "manual"][i]; refresh())
    capture_disabled.append(handicap_choice)
    player_choice = PracticeUi.choice(left, "Your rank", ranks, settings.player_rank, func(i: int): settings.player_rank = i; refresh())
    stone_choice = PracticeUi.number(left, "Black stones", settings.stones, 2, 9, 1, func(value: float): settings.stones = int(value); refresh())
    var advanced := VBoxContainer.new()
    advanced.visible = false
    PracticeUi.button(left, "Advanced settings", func(): advanced.visible = not advanced.visible)
    left.add_child(advanced)
    capture_disabled.append(PracticeUi.choice(advanced, "Komi", ["Standard", "Custom"], 1 if settings.custom_komi else 0, func(i: int):
        settings.custom_komi = i == 1; refresh()))
    komi_choice = PracticeUi.number(advanced, "Custom komi", settings.komi, -50, 50, 0.5, func(value: float): settings.komi = value; refresh())
    capture_disabled.append(komi_choice)
    PracticeUi.label(advanced, "Your practice name")
    var name_edit := LineEdit.new()
    name_edit.text = settings.player_name
    name_edit.max_length = 24
    name_edit.text_changed.connect(func(value: String): settings.player_name = value.strip_edges() if not value.strip_edges().is_empty() else "You"; refresh())
    advanced.add_child(name_edit)
    PracticeUi.style_field(name_edit)
    PracticeUi.paragraph(left, "Teaching adds coaching, Hint and Undo. Your practice rank is only used for automatic handicap.")
    PracticeUi.label(right, "Opponent avatar")
    var gallery := GridContainer.new()
    gallery.columns = 7
    gallery.add_theme_constant_override("h_separation", 2)
    gallery.add_theme_constant_override("v_separation", 2)
    right.add_child(gallery)
    var avatar_group := ButtonGroup.new()
    for id in PracticeSettings.AVATARS:
        var button := Button.new()
        button.custom_minimum_size = Vector2(17, 17)
        button.toggle_mode = true
        button.button_group = avatar_group
        button.button_pressed = settings.avatar == id
        button.tooltip_text = "Avatar %d" % (PracticeSettings.AVATARS.find(id) + 1)
        button.pressed.connect(func(): settings.avatar = id; refresh())
        gallery.add_child(button)
        var avatar := ExpressivePortrait.new()
        avatar.size = Vector2(17, 17)
        button.add_child(avatar)
        avatar.setup(id)
    summary = PracticeUi.paragraph(right, "")
    summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
    PracticeUi.button(right, "Start game", start)
    refresh()

func refresh() -> void:
    if summary == null: return
    settings.stones = clampi(settings.stones, 2, GoRank.max_handicap(settings.board_size))
    summary.text = "Avatar %d · Practice AI\n%s" % [PracticeSettings.AVATARS.find(settings.avatar) + 1, settings.summary()]
    rank_slider.set_value_no_signal(settings.rank)
    rank_choice.select(settings.rank)
    var capture := settings.mode == "capture"
    for control in capture_disabled:
        if control is OptionButton: control.disabled = capture
        elif control is HSlider: control.editable = not capture
        elif control is SpinBox: control.editable = not capture
    komi_choice.get_parent().visible = settings.custom_komi
    colour_choice.disabled = capture or settings.handicap_mode == "auto"
    if settings.handicap_mode == "manual" and settings.colour == "nigiri":
        settings.colour = "black"
        colour_choice.select(0)
        summary.text = "Avatar %d · Practice AI\n%s" % [PracticeSettings.AVATARS.find(settings.avatar) + 1, settings.summary()]
    colour_choice.set_item_disabled(2, settings.handicap_mode == "manual")
    player_choice.get_parent().visible = not capture and settings.handicap_mode == "auto"
    stone_choice.get_parent().visible = not capture and settings.handicap_mode == "manual"
    stone_choice.max_value = GoRank.max_handicap(settings.board_size)
    PracticeSession.save()

func start() -> void:
    if not PracticeSession.store.data.active.is_empty():
        var choice := TeachingChoice.new()
        choice.text = "You have a suspended game. Resume it, or replace it with this setup?"
        choice.options = ["Resume game", "Replace game", "Back"]
        choice.cancel_index = 2
        get_tree().current_scene.add_child(choice)
        var selected: int = await choice.selected
        if selected == 0: PracticeSession.start_game(true)
        if selected != 1: return
        PracticeSession.discard()
    PracticeSession.start_game()
