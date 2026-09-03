## Content validation: every data file the game ships must load and resolve.
class_name GoDataTests
extends RefCounted


static func run(t: TestKit) -> void:
    _test_dialogue(t)
    _test_resources(t)
    _test_puzzles(t)
    _test_maps(t)
    _test_dialogue_branches(t)
    _test_lessons(t)


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
        t.ok(p.kind in ["capture", "live", "escape"],
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
        # every tile character must exist in the atlas
        for y in m.height:
            for x in m.width:
                var tile_name := m.tile_name_at(m.ground, x, y)
                if tile_name != "":
                    t.ok(TileAtlas.at(tile_name).x >= 0,
                        "%s: tile '%s' at %d,%d is in the atlas" % [map_id, tile_name, x, y])


## The rival's lines must actually change with the result -- that is the whole
## point of the encounter, and a broken branch would be silent otherwise.
static func _test_dialogue_branches(t: TestKit) -> void:
    t.section("dialogue branching")
    var state: Node = (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
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
