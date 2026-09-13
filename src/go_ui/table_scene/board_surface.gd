class_name TableSceneBoardSurface
extends Control

var contacts: TableStoneAudio
var viewport: SubViewport
var input_viewport: SubViewport
var camera: Camera3D
var board: GoBoardView
var stones: Dictionary = {}
var markers: TableBoardMarkers
var layout := TableBoardLayout.new()
var grid: Node3D
var drawn_region := Rect2i()
var drawn_size := 0
var mouse_inside := false
var black_bowl: Array[MeshInstance3D] = []
var white_bowl: Array[MeshInstance3D] = []

func setup(value: GoBoardView) -> void:
    board = value
    size = Vector2(768, 300)
    mouse_filter = Control.MOUSE_FILTER_STOP
    viewport = TableSceneStage.viewport(self, Vector2i(size), false)
    (get_child(1) as TextureRect).hide()
    if AudioPreview.requested():
        contacts = TableStoneAudio.new()
        add_child(contacts)
        var audio := get_tree().root.get_node("Audio")
        contacts.stone_landed.connect(audio.play_stone)
        contacts.capture_landed.connect(audio.play_capture)
    var table: Node3D = load(KettleNextProfile.table_path()).instantiate()
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
    grid = Node3D.new()
    viewport.add_child(grid)
    markers = TableBoardMarkers.new()
    markers.surface = self
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
    grid.add_child(node)

func world_point(point: int, height: float = 0.143) -> Vector3:
    return layout.world_point(point, height)

func screen_point(point: int) -> Vector2:
    return position + project(world_point(point, 0.122))

func project(at: Vector3) -> Vector2:
    return TableSceneStage.to_logical(viewport, size, camera.unproject_position(at))

func point_at(local: Vector2) -> int:
    local = TableSceneStage.to_pixels(viewport, size, local)
    var hit: Variant = Plane(Vector3.UP, 0.122).intersects_ray(camera.project_ray_origin(local), camera.project_ray_normal(local))
    if hit == null: return -1
    return layout.point_at(hit)

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
    board._layout()
    layout.configure(board.game.size(), board.geometry.region)
    if drawn_region != layout.region or drawn_size != layout.board_size:
        _rebuild_grid()
    if contacts != null:
        for point: int in contacts.pending.keys():
            if not layout.contains(point): contacts.wait_offscreen(point)
    for point in board.game.size() * board.game.size():
        var colour: int = board.game.board.cells[point]
        if stones.has(point):
            var old: Node3D = stones[point]
            if colour == 0 or not layout.contains(point) or int(old.get_meta("colour")) != colour:
                stones.erase(point)
                if board._ghosts.has(point):
                    var lift := create_tween()
                    lift.tween_property(old, "position:y", old.position.y + 0.14, 0.25)
                    lift.parallel().tween_property(old, "scale", Vector3.ZERO, 0.25)
                    lift.tween_callback(old.queue_free)
                else:
                    old.queue_free()
            elif contacts != null and contacts.pending.has(point) and not old.has_meta("audio_landing"):
                # Teaching can await feedback after updating the board, before
                # announcing a committed move. Its stone may already exist.
                _drop(old, point)
        if colour != 0 and layout.contains(point) and not stones.has(point):
            var stone: Node3D = load("res://art/table_scene/%s_stone.glb" % ("black" if colour == 1 else "white")).instantiate()
            viewport.add_child(stone)
            stone.set_meta("colour", colour)
            _stone_material(stone, colour)
            stone.scale = Vector3.ONE * layout.stone_scale
            stone.position = world_point(point, 0.122 + 0.02 * layout.stone_scale)
            stones[point] = stone
            if (contacts != null and contacts.pending.has(point)) or (contacts == null and board._placing.has(point)):
                _drop(stone, point)
    markers.refresh()

func _drop(stone: Node3D, point: int) -> void:
    if contacts != null: contacts.cancel_offscreen(point)
    stone.set_meta("audio_landing", true)
    var target_y := 0.122 + 0.02 * layout.stone_scale
    stone.position.y = target_y + 0.10
    # Rebuilding/zooming frees this stone and its tween. The intent remains
    # pending for the replacement visual instead of firing a stale callback.
    var landing := stone.create_tween()
    landing.tween_property(stone, "position:y", target_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    if contacts != null: landing.tween_callback(contacts.land.bind(point))
    landing.tween_callback(func() -> void: stone.remove_meta("audio_landing"))

func _rebuild_grid() -> void:
    drawn_region = layout.region
    drawn_size = layout.board_size
    for stone: Node3D in stones.values(): stone.queue_free()
    stones.clear()
    for child in grid.get_children(): child.queue_free()
    for index in layout.region.size.x:
        var offset := float(index) * layout.spacing - 0.42
        _bar(Vector3(offset, 0.122, 0), Vector3(0.0023, 0.001, 0.842))
        _bar(Vector3(0, 0.122, offset), Vector3(0.842, 0.001, 0.0023))
        # Short continuations distinguish a cropped nineteen-line region from 9x9.
        if layout.region.position.y > 0: _bar(Vector3(offset, 0.122, -0.435), Vector3(0.0023, 0.001, 0.03))
        if layout.region.end.y < layout.board_size: _bar(Vector3(offset, 0.122, 0.435), Vector3(0.0023, 0.001, 0.03))
        if layout.region.position.x > 0: _bar(Vector3(-0.435, 0.122, offset), Vector3(0.03, 0.001, 0.0023))
        if layout.region.end.x < layout.board_size: _bar(Vector3(0.435, 0.122, offset), Vector3(0.03, 0.001, 0.0023))
    for point in GoBoardView.star_points(layout.board_size):
        if not layout.contains(point): continue
        var dot := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.004 * layout.stone_scale
        mesh.bottom_radius = mesh.top_radius
        mesh.height = 0.001
        dot.mesh = mesh
        dot.material_override = TableSceneStage.material(Color("57432b"))
        dot.position = world_point(point, 0.123)
        grid.add_child(dot)
    queue_redraw()

func set_colours(player_colour: int) -> void:
    for stone in black_bowl: _stone_material(stone, player_colour)
    for stone in white_bowl: _stone_material(stone, GoBoard.opponent(player_colour))

func _wood(node: Node) -> void:
    if node is MeshInstance3D:
        for index in node.mesh.get_surface_count():
            var old: Material = node.get_active_material(index)
            if old and old.resource_name == "Black slate":
                black_bowl.append(node)
                if KettleNextProfile.campaign(): _stone_material(node,GoBoard.BLACK)
            if old and old.resource_name == "White shell":
                white_bowl.append(node)
                if KettleNextProfile.campaign(): _stone_material(node,GoBoard.WHITE)
            if old and (old.resource_name == "Kaya" or old.resource_name == "Table walnut" or old.resource_name == "Board end grain"):
                var mat := ShaderMaterial.new()
                mat.shader = preload("res://src/rpg/kettle_next/board_wood.gdshader") if KettleNextProfile.enabled() else preload("res://src/go_ui/table_scene/wood.gdshader")
                mat.set_shader_parameter("quiet", KettleNextProfile.campaign())
                mat.set_shader_parameter("grain", load("res://art/table_scene/kaya.png"))
                mat.set_shader_parameter("tint", Color.WHITE if old.resource_name == "Kaya" else Color("927247"))
                node.set_surface_override_material(index, mat)
    for child in node.get_children(): _wood(child)

func _draw() -> void:
    if camera == null: return
    draw_texture_rect(viewport.get_texture(), Rect2(Vector2.ZERO, size), false)
    var font := preload("res://art/fonts/DejaVuSans.ttf")
    for index in layout.region.size.x:
        var x := float(index) * layout.spacing - 0.42
        var top := project(Vector3(x, 0.123, -0.493))
        draw_string(font, top + Vector2(-3,3), "ABCDEFGHJKLMNOPQRST"[index + layout.region.position.x], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("6d512e"))
        var left := project(Vector3(-0.485, 0.123, x))
        draw_string(font, left + Vector2(-3,3), str(layout.board_size - index - layout.region.position.y), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("6d512e"))

func _stone_material(node: Node, colour: int) -> void:
    if node is MeshInstance3D:
        var mat := TableSceneStage.material(Color("192025") if colour == 1 else Color("f2f0e8"))
        mat.roughness = 0.24
        mat.metallic_specular = 0.7
        if KettleNextProfile.enabled():
            mat.roughness = .30 if colour == 1 else .39
            mat.metallic_specular = .48
            mat.albedo_color = Color("172126") if colour == 1 else Color("f6efdf")
            if KettleNextProfile.campaign():
                mat.roughness = .40 if colour == 1 else .52
                mat.metallic_specular = .30
                mat.albedo_color = Color("202b2d") if colour == 1 else Color("d8d6cc")
        node.material_override = mat
    for child in node.get_children(): _stone_material(child, colour)
