## A dialogue graph loaded from JSON. Pure logic: it evaluates conditions and
## applies actions against GameState, and never touches the UI.
class_name DialogueGraph
extends RefCounted

var id: String = ""
var nodes: Dictionary = {}


static func load_graph(path: String) -> DialogueGraph:
    if not FileAccess.file_exists(path):
        push_error("DialogueGraph: missing %s" % path)
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (parsed is Dictionary):
        push_error("DialogueGraph: %s is not valid JSON" % path)
        return null
    var g := DialogueGraph.new()
    g.id = str(parsed.get("id", ""))
    g.nodes = parsed.get("nodes", {})
    return g


func node(node_id: String) -> Dictionary:
    return nodes.get(node_id, {})


## Follows `branches` until a node with real content is reached.
func resolve(node_id: String, depth: int = 0) -> String:
    if node_id == "" or depth > 32 or not nodes.has(node_id):
        return ""
    var n: Dictionary = nodes[node_id]
    if n.has("branches"):
        for b in n["branches"]:
            if check(b.get("if", [])):
                return resolve(str(b.get("goto", "")), depth + 1)
        return ""
    return node_id


# Autoloads are not resolvable as plain identifiers when this script is compiled
# ahead of the scene tree -- which is exactly what a `--script` test run does --
# and they are scene-tree nodes rather than engine singletons, so they are looked
# up by path. Cached, because conditions are evaluated per dialogue node.
static var _state_node: Node = null
static var _bus_node: Node = null


static func _autoload(name: String, cache: Node) -> Node:
    if cache != null and is_instance_valid(cache):
        return cache
    var loop := Engine.get_main_loop()
    if loop is SceneTree:
        return (loop as SceneTree).root.get_node_or_null(NodePath(name))
    return null


static func _state() -> Node:
    _state_node = _autoload("GameState", _state_node)
    return _state_node


static func _bus() -> Node:
    _bus_node = _autoload("EventBus", _bus_node)
    return _bus_node


# --- conditions --------------------------------------------------------------

static func check(conditions) -> bool:
    if conditions == null or not (conditions is Array):
        return true
    for c in conditions:
        if not _check_one(c):
            return false
    return true


static func _check_one(c: Array) -> bool:
    if c.is_empty():
        return true
    var op := str(c[0])
    match op:
        "flag":
            return _state().has_flag(str(c[1]))
        "not_flag":
            return not _state().has_flag(str(c[1]))
        "flag_at_least":
            return int(_state().get_flag(str(c[1]), 0)) >= int(c[2])
        "quest_step":
            return _state().quest_step(str(c[1])) >= int(c[2])
        "quest_done":
            return _state().quest_done(str(c[1]))
        "has_item":
            return _state().has_item(str(c[1]))
        "ranked":
            return _state().is_ranked()
        "rank_at_least":
            # Written as a label -- ["rank_at_least", "1d"] -- because a dialogue
            # file should say what the entry form says, not a strength value.
            return _state().is_ranked() and int(_state().rank_strength) >= GoRank.from_string(str(c[1]))
        "on_map":
            # Marguerite works two desks: the Institute's register and the
            # federation's entry table. One graph, and it has to know which.
            return str(_state().current_map) == str(c[1])
        "rank_at_most":
            # "Fifteen kyu and below" is a ceiling on strength, not a floor: the
            # Beginner Cup is a thing you can be too good for, and eventually are.
            return _state().is_ranked() and int(_state().rank_strength) <= GoRank.from_string(str(c[1]))
        "unranked":
            return not _state().is_ranked()
        "league_position_at_most":
            # Entry to the exam is by league position, which the board has been
            # promising since the day you enrolled. Derived from the record every
            # time it is asked, stored nowhere -- Rule 5 -- so a graph can read it
            # the way the noticeboard states it.
            return LeagueTable.current_position() <= int(c[1])
        "rated_wins_at_least":
            # The chapter-2 gate from GAME_DESIGN section 9: three rated games
            # won and the bigger board opens. Counted off the record every time
            # it is asked rather than stored behind a flag -- Rule 5, and the
            # M27 lesson besides, since a flag called `won_enough` would start
            # meaning whatever the next thing to set it happened to mean.
            var rated_wins := 0
            for r in _state().match_records:
                if r is Dictionary and not bool(r.get("unrated", false)) \
                        and bool(r.get("player_won", false)):
                    rated_wins += 1
            return rated_wins >= int(c[1])
        "played_at_least":
            # Games against somebody, win or lose. The record is what the game
            # tracks instead of affection, so it is what an arc advances on.
            var record: Dictionary = _state().head_to_head(str(c[1]))
            return int(record["wins"]) + int(record["losses"]) >= int(c[2])
        "beat":
            return _state().head_to_head(str(c[1]))["wins"] > 0
        "lost_to":
            return _state().head_to_head(str(c[1]))["losses"] > 0
        _:
            push_warning("DialogueGraph: unknown condition '%s'" % op)
            return false


# --- actions -----------------------------------------------------------------

static func apply(actions) -> void:
    if actions == null or not (actions is Array):
        return
    for a in actions:
        _apply_one(a)


static func _apply_one(a: Array) -> void:
    if a.is_empty():
        return
    match str(a[0]):
        "set_flag":
            _state().set_flag(str(a[1]), a[2] if a.size() > 2 else true)
        "bump_flag":
            _state().bump_flag(str(a[1]), int(a[2]) if a.size() > 2 else 1)
        "give":
            _state().give_item(str(a[1]), str(a[2]) if a.size() > 2 else "")
        "take":
            # The other half of `give`, and it took until M32 to need one. A
            # borrowed thing that cannot be handed back is not borrowed.
            _state().take_item(str(a[1]))
        "rank":
            _state().set_rank(str(a[1]))
        "quest_start":
            _bus().quest_started.emit(str(a[1]))
        "quest_advance":
            _bus().quest_advanced.emit(str(a[1]), -1, "")
        "toast":
            _bus().toast.emit(str(a[1]))
        _:
            push_warning("DialogueGraph: unknown action '%s'" % str(a[0]))
