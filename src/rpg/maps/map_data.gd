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
## Track name for this map, matched against audio/<name>.wav. "" is silence.
var music: String = ""
## What plays here after dark. "" keeps `music` at every hour.
var music_night: String = ""
## Indoors takes the hour much more gently and never gets rained on: inside a
## room the lights are simply on. Ambient reads this.
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
    m.music = str(parsed.get("music", ""))
    m.music_night = str(parsed.get("music_night", ""))
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


## Is this NPC entry standing here at this hour, on this day?
##
## The whole of the schedule rule, and it lives here rather than in MapBuilder
## because MapBuilder reads autoloads and therefore does not compile in a
## `--script` run -- which is how the entire suite runs, so anything put on it is
## unreachable from every test in the project, silently. ROADMAP.md section 8
## keeps a list of the times that has cost a milestone; this is the boundary
## LeagueTable/LeagueBoard and HooksLadder/HooksBoard already draw.
##
## "blocks" is matched against the hour and "days" against the weekday. Absent or
## empty means always, for both, which is the same reading TileAnimator and
## Soundscape give the key -- so every map entry written before either axis
## existed keeps working untouched. Both must pass: club night is the evening
## hours *and* Wednesday, not a third kind of rule.
static func is_present(spec: Dictionary, block: String, weekday: String) -> bool:
    var blocks: Array = spec.get("blocks", [])
    if not blocks.is_empty() and not blocks.has(block):
        return false
    var days: Array = spec.get("days", [])
    if not days.is_empty() and not days.has(weekday):
        return false
    return true
