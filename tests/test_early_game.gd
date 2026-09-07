class_name EarlyGameTests
extends RefCounted


static func run(t: TestKit) -> void:
    t.section("finishing uses real game actions and scoring")
    for id in ["finishing", "counting"]:
        var lesson := GoLessonData.load_lesson(id)
        for i in lesson.step_count():
            var game := lesson.make_game(i)
            var step: Dictionary = lesson.steps[i]
            var actions := GoLessonActions.new()
            actions.setup(game, step)
            if step["action"] == "pass":
                t.ok(actions.pass_and_reply(), "two passes reach counting")
                t.eq(game.state, GoGame.State.SCORING, "real scoring phase")
            elif step["action"] == "count":
                var expected: Array = step["expected_score"]
                t.eq(actions.current_score()["black"], float(expected[0]), "Black count")
                t.eq(actions.current_score()["white"], float(expected[1]), "White count")
                t.ok(not actions.accept_count(), "inspect mark before confirmation")
                for other in game.board.cells.size():
                    if not game.board.is_empty(other) and not actions.dead.has(other):
                        actions.activate(other)
                        actions.activate(other)
                        break
                t.ok(not actions.accept_count(), "toggling an unrelated group cannot skip the marked-group comparison")
                var point: int = actions.dead.keys()[0]
                actions.activate(point)
                t.ok(actions.current_score()["black"] != float(expected[0]), "unmarking changes score")
                t.ok(not actions.accept_count(), "incorrect mark cannot finish example")
                actions.activate(point)
                t.ok(actions.accept_count(), "restored example can finish")
            for proof in step["proofs"]:
                var position := lesson.make_game(i)
                var outcome := GoLessonActions.demonstrate(position, proof)
                for legal in outcome["legal"]:
                    t.eq(legal, not bool(proof.get("refused", false)), "each authored continuation is legal or refused as claimed")
                if proof.has("captured"):
                    t.eq(outcome["captured"], int(proof["captured"]), "authored capture proof")
    _test_presentation(t)
    t.section("practice observations describe an existing group")
    var game := GoGame.new(7)
    var empty := PracticeGuide.observation(game, GoBoard.BLACK)
    t.ok(empty["stones"].is_empty(), "empty board has no invented group")
    t.ok(empty["text"].contains("empty"), "empty board guidance names its state")
    game.play(16)
    game.play(32)
    t.ok(PracticeGuide.observation(game, GoBoard.BLACK)["stones"].is_empty(), "no invented atari target")
    var board := GoBoard.from_ascii(".......\n..X....\n.XO....\n..X....\n.......\n.......\n.......")
    game.set_position(board.cells)
    var advice := PracticeGuide.observation(game, GoBoard.BLACK)
    t.ok(advice["stones"].has(16), "one-liberty enemy is highlighted")
    t.ok(advice["text"].contains("D5"), "actual capture liberty is named")
    game.to_move = GoBoard.BLACK
    game.ko_point = 17
    var blocked_capture := PracticeGuide.observation(game, GoBoard.BLACK)
    t.ok(blocked_capture["stones"].is_empty(), "a ko-refused capture is not recommended")
    t.ok(not blocked_capture["text"].contains("No group"), "general advice does not deny an existing ko group's atari")
    game.ko_point = -1
    var own := PracticeGuide.observation(game, GoBoard.WHITE)
    t.ok(own["stones"].has(16), "own one-liberty group is highlighted")
    t.ok(own["prompt"].contains("one liberty"), "persistent guide names a real atari")
    _test_compatibility(t)
    _test_record_once(t)


static func _test_compatibility(t: TestKit) -> void:
    t.section("early revision preserves old progress")
    var tree := Engine.get_main_loop() as SceneTree
    var state := tree.root.get_node("GameState")
    var quests := tree.root.get_node("Quests")
    var cases := [
        [{}, 0],
        [{"lesson_liberties_done": true}, 0],
        [{"knows_the_rules": true, "wren_match_done": true}, 0],
        [{"hana_offered_puzzle": true}, 2],
        [{"enrolled": true}, 4],
        [{"enrolled": true, "read_league_board": true, "played_a_novice_game": true}, 5],
    ]
    for entry in cases:
        state.reset()
        state.flags = entry[0].duplicate()
        state.set_rank("28k")
        state.set_quest("enrolment", 1, false)
        state.match_records = [{"context_id": "wren_first", "player_won": false}]
        var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
        state.from_dict(saved)
        quests._reconcile_all()
        t.eq(state.quest_step("enrolment"), entry[1], "legacy journal follows durable facts")
        t.eq(state.rank_label(), "28k", "migration preserves rank")
        t.eq(state.match_records.size(), 1, "migration preserves history")
        t.ok(not state.has_flag("capture_1_solved"), "migration invents no puzzle completion")
        for flag in entry[0]:
            t.ok(state.has_flag(flag), "migration preserves " + flag)
        var snapshot: Dictionary = state.to_dict().duplicate(true)
        quests._reconcile_all()
        t.eq(state.to_dict(), snapshot, "migration is repeatable without changes")
    state.reset()
    state.flags = {"early_game_revision": 2, "knows_the_rules": true, "lesson_first_game_rules_done": true}
    state.set_quest("first_stones", 2, false)
    quests._reconcile_all()
    t.ok(not state.has_flag("finishing_skipped"), "new partial teaching save still offers finishing")
    t.ok(state.has_flag("lesson_first_game_rules_done"), "new save keeps completed exercises")
    state.flags = {"enrolled": true}
    state.set_quest("enrolment", 6, true)
    quests._reconcile_all()
    t.ok(state.quest_done("enrolment"), "completed old quest stays complete")
    state.reset()


static func _test_record_once(t: TestKit) -> void:
    t.section("review requests never replay match consequences")
    var tree := Engine.get_main_loop() as SceneTree
    var state := tree.root.get_node("GameState")
    var bridge := tree.root.get_node("MatchBridge")
    state.reset()
    state.set_rank("30k")
    var result := MatchResult.new()
    result.npc_id = "noor"
    result.context_id = "practice_noor"
    result.player_won = true
    result.opponent_strength = GoRank.from_string("30k")
    result.sgf = "(;GM[1]SZ[9]KM[5.5];B[cc];W[gg];B[];W[])"
    result.move_count = 4
    var index: int = bridge.record_completed_match(result)
    var rank: int = state.rank_strength
    t.eq(bridge.record_completed_match(result), index, "duplicate callback returns same record")
    t.eq(state.match_records.size(), 1, "duplicate callback records once")
    for availability in ["pending", "available", "steady"]:
        state.match_analysis[str(index)] = {"availability": availability}
        for repeat in 2:
            t.ok(bridge.request_review(index), "existing review can be opened")
            t.eq(state.match_records.size(), 1, "review keeps one record")
            t.eq(state.rank_strength, rank, "review cannot advance rank")
    t.ok(not bridge.request_review(-1), "invalid review index is rejected")
    var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
    state.from_dict(saved)
    t.ok(bridge.request_review(index), "saved review is reopened by index")
    t.eq(state.match_records.size(), 1, "reload and review keep one record")
    t.eq(state.rank_strength, rank, "reload and review preserve rank")
    var service := tree.root.get_node("MatchReviewService")
    state.match_analysis[str(index)] = MatchAnalysis.pending(index)
    service._index = index
    service._runner = KataGoAnalysis.new()
    var pending_save: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
    state.from_dict(pending_save)
    t.ok(not service.is_running(), "loading cancels the old session's analysis")
    t.eq(state.match_analysis[str(index)]["reason"], "interrupted", "saved pending analysis is honestly interrupted")
    t.eq(state.match_records.size(), 1, "interrupted reload records no second result")
    t.eq(state.rank_strength, rank, "interrupted reload preserves rank")
    var rematch := MatchResult.new()
    rematch.npc_id = "noor"
    rematch.unrated = true
    bridge.record_completed_match(rematch)
    t.eq(state.match_records.size(), 2, "a real rematch adds its own record")
    bridge.last_result = null
    bridge._committed_result = null
    bridge.last_record_index = -1
    state.reset()


static func _test_presentation(t: TestKit) -> void:
    t.section("lesson marks survive board resets and text blocks stay together")
    var lesson := GoLessonData.load_lesson("finishing")
    var actions := GoLessonActions.new()
    var board := GoBoardView.new()
    var game := lesson.make_game(3)
    actions.setup(game, lesson.steps[3])
    board.dead = actions.dead
    board.set_game(game)
    t.eq(actions.dead.size(), 1, "resetting the board cannot clear its owner's proposed mark")
    board.free()
    var advice := "Next time: inspect the group's empty neighbours before choosing a move."
    var blocks: Array[String] = ["This explanation needs a long first paragraph to use most of this small card before the next recommendation.", advice]
    var pages := ReviewComparison.pages(blocks, 178, 77)
    t.ok(pages.has(advice), "a fitting recommendation remains on one page")
    for page in pages:
        t.ok(UiKit.text_height(page, 178) <= 77, "paginated explanation fits measured area")
