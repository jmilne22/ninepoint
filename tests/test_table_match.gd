class_name TableMatchTests
extends RefCounted

static func run(t: TestKit) -> void:
    t.section("match presentation routing and region mapping")
    var request := MatchRequest.new()
    for npc in ["wren", "pip", "kesh", "ilse", "tomas", "sunny", "orla", "bertie", "nadia", "marguerite", "hana", "joos", "abel", "dov", "moss", "noor", "ivo", "lea", "emil", "sora"]:
        request.npc_id = npc
        request.profile = OpponentProfile.new()
        for n in [7, 9, 13, 19]:
            request.profile.board_size = n
            t.eq(MatchViewRoute.scene_for(request), MatchViewRoute.TABLE, "cast routes to shared presentation: " + npc)
    request.npc_id = "development_fixture"
    t.eq(MatchViewRoute.scene_for(request), MatchViewRoute.STANDARD, "custom engine harness retains fallback")
    var layout := TableBoardLayout.new()
    for n in [7, 9, 13, 19]:
        layout.configure(n, Rect2i(0, 0, n, n))
        for point in n * n:
            t.eq(layout.point_at(layout.world_point(point)), point, "surface round trip preserves global index")
        for edge in [Vector3(-0.6, 0, 0), Vector3(0.6, 0, 0), Vector3(0, 0, -0.6), Vector3(0, 0, 0.6)]:
            t.eq(layout.point_at(edge), -1, "table outside board is not playable")
    for origin in [Vector2i(0,0), Vector2i(10,0), Vector2i(0,10), Vector2i(10,10), Vector2i(5,5)]:
        layout.configure(19, Rect2i(origin, Vector2i(9,9)))
        var visible := 0
        for point in 361:
            if layout.contains(point):
                visible += 1
                t.eq(layout.point_at(layout.world_point(point)), point, "zoom retains global SGF coordinates")
        t.eq(visible, 81, "close view exposes exactly nine lines each way")
