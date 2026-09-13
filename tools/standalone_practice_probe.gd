## Serial acceptance through the real practice scenes, using disposable user data.
class_name StandalonePracticeProbe
extends RefCounted

static func perform(tree: SceneTree, route: String, shot: Callable) -> void:
    var probe := StandalonePracticeProbe.new()
    probe.tree = tree
    probe.shot = shot
    await probe.run(route)

var tree: SceneTree
var shot: Callable
var checks := 0
var failures := 0
var baseline: Dictionary
var slots: Array[String] = []

func run(route: String) -> void:
    SaveSystem.load_game(1)
    var title: Control = tree.current_scene
    title._index = 4
    title._activate()
    await scene("PracticeHub")
    baseline = GameState.to_dict().duplicate(true)
    for i in range(1, 4):
        slots.append(FileAccess.get_file_as_string(SaveSystem.path_for(i)) if SaveSystem.has_save(i) else "")
    await snap("01_practice_hub")
    check(MatchBridge.activity_context.standalone, "title enters independent context")
    if route == "engines":
        await engines()
    elif route == "layout":
        await layout()
    else:
        await core()
    check(GameState.to_dict() == baseline, "campaign memory including playtime unchanged")
    for i in range(1, 4):
        var contents := FileAccess.get_file_as_string(SaveSystem.path_for(i)) if SaveSystem.has_save(i) else ""
        check(contents == slots[i - 1], "campaign slot %d unchanged" % i)
    PracticeSession.leave()
    await scene("TitleScreen")
    await snap("99_title")
    check(not KettleNextProfile.practice_presentation, "practice presentation cleared on exit")
    print("PRACTICE ACCEPTANCE: %d checks, %d failures" % [checks, failures])
    if failures > 0: tree.quit(1)

func layout() -> void:
    var panel: PracticeSetupPanel = tree.current_scene.current
    panel.rank_slider.value = 29
    check(panel.rank_choice.get_item_text(panel.rank_choice.selected) == "1k", "rank slider reaches 1k")
    panel.rank_slider.value = 30
    check(panel.rank_choice.get_item_text(panel.rank_choice.selected) == "1d", "rank slider crosses into dan")
    panel.rank_slider.value = 34
    panel.handicap_choice.select(1)
    panel.handicap_choice.item_selected.emit(1)
    await snap("layout_automatic")
    check(PracticeSession.settings.resolve_setup().handicap == 5, "setup UI previews automatic handicap")
    panel.handicap_choice.select(2)
    panel.handicap_choice.item_selected.emit(2)
    panel.colour_choice.select(1)
    panel.colour_choice.item_selected.emit(1)
    await snap("layout_manual")
    check(PracticeSession.settings.resolve_setup().player_color == GoBoard.WHITE, "manual setup UI lets player give stones")
    click(panel, "Advanced settings")
    for control in panel.find_children("*", "OptionButton", true, false):
        if control.get_item_text(0) == "Standard":
            control.select(1)
            control.item_selected.emit(1)
    panel.komi_choice.value = 3.5
    check(panel.settings.resolve_setup().komi == 3.5, "advanced custom komi changes actual setup")
    await tree.process_frame
    var scroll: ScrollContainer = panel.get_child(0)
    scroll.ensure_control_visible(panel.komi_choice)
    await snap("layout_custom_komi")
    for i in 2:
        var result := MatchResult.new()
        result.summary = "Neither player captured a stone." if i == 0 else "White wins by 35.5"
        result.board_size = 7 if i == 0 else 9
        result.opponent_name = "Practice AI"
        result.unrated = true
        result.sgf = "(;GM[1]FF[4]SZ[9]KM[5.5];B[cc];W[gg])"
        var record := result.to_dict()
        var fixture_settings := PracticeSettings.new()
        fixture_settings.mode = "capture" if i == 0 else "ordinary"
        record["settings"] = fixture_settings.to_dict()
        record["date"] = "2026-09-13 22:35:00"
        PracticeSession.store.complete("layout_%d" % i, record)
    tree.current_scene.show_tab("History")
    await snap("layout_history")
    check(tree.current_scene.content.size.x <= 368.1, "history keeps content within viewport")
    tree.current_scene.show_tab("Learn")
    await snap("layout_library")

func core() -> void:
    tree.current_scene.show_tab("Learn")
    await snap("02_library")
    PracticeSession.start_lesson("first_game_rules")
    await scene("GoLesson")
    await snap("03_lesson")
    tree.current_scene.context.set_flag("lesson_first_game_rules_done", true)
    tree.current_scene.context.lesson_finished.call("first_game_rules", true)
    await scene("PracticeHub")
    PracticeSession.start_puzzle("capture_1")
    await scene("GoPuzzle")
    await snap("04_puzzle")
    var puzzle_scene: Control = tree.current_scene
    for point: int in puzzle_scene.puzzle.solutions:
        if puzzle_scene.game.is_legal(point):
            puzzle_scene._on_point(point)
            break
    await tree.process_frame
    check(puzzle_scene._finished, "puzzle solution completed in real scene")
    puzzle_scene._unhandled_input(MouseActions.event(&"interact"))
    await scene("PracticeHub")
    PracticeSession.settings.mode = "capture"
    tree.current_scene.show_tab("Play")
    await snap("05_capture_setup")
    PracticeSession.start_game()
    await ready()
    var match_scene: Control = tree.current_scene
    check(match_scene.opponent is CaptureOpponent, "Capture Go uses its stated engine")
    await snap("06_capture_game")
    match_scene._mouse_action(&"go_help")
    await tree.create_timer(0.15).timeout
    await snap("07_capture_help")
    close_brief(match_scene)
    await tree.process_frame
    match_scene._mouse_action(&"go_pass")
    await scene("PracticeHub")
    check(PracticeSession.store.data.records.size() == 1, "neutral Capture Go recorded once")
    check(PracticeSession.store.data.records[0].practice_ended, "two passes are neutral")
    await snap("08_capture_result")
    click(tree.current_scene, "Replay")
    await snap("09_capture_replay")
    for child in tree.current_scene.get_children():
        if child is PracticeReplay: child.queue_free()
    await tree.process_frame
    # A real ranked engine game supplies suspend, takeback and history evidence.
    PracticeSession.settings = PracticeSettings.new()
    PracticeSession.settings.mode = "teaching"
    PracticeSession.settings.rank = 18
    PracticeSession.settings.avatar = "noor"
    PracticeSession.start_game()
    await ready()
    match_scene = tree.current_scene
    check(match_scene.opponent is GtpOpponent, "teaching game uses KataGo")
    await snap("10_teaching_board")
    match_scene._mouse_action(&"go_help")
    await tree.process_frame
    await snap("11_teaching_help")
    choose(match_scene, 1)
    await tree.process_frame
    var legal: PackedInt32Array = match_scene.game.legal_moves()
    match_scene._on_point_activated(legal[20])
    await ready()
    check(match_scene.game.moves.size() >= 2, "real engine replied")
    await snap("12_teaching_reply")
    var before := TeachingPosition.key(match_scene.game)
    match_scene._practice_action(&"leave")
    await tree.process_frame
    await snap("13_suspend_choice")
    choose(match_scene, 0)
    await scene("PracticeHub")
    var reload := PracticeStore.new()
    reload.read()
    check(not reload.data.active.is_empty(), "suspended game written to disk")
    check(TeachingPosition.key(PracticeSnapshot.restore(reload.data.active.snapshot)) == before, "disk snapshot preserves committed moves")
    await snap("14_resume_hub")
    PracticeSession.start_game(true)
    await ready()
    match_scene = tree.current_scene
    check(TeachingPosition.key(match_scene.game) == before, "resume reconstructs exact position")
    match_scene._practice_action(&"undo")
    await scene("PracticeMatch")
    await ready()
    match_scene = tree.current_scene
    check(match_scene.game.moves.is_empty(), "Undo removes player decision and AI reply")
    await snap("15_undo")
    match_scene._practice_action(&"hint")
    var deadline := Time.get_ticks_msec() + 35000
    while not match_scene._teaching.opened and Time.get_ticks_msec() < deadline:
        await tree.process_frame
    check(match_scene._teaching.opened, "hint opens beside live board")
    await snap("16_hint")
    close_brief(match_scene)
    await tree.process_frame
    match_scene._live.close()
    await play_to_count()
    if tree.current_scene.name == "PracticeMatch":
        match_scene = tree.current_scene
        await snap("17_counting")
        check(match_scene.game.state == GoGame.State.SCORING, "full game reaches counting")
        match_scene._mouse_action(&"go_pass")
    await scene("PracticeHub")
    await snap("18_full_result")
    click(tree.current_scene, "Export SGF")
    await snap("19_export")
    tree.current_scene.show_tab("History")
    await snap("20_history")

func engines() -> void:
    for size in PracticeSettings.SIZES:
        PracticeSession.settings = PracticeSettings.new()
        PracticeSession.settings.board_size = size
        PracticeSession.settings.mode = "teaching"
        PracticeSession.settings.rank = 34 if size == 19 else 10
        PracticeSession.start_game()
        await ready()
        var match_scene: Control = tree.current_scene
        check(match_scene.opponent is GtpOpponent, "%dx%d engine starts" % [size, size])
        await snap("engine_%d_board" % size)
        match_scene._practice_action(&"hint")
        var hint_deadline := Time.get_ticks_msec() + 25000
        while not match_scene._teaching.opened and Time.get_ticks_msec() < hint_deadline: await tree.process_frame
        check(match_scene.board_view.highlight.size() == 1, "%dx%d legal engine hint" % [size, size])
        await snap("engine_%d_hint" % size)
        close_brief(match_scene)
        await tree.process_frame
        match_scene._live.close()
        match_scene._on_point_activated(match_scene.game.board.idx(2, 2))
        await ready()
        check(match_scene.game.moves.size() == 2, "%dx%d legal engine reply" % [size, size])
        check(not match_scene.opponent.fallback_used, "%dx%d no fallback" % [size, size])
        await snap("engine_%d_reply" % size)
        match_scene._mouse_action(&"go_resign")
        match_scene._mouse_action(&"go_resign")
        await scene("PracticeHub")
        await snap("engine_%d_result" % size)
    var history: PracticeHistory = tree.current_scene.current
    history.open_review()
    tree.current_scene.show_tab("Learn")
    await snap("review_while_browsing")
    var deadline := Time.get_ticks_msec() + 120000
    while MatchReviewService.is_running() and Time.get_ticks_msec() < deadline:
        await tree.process_frame
    var payload: Dictionary = PracticeSession.store.data.reviews.get(str(PracticeSession.selected_record), {})
    check(payload.get("availability", "") in ["available", "steady"], "real review persisted outside campaign")
    tree.current_scene.show_tab("Result")
    history = tree.current_scene.current
    history.open_review()
    await snap("engine_review")
    for child in tree.current_scene.get_children():
        if child is ReviewCards: child._unhandled_input(MouseActions.event(&"cancel"))
    await tree.process_frame
    tree.current_scene.show_tab("History")
    await snap("engine_history")

func play_to_count() -> void:
    var brain := HeuristicOpponent.new()
    var profile := OpponentProfile.new()
    profile.mistake_rate = 0.05
    profile.reading_depth = 1
    brain.setup(profile, tree.current_scene.game)
    var deadline := Time.get_ticks_msec() + 300000
    while tree.current_scene.name == "PracticeMatch" and Time.get_ticks_msec() < deadline:
        var value: Control = tree.current_scene
        if value.is_counting(): return
        close_brief(value)
        if value.is_player_turn_ready():
            var move: Dictionary = await brain.choose_move(value.game)
            if move.type == "move" and value.game.moves.size() < 180:
                value._on_point_activated(int(move.point))
            else: value._mouse_action(&"go_pass")
        await tree.process_frame
    check(tree.current_scene.name != "PracticeMatch", "full game completes within deadline")

func ready() -> void:
    var deadline := Time.get_ticks_msec() + 40000
    while Time.get_ticks_msec() < deadline:
        var value: Node = tree.current_scene
        if value != null and value.name == "PracticeMatch" and value.is_player_turn_ready():
            await tree.process_frame
            return
        await tree.process_frame
    check(false, "player turn timeout")

func scene(expected: String) -> void:
    var deadline := Time.get_ticks_msec() + 15000
    while Time.get_ticks_msec() < deadline:
        if tree.current_scene != null and str(tree.current_scene.name) == expected and not SceneRouter.is_busy():
            await tree.process_frame
            return
        await tree.process_frame
    check(false, "scene timeout: " + expected)

func snap(name: String) -> void:
    await tree.create_timer(0.15).timeout
    await shot.call(name)

func check(ok: bool, text: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("PRACTICE: " + text)

func choose(parent: Node, index: int) -> void:
    for child in parent.get_children():
        if child is TeachingChoice: child.choose(index); return
    check(false, "expected choice")

func close_brief(parent: Node) -> void:
    for child in parent.get_children():
        if child is BoardBrief: child._input(MouseActions.event(&"cancel")); return

func click(parent: Node, text: String) -> void:
    for child in parent.find_children("*", "Button", true, false):
        if child.text == text: child.pressed.emit(); return
    check(false, "button exists: " + text)
