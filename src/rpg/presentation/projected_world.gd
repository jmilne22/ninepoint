## The camera and static render share the projection used by character visuals.
class_name ProjectedWorld
extends Node2D

var world: Node2D
var room: RoomProjection

func setup(owner_world: Node2D) -> void:
    world = owner_world
    room = world.map.presentation
    var scenery := Sprite2D.new()
    scenery.texture = room.image
    var surface := ShaderMaterial.new()
    surface.shader = preload("res://src/rpg/presentation/scenery_material.gdshader")
    surface.set_shader_parameter("material_map", room.depth)
    scenery.material = surface
    scenery.centered = false
    scenery.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    scenery.z_index = -5
    add_child(scenery)
    var listener := AudioListener2D.new()
    world.player.add_child(listener)
    listener.make_current()
    world.camera.reparent(self)
    world.camera.position = room.project(world.player.position)
    var pad := (Vector2(384, 216) - room.size).max(Vector2.ZERO) / 2.0
    world.camera.limit_left = int(-pad.x)
    world.camera.limit_top = int(-pad.y)
    world.camera.limit_right = int(room.size.x + pad.x)
    world.camera.limit_bottom = int(room.size.y + pad.y)

func _process(_delta: float) -> void:
    if world == null:
        return
    if world.hud != null:
        world.hud.set_conversation(world.dialogue != null and world.dialogue.running)
    var lift := 18.0 if world.dialogue != null and world.dialogue.running else -14.0
    world.camera.position = (room.project(world.player.global_position) + Vector2(0, lift)).round()
