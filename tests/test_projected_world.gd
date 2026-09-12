class_name ProjectedWorldTests
extends RefCounted

static func run(t: TestKit) -> void:
    t.section("production projection: coverage, coordinates and depth")
    var maps := DirAccess.get_files_at("res://data/maps")
    var count := 0
    for file in maps:
        if not file.ends_with(".json"):
            continue
        count += 1
        var map := MapData.load_map(file.get_basename())
        var room := map.presentation
        t.ok(room != null, "rendered map: " + map.id)
        if room == null:
            continue
        t.eq(room.source_sha256, FileAccess.get_sha256("res://data/maps/" + file), "rendered geometry matches the authored map")
        t.eq(room.image.get_size(), room.size, "scenery has the declared camera canvas")
        t.eq(room.depth.get_size(), room.size, "occlusion uses that same camera canvas")
        for point in [Vector2.ZERO, Vector2(37, 92), map.pixel_size()]:
            var restored := room.unproject_vector(room.project(point) - room.origin)
            t.ok(restored.distance_to(point) < 0.001, "logical coordinates survive projection round trip")
        for vector in [Vector2.RIGHT, Vector2.DOWN, Vector2(-1, 1).normalized()]:
            var velocity := room.unproject_vector(vector) * Player.WALK_SPEED
            var screen_velocity := room.project_vector(velocity)
            t.ok(screen_velocity.distance_to(vector * Player.WALK_SPEED) < 0.001,
                "screen-relative speed and diagonals are preserved")
        for spawn in map.spawns:
            var foot := map.spawn_position(spawn)
            t.ok(Rect2(Vector2.ZERO, room.size).has_point(room.project(foot)), "saved spawn projects inside the render")
        # Scenery dimensions are metadata only: they cannot change legacy save/grid coordinates.
        t.eq(map.tile_size, 16, "logical tile size remains save compatible")
    t.eq(count, 12, "all twelve production maps are converted")
    t.ok(RoomProjection.load_room("missing_fixture") == null, "ordinary grid maps retain their renderer")
    var activity_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/rendered/people/activities.json"))
    for file in DirAccess.get_files_at("res://data/npcs"):
        if not file.ends_with(".tres"):
            continue
        var id := file.get_basename()
        var root := "res://art/rendered/people/" + id
        t.ok(ResourceLoader.exists(root + "_sheet.png"), "eight-way body: " + id)
        t.eq((load(root + "_busts.png") as Texture2D).get_size(), Vector2(756,108), "seven model expressions: " + id)
        for map_file in maps:
            if not map_file.ends_with(".json"):
                continue
            var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/" + map_file))
            for npc: Dictionary in data.get("npcs", []):
                if str(npc.id) != id:
                    continue
                var used: Array = [str(npc.get("idle", ""))]
                for variation: Dictionary in npc.get("activity_variations", []):
                    used.append(str(variation.get("idle", "")))
                for activity in used:
                    if activity in ["play", "read", "fold", "wipe", "arrange"]:
                        t.ok(activity_data.get(id, []).has(activity), "authored activity has rendered poses: " + id + "/" + activity)
    for id in ["player", "extra_commuter", "extra_shopper", "extra_docker", "extra_student", "extra_kid"]:
        t.eq((load("res://art/rendered/people/%s_sheet.png" % id) as Texture2D).get_size(),
            Vector2(240,512), "player and street traffic share the camera convention")

    var tram: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/rendered/ui/tram.json"))
    var canvas := Vector2(float(tram.size[0]), float(tram.size[1]))
    t.eq(tram.sections.size(), 5, "long tram has five independent ground sorting sections")
    for section: Dictionary in tram.sections:
        t.eq((load("res://art/rendered/ui/" + str(section.texture)) as Texture2D).get_size(),
            canvas, "tram sections share the source camera, without scale drift")
    var origin := Vector2(float(tram.origin[0]), float(tram.origin[1]))
    t.ok(Rect2(Vector2.ZERO, canvas).has_point(origin), "tram ground origin lies inside its canvas")
