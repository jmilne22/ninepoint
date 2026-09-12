## Acceptance driver for rendered-room coordinates; movement always uses real input.
class_name KetelProbe
extends RefCounted


static func perform(tree: SceneTree, command: Dictionary) -> void:
    if command.get("assert", "") == "unrated_request":
        var bridge: Node = tree.root.get_node("MatchBridge")
        var request: MatchRequest = bridge.pending_request
        if request == null or not request.unrated or not request.practice or request.context_id != "wren_first":
            fail(tree, "Wren practice request changed")
        else:
            print("KETEL PASS: original Wren unrated practice request")
        return
    var room := tree.current_scene
    if room == null or room.scene_file_path != "res://src/prototype/ketel/room.tscn":
        fail(tree, "not in the prototype room")
        return
    if command.has("walk"):
        var dest: Variant = command.walk
        var point: Vector2
        if dest is Array:
            point = room.presentation.point(dest)
        else:
            point = room.presentation.point(room.presentation.data[dest])
            # Seat names are resolved separately below by the route author.
        await walk(tree, point)
    if command.has("seat"):
        for spec: Dictionary in room.presentation.data.people:
            if spec.id == command.seat:
                await walk(tree, room.presentation.point(spec.seat))
    if command.has("talk"):
        var id := str(command.talk)
        if room.target_at(room.player.position) != id:
            fail(tree, "wrong interaction target before talking to " + id)
            return
        send("interact", true)
        await tree.process_frame
        send("interact", false)
        await tree.create_timer(.2).timeout
        if not room.dialogue.running:
            fail(tree, "conversation did not open")
    if command.has("assert"):
        match str(command.assert):
            "isolation":
                var saves: Node = tree.root.get_node("SaveSystem")
                var state: Node = tree.root.get_node("GameState")
                var before: Dictionary = state.to_dict().duplicate(true)
                if not saves.session_only or saves.save_game(1) or saves.load_game(1) or saves.delete_save(1):
                    fail(tree, "save API accepted a session-only operation")
                if before != state.to_dict():
                    fail(tree, "refused save/load changed progress")
                print("KETEL PASS: save/load/delete refused without changing session")
            "free":
                if room.busy or not room.presentation.walkable(room.player.position):
                    fail(tree, "room not freely walkable after return")
                print("KETEL PASS: control returned to walkable room")
            "layout":
                check_layout(tree, room)
            "no_record":
                var state: Node = tree.root.get_node("GameState")
                if not state.match_records.is_empty():
                    fail(tree, "cancelled setup created a match record")
                print("KETEL PASS: cancelled setup did not record a game")
            _:
                fail(tree, "unknown assertion " + str(command.assert))
    if command.has("fixture_result"):
        # Explicit synthetic branch regression, never used as proof of a played win.
        var result := MatchResult.new()
        result.npc_id = "wren"
        result.opponent_name = "Wren Calloway"
        result.context_id = "wren_first"
        result.unrated = true
        result.player_won = bool(command.fixture_result)
        result.by_resignation = true
        result.winner = GoBoard.BLACK if result.player_won else GoBoard.WHITE
        result.sgf = "(;GM[1]FF[4]SZ[9]KM[5.5];B[dd];W[fd])"
        result.move_count = 2
        var bridge: Node = tree.root.get_node("MatchBridge")
        bridge.record_completed_match(result)
        room.conversation.returned()
    if command.has("review"):
        var state: Node = tree.root.get_node("GameState")
        room.conversation.offer_review(state.match_records.size()-1)


static func check_layout(tree: SceneTree, room: Node) -> void:
    var layout: RoomPresentation = room.presentation
    if not layout.walkable(layout.point(layout.data.spawn)):
        fail(tree, "spawn is blocked")
    for spec: Dictionary in layout.data.people:
        var seat := layout.point(spec.seat)
        if not layout.walkable(seat) or room.target_at(seat) != spec.id:
            fail(tree, "blocked or ambiguous seat: " + str(spec.id))
    if layout.walkable(Vector2.ZERO):
        fail(tree, "outside room accepted")
    for values: Array in layout.data.collision:
        var centre := Vector2.ZERO
        for value: Array in values:
            centre += layout.point(value) / float(values.size())
        if layout.walkable(centre):
            fail(tree, "furniture centre accepted")
    print("KETEL PASS: spawn, seats, bounds and all furniture footprints")


static func safe(room: Node, point: Vector2) -> bool:
    for offset in [Vector2.ZERO, Vector2(4.5,0), Vector2(-4.5,0), Vector2(0,4.5), Vector2(0,-4.5),
            Vector2(3.2,3.2), Vector2(-3.2,3.2), Vector2(3.2,-3.2), Vector2(-3.2,-3.2)]:
        if not room.presentation.walkable(point + offset):
            return false
    for actor: KetelActor in room.people.values():
        if point.distance_to(actor.position) < 8:
            return false
    return true


static func walk(tree: SceneTree, goal: Vector2) -> void:
    var room := tree.current_scene
    var start := Vector2i((room.player.position / 2).round())
    var queue: Array[Vector2i] = [start]
    var visited := {start: start}
    var found := start
    var index := 0
    while index < queue.size():
        var at := queue[index]
        index += 1
        if Vector2(at * 2).distance_to(goal) < 5:
            found = at
            break
        for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var next: Vector2i = at + step
            if not visited.has(next) and safe(room, Vector2(next * 2)):
                visited[next] = at
                queue.append(next)
    if found == start and room.player.position.distance_to(goal) >= 7:
        fail(tree, "no foot-safe route to %s" % goal)
        return
    var path: Array[Vector2] = []
    while found != start:
        path.push_front(Vector2(found * 2))
        found = visited[found]
    for point in path:
        for frame in 45:
            var delta: Vector2 = point - room.player.position
            if delta.length() < 1.05:
                break
            release()
            if absf(delta.x) > .6:
                send("move_right" if delta.x > 0 else "move_left", true)
            if absf(delta.y) > .6:
                send("move_down" if delta.y > 0 else "move_up", true)
            await tree.physics_frame
        release()
        if room.player.position.distance_to(point) > 3:
            fail(tree, "collision stopped actual movement at %s toward %s" % [room.player.position, point])
            return
    if room.player.position.distance_to(goal) > 8:
        fail(tree, "walk missed its destination")
    print("KETEL PASS: walked to %s" % goal)


static func send(action: String, pressed: bool) -> void:
    var event := InputEventAction.new()
    event.action = action
    event.pressed = pressed
    Input.parse_input_event(event)


static func release() -> void:
    for action in ["move_left", "move_right", "move_up", "move_down"]:
        send(action, false)


static func fail(tree: SceneTree, message: String) -> void:
    push_error("Ketel probe: " + message)
    release()
    tree.quit(1)
