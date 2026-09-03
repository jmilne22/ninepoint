## Maps tile names to atlas coordinates, from the manifest the art tool writes.
class_name TileAtlas
extends RefCounted

const MANIFEST := "res://art/tiles/tileset_manifest.json"
const TILESET := "res://art/tiles/town_tileset.tres"

static var _coords: Dictionary = {}


static func coords() -> Dictionary:
    if _coords.is_empty():
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
        if parsed is Dictionary:
            for name in parsed.get("tiles", {}).keys():
                var c: Array = parsed["tiles"][name]
                _coords[name] = Vector2i(int(c[0]), int(c[1]))
        else:
            push_error("TileAtlas: cannot read %s" % MANIFEST)
    return _coords


static func at(tile_name: String) -> Vector2i:
    return coords().get(tile_name, Vector2i(-1, -1))


static func tile_set() -> TileSet:
    return load(TILESET)
