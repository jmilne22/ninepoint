extends Node

func _ready() -> void:
    SaveSystem.load_game(1)
    SceneRouter.go_to_map("de_ketel", "from_street")
