class_name RoomPresentationTests
extends RefCounted


static func run(t: TestKit) -> void:
    t.section("rendered room: navigation and exported assets")
    var room := RoomPresentation.new()
    room.read()
    t.ok(room.walkable(room.point(room.data.spawn)), "spawn is on an unobstructed floor")
    t.ok(not room.walkable(Vector2.ZERO), "void is not floor")
    for spec: Dictionary in room.data.people:
        t.ok(room.walkable(room.point(spec.seat)), str(spec.id) + " has a clear conversation approach")
    for values: Array in room.data.collision:
        var centre := Vector2.ZERO
        for value: Array in values:
            centre += room.point(value) / float(values.size())
        t.ok(not room.walkable(centre), "furniture footprint blocks feet")
    for layer: Dictionary in room.data.layers:
        var tex := room.texture(str(layer.image))
        t.eq(tex.get_size(), Vector2(384, 216), "layer shares the camera canvas")
    for id in ["player", "wren", "kesh", "tomas"]:
        var sheet := room.texture(id + "_sheet.png")
        t.eq(sheet.get_size(), Vector2(240, 512), "six poses in eight directions: " + id)
        var bust := room.texture(id + "_bust.png")
        t.eq(bust.get_size(), Vector2(108, 108), "model bust: " + id)
    for line in ["Short.", "A long line without sentence punctuation that still needs to fit inside the dialogue card when it wraps across multiple rows of the original bitmap font and reaches the final word"]:
        for page in UiKit.paginate(line, 344, 33):
            t.ok(UiKit.text_height(page, 344) <= 33, "dialogue pagination respects the card")
    t.section("rendered room: runtime-only isolation")
    var tree := Engine.get_main_loop() as SceneTree
    var saves = tree.root.get_node("SaveSystem")
    var router = tree.root.get_node("SceneRouter")
    var state = tree.root.get_node("GameState")
    var snapshot: Dictionary = state.to_dict().duplicate(true)
    var original_scene: String = router.world_scene()
    var before: Array[String] = []
    for slot in range(1, 4):
        before.append(FileAccess.get_file_as_string(saves.path_for(slot)) if saves.has_save(slot) else "")
    saves.session_only = true
    router.session_world_scene = "res://src/prototype/ketel/room.tscn"
    for slot in range(1, 4):
        t.ok(not saves.save_game(slot), "session cannot write slot")
        t.ok(not saves.load_game(slot), "session cannot read progress from slot")
        t.ok(not saves.delete_save(slot), "session cannot delete slot")
        var after: String = FileAccess.get_file_as_string(saves.path_for(slot)) if saves.has_save(slot) else ""
        t.eq(after, before[slot - 1], "slot bytes unchanged")
    t.eq(state.to_dict(), snapshot, "refused persistence leaves session progress unchanged")
    t.eq(router.world_scene(), "res://src/prototype/ketel/room.tscn", "board return uses prototype")
    t.ok(not state.to_dict().has("session_world_scene"), "presentation is not serialized")
    saves.session_only = false
    router.session_world_scene = ""
    t.eq(router.world_scene(), original_scene, "normal world remains the default")
