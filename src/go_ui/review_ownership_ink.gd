## Muted review evidence, underneath markers and stones; global board coordinates.
class_name ReviewOwnershipInk
extends RefCounted


static func draw(view: Control, game: GoGame, geometry: GoBoardGeometry,
        ownership: PackedFloat32Array, regions: Array) -> void:
    if ownership.size() == game.board.cells.size():
        for point in ownership.size():
            if game.board.cells[point] != GoBoard.EMPTY or not geometry.contains(point):
                continue
            var colour := Color("#286b78") if ownership[point] > 0 else Color("#994836")
            colour.a = absf(ownership[point]) * 0.25
            var extent := Vector2.ONE * geometry.cell * 0.75
            view.draw_rect(Rect2(geometry.position(point) - extent / 2, extent), colour)
    for region: PackedInt32Array in regions:
        for point in region:
            if not geometry.contains(point):
                continue
            var centre := geometry.position(point)
            var half := geometry.cell * 0.45
            var xy := game.board.point(point)
            var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
            for direction: Vector2i in directions:
                var next := xy + direction
                var neighbour := next.y * game.size() + next.x
                if next.x >= 0 and next.y >= 0 and next.x < game.size() and next.y < game.size() and region.has(neighbour):
                    continue
                var edge := centre + Vector2(direction) * half
                var tangent := Vector2(-direction.y, direction.x) * half
                view.draw_line(edge - tangent, edge + tangent, Color(0.57,0.25,0.15,0.65),1.0)
