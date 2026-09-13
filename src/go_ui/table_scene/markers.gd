## Teaching targets, liberties and counting marks follow the board's own state.
class_name TableBoardMarkers
extends Node3D
var surface: TableSceneBoardSurface
var signature := ""

func refresh() -> void:
    var b := surface.board
    var selected := b.target_point()
    var state := str([b.game.board.cells, b.dead, b.show_territory, b.territory, selected,
        b.highlight, b.mark_point, b.mark_good, b.show_liberties, b.liberty_targets,
        b.pointer.mode, b.game.last_move(), surface.layout.region])
    if signature == state: return
    signature = state
    for child in get_children(): child.queue_free()
    for point in b.game.size() * b.game.size():
        if b.dead.has(point): mark(point, Color("c95848"), 0.029, true)
        elif b.show_territory and point < b.territory.size() and b.game.board.cells[point] == 0 and b.territory[point] != 0:
            mark(point, Color("333f43") if b.territory[point] == 1 else Color("fff5d7"), 0.013)
    for point in b.highlight: mark(point, Color("367f72"), 0.035)
    if b.mark_point >= 0: mark(b.mark_point, Color("c9962b") if b.mark_good else Color("367f72"), 0.014)
    var targets := b.liberty_targets.duplicate()
    if targets.is_empty() and b.show_liberties and selected >= 0 and (b.interactive or b.inspection):
        targets.append(selected)
    var seen := {}
    for target in targets:
        var liberties: PackedInt32Array = b.game.board.chain_at(target)["liberties"] if b.game.board.cells[target] != 0 else b.game.board.neighbours(target)
        for point in liberties:
            if b.game.board.cells[point] == 0 and not seen.has(point):
                seen[point] = true
                mark(point, Color("367f72"), 0.015)
    if selected >= 0 and b.pointer.mode != BoardPointer.Mode.HIDDEN:
        if b.pointer.mode == BoardPointer.Mode.COUNT and b.game.board.cells[selected] != 0:
            for point in b.game.board.chain_at(selected)["stones"]: mark(point, Color("367f72"), 0.038)
        mark(selected, Color("b5673c"), 0.012)
    var move := b.game.last_move()
    var last := int(move.get("point", -1))
    if last >= 0 and b.game.board.cells[last] != 0:
        mark(last, Color("fff5d7") if b.game.board.cells[last] == 1 else Color("333f43"), 0.008)

func mark(point: int, colour: Color, radius: float, cross: bool = false) -> void:
    if not surface.layout.contains(point): return
    var scale_factor := surface.layout.stone_scale
    var height := 0.126 + (0.04 * scale_factor if surface.board.game.board.cells[point] != 0 else 0.0)
    if cross:
        for angle in [-PI / 4, PI / 4]:
            var stroke := MeshInstance3D.new()
            var box := BoxMesh.new()
            box.size = Vector3(radius * 2 * scale_factor, 0.002, 0.005 * scale_factor)
            stroke.mesh = box
            stroke.rotation.y = angle
            stroke.position = surface.world_point(point, height)
            stroke.material_override = TableSceneStage.material(colour)
            add_child(stroke)
        return
    var marker := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = radius * 0.65 * scale_factor
    mesh.outer_radius = radius * scale_factor
    mesh.rings = 16
    mesh.ring_segments = 8
    marker.mesh = mesh
    marker.material_override = TableSceneStage.material(colour)
    marker.position = surface.world_point(point, height)
    add_child(marker)
