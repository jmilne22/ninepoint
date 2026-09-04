## Tiles that move.
##
## Godot's TileSet can animate a tile natively, but it wants the frames in
## consecutive atlas cells, and gen_tiles.py packs strictly i % 16 with no way
## to control adjacency -- so the native route means rewriting the packer and
## editing the generated .tres, which build_assets.py carries a warning about
## (a tile outside that resource draws as nothing, in silence; that is how the
## city's windows came out black). Cycling cells by tile *name* instead costs a
## handful of set_cell calls a second and touches neither.
##
class_name TileAnimator
extends Node2D

## Ground tile name -> the frames it cycles through and how long each holds.
##
## Holds are per-frame, not a frame rate, because the interesting ones are not
## even: a failing neon tube sits lit for four seconds and dark for a fifth of
## one, and an even blink reads as a decoration rather than as a fault.
##
##   phase     "wave" staggers cells along the diagonal, so water travels;
##             anything else gets a random offset so two tables do not tick
##             together.
##   people    NPCs the map needs first -- the board in your own attic is not a
##             game in progress. Soundscape gates the stone clicks the same way.
const ANIMATIONS := {
    "water": {
        "frames": ["water", "water_f1", "water_f2"],
        "hold": [0.42, 0.42, 0.42], "phase": "wave",
    },
    "canal": {
        "frames": ["canal", "canal_f1", "canal_f2"],
        "hold": [0.50, 0.50, 0.50], "phase": "wave",
    },
    "neon_sign": {
        "frames": ["neon_sign", "neon_sign_f1"],
        "hold": [4.50, 0.16], "sync": true,
    },
    "stove": {
        "frames": ["stove", "stove_f1"],
        "hold": [0.70, 0.55],
    },
    "go_table": {
        "frames": ["go_table", "go_table_f1", "go_table_f2"],
        "hold": [22.0, 22.0, 22.0], "people": 2,
    },
    # The machines in the wassalon.
    "washer": {
        "frames": ["washer", "washer_f1"],
        "hold": [1.60, 1.60],
    },
    "kifu_board": {
        "frames": ["kifu_board", "kifu_board_f1", "kifu_board_f2"],
        "hold": [14.0, 14.0, 14.0],
    },
}

var _layer: TileMapLayer
var _map: MapData
var _anims: Array[Dictionary] = []


func setup(map: MapData, ground: TileMapLayer) -> void:
    _map = map
    _layer = ground
    if _layer == null:
        return
    for tile_name in ANIMATIONS:
        _collect(tile_name, ANIMATIONS[tile_name])


func _collect(tile_name: String, spec: Dictionary) -> void:
    if _map.npcs.size() < int(spec.get("people", 0)):
        return
    var frames: Array = spec.get("frames", [])
    var coords: Array[Vector2i] = []
    for f in frames:
        var c := TileAtlas.at(str(f))
        if c.x < 0:
            # A frame missing from the atlas would draw as a hole and say
            # nothing about it. Refuse the whole animation instead.
            push_error("TileAnimator: no atlas tile '%s' for '%s'" % [str(f), tile_name])
            return
        coords.append(c)
    if coords.size() < 2:
        return

    var cells: Array[Vector2i] = []
    for y in _map.height:
        for x in _map.width:
            if _map.tile_name_at(_map.ground, x, y) == tile_name:
                cells.append(Vector2i(x, y))
    if cells.is_empty():
        return

    var hold := PackedFloat32Array()
    var total := 0.0
    for h in spec.get("hold", []):
        hold.append(float(h))
        total += float(h)
    if total <= 0.0:
        return

    var wave := str(spec.get("phase", "")) == "wave"
    var phase := PackedFloat32Array()
    var last := PackedInt32Array()
    for cell in cells:
        if wave:
            phase.append(float((cell.x + cell.y) % coords.size()) * (total / coords.size()))
        elif bool(spec.get("sync", false)):
            # Every neon cell shares one clock, so the tubes blink together. Both start
            # at t = 0 when the map loads, so a zero phase keeps the tube and the
            # light it throws going out together.
            phase.append(0.0)
        else:
            phase.append(randf() * total)
        last.append(-1)

    _anims.append({
        "cells": cells, "coords": coords, "hold": hold, "total": total,
        "phase": phase, "last": last, "t": 0.0,
    })


func _process(delta: float) -> void:
    for a in _anims:
        a["t"] = fmod(float(a["t"]) + delta, float(a["total"]))
        var cells: Array = a["cells"]
        var coords: Array = a["coords"]
        var phase: PackedFloat32Array = a["phase"]
        var last: PackedInt32Array = a["last"]
        var total: float = a["total"]
        for i in cells.size():
            var f := _frame_at(a, fmod(float(a["t"]) + phase[i], total))
            if f != last[i]:
                last[i] = f
                _layer.set_cell(cells[i], 0, coords[f])
        a["last"] = last


static func _frame_at(a: Dictionary, at: float) -> int:
    var hold: PackedFloat32Array = a["hold"]
    var acc := 0.0
    for i in hold.size():
        acc += hold[i]
        if at < acc:
            return i
    return hold.size() - 1
