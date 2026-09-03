## Who an NPC is: identity, rank, art, dialogue, and who they are at the board.
class_name NpcData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
## A real rank ("20k", "4k", "1d"), never a difficulty word.
@export var rank_label: String = "20k"
@export_multiline var blurb: String = ""

@export_group("Art")
@export var sprite_id: String = ""
@export var portrait_id: String = ""

@export_group("Behaviour")
@export var dialogue_path: String = ""
@export var default_dir: String = "down"

@export_group("Go")
@export var opponent_profile: OpponentProfile


func portrait_texture() -> Texture2D:
    var path := "res://art/portraits/%s.png" % (portrait_id if portrait_id != "" else id)
    return load(path) if ResourceLoader.exists(path) else null


func strength() -> int:
    return GoRank.from_string(rank_label)
