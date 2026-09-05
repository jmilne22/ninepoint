## A town map, loaded from data/maps/<id>.json.
##
## Maps are data, not scenes: a grid of legend characters plus spawns, warps,
## signs and NPC placements. tools/gen_maps.py authors them.
class_name MapData
extends RefCounted

const DIR := "res://data/maps/"

var id: String = ""
var display_name: String = ""
var width: int = 0
var height: int = 0
var tile_size: int = 16
var legend: Dictionary = {}          ## character -> tile name
var ground: PackedStringArray = PackedStringArray()
var decor: PackedStringArray = PackedStringArray()
var solid: PackedStringArray = PackedStringArray()
var spawns: Dictionary = {}
var warps: Array = []
var signs: Array = []
var npcs: Array = []
## Walk-through routes for the crowd: {"path": [[x, y], ...], "rate": seconds}.
## Empty on every interior, and on any map where traffic would be a lie.
var routes: Array = []
## Optional story-state variants. WorldPresence resolves one at map load; it
## may replace NPC placements/routes and add a decor overlay plus overheard text.
var presence_states: Array = []
var presence_tiles: Array = []
var presence_lines: Array = []
var presence_exchanges: Array = []
## Track name for this map, matched against audio/<name>.wav. "" is silence.
var art_props: Array = []
var music: String = ""
## Retained as an empty compatibility field: ambience tests and older authored
## maps may ask for it, but the game deliberately has no time-of-day music.
var music_night: String = ""
## What plays here after dark. "" keeps `music` at every hour.
## Indoors takes the hour much more gently and never gets rained on: inside a
## room the lights are simply on. Soundscape reads this.
var indoors: bool = false


static func load_map(map_id: String) -> MapData:
    var path := DIR + map_id + ".json"
    if not FileAccess.file_exists(path):
        push_error("MapData: no such map '%s'" % map_id)
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (parsed is Dictionary):
        push_error("MapData: '%s' is not valid JSON" % path)
        return null
    var m := MapData.new()
    m.id = map_id
    m.display_name = str(parsed.get("name", map_id))
    var size: Array = parsed.get("size", [0, 0])
    m.width = int(size[0])
    m.height = int(size[1])
    m.tile_size = int(parsed.get("tile_size", 16))
    m.legend = parsed.get("legend", {})
    m.ground = PackedStringArray(parsed.get("ground", []))
    m.decor = PackedStringArray(parsed.get("decor", []))
    m.solid = PackedStringArray(parsed.get("solid", []))
    m.spawns = parsed.get("spawns", {})
    m.warps = parsed.get("warps", [])
    m.signs = parsed.get("signs", [])
    m.npcs = parsed.get("npcs", [])
    m.routes = parsed.get("routes", [])
    m.presence_states = parsed.get("presence_states", [])
    m.art_props = parsed.get("art_props", [])
    m.music = str(parsed.get("music", ""))
    m.indoors = bool(parsed.get("indoors", false))
    return m


func tile_name_at(layer: PackedStringArray, x: int, y: int) -> String:
    if y < 0 or y >= layer.size():
        return ""
    var row := layer[y]
    if x < 0 or x >= row.length():
        return ""
    return str(legend.get(row[x], ""))


func is_solid(x: int, y: int) -> bool:
    if x < 0 or y < 0 or y >= solid.size() or x >= solid[y].length():
        return true
    return solid[y][x] == "1"


## World position of the centre of a tile.
func tile_centre(tile: Vector2i) -> Vector2:
    return Vector2(tile.x * tile_size + tile_size / 2.0, tile.y * tile_size + tile_size / 2.0)


## Where a character standing on this tile has their feet.
func stand_position(tile: Vector2i) -> Vector2:
    return Vector2(tile.x * tile_size + tile_size / 2.0, tile.y * tile_size + tile_size - 1)


func spawn_position(spawn_name: String) -> Vector2:
    var t: Array = spawns.get(spawn_name, [])
    if t.size() < 2:
        if spawns.is_empty():
            return Vector2(tile_size, tile_size)
        t = spawns.values()[0]
    return stand_position(Vector2i(int(t[0]), int(t[1])))


func pixel_size() -> Vector2:
    return Vector2(width * tile_size, height * tile_size)
