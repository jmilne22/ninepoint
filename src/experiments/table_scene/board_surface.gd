class_name TableSceneBoardSurface
extends Control

var viewport: SubViewport
var input_viewport: SubViewport
var camera: Camera3D
var board: GoBoardView
var stones: Dictionary = {}
var markers: Node3D
var last_state := ""
var mouse_inside := false

func setup(value: GoBoardView) -> void:
    board = value
    size = Vector2(768, 300)
    mouse_filter = Control.MOUSE_FILTER_STOP
    viewport = TableSceneStage.viewport(self, Vector2i(size), false)
    (get_child(1) as TextureRect).hide()
    var table: Node3D = load("res://art/table_scene/table.glb").instantiate()
    viewport.add_child(table)
    _wood(table)
    camera = Camera3D.new()
    viewport.add_child(camera)
    camera.position = Vector3(0, 1.80, 1.48)
    camera.fov = 28
    camera.look_at(Vector3(0, 0, 0))
    input_viewport = SubViewport.new()
    input_viewport.size = Vector2i(384,384)
    input_viewport.disable_3d = true
    input_viewport.handle_input_locally = true
    add_child(input_viewport)
    board.reparent(input_viewport)
    board.position = Vector2.ZERO
    board.size = Vector2(384,384)
    for index in 9:
        var offset := (index - 4) * 0.105
        _bar(Vector3(offset, 0.122, 0), Vector3(0.0023, 0.001, 0.842))
        _bar(Vector3(0, 0.122, offset), Vector3(0.842, 0.001, 0.0023))
    for point in [20,24,40,56,60]:
        var dot := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.004
        mesh.bottom_radius = 0.004
        mesh.height = 0.001
        dot.mesh = mesh
        dot.material_override = TableSceneStage.material(Color("57432b"))
        dot.position = world_point(point, 0.123)
        viewport.add_child(dot)
    markers = Node3D.new()
    viewport.add_child(markers)
    mouse_exited.connect(_leave)
    queue_redraw()

func _bar(at: Vector3, extent: Vector3) -> void:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = extent
    node.mesh = mesh
    node.material_override = TableSceneStage.material(Color("57432b"))
    node.position = at
    viewport.add_child(node)

func world_point(point: int, height: float = 0.143) -> Vector3:
    return Vector3((point % 9 - 4) * 0.105, height, (point / 9 - 4) * 0.105)

func screen_point(point: int) -> Vector2:
    return position + camera.unproject_position(world_point(point, 0.122))

func point_at(local: Vector2) -> int:
    var hit: Variant = Plane(Vector3.UP, 0.122).intersects_ray(camera.project_ray_origin(local), camera.project_ray_normal(local))
    if hit == null: return -1
    var p: Vector3 = hit
    if absf(p.x) > 0.4725 or absf(p.z) > 0.4725: return -1
    var col := roundi(p.x / 0.105) + 4
    var row := roundi(p.z / 0.105) + 4
    return row * 9 + col if col >= 0 and col < 9 and row >= 0 and row < 9 else -1

func _gui_input(event: InputEvent) -> void:
    if not event is InputEventMouse: return
    var point := point_at(event.position)
    if point < 0:
        _leave()
        return
    var mapped := event.duplicate() as InputEventMouse
    mapped.position = board.point_position(point)
    mapped.global_position = mapped.position
    if not mouse_inside:
        input_viewport.notify_mouse_entered()
        mouse_inside = true
    input_viewport.push_input(mapped, true)
    accept_event()

func _leave() -> void:
    if mouse_inside:
        input_viewport.notify_mouse_exited()
        mouse_inside = false
    board._clear_pointer()

func _process(_delta: float) -> void:
    if board == null or board.game == null: return
    for point in 81:
        var colour: int = board.game.board.cells[point]
        if colour == 0 and stones.has(point):
            var old: Node3D = stones[point]
            stones.erase(point)
            var tw := create_tween()
            tw.tween_property(old, "position:y", 0.29, 0.25)
            tw.parallel().tween_property(old, "scale", Vector3.ZERO, 0.25)
            tw.tween_callback(old.queue_free)
        elif colour != 0 and not stones.has(point):
            var stone: Node3D = load("res://art/table_scene/%s_stone.glb" % ("black" if colour == 1 else "white")).instantiate()
            viewport.add_child(stone)
            _stone_material(stone, colour)
            stone.position = world_point(point, 0.24)
            stones[point] = stone
            create_tween().tween_property(stone, "position:y", 0.143, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    var selected := board.target_point()
    var state := str(selected) + str(board.dead) + str(board.show_territory) + str(board.territory)
    if state != last_state:
        last_state = state
        for child in markers.get_children(): child.queue_free()
        for point in 81:
            if board.dead.has(point): _marker(point, Color("c95848"), 0.027)
            elif board.show_territory and point < board.territory.size() and board.game.board.cells[point] == 0 and board.territory[point] != 0:
                _marker(point, Color("333f43") if board.territory[point] == 1 else Color("fff5d7"), 0.013)
        if selected >= 0: _marker(selected, Color("b5673c"), 0.012)

func _marker(point: int, colour: Color, radius: float) -> void:
    var marker := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = radius * 0.7
    mesh.outer_radius = radius
    mesh.rings = 16
    mesh.ring_segments = 8
    marker.mesh = mesh
    marker.material_override = TableSceneStage.material(colour)
    marker.position = world_point(point, 0.166 if stones.has(point) else 0.126)
    markers.add_child(marker)

func _wood(node: Node) -> void:
    if node is MeshInstance3D:
        for index in node.mesh.get_surface_count():
            var old: Material = node.get_active_material(index)
            if old and (old.resource_name == "Kaya" or old.resource_name == "Table walnut" or old.resource_name == "Board end grain"):
                var mat := ShaderMaterial.new()
                mat.shader = preload("res://src/experiments/table_scene/wood.gdshader")
                mat.set_shader_parameter("grain", load("res://art/table_scene/kaya.png"))
                mat.set_shader_parameter("tint", Color.WHITE if old.resource_name == "Kaya" else Color("927247"))
                node.set_surface_override_material(index, mat)
    for child in node.get_children(): _wood(child)

func _draw() -> void:
    if camera == null: return
    draw_texture_rect(viewport.get_texture(), Rect2(Vector2.ZERO, size), false)
    var font := preload("res://art/ui/ninepoint_font.fnt")
    for index in 9:
        var x := (index - 4) * 0.105
        var top := camera.unproject_position(Vector3(x, 0.123, -0.493))
        draw_string(font, top + Vector2(-3,3), "ABCDEFGHJ"[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("6d512e"))
        var left := camera.unproject_position(Vector3(-0.485, 0.123, x))
        draw_string(font, left + Vector2(-3,3), str(9-index), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("6d512e"))

func _stone_material(node: Node, colour: int) -> void:
    if node is MeshInstance3D:
        var mat := TableSceneStage.material(Color("192025") if colour == 1 else Color("f2f0e8"))
        mat.roughness = 0.24
        mat.metallic_specular = 0.7
        node.material_override = mat
    for child in node.get_children(): _stone_material(child, colour)
