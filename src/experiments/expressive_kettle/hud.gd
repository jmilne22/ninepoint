## Retain the existing novice-card and toast input seam in the isolated room.
extends Hud
func _ready() -> void:
    super._ready()
    _root.scale = Vector2(2,2)
    _journal_panel.hide()
    _journal.hide()
    _rank.hide()
