## Reuse the honest record/card content; this disposable visit has no save menu.
extends PauseMenu
func _ready() -> void:
    super._ready()
    _root.scale = Vector2(2,2)
    _root.get_child(1).hide()

func show_menu() -> void:
    open = true
    _root.show()
    _show_trainer_card()
    opened.emit()

func _input(event: InputEvent) -> void:
    if not open: return
    super._input(event)
    if not _card.visible:
        close()
