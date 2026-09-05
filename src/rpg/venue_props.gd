## Furniture can span tiles; its map data supplies the matching collision cells.
class_name VenueProps
extends RefCounted

static func build(entries: Array, parent: Node2D) -> void:
    for entry in entries:
        var path := "res://art/props/%s.png" % str(entry.get("art", ""))
        if not ResourceLoader.exists(path):
            push_error("Missing venue prop: " + path)
            continue
        var sprite := Sprite2D.new()
        sprite.texture = load(path)
        sprite.centered = false
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        var at: Array = entry.get("position", [0, 0])
        sprite.position = Vector2(float(at[0]), float(at[1]))
        parent.add_child(sprite)
