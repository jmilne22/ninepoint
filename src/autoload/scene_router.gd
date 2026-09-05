## Scene changes and fades. Knows nothing about what a Go match is.
extends Node

signal transition_midpoint()

const FADE_TIME := 0.22
const WORLD_SCENE := "res://src/rpg/world.tscn"

var _fade: ColorRect
var _busy := false

## Where the player should appear in the map that is about to load.
var pending_spawn: String = ""
var pending_position: Vector2 = Vector2.ZERO
var use_pending_position := false


func _ready() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 128
    add_child(layer)
    _fade = ColorRect.new()
    _fade.color = Color(0.078, 0.071, 0.102, 1.0)
    _fade.set_anchors_preset(Control.PRESET_FULL_RECT)
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade.modulate.a = 0.0
    _fade.visible = false
    layer.add_child(_fade)


func is_busy() -> bool:
    return _busy


## Fade out, swap the scene, fade in.
func go_to(scene_path: String, spawn: String = "", position_override = null) -> void:
    if _busy:
        return
    _busy = true
    pending_spawn = spawn
    use_pending_position = position_override != null
    if use_pending_position:
        pending_position = position_override
    await fade_out()
    transition_midpoint.emit()
    var err := get_tree().change_scene_to_file(scene_path)
    if err != OK:
        push_error("SceneRouter: cannot open %s (error %d)" % [scene_path, err])
    await get_tree().process_frame
    await get_tree().process_frame
    await fade_in()
    _busy = false


## Travel to a town map (by map id) and remember it as the player's location.
func go_to_map(map_id: String, spawn: String) -> void:
    if _busy:
        return
    GameState.current_map = map_id
    GameState.spawn_point = spawn
    GameState.has_return_position = false
    await go_to(WORLD_SCENE, spawn)


func fade_out() -> void:
    _fade.visible = true
    var tw := create_tween()
    tw.tween_property(_fade, "modulate:a", 1.0, FADE_TIME)
    await tw.finished


func fade_in() -> void:
    var tw := create_tween()
    tw.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
    await tw.finished
    _fade.visible = false


## Consumes the spawn instruction left for the map that just loaded.
func take_spawn() -> Dictionary:
    var out := {
        "spawn": pending_spawn,
        "position": pending_position,
        "use_position": use_pending_position,
    }
    pending_spawn = ""
    use_pending_position = false
    return out


## Owned by the router so the departure world never awaits its own destruction.
func travel_to_map(map_id: String, spawn: String) -> void:
    if _busy:
        return
    if map_id in ["academy_hall", "bondszaal"]:
        _busy = true
        var arrival := TramArrival.new()
        arrival.destination = map_id
        add_child(arrival)
        await arrival.finished
        _busy = false
    go_to_map(map_id, spawn)
