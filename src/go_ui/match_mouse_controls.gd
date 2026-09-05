## Phase-specific buttons reuse the match's guarded keyboard actions.
class_name MatchMouseControls
extends Node

var _scene: Control
var _bar: MouseActions
var _modal: MouseActions
var _navigation: BoardNavigation
var _choices: VBoxContainer


func setup(scene: Control, overlay: Control, navigation: BoardNavigation) -> void:
    _scene = scene
    _navigation = navigation
    _bar = MouseActions.new()
    _bar.position = Vector2(204, 197)
    scene.add_child(_bar)
    _bar.action_selected.connect(scene._mouse_action)
    _modal = MouseActions.new()
    _modal.position = Vector2(82, 197)
    overlay.add_child(_modal)
    _modal.action_selected.connect(scene._mouse_action)


func refresh(phase: int, awaiting: StringName, ready: bool, handicap: bool, help_open: bool) -> void:
    var states: Dictionary = _scene.Phase
    var specs: Array = []
    var modal: Array = []
    if _choices != null:
        _choices.visible = phase == states.REVIEW and awaiting == &"review"
    _navigation.visible = not help_open and phase in [states.PLAYING, states.SCORING]
    if not help_open:
        if phase == states.PLAYING:
            specs = [["Pass P", "go_pass", ready], ["Resign R", "go_resign", ready]]
            if handicap:
                specs.append(["Help H", "go_help"])
        elif phase == states.SCORING:
            specs = [["Accept count P", "go_pass", awaiting == &"scoring"]]
            if handicap:
                specs.append(["Help H", "go_help"])
        elif phase == states.PREPARING:
            specs = [["Cancel", "cancel", awaiting == &"prepare"]]
        elif phase == states.CONFIRM:
            modal = [["Resign R", "go_resign"], ["Keep playing", "cancel"]]
        elif phase == states.DONE and awaiting == &"dismiss":
            modal = [["Continue", "interact"]]
    _bar.configure(specs)
    _modal.configure(modal)


func show_review_choice(card: Control, body: Label, who: String, yes: bool) -> void:
    var question := "Go over the game with %s?" % who
    # Reserve the same two choice rows in the measured card; the rows themselves
    # are buttons, so their visible labels are also their mouse targets.
    UiKit.fit_card(card, body, question + "\n\n\n\n\n[Space] choose", 288)
    if _choices == null:
        _choices = VBoxContainer.new()
        _choices.add_theme_constant_override("separation", 0)
        card.add_child(_choices)
        for value in [true, false]:
            var button := Button.new()
            button.name = "review_yes" if value else "review_no"
            button.alignment = HORIZONTAL_ALIGNMENT_LEFT
            button.focus_mode = Control.FOCUS_NONE
            button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
            button.custom_minimum_size = Vector2(268, UiKit.LINE_H)
            button.add_theme_font_override("font", UiKit.FONT)
            button.add_theme_font_size_override("font_size", UiKit.FONT_SIZE)
            for state in ["normal", "hover", "pressed"]:
                var style := StyleBoxFlat.new()
                style.bg_color = Color(0, 0, 0, 0) if state == "normal" else Color("#eccd96")
                style.set_content_margin_all(0)
                button.add_theme_stylebox_override(state, style)
                button.add_theme_color_override("font_" + state + "_color", UiKit.INK)
            button.add_theme_color_override("font_color", UiKit.INK)
            button.mouse_entered.connect(_scene._select_review_choice.bind(value))
            button.pressed.connect(_scene._mouse_action.bind(&"review_yes" if value else &"review_no"))
            _choices.add_child(button)
    _choices.position = body.position + Vector2(0, UiKit.text_height(question, 268) + UiKit.LINE_H)
    _choices.size = Vector2(268, UiKit.LINE_H * 2)
    (_choices.get_child(0) as Button).text = "> Yes" if yes else "  Yes"
    (_choices.get_child(1) as Button).text = "  No" if yes else "> No"
    _choices.show()
