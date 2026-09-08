## Furniture can span tiles; its map data supplies the matching collision cells.
##
## Two kinds, decided by whether the generator gave the entry a `base`:
##
## * A piece of furniture standing on the floor has one -- the pixel row where
##   it meets the ground -- and belongs in `Entities` with the people, sorted
##   against them. Without that, every prop was added before `Entities` existed
##   and with no z_index at all, so the player and the whole cast drew in front
##   of the bed, the washing machines and the table they were sitting at.
## * A thing fixed to a wall or a roof (the attic's rafters, a shop window, a
##   hanging sign) has none, and stays behind everybody, which is where it was.
class_name VenueProps
extends RefCounted


static func build_background(entries: Array, parent: Node2D) -> void:
    for entry in entries:
        if entry.has("base"):
            continue
        _add(entry, parent)


static func build_sorted(entries: Array, parent: Node2D) -> void:
    for entry in entries:
        if not entry.has("base"):
            continue
        var sprite := _add(entry, parent)
        if sprite == null:
            continue
        # Godot 4 y-sorts children by their own position, and Node2D has no
        # y_sort_origin to move that key with (TileMapLayer does; a Sprite2D
        # does not -- assigning it is a runtime error, not a compile one).
        # So the node stands on the floor row where its legs are, and the
        # texture is drawn back up to where the art belongs.
        var base := float(entry["base"])
        var top := sprite.position.y
        sprite.position.y = base
        sprite.offset = Vector2(0.0, top - base)


static func _add(entry: Dictionary, parent: Node2D) -> Sprite2D:
    var path := "res://art/props/%s.png" % str(entry.get("art", ""))
    if not ResourceLoader.exists(path):
        push_error("Missing venue prop: " + path)
        return null
    var sprite := Sprite2D.new()
    sprite.texture = load(path)
    sprite.centered = false
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var at: Array = entry.get("position", [0, 0])
    sprite.position = Vector2(float(at[0]), float(at[1]))
    parent.add_child(sprite)
    return sprite
