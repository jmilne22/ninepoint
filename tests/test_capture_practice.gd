class_name CapturePracticeTests
extends RefCounted


static func run(t: TestKit) -> void:
    _endings(t)
    _policy(t)
    _guidance(t)
    _records(t)


static func _position(color: int = GoBoard.BLACK) -> GoGame:
    var lesson := GoLessonData.load_lesson("pip_first_capture")
    var game := lesson.make_game(0)
    if color == GoBoard.WHITE:
        for point in game.board.cells.size():
            if not game.board.is_empty(point):
                game.board.cells[point] = GoBoard.opponent(game.board.get_idx(point))
        game.set_position(game.board.cells, color)
    game.capture_goal = 1
    return game


static func _endings(t: TestKit) -> void:
    t.section("first capture has no territory ending")
    for color in [GoBoard.BLACK, GoBoard.WHITE]:
        var game := _position(color)
        t.ok(not game.play(game.board.from_label("D4")), "occupied move refused")
        t.ok(game.play(game.board.from_label("D3")), "demonstration capture is legal")
        t.eq(game.result["winner"], color, "either colour wins by actual capture")
        t.ok(game.result["by_capture"], "capture is the terminal condition")
        var result := game.result.duplicate(true)
        game.pass_turn()
        game.resign()
        game.finish_with_score({"winner": GoBoard.opponent(color)})
        t.eq(game.result, result, "later terminal calls cannot replace the capture")
    for occupied in [false, true]:
        var game := _position() if occupied else GoGame.new(7, 0.5)
        game.capture_goal = 1
        game.pass_turn()
        t.eq(game.state, GoGame.State.PLAYING, "one pass still allows a reply")
        game.pass_turn()
        t.eq(game.state, GoGame.State.FINISHED, "two passes bypass counting")
        t.eq(game.result["winner"], GoBoard.EMPTY, "no komi winner")
        t.ok(game.result["practice_ended"], "neutral practice has explicit semantics")
        game.finish_with_score(GoScoring.score(game.board, {}, game.captures, game.komi))
        t.eq(game.result["winner"], GoBoard.EMPTY, "score payload cannot override variant")
        t.ok(game.undo(), "neutral ending can be undone by pure rules tools")
        t.eq(game.state, GoGame.State.PLAYING, "undo restores the one-pass position")
    var resigned := _position()
    resigned.resign(GoBoard.BLACK)
    t.eq(resigned.result["winner"], GoBoard.WHITE, "resignation remains an honest concession")


static func _policy(t: TestKit) -> void:
    t.section("practice opponent follows first capture with or without KataGo")
    var profile := load("res://data/opponents/pip_capture.tres") as OpponentProfile
    for engine in ["capture", "gtp"]:
        var copy := profile.duplicate() as OpponentProfile
        copy.engine = engine
        copy.gtp_command = "/missing-engine"
        var game := _position(GoBoard.WHITE)
        var opponent := OpponentFactory.create(copy, game)
        t.ok(opponent is CaptureOpponent, "capture objective selects the dedicated policy")
        var move := opponent.choose_move(game)
        t.eq(move["point"], game.board.from_label("D3"), "takes an available winning capture")
        game.pass_turn()
        t.eq(opponent.choose_move(game)["type"], "pass", "accepts the neutral end offer")
    for seed_value in range(1, 13):
        var game := GoGame.new(7, 0.5)
        game.capture_goal = 1
        profile.rng_seed = seed_value
        var opponent := CaptureOpponent.new()
        opponent.setup(profile, game)
        var random := RandomNumberGenerator.new()
        random.seed = seed_value
        for ply in 80:
            if game.state != GoGame.State.PLAYING:
                break
            if game.to_move == GoBoard.BLACK:
                var legal := game.legal_moves()
                if legal.is_empty():
                    game.pass_turn()
                else:
                    game.play(legal[random.randi_range(0, legal.size() - 1)])
            else:
                var move := opponent.choose_move(game)
                if move["type"] == "pass":
                    t.ok(game.legal_moves().is_empty() or game.consecutive_passes > 0, "no territory stopping policy")
                    game.pass_turn()
                else:
                    t.ok(game.is_legal(move["point"]), "unanticipated player moves get legal replies")
                    game.play(move["point"])
        if game.state == GoGame.State.PLAYING:
            game.pass_turn()
            game.pass_turn()
        t.eq(game.state, GoGame.State.FINISHED, "practice always allows a neutral exit")


static func _guidance(t: TestKit) -> void:
    t.section("capture guidance and saved final position")
    var game := _position()
    var point := game.board.from_label("D3")
    var advice := CaptureGuide.observation(game, GoBoard.BLACK, game.board.from_label("D4"))
    t.ok(advice["text"].contains("one") or advice["text"].contains("1 liberties"), "selected group's liberties explained")
    t.ok(advice["text"].contains("D3"), "real capture point named")
    game.ko_point = point
    t.ok(not CaptureGuide.observation(game, GoBoard.BLACK)["text"].contains("capture is available"), "illegal ko capture is not advised")
    game.ko_point = -1
    var before := game.board.cells.duplicate()
    game.play(point)
    var payload: Dictionary = JSON.parse_string(JSON.stringify(CaptureGuide.final_capture(game)))
    t.eq(CaptureGuide.review_position(payload).board.cells, before, "disk-safe replay shows the exact previous position")
    t.eq(CaptureGuide.review_position(payload, true).board.cells, game.board.cells, "replay produces the recorded capture")
    t.eq(CaptureGuide.review_position({}), null, "absent old-save replay is harmless")


static func _records(t: TestKit) -> void:
    t.section("neutral practice survives save and keeps access without a loss")
    var tree := Engine.get_main_loop() as SceneTree
    var state = tree.root.get_node("GameState")
    var backup: Dictionary = state.to_dict().duplicate(true)
    state.reset()
    state.set_rank("20k")
    state.set_quest("first_stones", 0, false)
    var result := MatchResult.new()
    result.context_id = "pip_capture"
    result.npc_id = "pip"
    result.capture_goal = 1
    result.practice_ended = true
    result.opponent_strength = 0
    result.sgf = "(;SZ[7];B[];W[])"
    state.record_match(result)
    t.eq(state.rank_label(), "20k", "neutral result cannot lower rank even with a bad unrated flag")
    t.eq(state.head_to_head("pip"), {"wins": 0, "losses": 0}, "no invented loss")
    t.eq(state.get_flag("last_result"), "neutral", "neutral reaction fact survives")
    var graph := DialogueGraph.load_graph("res://data/dialogue/pip.json")
    t.eq(graph.resolve("post_match"), "capture_ended", "Pip does not celebrate winning a neutral practice")
    var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
    state.from_dict(saved)
    t.ok(state.match_records[-1]["practice_ended"], "neutral record survives serialization")
    t.ok(state.has_flag("match_pip_capture_done"), "onward access survives")
    t.eq(graph.resolve("start"), "back", "old completed attempts offer retry")
    for field in [{"capture_goal": 1}, {"context_id": "pip_capture"}, {"by_capture": true}, {"practice_ended": true}]:
        var record: Dictionary = {"board_size": 7, "sgf": result.sgf, "by_resignation": true}
        record.merge(field, true)
        t.ok(not MatchAnalysis.eligible(record), "all new and legacy capture endings exclude territory review")
    state.reset()
    state.set_quest("first_stones", 0, false)
    state.set_flag("lesson_pip_first_capture_done", true)
    t.eq(state.quest_step("first_stones"), 1, "demonstration opens Wren without requiring practice")
    state.from_dict(backup)
