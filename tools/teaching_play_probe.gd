## Explicit prepared-position acceptance through real controls and the real worker.
class_name TeachingPlayProbe
extends RefCounted

class LineOpponent extends GoOpponent:
    var teaching: LiveTeaching
    func choose_move(_game: GoGame) -> Dictionary:
        var line: Array = teaching._reply_facts.get("refutation", [])
        return GoOpponent.point_move(int(line[0]["point"])) if not line.is_empty() else GoOpponent.pass_move()


static func run(tree: SceneTree, spec: Dictionary, shot: Callable) -> void:
    var npc := str(spec.get("npc", "wren"))
    var mouse := bool(spec.get("mouse", false))
    var normally := bool(spec.get("normally", false))
    var keep := bool(spec.get("keep", false))
    var world := tree.current_scene
    var person: Npc = world._find_npc(npc)
    var request := MatchRequest.new()
    request.profile = load(OpponentProfile.path_for(npc, 9, "first" if npc == "kesh" else ""))
    request.npc_id = npc
    request.opponent_name = request.profile.display_name
    request.opponent_rank = request.profile.rank_label
    request.context_id = npc + "_first"
    request.practice = true
    request.unrated = true
    request.player_strength = 0 if npc == "kesh" else -1
    request.portrait_path = "res://art/portraits/%s.png" % npc
    tree.root.get_node("MatchBridge").start_match(request, world.player.position)
    var deadline := Time.get_ticks_msec() + 45000
    var scene: Control
    var chosen := false
    while Time.get_ticks_msec() < deadline:
        scene = tree.current_scene as Control
        if scene == null or not scene.has_method("is_player_turn_ready"):
            await tree.process_frame
            continue
        if scene.is_player_turn_ready():
            break
        for child in scene.get_children():
            if child is TeachingChoice and not chosen:
                await shot.call(npc + "_teaching_choice")
                await _choose(tree, 1 if normally else 0, mouse)
                chosen = true
            elif child is BoardBrief or child is HandicapHelp:
                await ExperienceProbe.press(tree, "cancel")
        await tree.process_frame
    if scene == null or not scene.has_method("is_player_turn_ready") or not scene.is_player_turn_ready():
        BoardPlayProbe.fail(tree, "Teaching practice did not start")
        return
    if normally:
        if scene._live.active or scene._live.worker.queries_sent != 0:
            BoardPlayProbe.fail(tree, "Ordinary practice started teaching queries")
            return
        await shot.call(npc + "_normal_practice")
        await _finish(tree)
        return
    var game: GoGame
    if npc == "wren":
        var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/review/wren-played.json"))
        var replay := MatchAnalysis.replay(record["sgf"])
        game = GoGame.new(9, 5.5)
        for move: Dictionary in replay["moves"].slice(0, 28):
            game.play(int(move["point"]))
    else:
        # This is a prepared handicap teaching position, not a game played by the probe.
        game = GoGame.new(9, 0.5, 5)
        var cells := game.board.cells.duplicate()
        for label in ["F2"]:
            cells[game.board.from_label(label)] = GoBoard.BLACK
        for label in ["E2", "F3", "G1", "H2", "G4", "H3", "H4", "F4"]:
            cells[game.board.from_label(label)] = GoBoard.WHITE
        game.set_position(cells, GoBoard.BLACK)
    scene.game = game
    if bool(spec.get("note_fixture", false)):
        scene.opponent.shutdown()
        var reply := LineOpponent.new()
        reply.teaching = scene._live
        scene.opponent = reply
        print("TEACHING NOTE FIXTURE: scripted PV reply; not an independently chosen Wren move")
    scene.board_view.set_game(game)
    scene._refresh()
    var actual := game.board.from_label("J9")
    var before := TeachingPosition.key(game)
    var engine_moves: int = scene.opponent._synced_moves if scene.opponent is GtpOpponent else -1
    deadline = Time.get_ticks_msec() + 15000
    while not scene._live.worker.cached_for(game) and Time.get_ticks_msec() < deadline:
        await tree.process_frame
    if not scene._live.worker.cached_for(game):
        BoardPlayProbe.fail(tree, "Teaching position did not prefetch")
        return
    await shot.call(npc + "_before_abandonment")
    if mouse:
        await BoardPlayProbe.perform(tree, {"click": [8,0]})
    else:
        await BoardPlayProbe.place(tree, actual)
    deadline = Time.get_ticks_msec() + 3000
    while tree.root.find_child("TeachingChoice", true, false) == null and Time.get_ticks_msec() < deadline:
        await tree.process_frame
    var choice := tree.root.find_child("TeachingChoice", true, false) as TeachingChoice
    if choice == null:
        BoardPlayProbe.fail(tree, "No teaching question; ms=%d" % scene._live.worker.comparison_ms)
        return
    print("TEACHING PLAY comparison_ms=%d npc=%s" % [scene._live.worker.comparison_ms, npc])
    await shot.call(npc + "_question")
    var provisional := TeachingPosition.key(scene.game)
    scene._on_point_activated(0)
    await BoardPlayProbe.tap(tree, "go_pass")
    await BoardPlayProbe.tap(tree, "go_resign")
    if TeachingPosition.key(scene.game) != provisional or (scene.opponent is GtpOpponent and scene.opponent._synced_moves != engine_moves):
        BoardPlayProbe.fail(tree, "Question allowed input or sent provisional move to GTP")
        return
    await _choose(tree, 1 if keep else 0, mouse)
    if not keep:
        await tree.process_frame
        if TeachingPosition.key(scene.game) != before:
            BoardPlayProbe.fail(tree, "Undo did not restore exact game")
            return
        await shot.call(npc + "_undone")
        # Retry the same decision: no repeat question and only the retained move reaches GTP.
        deadline = Time.get_ticks_msec() + 10000
        while not scene._live.worker.cached_for(game) and Time.get_ticks_msec() < deadline:
            await tree.process_frame
        await BoardPlayProbe.place(tree, actual)
    deadline = Time.get_ticks_msec() + 15000
    while not scene.is_player_turn_ready() and Time.get_ticks_msec() < deadline:
        if tree.root.find_child("TeachingChoice", true, false) != null:
            BoardPlayProbe.fail(tree, "Undo retry repeated question")
            return
        await tree.process_frame
    await shot.call(npc + "_retained_reply")
    await ExperienceProbe.press(tree, "go_help")
    await shot.call(npc + "_help_menu")
    var menu := tree.root.find_child("TeachingChoice", true, false) as TeachingChoice
    if menu == null:
        BoardPlayProbe.fail(tree, "Help menu missing")
        return
    if menu.options.has("Last explanation"):
        await _choose(tree, menu.options.find("Last explanation"), mouse)
        await shot.call(npc + "_reopened_note")
        await ExperienceProbe.press(tree, "cancel")
        await ExperienceProbe.press(tree, "go_help")
        menu = tree.root.find_child("TeachingChoice", true, false) as TeachingChoice
    if menu.options.has("Handicap stones"):
        await _choose(tree, menu.options.find("Handicap stones"), mouse)
        await shot.call(npc + "_handicap_help")
        await ExperienceProbe.press(tree, "cancel")
        await ExperienceProbe.press(tree, "go_help")
        menu = tree.root.find_child("TeachingChoice", true, false) as TeachingChoice
    var off := menu.options.find("Turn teaching off")
    await _choose(tree, off, mouse)
    if scene._live.active or scene._live.worker._pipe.is_open():
        BoardPlayProbe.fail(tree, "Teaching off did not close worker")
        return
    await shot.call(npc + "_teaching_off")
    await _finish(tree)


static func _choose(tree: SceneTree, index: int, mouse: bool) -> void:
    if mouse:
        await BoardPlayProbe.click_button(tree, "option_%d" % index)
    else:
        for i in index:
            await ExperienceProbe.press(tree, "move_down")
        await ExperienceProbe.press(tree, "interact")


static func _finish(tree: SceneTree) -> void:
    await ExperienceProbe.press(tree, "go_resign")
    await ExperienceProbe.press(tree, "go_resign")
    await tree.create_timer(0.3).timeout
