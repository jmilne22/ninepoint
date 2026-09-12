## The tram the rails on Market Lane have always implied.
##
## It finds its own route: the longest unbroken run of tram_rail_h on the ground
## layer is the track, so this needs no map data at all -- the same trick
## Soundscape uses to find the stove.
##
## Deliberately no collision. It is scenery on the far track, and it y-sorts
## against the player like everything else in Entities, so walking south of the
## rails puts you in front of it.
##
## It is also the tram you board: the stop asks it to `arrive()` and the scene
## changes once it has pulled up, so the thing that passes and the thing that
## carries you are one vehicle rather than two.
class_name Tram
extends Node2D

const SPRITE := "res://art/props/tram.png"
const WIDTH := 160.0
const HEIGHT := 36.0
## Below this a "run of rails" is a decoration, not a route.
const MIN_RUN := 10
const CROSS_TIME := 6.5
const GAP_MIN := 26.0
const GAP_MAX := 52.0

var _room: RoomProjection
var _sprite: Sprite2D
var _sections: Array[Sprite2D] = []
var _section_feet: Array[Vector2] = []
var _shadows: Array[Polygon2D] = []
var _travel: Tween
var _bell: Tween
var _left: float = 0.0
var _right: float = 0.0
var _t: float = 0.0
var _crossing: bool = false
var _going_east: bool = true


## Returns the tram, or null if this map has no track worth running one on.
static func build(map: MapData, parent: Node2D) -> Tram:
    var run := _longest_run(map)
    if int(run.get("len", 0)) < MIN_RUN:
        return null
    if not ResourceLoader.exists(SPRITE):
        push_warning("Tram: no %s -- run python3 tools/build_assets.py" % SPRITE)
        return null
    var tram := Tram.new()
    tram.name = "Tram"
    tram._room = map.presentation
    var t := map.tile_size
    tram._left = float(int(run["x"]) * t)
    tram._right = float((int(run["x"]) + int(run["len"])) * t)
    # The rails sit across the middle of their tile; put the tram's base there.
    tram.position = Vector2(tram._left - WIDTH, float(int(run["y"]) * t + t))
    parent.add_child(tram)
    return tram


func _ready() -> void:
    _sprite = Sprite2D.new()
    _sprite.texture = load(SPRITE)
    _sprite.centered = false
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    # Base at the node's y, so Entities' y-sort puts the player in front of it
    # from the pavement south of the tracks.
    _sprite.position = Vector2(-WIDTH * 0.5, -HEIGHT)
    add_child(_sprite)
    if _room != null:
        _sprite.hide()
        var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/rendered/ui/tram.json"))
        var origin := Vector2(float(data.origin[0]), float(data.origin[1]))
        for section: Dictionary in data.sections:
            var part := Sprite2D.new()
            part.texture = load("res://art/rendered/ui/" + str(section.texture))
            part.centered = false
            part.top_level = true
            part.offset = -origin
            part.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            part.material = _room.material_for_actor()
            add_child(part)
            _sections.append(part)
            _section_feet.append(Vector2(float(section.ground[0]), float(section.ground[1])))
            var shadow := Polygon2D.new()
            var points := PackedVector2Array()
            for j in 16:
                var angle := float(j) * TAU / 16.0
                points.append(Vector2(cos(angle) * 29, sin(angle) * 10).rotated(atan(0.5)))
            shadow.polygon = points
            shadow.color = Color(0.02, 0.025, 0.03, 0.23)
            shadow.top_level = true
            shadow.material = part.material
            add_child(shadow)
            _shadows.append(shadow)
    visible = false
    # The first one comes soon after you arrive on the street. A first wait
    # drawn from the full gap meant the tram was frequently a rumour.
    _t = randf_range(6.0, 14.0)


func _process(delta: float) -> void:
    if _room != null:
        for i in _sections.size():
            var part := _sections[i]
            var feet := global_position + _section_feet[i]
            var ground := _room.project(feet).round()
            part.global_position = _room.project(global_position).round()
            part.z_as_relative = false
            part.z_index = clampi(int(ground.y), 1, 4000)
            (part.material as ShaderMaterial).set_shader_parameter("actor_depth", _room.ground_depth(feet))
            _shadows[i].global_position = ground
            _shadows[i].z_as_relative = false
            _shadows[i].z_index = part.z_index - 1
    if _crossing:
        return
    _t -= delta
    if _t <= 0.0:
        _cross()


## Tweened rather than awaited. A node must not await a call that can destroy
## it, and leaving this map does exactly that mid-crossing.
func _cross() -> void:
    _crossing = true
    _going_east = not _going_east
    var from_x := _left - WIDTH if _going_east else _right + WIDTH
    var to_x := _right + WIDTH if _going_east else _left - WIDTH
    position.x = from_x
    _sprite.flip_h = not _going_east
    visible = true

    Audio.play_at("amb_tram", self, 0.03, -7.0, 360.0)

    _cancel_travel()
    _travel = create_tween()
    _travel.tween_property(self, "position:x", to_x, CROSS_TIME)
    _travel.tween_callback(_finish)

    _bell = create_tween()
    _bell.tween_interval(CROSS_TIME * 0.42)
    _bell.tween_callback(_ring)


## Pull in from the east and stop with the door at `stop_x`, then wait a beat.
## Awaited by the stop; the caller changes scene afterwards, which frees this
## node, so nothing here may run after the await returns.
func arrive(stop_x: float) -> void:
    _cancel_travel()
    _crossing = true
    _going_east = false
    position.x = _right + WIDTH
    _sprite.flip_h = true
    visible = true
    Audio.play_at("amb_tram", self, 0.03, -7.0, 360.0)
    _travel = create_tween()
    _travel.tween_property(self, "position:x", stop_x, 2.4) \
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
    await _travel.finished
    _ring()
    await get_tree().create_timer(0.8).timeout


func _cancel_travel() -> void:
    # Boarding can interrupt a passing tram; its old tween must relinquish position.
    if _travel != null and _travel.is_valid():
        _travel.kill()
    if _bell != null and _bell.is_valid():
        _bell.kill()


func _ring() -> void:
    Audio.play_at("tram_bell", self, 0.02, -10.0, 360.0)


func _finish() -> void:
    visible = false
    _crossing = false
    _t = randf_range(GAP_MIN, GAP_MAX)


## The longest unbroken horizontal run of track on the map.
static func _longest_run(map: MapData) -> Dictionary:
    var best := {"x": 0, "y": 0, "len": 0}
    for y in map.height:
        var x := 0
        while x < map.width:
            if map.tile_name_at(map.ground, x, y) != "tram_rail_h":
                x += 1
                continue
            var run := 0
            while x + run < map.width \
                    and map.tile_name_at(map.ground, x + run, y) == "tram_rail_h":
                run += 1
            if run > int(best["len"]):
                best = {"x": x, "y": y, "len": run}
            x += run
    return best
