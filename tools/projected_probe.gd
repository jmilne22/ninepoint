## Exercises the actual shader and screen-relative input on the live renderer.
class_name ProjectedProbe
extends RefCounted

static func perform(tree: SceneTree) -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(64, 64)
    viewport.transparent_bg = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.world_2d = World2D.new()
    tree.root.add_child(viewport)
    var sprite := Sprite2D.new()
    var paint := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    paint.fill(Color(0.4, 0.6, 0.8, 1))
    sprite.texture = ImageTexture.create_from_image(paint)
    sprite.position = Vector2(32, 32)
    var mask := Image.create(64, 64, false, Image.FORMAT_RGBA8)
    mask.fill(Color(0.2, 0, 0, 1))
    var mask_texture := ImageTexture.create_from_image(mask)
    var mat := ShaderMaterial.new()
    mat.shader = RoomProjection.OCCLUSION
    mat.set_shader_parameter("room_size", Vector2(64, 64))
    mat.set_shader_parameter("depth_map", mask_texture)
    mat.set_shader_parameter("actor_depth", 0.5)
    sprite.material = mat
    viewport.add_child(sprite)
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    var pixel := viewport.get_texture().get_image().get_pixel(32, 32)
    if not pixel.is_equal_approx(paint.get_pixel(0, 0)):
        _fail(tree, "actor shader changes unoccluded texture colour: " + str(pixel))
        return
    mask.fill(Color(0.8, 0, 0, 1))
    mask_texture.update(mask)
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    pixel = viewport.get_texture().get_image().get_pixel(32, 32)
    if pixel.a > 0.01:
        _fail(tree, "a surface in front of the feet fails to occlude the body")
        return
    viewport.queue_free()
    print("PROJECTED: texture colours preserved; foreground masks occlude")
    var world := tree.current_scene
    if not "map" in world or not world.map is MapData or world.map.presentation == null:
        _fail(tree, "motion probe needs a production map")
        return
    var player: Player = world.player
    var map: MapData = world.map
    var start := Vector2.INF
    for y in range(4, map.height - 2):
        for x in range(2, map.width - 2):
            var clear := true
            for dx in range(-1, 2):
                for dy in range(-1, 2):
                    clear = clear and not map.is_solid(x + dx, y + dy)
            var candidate := map.stand_position(Vector2i(x, y))
            for npc: Npc in world.npcs:
                clear = clear and candidate.distance_to(npc.position) > 50
            if clear:
                start = candidate
                break
        if start.is_finite():
            break
    if not start.is_finite():
        _fail(tree, "motion probe cannot find a clear patch of floor")
        return
    var original := player.position
    var lengths: Array[float] = []
    for direction in [Vector2.RIGHT, Vector2(1, 1).normalized()]:
        player.position = start
        var before := map.presentation.project(start)
        _input("move_right", true, direction.x)
        _input("move_down", direction.y > 0, direction.y)
        for frame in 18:
            await tree.physics_frame
        _input("move_right", false)
        _input("move_down", false)
        await tree.physics_frame
        var travelled := map.presentation.project(player.position) - before
        lengths.append(travelled.length())
        if travelled.normalized().distance_to(direction) > 0.04:
            _fail(tree, "live movement is not screen-relative: " + str(travelled))
            return
    player.position = original
    if lengths[0] < 12 or absf(lengths[0] - lengths[1]) > 2:
        _fail(tree, "live diagonal speed differs: " + str(lengths))
        return
    print("PROJECTED: live right/diagonal input has equal screen speed ", lengths)

static func _input(action: String, pressed: bool, strength: float = 1.0) -> void:
    var event := InputEventAction.new()
    event.action = action
    event.pressed = pressed
    event.strength = strength if pressed else 0.0
    Input.parse_input_event(event)

static func _fail(tree: SceneTree, reason: String) -> void:
    push_error("Projected presentation: " + reason)
    tree.quit(1)


static func tram_stop(tree: SceneTree, shot: Callable) -> void:
    var world := tree.current_scene
    var tram := world.find_child("Tram", true, false) as Tram
    if tram == null:
        _fail(tree, "tram stop probe needs Market Lane")
        return
    var stop_x: float = world.player.position.x
    tram._cross()
    await tree.create_timer(0.6).timeout
    # Reproduce boarding during a pass: the first tween must stop owning position.
    await tram.arrive(stop_x)
    await tree.create_timer(0.5).timeout
    if absf(tram.position.x - stop_x) > 0.1 or not tram.visible:
        _fail(tree, "a passing tween displaced the tram from the boarding stop")
        return
    await shot.call("tram_held_at_platform")
    print("PROJECTED: passing tram interrupted and held at the boarding stop")


static func follow_logical(map: MapData, direction: Vector2, pressed: bool) -> void:
    # Lane probes retain their physical target while exercising screen-relative input.
    var vector := map.presentation.project_vector(direction).normalized() if map.presentation != null else direction
    var strengths := {"move_right": maxf(vector.x, 0), "move_left": maxf(-vector.x, 0),
        "move_down": maxf(vector.y, 0), "move_up": maxf(-vector.y, 0)}
    for action: String in strengths:
        if pressed and float(strengths[action]) > 0.0:
            Input.action_press(action, float(strengths[action]))
        else:
            Input.action_release(action)


static func distance(map: MapData, a: Vector2, b: Vector2) -> float:
    return map.presentation.project_vector(a - b).length() if map.presentation != null else a.distance_to(b)


static func capture_motion(tree: SceneTree, shot: Callable) -> void:
    var player := tree.get_first_node_in_group("player") as Player
    var start := player.position
    for running: bool in [false, true]:
        player.position = start
        player.velocity = Vector2.ZERO
        player.sprite._idle = 0.0
        _input("run", running)
        _input("move_right", true)
        for frame in 16:
            await tree.create_timer(0.09 / (Player.RUN_MULTIPLIER if running else 1.0)).timeout
            await shot.call(("run" if running else "walk") + "_%02d" % frame)
        _input("move_right", false)
        _input("run", false)
        await tree.physics_frame
    player.position = start
