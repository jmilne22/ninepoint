## What a map sounds like.
##
## It reads the map's own tiles
## and decides from them. A map that gains a stove gains the sound of one, with
## no data to keep in step -- which is why eight of the nine maps needed no
## edit at all to get their ambience.
##
class_name Soundscape
extends Node2D

## Tiles that make a noise, and what noise they make.
##
##   every/jitter  seconds between one-shots, and how much that varies. A fixed
##                 interval is a metronome and the ear finds it immediately.
##   people        how many NPCs the map needs before this is allowed. Stone
##                 clicks come from a game somebody is playing -- the board in
##                 your own attic must stay silent, and it has no NPCs.
##   max           cap on emitters of this kind. The quay has 156 canal tiles;
##                 156 gulls is a seabird attack, not a port.
const SOUND_SOURCES := {
    "stove": {
        "sound": "stove_crackle", "every": 7.0, "jitter": 3.0, "db": -6.0, "max": 1,
    },
    "snack_window": {
        "sound": "fryer", "every": 6.0, "jitter": 2.5, "db": -9.0, "max": 1,
    },
    "go_table": {
        "sound": "stone_place", "every": 4.5, "jitter": 3.5, "db": -13.0,
        "people": 2, "max": 3,
    },
    "stone_table": {
        "sound": "stone_place", "every": 6.0, "jitter": 4.0, "db": -15.0,
        "people": 1, "max": 2,
    },
    # Thinned hard on purpose. The wassalon has five machines in a row and
    # five emitters at five seconds each is a laundrette that sounds like an
    # engine room -- the same mistake the quay's 156 gulls would have been.
    "washer": {
        "sound": "washer", "every": 5.0, "jitter": 2.0, "db": -14.0, "max": 2,
    },
    "quay_edge": {
        "sound": "amb_gull", "every": 24.0, "jitter": 16.0, "db": -8.0,
        "max": 2, "reach": 420.0,
    },
    "canal": {
        "sound": "pigeons", "every": 30.0, "jitter": 20.0, "db": -12.0,
        "max": 2, "reach": 380.0,
    },
}

## The looping bed, chosen from the map rather than declared on it.
const BED_CANAL_TILES := ["canal", "quay_edge", "water", "water_edge"]

var _map: MapData
var _emitters: Array[Dictionary] = []


func setup(map: MapData) -> void:
    _map = map
    _scan()
    apply()


func apply() -> void:
    var bed := _choose_bed()
    if bed == "":
        Audio.stop_ambience()
    else:
        Audio.play_ambience(bed)


## Leaving the map takes the bed with it. Otherwise the rain from Ketelsteeg
## carries on underneath a Go match and the title screen.
func _exit_tree() -> void:
    Audio.stop_ambience()


func _choose_bed() -> String:
    if _map == null:
        return ""
    # A room tone exists to fill silence, so it only plays where there is
    # silence to fill -- the attic and the dormitory. Running it underneath a
    # track as well put a hiss under every scored interior in the game, which
    # is audible as water rather than as a room.
    if _map.indoors:
        return "amb_room" if _map.music == "" else ""
    for tile_name in BED_CANAL_TILES:
        if not _cells_named(tile_name).is_empty():
            return "amb_canal"
    return ""


# --- emitters ----------------------------------------------------------------

func _scan() -> void:
    for tile_name in SOUND_SOURCES:
        var spec: Dictionary = SOUND_SOURCES[tile_name]
        if _map.npcs.size() < int(spec.get("people", 0)):
            continue
        var cells := _cells_named(tile_name)
        if cells.is_empty():
            continue
        for cell in _thin(cells, int(spec.get("max", 2))):
            _add_emitter(cell, spec)


func _add_emitter(cell: Vector2i, spec: Dictionary) -> void:
    var node := Node2D.new()
    node.name = "Emit_%s_%d_%d" % [str(spec["sound"]), cell.x, cell.y]
    node.position = _map.tile_centre(cell)
    add_child(node)
    var every := float(spec.get("every", 8.0))
    _emitters.append({
        "node": node,
        "sound": str(spec.get("sound", "")),
        "every": every,
        "jitter": float(spec.get("jitter", 0.0)),
        "db": float(spec.get("db", 0.0)),
        "reach": float(spec.get("reach", Audio.AMBIENCE_REACH)),
        # Stagger the first shot, or every emitter on the map fires together on
        # the frame the map loads.
        "t": randf_range(0.5, every),
    })


func _process(delta: float) -> void:
    for e in _emitters:
        e["t"] -= delta
        if e["t"] > 0.0:
            continue
        e["t"] = float(e["every"]) + randf_range(0.0, float(e["jitter"]))
        Audio.play_at(str(e["sound"]), e["node"], 0.07, float(e["db"]), float(e["reach"]))


# --- the map -----------------------------------------------------------------

func _cells_named(tile_name: String) -> Array[Vector2i]:
    var out: Array[Vector2i] = []
    if _map == null:
        return out
    for y in _map.height:
        for x in _map.width:
            if _map.tile_name_at(_map.ground, x, y) == tile_name:
                out.append(Vector2i(x, y))
    return out


## Keep at most `n`, spread across the whole list rather than taken off the
## front -- otherwise every canal emitter ends up in the map's top-left corner
## and the rest of the water is silent.
static func _thin(cells: Array[Vector2i], n: int) -> Array[Vector2i]:
    if n <= 0 or cells.size() <= n:
        return cells
    var out: Array[Vector2i] = []
    var stride := float(cells.size()) / float(n)
    for i in n:
        out.append(cells[int(i * stride)])
    return out
