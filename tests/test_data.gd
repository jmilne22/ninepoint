## Content validation: every data file the game ships must load and resolve.
class_name GoDataTests
extends RefCounted


## The GameState autoload, fetched rather than named.
##
## A bare `GameState.x` here is compiled before the autoload's script is in the
## global cache, so the analyser types the singleton as plain Node -- and keeps
## that answer for everything compiled afterwards, including production code.
## It is why `state.reset()` below had never once run, and why it took the save
## suite down with it when that suite arrived in M31.
static func _state():
    return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")


static func run(t: TestKit) -> void:
    _test_dialogue(t)
    _test_dialogue_exits(t)
    _test_opponents_reachable(t)
    _test_every_section_is_enterable(t)
    _test_resources(t)
    _test_puzzles(t)
    _test_maps(t)
    _test_the_wassalon(t)
    _test_conditions_are_known(t)
    _test_dialogue_branches(t)
    _test_lessons(t)
    _test_lessons_have_a_close(t)
    _test_lessons_and_puzzles_reachable(t)
    _test_no_orphan_nodes(t)
    _test_rulebook_exits_carry_the_track(t)
    _test_items_round_trip(t)
    _test_quest_targets(t)
    _test_journal_order(t)


static func _list(dir_path: String, ext: String) -> PackedStringArray:
    var out := PackedStringArray()
    var d := DirAccess.open(dir_path)
    if d == null:
        return out
    for f in d.get_files():
        var name := f.trim_suffix(".remap")
        if name.ends_with(ext):
            out.append(dir_path.path_join(name))
    return out


static func _test_dialogue(t: TestKit) -> void:
    t.section("dialogue data")
    var files := _list("res://data/dialogue", ".json")
    t.ok(files.size() > 0, "there is dialogue to validate")
    for path in files:
        var text := FileAccess.get_file_as_string(path)
        var parsed = JSON.parse_string(text)
        t.ok(parsed is Dictionary, "%s parses as JSON" % path)
        if not (parsed is Dictionary):
            continue
        var nodes = parsed.get("nodes", {})
        t.ok(nodes is Dictionary and nodes.size() > 0, "%s has nodes" % path)
        t.ok(nodes.has("start"), "%s has a start node" % path)
        for key in nodes.keys():
            var node: Dictionary = nodes[key]
            for target in _gotos(node):
                t.ok(nodes.has(target), "%s: '%s' points at a node that exists ('%s')" % [path, key, target])


static func _gotos(node: Dictionary) -> PackedStringArray:
    var out := PackedStringArray()
    if node.has("goto") and node["goto"] != "":
        out.append(str(node["goto"]))
    for c in node.get("choices", []):
        if c.has("goto"):
            out.append(str(c["goto"]))
    for b in node.get("branches", []):
        if b.has("goto"):
            out.append(str(b["goto"]))
    return out


## Every exit in every graph. _gotos() above never looks at one, so until now a
## typo in a profile, lesson or puzzle id passed every test in the project and
## turned into a silently wrong match or a broken scene at run time.
static func _exits(node: Dictionary) -> Array:
    var out: Array = []
    if node.has("exit"):
        out.append(node["exit"])
    for c in node.get("choices", []):
        if c.has("exit"):
            out.append(c["exit"])
    return out


## Every `actions` list a node can carry: its own, and each choice's.
static func _actions(node: Dictionary) -> Array:
    var out: Array = []
    for a in node.get("actions", []):
        out.append(a)
    for c in node.get("choices", []):
        for a in c.get("actions", []):
            out.append(a)
    return out


## Every condition a node can test: branch `if` lists and choice `if` lists.
static func _conditions(node: Dictionary) -> Array:
    var out: Array = []
    for b in node.get("branches", []):
        for c in b.get("if", []):
            out.append(c)
    for c in node.get("choices", []):
        for cond in c.get("if", []):
            out.append(cond)
    return out


## The exit types World._handle_exit knows. Anything else is dispatched to
## nothing at all and the conversation simply stops.
const EXIT_TYPES := ["start_match", "start_lesson", "start_puzzle", "cup_round",
                     "exam_round", "exam_paper", "end"]


static func _test_dialogue_exits(t: TestKit) -> void:
    t.section("dialogue exits")
    for path in _list("res://data/dialogue", ".json"):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (parsed is Dictionary):
            continue
        var nodes: Dictionary = parsed.get("nodes", {})
        var starts_a_match := false
        for key in nodes.keys():
            for exit in _exits(nodes[key]):
                var kind := str(exit.get("type", "end"))
                t.ok(EXIT_TYPES.has(kind),
                    "%s: '%s' exits with a type the world handles ('%s')" % [path, key, kind])
                if kind == "start_match":
                    starts_a_match = true
                if exit.has("profile"):
                    t.ok(ResourceLoader.exists("res://data/opponents/%s.tres" % str(exit["profile"])),
                        "%s: '%s' names a real opponent ('%s')" % [path, key, str(exit["profile"])])
                if exit.has("lesson"):
                    t.ok(FileAccess.file_exists("res://data/lessons/%s.json" % str(exit["lesson"])),
                        "%s: '%s' names a real lesson ('%s')" % [path, key, str(exit["lesson"])])
                if exit.has("puzzle"):
                    t.ok(FileAccess.file_exists("res://data/puzzles/%s.json" % str(exit["puzzle"])),
                        "%s: '%s' names a real puzzle ('%s')" % [path, key, str(exit["puzzle"])])
        # World._post_match re-enters the graph at "post_match" when the player
        # lands back in the world. If it is missing, resolve() returns "" and the
        # box never opens -- so the after-game beat is skipped in silence. Tomas
        # shipped like that from the day he was given a game.
        if starts_a_match:
            t.ok(nodes.has("post_match"),
                "%s offers a game, so it has a post_match node" % path)


## Entering the rulebook anywhere must teach the rest of it.
##
## `track` is what queues the remainder of MatchBridge.TUTORIAL_TRACK after the
## lesson named. Wren's "A bit. Remind me of the capturing rule." started
## `capture` without it, so `self_capture` was never queued -- and then
## finish_lesson declared the rules known and Wren's closing line said she had
## taught "liberties, capture, and no filling in your own last one", one third of
## which had not happened. A rulebook lesson offered without `track` is that bug.
static func _test_rulebook_exits_carry_the_track(t: TestKit) -> void:
    t.section("the rulebook is taught whole")
    var track := _script_const("res://src/autoload/match_bridge.gd", "TUTORIAL_TRACK")
    t.ok(track.size() > 0, "the tutorial track is readable")
    for path in _list("res://data/dialogue", ".json"):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (parsed is Dictionary):
            continue
        var nodes: Dictionary = parsed.get("nodes", {})
        for key in nodes.keys():
            for exit in _exits(nodes[key]):
                if str(exit.get("type", "")) != "start_lesson":
                    continue
                if not track.has(str(exit.get("lesson", ""))):
                    continue
                t.ok(bool(exit.get("track", false)),
                    "%s: '%s' teaches rulebook lesson '%s', so it carries the whole track"
                        % [path, key, str(exit["lesson"])])


## The reverse direction: a profile nothing can reach is a file that loads, is
## never wrong, and never happens. check_load.gd loads them all, which is exactly
## why hana_teaching survived unreferenced from the day it was written.
##
## This is still not a blanket rule for anything a tournament might pick up by
## string interpolation -- it names the two events that do it, and both of them
## have to say which people and which board.
##
## It is **derived** rather than retyped, which is the one change from the hand
## written list this replaces. ROADMAP section 8 records what the other shape
## costs: LESSONS_REACHED_BY_TRACK is a hand-kept copy of the track it guards,
## so adding a class means remembering two places, and the copy in the test is
## the one that goes on passing. A second Cup section is exactly that trap --
## five new entrants on a bigger board, against a list somebody would have had
## to remember existed.
static func _reached_by_event() -> Dictionary:
    var out := {}
    for section_id in CupDraw.SECTIONS:
        var board: int = CupDraw.board_for(section_id)
        for npc_id in CupDraw.FIELDS[section_id]:
            out["%s_%dx%d" % [npc_id, board, board]] = true
    for npc_id in LeagueTable.ROSTER:
        if Exam.EXCLUDED.has(npc_id):
            continue
        out["%s_exam" % npc_id] = true
    return out


static func _test_opponents_reachable(t: TestKit) -> void:
    t.section("every opponent can be played")
    var named := {}
    for path in _list("res://data/dialogue", ".json"):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (parsed is Dictionary):
            continue
        var nodes: Dictionary = parsed.get("nodes", {})
        for key in nodes.keys():
            for exit in _exits(nodes[key]):
                if exit.has("profile"):
                    named[str(exit["profile"])] = true
    var by_event := _reached_by_event()
    for path in _list("res://data/opponents", ".tres"):
        var id := path.get_file().trim_suffix(".tres")
        t.ok(named.has(id) or by_event.has(id),
            "%s is reachable: some dialogue starts it, or an event draws it" % id)
    # And the exam's field must match the league roster it is drawn from, or the
    # generator will stop emitting a profile the world then asks for.
    for npc_id in LeagueTable.ROSTER:
        if Exam.EXCLUDED.has(npc_id):
            continue
        t.ok(ResourceLoader.exists("res://data/opponents/%s_exam.tres" % npc_id),
            "%s can be drawn in the exam and has an even-game profile" % npc_id)


## A section nothing writes is a board size nobody can reach.
##
## CupDraw knows two sections and World reads one off a flag; the only thing that
## ever *writes* that flag is a line in Marguerite's graph. That is one dialogue
## edit away from a game with an open section in the code, a title for it, five
## profiles generated for it, and no way into it -- which would load, pass every
## other check in this file, and simply never happen. The same reverse-direction
## argument as _reached_by_event() above.
static func _test_every_section_is_enterable(t: TestKit) -> void:
    t.section("both Cup sections can be entered")
    var written := {}
    for path in _list("res://data/dialogue", ".json"):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (parsed is Dictionary):
            continue
        var nodes: Dictionary = parsed.get("nodes", {})
        for key in nodes.keys():
            var node = nodes[key]
            if not (node is Dictionary):
                continue
            for action in node.get("actions", []):
                if not (action is Array) or action.size() < 3:
                    continue
                if str(action[0]) == "set_flag" and str(action[1]) == "cup_section":
                    written[str(action[2])] = "%s:%s" % [path.get_file(), key]
    for section_id in CupDraw.SECTIONS:
        t.ok(written.has(section_id),
            "some dialogue enters the player in the '%s' section" % section_id)
    # And nothing writes a section CupDraw has never heard of, which would land
    # as a silent fall back to the beginners' board at round one.
    for value in written.keys():
        t.ok(CupDraw.SECTIONS.has(str(value)),
            "'%s' is a section CupDraw knows (written at %s)" % [value, written[value]])


static func _test_resources(t: TestKit) -> void:
    t.section("resource data")
    for path in _list("res://data/opponents", ".tres"):
        var res := ResourceLoader.load(path)
        t.ok(res is OpponentProfile, "%s loads as an OpponentProfile" % path)
        if res is OpponentProfile:
            t.ok(res.board_size >= 5, "%s has a sane board size" % path)
            # A rank may be withheld -- Joos under the arches has never had one
            # written down -- but never invented, and never a difficulty word.
            t.ok(res.rank_label == OpponentProfile.RANK_WITHHELD
                    or GoRank.from_string(res.rank_label) >= 0,
                "%s uses a real rank label, not a difficulty word" % path)
            t.ok(res.strength() >= 0,
                "%s has a real strength behind its label" % path)
            t.ok(res.setup_rule() >= 0, "%s declares how the colours are decided" % path)
            t.ok(res.capture_goal >= 0, "%s has a sane capture goal" % path)
            # A capture-go profile must be a small board: it is a teaching game.
            if res.capture_goal > 0:
                t.ok(res.board_size <= 9, "%s: capture go is played small" % path)
    for path in _list("res://data/npcs", ".tres"):
        var res := ResourceLoader.load(path)
        t.ok(res != null, "%s loads" % path)
    for path in _list("res://data/quests", ".tres"):
        var res := ResourceLoader.load(path)
        t.ok(res != null, "%s loads" % path)


static func _test_puzzles(t: TestKit) -> void:
    t.section("puzzle data")
    var paths := _list("res://data/puzzles", ".json")
    t.ok(paths.size() > 0, "there are puzzles to validate")
    for path in paths:
        var puzzle_id := path.get_file().trim_suffix(".json")
        var p := GoPuzzleData.load_puzzle(puzzle_id)
        t.ok(p != null, "%s loads" % path)
        if p == null:
            continue
        t.ok(p.solutions.size() > 0, "%s has at least one solution" % path)
        t.ok(p.title.length() <= 44,
            "%s: the title fits the two lines the panel gives it" % path)
        t.ok(p.goal != "" and p.hint != "" and p.explanation != "",
            "%s teaches something: goal, hint and explanation" % path)
        # Every listed solution must be legal, and must actually do what the
        # puzzle claims -- an answer that does not work is worse than no puzzle.
        # What "work" means depends on the kind: a capture puzzle takes the
        # target off the board, and a life or escape puzzle takes nothing at all.
        # tools/check_lessons.py proves the eyes and the liberties; this proves
        # the answer is playable and that the two files agree about the kind.
        t.ok(p.kind in GoPuzzleData.KINDS,
            "%s: '%s' is a puzzle kind the game knows" % [path, p.kind])
        for sol in p.solutions:
            var g := p.make_game()
            t.ok(g.is_legal(sol), "%s: solution %s is legal" % [path, g.board.label(sol)])
            var before: int = g.captures[p.to_move]
            g.play(sol)
            if p.kind != "capture":
                continue
            t.ok(g.captures[p.to_move] > before,
                "%s: playing %s captures something" % [path, g.board.label(sol)])
            for point in p.target:
                t.eq(g.board.get_idx(point), GoBoard.EMPTY,
                    "%s: the target group is gone after %s" % [path, g.board.label(sol)])


static func _test_maps(t: TestKit) -> void:
    t.section("map data")
    var ids := PackedStringArray()
    for path in _list("res://data/maps", ".json"):
        ids.append(path.get_file().trim_suffix(".json"))
    t.ok(ids.size() > 0, "there are maps to validate")
    for map_id in ids:
        var m := MapData.load_map(map_id)
        t.ok(m != null, "%s loads" % map_id)
        if m == null:
            continue
        t.eq(m.ground.size(), m.height, "%s: ground has one row per tile row" % map_id)
        t.eq(m.solid.size(), m.height, "%s: solid mask has one row per tile row" % map_id)
        for spawn in m.spawns.keys():
            var s: Array = m.spawns[spawn]
            t.ok(not m.is_solid(int(s[0]), int(s[1])),
                "%s: spawn '%s' is somewhere you can stand" % [map_id, spawn])
        for npc in m.npcs:
            var tile: Array = npc["tile"]
            t.ok(not m.is_solid(int(tile[0]), int(tile[1])),
                "%s: npc '%s' is not inside the furniture" % [map_id, str(npc.get("id", "?"))])
            t.ok(ResourceLoader.exists("res://data/npcs/%s.tres" % str(npc.get("id", ""))),
                "%s: npc '%s' has data" % [map_id, str(npc.get("id", ""))])
        for w in m.warps:
            var wt: Array = w["tile"]
            t.ok(not m.is_solid(int(wt[0]), int(wt[1])),
                "%s: the doorway to %s can be stood in" % [map_id, str(w.get("map", ""))])
            t.ok(ids.has(str(w.get("map", ""))), "%s: warp target '%s' exists" % [map_id, str(w.get("map", ""))])
            var target := MapData.load_map(str(w.get("map", "")))
            if target != null:
                t.ok(target.spawns.has(str(w.get("spawn", ""))),
                    "%s: '%s' has the spawn point '%s'" % [map_id, str(w.get("map", "")), str(w.get("spawn", ""))])
        # A sign must have somewhere to stand and read it. Being solid is only
        # half of readable: the interaction probe is a 14x14 box thrown 12 px
        # from the player's feet, so it reaches exactly one tile, and a sign
        # with no walkable orthogonal neighbour builds an Interactable the
        # probe can never overlap. It draws nothing, it errors nothing, and the
        # prompt never appears. gen_maps.validate() refuses to write one now;
        # this is the same rule asserted against what actually shipped, because
        # a generator guard only protects the next map and this file protects
        # the ten that are already here.
        #
        # It found one: the attic dormer, unreadable since M14.
        for s in m.signs:
            var st: Array = s.get("tile", [0, 0])
            var sx := int(st[0])
            var sy := int(st[1])
            var reachable := false
            for step in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
                var nx := sx + int(step[0])
                var ny := sy + int(step[1])
                if nx >= 0 and ny >= 0 and nx < m.width and ny < m.height \
                        and not m.is_solid(nx, ny):
                    reachable = true
            t.ok(reachable, "%s: the sign at %d,%d can be stood in front of"
                % [map_id, sx, sy])
        # every tile character must exist in the atlas
        for y in m.height:
            for x in m.width:
                var tile_name := m.tile_name_at(m.ground, x, y)
                if tile_name != "":
                    t.ok(TileAtlas.at(tile_name).x >= 0,
                        "%s: tile '%s' at %d,%d is in the atlas" % [map_id, tile_name, x, y])


## The wassalon, and the two things about it that no other check would notice.
##
## Every guard in this file so far asserts that somebody *is* somewhere: the
## cover, the staffed rooms, the findability list. Nothing anywhere asserts that
## a room is EMPTY, and this is the first room in the game whose design depends
## on it -- five lit portholes still turning and nobody in the chair is the
## image the map exists for, and it is one careless "night" away from being
## deleted with every test still green.
##
## The other half is the claim the milestone actually makes: the Beginner Cup
## used to draw three names the player had never seen. That is only fixed for as
## long as all three of them still stand in a room, so it is asserted rather
## than remembered.
static func _test_the_wassalon(t: TestKit) -> void:
    t.section("the wassalon: three strangers and nowhere else")
    var m := MapData.load_map("wassalon")
    t.ok(m != null, "the wassalon loads")
    if m == null:
        return

    # The three strangers, and nowhere else. If one of them turns up on another
    # map the room stops being the only place you can have met them, and the
    # Cup draw quietly goes back to being a list of names.
    var here := {}
    for npc in m.npcs:
        here[str(npc.get("id", ""))] = true
    for who in ["abel", "dov", "moss"]:
        t.ok(here.has(who), "%s is in the wassalon" % who)
        t.ok(CupDraw.FIELD_BEGINNERS.has(who),
            "%s is in the Cup's beginners' field, which is the point of meeting them" % who)
        var elsewhere := ""
        for path in _list("res://data/maps", ".json"):
            var other_id := path.get_file().trim_suffix(".json")
            if other_id == "wassalon":
                continue
            var other := MapData.load_map(other_id)
            if other == null:
                continue
            for npc in other.npcs:
                if str(npc.get("id", "")) == who:
                    elsewhere = other_id
        t.eq(elsewhere, "", "%s stands in the wassalon and nowhere else" % who)

    # Two of the three games are free, and that is a design rule rather than a
    # convenience: `rated_wins_at_least` counts every rated record in the save,
    # so a rated 21 kyu on a doorstep is three farmed wins away from opening the
    # bigger board and the Cup play-up. Moss is the exception on purpose -- he
    # is the one person in a room that records nothing who wants it recorded.
    for who in ["abel", "dov"]:
        t.ok(_offers_only_unrated(who),
            "%s plays for nothing: the wassalon keeps no record" % who)
    t.ok(not _offers_only_unrated("moss"),
        "moss plays one that counts, which is the whole of him")


## Does every game this graph offers carry `unrated`?
static func _offers_only_unrated(npc_id: String) -> bool:
    var parsed = JSON.parse_string(
        FileAccess.get_file_as_string("res://data/dialogue/%s.json" % npc_id))
    if not (parsed is Dictionary):
        return false
    var found := false
    for node in parsed.get("nodes", {}).values():
        for e in _exits(node):
            if str(e.get("type", "")) != "start_match":
                continue
            found = true
            if not bool(e.get("unrated", false)):
                return false
    return found


## Every condition a shipped dialogue file uses must be one DialogueGraph knows.
##
## An unknown op does not error: `_check_one` push_warnings and returns **false**,
## so a typo'd condition is a branch that silently never fires, which is a
## paragraph of writing that never plays and nothing to say so. `hana_teaching`
## sat orphaned for a whole milestone for a neighbouring reason.
##
## The vocabulary is *read off dialogue_graph.gd's own source* rather than
## retyped here. A hand-kept copy is the thing this project keeps paying for --
## LESSONS_REACHED_BY_TRACK and CLUB_NIGHT_GUESTS are both on the debt list for
## exactly this -- and the copy is always the one that goes on passing.
static func _test_conditions_are_known(t: TestKit) -> void:
    t.section("dialogue conditions are all real")
    var src := FileAccess.get_file_as_string("res://src/dialogue/dialogue_graph.gd")
    t.ok(src != "", "dialogue_graph.gd is readable")
    var known := {}
    # The condition ops are the `match` cases between "--- conditions" and the
    # "--- actions" banner, so the action vocabulary cannot leak in and make an
    # action name pass as a condition.
    var from := src.find("--- conditions")
    var to := src.find("--- actions")
    if from < 0 or to < 0:
        t.ok(false, "the condition section banners are still in dialogue_graph.gd")
        return
    for line in src.substr(from, to - from).split("\n"):
        var trimmed := line.strip_edges()
        if not trimmed.ends_with("\":") or not trimmed.begins_with("\""):
            continue
        known[trimmed.substr(1, trimmed.length() - 3)] = true
    t.ok(known.size() > 10, "read %d condition ops off the source" % known.size())

    for path in _list("res://data/dialogue", ".json"):
        var graph := DialogueGraph.load_graph(path)
        if graph == null:
            continue
        for node_id in graph.nodes.keys():
            var node: Dictionary = graph.nodes[node_id]
            for branch in node.get("branches", []):
                for cond in branch.get("if", []):
                    if cond is Array and not (cond as Array).is_empty():
                        var op := str(cond[0])
                        t.ok(known.has(op),
                            "%s/%s: condition '%s' is one DialogueGraph knows"
                                % [path.get_file(), node_id, op])


static func _test_dialogue_branches(t: TestKit) -> void:
    t.section("dialogue branching")
    var state = _state()
    var kesh := DialogueGraph.load_graph("res://data/dialogue/kesh.json")
    t.ok(kesh != null, "kesh's graph loads")
    if kesh == null:
        return

    state.reset()
    t.eq(kesh.resolve("start"), "cold_open", "before Wren explains anything, Kesh brushes you off")

    state.set_flag("wren_told_about_cup", true)
    t.eq(kesh.resolve("start"), "challenge", "once you know about the Cup she challenges you")

    state.set_flag("kesh_match_done", true)
    state.set_flag("record_kesh_loss", 1)
    t.eq(kesh.resolve("post_match"), "first_rating",
        "an unranked player is put on the club ladder after their first rated game")
    state.set_rank("22k")
    t.eq(kesh.resolve("start"), "won", "after a loss she talks you through it")
    t.eq(kesh.resolve("post_match"), "won", "and the post-match entry point agrees")

    state.set_flag("record_kesh_loss", 0)
    state.set_flag("record_kesh_win", 1)
    t.eq(kesh.resolve("post_match"), "beaten", "after a win she is a great deal less pleased")
    state.set_flag("record_kesh_win", 2)
    t.eq(kesh.resolve("post_match"), "beaten_twice", "twice beaten is a different conversation again")

    var hana := DialogueGraph.load_graph("res://data/dialogue/hana.json")
    state.reset()
    state.set_rank("22k")
    t.eq(hana.resolve("start"), "too_early", "Hana wants to watch a game first")
    state.set_flag("kesh_match_done", true)
    t.eq(hana.resolve("start"), "first", "after a game she has something to teach")
    state.set_flag("hana_offered_puzzle", true)
    t.eq(hana.resolve("start"), "puzzle_again", "and will set the problem again")
    state.set_flag("capture_1_solved", true)
    t.eq(hana.resolve("start"), "after_puzzle", "solving it moves her on")

    var wren := DialogueGraph.load_graph("res://data/dialogue/wren.json")
    state.reset()
    state.set_rank("22k")
    t.eq(wren.resolve("start"), "first", "Wren introduces herself")
    state.set_flag("kesh_match_done", true)
    state.set_flag("record_kesh_win", 1)
    t.eq(wren.resolve("start"), "after_win", "and reacts to you beating Kesh")
    state.reset()


## Lessons are the part of this game that is most expensive to get wrong: a step
## that claims a group has one liberty when it has two teaches the opposite of
## the intended thing. Every step is checked against the real rules.
static func _test_lessons(t: TestKit) -> void:
    t.section("lesson data")
    var files := _list("res://data/lessons", ".json")
    t.ok(files.size() > 0, "there are lessons to validate")
    for path in files:
        var lesson_id := path.get_file().trim_suffix(".json")
        var l := GoLessonData.load_lesson(lesson_id)
        t.ok(l != null, "%s loads" % lesson_id)
        if l == null:
            continue
        t.ok(l.title != "" and l.step_count() > 0, "%s has a title and steps" % lesson_id)
        # The lesson panel gives a title two lines and no more.
        t.ok(l.title.length() <= 44,
            "%s: the title fits the panel (%d chars)" % [lesson_id, l.title.length()])
        # A step that tells the player to try something forbidden must build a
        # game in which it really is forbidden. tools/check_lessons.py proves the
        # position; this proves the engine agrees, which is what the player meets.
        for i in l.step_count():
            if not l.step_wants_refusal(i):
                continue
            var g := l.make_game(i)
            for point in l.steps[i]["points"]:
                t.ok(not g.is_legal(point),
                    "%s step %d: %s is refused by the rules, as the step claims"
                        % [lesson_id, i + 1, g.board.label(point)])
        t.ok(l.intro.size() > 0 and l.outro.size() > 0, "%s is framed by a teacher" % lesson_id)

        for i in l.step_count():
            var step: Dictionary = l.steps[i]
            var where := "%s step %d" % [lesson_id, i + 1]
            var g := l.make_game(i)
            t.eq(g.size(), l.size, "%s: board matches the declared size" % where)
            t.ok(str(step["instruction"]) != "", "%s: says what to do" % where)
            t.ok(str(step["explanation"]) != "", "%s: says what happened" % where)

            match int(step["accept"]):
                GoLessonData.Accept.POINTS:
                    t.ok(step["points"].size() > 0, "%s: lists its answers" % where)
                    for point in step["points"]:
                        t.ok(g.is_legal(point), "%s: answer %s is legal" % [where, g.board.label(point)])
                        t.ok(l.step_accepts(i, point, true, 0), "%s: answer is accepted" % where)
                GoLessonData.Accept.CAPTURE:
                    # Some move must actually capture, and the marked group must
                    # really be down to its last liberty.
                    var found := false
                    for point in g.legal_moves():
                        var probe := g.board.duplicate_board()
                        if probe.place(point, g.to_move).size() > 0:
                            found = true
                            break
                    t.ok(found, "%s: a capturing move exists" % where)
                    for point in step["target"]:
                        t.ok(g.board.get_idx(point) != GoBoard.EMPTY,
                            "%s: target %s holds a stone" % [where, g.board.label(point)])
                        if g.board.get_idx(point) != GoBoard.EMPTY:
                            t.eq(g.board.chain_at(point)["liberties"].size(), 1,
                                "%s: target group is in atari" % where)
                GoLessonData.Accept.ILLEGAL_ATTEMPT:
                    t.ok(step["points"].size() > 0, "%s: names the forbidden point" % where)
                    for point in step["points"]:
                        t.ok(not g.is_legal(point),
                            "%s: %s really is illegal" % [where, g.board.label(point)])
                        t.ok(l.step_accepts(i, point, false, 0),
                            "%s: the refusal is what completes the step" % where)
                _:
                    t.ok(g.legal_moves().size() > 0, "%s: some legal move exists" % where)


## Every lesson's teacher must have something to say when it ends.
##
## World._post_lesson() enters `taught_<lesson>`, falling back to `taught`. If
## neither exists, DialogueGraph.resolve() returns "" and DialogueBox.run emits
## `end` without ever showing a box -- the teacher simply says nothing, with no
## error and no failing test. Four of eleven lessons shipped like that: Kesh's
## escape and connection, Bertie's ladders and Tomas's counting.
##
## This is the same rule as the `start_match` / `post_match` check above, one
## seam over. That one exists because the shape had already cost three silent
## bugs; this one exists because it then cost four more.
static func _test_lessons_have_a_close(t: TestKit) -> void:
    t.section("every lesson is closed by its teacher")
    for path in _list("res://data/lessons", ".json"):
        var lesson_id := path.get_file().trim_suffix(".json")
        var l := GoLessonData.load_lesson(lesson_id)
        if l == null:
            continue
        t.ok(l.teacher != "", "%s names a teacher" % lesson_id)
        if l.teacher == "":
            continue
        var graph_path := "res://data/dialogue/%s.json" % l.teacher
        t.ok(FileAccess.file_exists(graph_path),
            "%s: teacher '%s' has a dialogue graph" % [lesson_id, l.teacher])
        if not FileAccess.file_exists(graph_path):
            continue
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(graph_path))
        if not (parsed is Dictionary):
            continue
        var nodes: Dictionary = parsed.get("nodes", {})
        t.ok(nodes.has("taught_%s" % lesson_id) or nodes.has("taught"),
            "%s: %s has a 'taught_%s' or 'taught' node to end it on"
                % [lesson_id, l.teacher, lesson_id])


## The tracks are GDScript constants, so a typo in one is silent at run time --
## the same failure hana_teaching cost when nothing checked the reverse direction
## for opponent profiles. These are the only names by which four lessons and all
## eight puzzles are reached at all.
## The tracks are GDScript constants, so a typo in one is silent at run time --
## the same failure hana_teaching cost when nothing checked the reverse direction
## for opponent profiles. These are the only names by which four lessons and all
## eight puzzles are reached at all.
##
## Read off the script rather than named directly: MatchBridge is an autoload,
## and an autoload is not resolvable as a plain identifier in a `--script` run --
## the same reason dialogue_graph.gd looks its own up by path.
static func _script_const(path: String, name: String) -> Array:
    var s := load(path) as GDScript
    if s == null:
        return []
    return s.get_script_constant_map().get(name, [])


## Lessons and puzzles reached by a GDScript constant rather than by dialogue.
## A written list, for the reason _reached_by_event() is derived: a thing reachable only
## from code should be a decision somebody made, not an oversight nobody noticed.
const LESSONS_REACHED_BY_TRACK := ["self_capture", "openings", "two_eyes",
                                   "life_and_death", "capture_race", "false_eyes"]
const PUZZLES_REACHED_BY_TRACK := ["capture_1", "capture_2", "capture_3", "capture_4",
                                   "escape_1", "escape_2", "live_1", "live_2",
                                   "capture_5", "escape_3", "live_3", "connect_1"]


static func _test_lessons_and_puzzles_reachable(t: TestKit) -> void:
    t.section("every lesson and puzzle can be reached")
    # Forwards: a constant naming a file that does not exist is a lesson or a
    # class that silently does nothing when the player asks for it.
    const BRIDGE := "res://src/autoload/match_bridge.gd"
    const WORLD := "res://src/rpg/world.gd"
    const DESK := "res://src/rpg/sign_desk.gd"
    var tracks := {
        "MatchBridge.TUTORIAL_TRACK": _script_const(BRIDGE, "TUTORIAL_TRACK"),
        "World.CLASS_TRACK": _script_const(WORLD, "CLASS_TRACK"),
    }
    for track_name in tracks:
        var ids: Array = tracks[track_name]
        t.ok(ids.size() > 0, "%s is readable and not empty" % track_name)
        for lesson_id in ids:
            t.ok(FileAccess.file_exists("res://data/lessons/%s.json" % lesson_id),
                "%s names a real lesson ('%s')" % [track_name, lesson_id])
    var puzzle_tracks := {
        "SignDesk.PUZZLE_TRACK": _script_const(DESK, "PUZZLE_TRACK"),
        "World.EXAM_PAPER": _script_const(WORLD, "EXAM_PAPER"),
    }
    for track_name in puzzle_tracks:
        var ids: Array = puzzle_tracks[track_name]
        t.ok(ids.size() > 0, "%s is readable and not empty" % track_name)
        for puzzle_id in ids:
            t.ok(FileAccess.file_exists("res://data/puzzles/%s.json" % puzzle_id),
                "%s names a real puzzle ('%s')" % [track_name, puzzle_id])

    # Backwards: a lesson or puzzle nothing names is a file that loads, is never
    # wrong, and never happens.
    var named_lessons := {}
    var named_puzzles := {}
    for path in _list("res://data/dialogue", ".json"):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (parsed is Dictionary):
            continue
        var nodes: Dictionary = parsed.get("nodes", {})
        for key in nodes.keys():
            for exit in _exits(nodes[key]):
                if exit.has("lesson"):
                    named_lessons[str(exit["lesson"])] = true
                if exit.has("puzzle"):
                    named_puzzles[str(exit["puzzle"])] = true
    for path in _list("res://data/lessons", ".json"):
        var lesson_id := path.get_file().trim_suffix(".json")
        t.ok(named_lessons.has(lesson_id) or LESSONS_REACHED_BY_TRACK.has(lesson_id),
            "lesson %s is reachable: some dialogue teaches it, or a track lists it" % lesson_id)
    for path in _list("res://data/puzzles", ".json"):
        var puzzle_id := path.get_file().trim_suffix(".json")
        t.ok(named_puzzles.has(puzzle_id) or PUZZLES_REACHED_BY_TRACK.has(puzzle_id),
            "puzzle %s is reachable: some dialogue sets it, or a track lists it" % puzzle_id)


## Nodes no path can arrive at. _test_dialogue checks that every `goto` resolves;
## nothing checked the other direction, which is how pip.json's `capture_go` -- a
## whole written paragraph where Pip works out you have been getting the rules off
## Wren -- has sat unreachable since the prologue.
##
## Entry points are `start` plus the nodes the world enters graphs at directly.
const GRAPH_ENTRIES := ["start", "post_match", "taught"]

## Written down rather than fixed: the intended entry condition for this one is
## not obvious from the file, so it wants whoever wrote the prologue rather than a
## guess from whoever next runs the tests. ROADMAP section 8.
const KNOWN_ORPHANS := {"res://data/dialogue/pip.json": ["capture_go"]}


static func _test_no_orphan_nodes(t: TestKit) -> void:
    t.section("every dialogue node can be reached")
    for path in _list("res://data/dialogue", ".json"):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (parsed is Dictionary):
            continue
        var nodes: Dictionary = parsed.get("nodes", {})
        var seen := {}
        var queue: Array = []
        for entry in GRAPH_ENTRIES:
            if nodes.has(entry):
                queue.append(entry)
        # Plus any per-lesson close, which World._post_lesson enters by name.
        for key in nodes.keys():
            if str(key).begins_with("taught_"):
                queue.append(str(key))
        while not queue.is_empty():
            var id: String = queue.pop_back()
            if seen.has(id) or not nodes.has(id):
                continue
            seen[id] = true
            for target in _gotos(nodes[id]):
                queue.append(target)
        var allowed: Array = KNOWN_ORPHANS.get(path, [])
        for key in nodes.keys():
            t.ok(seen.has(key) or allowed.has(str(key)),
                "%s: '%s' is reachable from an entry point" % [path, key])


## Every item asked about is an item somebody hands over.
##
## There is no item registry -- `GameState.inventory` is a bare Array[String] --
## so an id exists only because two files spell it the same way. `give_item` and
## `take_item` both no-op silently on a miss and `has_item` just answers false,
## which means a typo in a `take` leaves the player holding a book the graph has
## already thanked them for returning. Nothing in the project would have said so.
static func _test_items_round_trip(t: TestKit) -> void:
    t.section("items")
    var given := {}
    var wanted := {}          # id -> "path: node"
    for path in _list("res://data/dialogue", ".json"):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (parsed is Dictionary):
            continue
        var nodes: Dictionary = parsed.get("nodes", {})
        for key in nodes.keys():
            var node: Dictionary = nodes[key]
            for a in _actions(node):
                if not (a is Array) or a.size() < 2:
                    continue
                if str(a[0]) == "give":
                    given[str(a[1])] = true
                elif str(a[0]) == "take":
                    wanted[str(a[1])] = "%s: '%s' takes it" % [path, key]
            for c in _conditions(node):
                if c is Array and c.size() >= 2 and str(c[0]) == "has_item":
                    wanted[str(c[1])] = "%s: '%s' asks for it" % [path, key]
    t.ok(given.size() > 0, "some dialogue gives the player something")
    for item in wanted.keys():
        t.ok(given.has(item),
            "item '%s' is given by some dialogue (%s)" % [item, wanted[item]])


## Quest steps that can never be reached are a quest that stops.
##
## `QuestTracker._matches` tests only the *current* step, and it compares the
## step's `type` against the event's by string. A step with a misspelt type, or
## naming a puzzle, lesson or map that does not exist, matches nothing for the
## life of the save -- no error, no warning, and the journal simply stops moving.
## Quests had only a load check before M32.
##
## Nothing here can validate a `flag` key, because a flag is created by being
## set; the honest guard for those is that the graph setting them is tested.
const QUEST_EVENTS := ["flag", "talk", "match", "puzzle", "lesson", "enter_map"]

## Match contexts a quest may wait on that no dialogue exit names, because a
## tournament round picks its own. Empty, and deliberately a written list rather
## than a blanket exemption -- the same idiom as the allow-lists above.
const QUEST_CONTEXTS_BY_EVENT: Array = []


static func _test_quest_targets(t: TestKit) -> void:
    t.section("quest targets")
    var contexts := {}
    var npcs := {}
    for path in _list("res://data/dialogue", ".json"):
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (parsed is Dictionary):
            continue
        npcs[str(parsed.get("id", path.get_file().trim_suffix(".json")))] = true
        for key in parsed.get("nodes", {}).keys():
            for exit in _exits(parsed["nodes"][key]):
                if exit.has("context"):
                    contexts[str(exit["context"])] = true
    var paths := _list("res://data/quests", ".tres")
    t.ok(paths.size() > 0, "there are quests to validate")
    for path in paths:
        var quest = ResourceLoader.load(path)
        if not (quest is QuestData):
            continue
        t.ok(quest.steps.size() > 0, "%s has steps" % path)
        for i in quest.steps.size():
            var step: Dictionary = quest.steps[i]
            t.ok(str(step.get("journal", "")) != "",
                "%s step %d says what to do" % [path, i])
            var cond: Dictionary = step.get("advance_on", {})
            var kind := str(cond.get("type", ""))
            t.ok(QUEST_EVENTS.has(kind),
                "%s step %d advances on an event the tracker emits ('%s')" % [path, i, kind])
            match kind:
                "puzzle":
                    t.ok(FileAccess.file_exists("res://data/puzzles/%s.json" % str(cond.get("id", ""))),
                        "%s step %d names a real puzzle ('%s')" % [path, i, str(cond.get("id", ""))])
                "lesson":
                    t.ok(FileAccess.file_exists("res://data/lessons/%s.json" % str(cond.get("id", ""))),
                        "%s step %d names a real lesson ('%s')" % [path, i, str(cond.get("id", ""))])
                "enter_map":
                    t.ok(FileAccess.file_exists("res://data/maps/%s.json" % str(cond.get("map", ""))),
                        "%s step %d names a real map ('%s')" % [path, i, str(cond.get("map", ""))])
                "talk":
                    t.ok(npcs.has(str(cond.get("npc", ""))),
                        "%s step %d names somebody with a graph ('%s')" % [path, i, str(cond.get("npc", ""))])
                "match":
                    var ctx := str(cond.get("context", ""))
                    t.ok(contexts.has(ctx) or QUEST_CONTEXTS_BY_EVENT.has(ctx),
                        "%s step %d waits on a game some dialogue starts ('%s')" % [path, i, ctx])


## The journal shows the quest you took on most recently.
##
## It used to show `active_quest_ids()[0]` against the order DirAccess handed
## back the .tres files, so which objective the player could see was decided by
## filename. A quest started after `enrolment` that sorted after it was invisible
## for as long as the older quest ran -- found by opening a
## screenshot, which is how all of these are found, and guarded here so it stays
## found.
static func _test_journal_order(t: TestKit) -> void:
    t.section("journal order")
    var state = _state()
    var quests = (Engine.get_main_loop() as SceneTree).root.get_node("Quests")
    # test_runner.gd works from `_initialize()`, which runs before any autoload's
    # `_ready()` -- so the tracker's registry is still empty here and every quest
    # id would look unknown. Load it the way the game does, once.
    if quests.quests.is_empty():
        quests._load_all()
    t.ok(quests.quests.has("beginner_cup"), "the tracker knows the quest exists")
    state.reset()
    t.eq(quests.active_quest_ids(), [], "nothing started")
    t.eq(quests.journal_quest_id(), "", "and nothing in the journal")
    state.set_quest("enrolment", 1, false)
    state.set_quest("beginner_cup", 0, false)
    var active: Array = quests.active_quest_ids()
    t.eq(active.size(), 2, "both are running")
    t.eq(str(active[active.size() - 1]), "beginner_cup",
        "the one taken on later is last")
    t.eq(quests.journal_quest_id(), "beginner_cup",
        "and is the one the journal shows")
    state.set_quest("beginner_cup", 0, true)
    t.eq(quests.active_quest_ids(), ["enrolment"],
        "and finishing it hands the journal back to the older one")

    # The same pair started the other way round. Without this the guard proves
    # nothing: these two happen to sort alphabetically into the order they are
    # started in, so the broken version -- ordering by the .tres filenames --
    # passes the assertions above by coincidence.
    state.reset()
    state.set_quest("beginner_cup", 0, false)
    state.set_quest("enrolment", 1, false)
    active = quests.active_quest_ids()
    t.eq(str(active[active.size() - 1]), "enrolment",
        "order comes from when a quest was started, not from its filename")
    t.eq(quests.journal_quest_id(), "enrolment", "and the journal follows it")
    state.reset()
