## Registers the game's input actions in code, so the key map lives next to the
## code that reads it rather than inside project.godot.
extends Node

const ACTIONS := {
    "move_left": [KEY_LEFT, KEY_A],
    "move_right": [KEY_RIGHT, KEY_D],
    "move_up": [KEY_UP, KEY_W],
    "move_down": [KEY_DOWN, KEY_S],
    "interact": [KEY_SPACE, KEY_ENTER, KEY_E, KEY_Z, KEY_KP_ENTER],
    "cancel": [KEY_ESCAPE, KEY_X, KEY_BACKSPACE],
    "menu": [KEY_TAB],
    "go_pass": [KEY_P],
    "go_resign": [KEY_R],
    "go_confirm": [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER],
    # Deleting a save is the only irreversible thing outside the board, so it
    # gets its own action rather than riding on `interact` -- the same reason
    # `go_resign` exists. D is also `move_right`: harmless, because the slot
    # panel is the only place that reads `delete_save` and it has nothing to
    # move right to, and everywhere else `delete_save` goes unread. It has to
    # be a named action either way: the autopilot sends InputEventAction, so a
    # raw keycode check would make deleting undriveable and unverifiable.
    "delete_save": [KEY_DELETE, KEY_D],
    "debug_screenshot": [KEY_F12],
}


func _enter_tree() -> void:
    for action in ACTIONS:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key in ACTIONS[action]:
            var ev := InputEventKey.new()
            ev.physical_keycode = key
            InputMap.action_add_event(action, ev)
