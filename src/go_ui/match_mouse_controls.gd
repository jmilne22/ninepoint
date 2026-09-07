## Phase-specific buttons reuse the match's guarded keyboard actions.
class_name MatchMouseControls
extends Node

var _scene: Control
var _bar: MouseActions
var _modal: MouseActions
var _navigation: BoardNavigation


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
