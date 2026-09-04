## Turns MapData into live nodes: two tile layers, merged collision, warps and
## signs. Deliberately static and dumb -- the World owns everything after this.
class_name MapBuilder
extends RefCounted

const NPC_SCENE := preload("res://src/rpg/npc/npc.tscn")


## Returns the Ground layer: TileAnimator cycles cells in it, and it is the
## only one anything else needs a handle on.
static func build_layers(map: MapData, parent: Node2D) -> TileMapLayer:
    var ts := TileAtlas.tile_set()
    var ground: TileMapLayer = null
    for spec in [["Ground", map.ground, 0], ["Decor", map.decor, 1]]:
        var layer := TileMapLayer.new()
        layer.name = str(spec[0])
        layer.tile_set = ts
        layer.z_index = int(spec[2]) - 2
        parent.add_child(layer)
        if spec[0] == "Ground":
            ground = layer
        var rows: PackedStringArray = spec[1]
        for y in rows.size():
            for x in rows[y].length():
                var tile_name := map.tile_name_at(rows, x, y)
                if tile_name == "":
                    continue
                var coords := TileAtlas.at(tile_name)
                if coords.x >= 0:
                    layer.set_cell(Vector2i(x, y), 0, coords)
    return ground


## One static body whose shapes are merged horizontal runs of solid tiles.
static func build_collision(map: MapData, parent: Node2D) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.name = "Solids"
    body.collision_layer = 1
    body.collision_mask = 0
    parent.add_child(body)
    var t := map.tile_size
    for y in map.height:
        var x := 0
        while x < map.width:
            if not map.is_solid(x, y):
                x += 1
                continue
            var run := 0
            while x + run < map.width and map.is_solid(x + run, y):
                run += 1
            var shape := CollisionShape2D.new()
            var rect := RectangleShape2D.new()
            rect.size = Vector2(run * t, t)
            shape.shape = rect
            shape.position = Vector2((x + run / 2.0) * t, (y + 0.5) * t)
            body.add_child(shape)
            x += run
    return body


static func build_warps(map: MapData, parent: Node2D) -> void:
    for w in map.warps:
        var tile: Array = w.get("tile", [0, 0])
        var warp := Warp.new()
        warp.name = "Warp_%s_%d_%d" % [str(w.get("map", "")), int(tile[0]), int(tile[1])]
        warp.target_map = str(w.get("map", ""))
        warp.target_spawn = str(w.get("spawn", ""))
        warp.prompt = str(w.get("prompt", ""))
        warp.required_flag = str(w.get("required_flag", ""))
        warp.blocked_text = str(w.get("blocked_text", ""))
        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = Vector2(map.tile_size, map.tile_size)
        shape.shape = rect
        warp.add_child(shape)
        warp.position = map.tile_centre(Vector2i(int(tile[0]), int(tile[1])))
        parent.add_child(warp)


## Signs are Interactables sitting on a solid tile: you face them and read them.
static func build_signs(map: MapData, parent: Node2D, on_read: Callable) -> void:
    for s in map.signs:
        var tile: Array = s.get("tile", [0, 0])
        var area := Interactable.new()
        area.name = "Sign_%d_%d" % [int(tile[0]), int(tile[1])]
        area.prompt = str(s.get("prompt", "Read"))
        area.interact_priority = Interactable.PRIORITY_SIGN
        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = Vector2(map.tile_size, map.tile_size)
        shape.shape = rect
        area.add_child(shape)
        area.position = map.tile_centre(Vector2i(int(tile[0]), int(tile[1])))
        parent.add_child(area)
        var text := str(s.get("text", ""))
        area.interacted.connect(func(_by): on_read.call(text))


# --- scenery -----------------------------------------------------------------
#
# The atmosphere systems all take the same shape: make it, add it, hand it the
# map, and let it read the tiles for whatever it needs. None of them are told
# anything a map does not already say.

## Behind the tiles. Without it an alley, an unlit interior or the frame around
## a small room is the window's clear colour, which reads as a missing tile
## rather than as shadow.
static func build_backdrop(map: MapData, parent: Node2D) -> void:
    var bg := ColorRect.new()
    bg.name = "Backdrop"
    bg.color = Color("#14121a")
    bg.position = Vector2(-192, -108)
    bg.size = map.pixel_size() + Vector2(384, 216)
    bg.z_index = -10
    parent.add_child(bg)


static func build_ambient(map: MapData, parent: Node2D) -> Ambient:
    var it := Ambient.new()
    it.name = "Ambient"
    parent.add_child(it)
    it.setup(map)
    return it


static func build_animator(map: MapData, parent: Node2D, ground: TileMapLayer) -> TileAnimator:
    var it := TileAnimator.new()
    it.name = "TileAnimator"
    parent.add_child(it)
    it.setup(map, ground)
    return it


static func build_soundscape(map: MapData, parent: Node2D) -> Soundscape:
    var it := Soundscape.new()
    it.name = "Soundscape"
    parent.add_child(it)
    it.setup(map)
    return it


## Goes under Entities rather than the World, so passers-by y-sort against the
## player like anybody else on the pavement.
static func build_crowd(map: MapData, parent: Node2D) -> CrowdSpawner:
    var it := CrowdSpawner.new()
    it.name = "Crowd"
    parent.add_child(it)
    it.setup(map)
    return it


## Who is standing here *at this hour, on this day*. An entry with no "blocks"
## and no "days" is somebody who is always here, which is the same reading
## TileAnimator and Soundscape give the key -- absent or empty means always, so
## every map that predates schedules keeps working untouched.
##
## The two keys are independent and both must pass: "blocks" is matched against
## GameState.time_block and "days" against GameState.weekday(), so club night is
## ["wednesday"] plus the evening hours rather than a third kind of rule.
##
## This is the whole of the schedule system on the engine side. Where somebody
## is at a given hour is content, and it lives in tools/gen_maps.py.
static func build_npcs(map: MapData, parent: Node2D, on_talk: Callable) -> Array[Npc]:
    var out: Array[Npc] = []
    for spec in map.npcs:
        if not MapData.is_present(spec, GameState.time_block,
                GameState.weekday(), GameState.weather()):
            continue
        var npc: Npc = NPC_SCENE.instantiate()
        var tile: Array = spec.get("tile", [0, 0])
        npc.npc_id = str(spec.get("id", ""))
        npc.name = "Npc_" + npc.npc_id
        npc.position = map.stand_position(Vector2i(int(tile[0]), int(tile[1])))
        parent.add_child(npc)
        npc.facing = Facing.from_name(str(spec.get("dir", "down")))
        npc.home_facing = npc.facing
        npc.sprite.face(npc.facing)
        # "idle" is the current way to say what somebody does; "wander": true
        # is what the maps said before there was more than one answer, and
        # still means the same thing.
        var idle := str(spec.get("idle", ""))
        if idle == "" and bool(spec.get("wander", false)):
            idle = "wander"
        npc.idle = NpcIdle.make(idle)
        npc.talk_requested.connect(on_talk)
        out.append(npc)
    return out
