## The tram the rails on Ketelsteeg have always implied.
##
## It finds its own route: the longest unbroken run of tram_rail_h on the ground
## layer is the track, so this needs no map data at all -- the same trick
## Soundscape uses to find the stove.
##
## Deliberately no collision. It is scenery on the far track, and it y-sorts
## against the player like everything else in Entities, so walking south of the
## rails puts you in front of it.
class_name Tram
extends Node2D

const SPRITE := "res://art/props/tram.png"
const WIDTH := 48.0
## Below this a "run of rails" is a decoration, not a route.
const MIN_RUN := 10
const CROSS_TIME := 6.5
const GAP_MIN := 26.0
const GAP_MAX := 52.0

var _sprite: Sprite2D
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
    _sprite.position = Vector2(-WIDTH * 0.5, -18.0)
    add_child(_sprite)
    visible = false
    # The first one comes soon after you arrive on the street. A first wait
    # drawn from the full gap meant the tram was frequently a rumour.
    _t = randf_range(6.0, 14.0)


func _process(delta: float) -> void:
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

    var tw := create_tween()
    tw.tween_property(self, "position:x", to_x, CROSS_TIME)
    tw.tween_callback(_finish)

    var bell := create_tween()
    bell.tween_interval(CROSS_TIME * 0.42)
    bell.tween_callback(_ring)


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
