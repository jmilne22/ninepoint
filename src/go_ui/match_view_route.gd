## Cast matches use the approved presentation; development profiles retain their harness.
class_name MatchViewRoute
extends RefCounted
const TABLE := "res://src/go_ui/table_scene/match.tscn"
const STANDARD := "res://src/go_ui/go_match.tscn"
static func scene_for(request: MatchRequest) -> String:
    if request != null and request.profile != null and request.profile.board_size in [7,9,13,19] and ResourceLoader.exists("res://art/table_scene/%s.glb" % request.npc_id):
        return TABLE
    return STANDARD
