## Follows the existing arrival tween; boarding and bell timing stay with Tram.
class_name ExpressiveTramVisual
extends Node3D
var source: Tram
func _ready() -> void:
    var vehicle: Node3D = load("res://art/campaign_next/tram.glb" if KettleNextProfile.campaign() else "res://art/expressive_world/tram.glb").instantiate()
    add_child(vehicle)
    if KettleNextProfile.campaign(): CampaignNextRoom.apply(vehicle)
    else: ExpressiveSurfaces.apply(vehicle)
func _process(_delta: float) -> void:
    if not is_instance_valid(source):
        queue_free()
        return
    visible = source.visible
    position = Vector3(source.position.x*.05,0,source.position.y*.05-.4)
    for child in source.get_children():
        if child is CanvasItem: child.hide()
