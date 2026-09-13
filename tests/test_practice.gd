class_name PracticeTests
extends RefCounted

static func run(t: TestKit) -> void:
    t.section("standalone practice")
    var settings := PracticeSettings.new()
    t.eq(settings.summary(), "9×9 · 30k (approx.) · Balanced\nYou play Black · 0 handicap stones · komi 5.5", "default preview describes actual setup")
    for size in PracticeSettings.SIZES:
        for rank in 35:
            settings.board_size = size
            settings.rank = rank
            for style in ["steady", "balanced", "fighting"]:
                settings.style = style
                var request := PracticeProfile.make(settings)
                t.eq(request.profile.strength(), rank, "practice profile uses selected rank")
                t.eq(request.profile.board_size, size, "all practice board sizes")
                t.ok(FileAccess.file_exists(request.profile.gtp_config_path), "every rank/style config exists")
            settings.handicap_mode = "auto"
            var setup := settings.resolve_setup()
            t.ok(setup.handicap <= GoRank.max_handicap(size), "automatic handicap fits board")
            settings.handicap_mode = "none"
    for size in PracticeSettings.SIZES:
        settings.board_size = size
        settings.mode = "teaching"
        var teaching := PracticeProfile.make(settings)
        t.ok(LiveTeaching.eligible(teaching, settings.resolve_setup()), "all four practice sizes allow teaching")
        t.ok(teaching.allow_undo and teaching.help_enabled, "teaching requests explicit assistance")
    settings.mode = "ordinary"
    settings.rank = 30
    settings.avatar = "hana"
    var a := PracticeProfile.make(settings)
    settings.avatar = "noor"
    var b := PracticeProfile.make(settings)
    t.eq(a.profile.gtp_config_path, b.profile.gtp_config_path, "avatar cannot change strength")
    t.ok(a.portrait_path != b.portrait_path, "avatar changes appearance")
    t.eq(a.npc_id, "", "no campaign NPC identity")
    settings.board_size = 9
    settings.handicap_mode = "manual"
    settings.stones = 9
    settings.colour = "white"
    var setup := settings.resolve_setup()
    t.eq(setup.handicap, 5, "manual handicap capped on nine")
    t.eq(setup.player_color, GoBoard.WHITE, "player may give handicap")
    t.eq(setup.komi, 0.5, "handicap komi")
    settings.custom_komi = true
    settings.komi = 3.5
    t.eq(settings.resolve_setup().komi, 3.5, "custom komi overrides handicap default")
    settings.handicap_mode = "auto"
    t.eq(settings.resolve_setup().komi, 3.5, "custom komi also applies to automatic handicap")
    settings.handicap_mode = "none"
    settings.custom_komi = false
    t.eq(settings.resolve_setup().komi, 5.5, "standard komi clears previous custom override")
    settings.custom_komi = true
    settings.mode = "capture"
    var capture := PracticeProfile.make(settings)
    t.eq(capture.profile.board_size, 7, "capture preset board")
    t.eq(capture.profile.komi, 0.0, "capture ignores custom komi")
    t.eq(capture.profile.capture_goal, 1, "capture preset goal")
    t.eq(capture.profile.engine, "capture", "capture preset uses honest local opponent")
    for size in PracticeSettings.SIZES:
        for handicap in [0, 2, GoRank.max_handicap(size)]:
            var game := GoGame.new(size, 0.5 if handicap > 0 else 5.5, handicap)
            game.ko_rule = GoGame.KoRule.POSITIONAL_SUPERKO
            for i in 12:
                var legal := game.legal_moves()
                game.play(legal[mini(i * 3, legal.size() - 1)])
            var key := TeachingPosition.key(game)
            var snapshot := PracticeSnapshot.capture(game, GoBoard.WHITE, {}, true)
            var json: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
            var restored := PracticeSnapshot.restore(json)
            t.ok(restored != null, "JSON snapshot replays legally")
            t.eq(TeachingPosition.key(restored), key, "resume retains board, ko and complete history")
            t.eq(restored.captures, game.captures, "resume retains captures")
            t.ok(PracticeSnapshot.take_back(restored, GoBoard.WHITE), "takeback finds player's decision")
            t.eq(restored.to_move, GoBoard.WHITE, "takeback returns player turn")
            restored.pass_turn()
            restored.pass_turn()
            var counted := PracticeSnapshot.restore(PracticeSnapshot.capture(restored, GoBoard.WHITE, {0: true}))
            t.eq(counted.state, GoGame.State.SCORING, "resume retains consecutive passes/counting")
            t.ok(PracticeSnapshot.take_back(counted, GoBoard.WHITE), "takeback from counting")
            t.eq(counted.state, GoGame.State.PLAYING, "takeback resumes play")
    var ko := GoGame.new(9, 5.5)
    for xy in [Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 2), Vector2i(4, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(0, 0), Vector2i(2, 2), Vector2i(3, 2)]:
        t.ok(ko.play_xy(xy.x, xy.y), "ko fixture is a committed legal history")
    t.eq(ko.captures[GoBoard.BLACK], 1, "fixture actually captures")
    var resumed_ko := PracticeSnapshot.restore(PracticeSnapshot.capture(ko, GoBoard.BLACK))
    t.eq(resumed_ko.ko_point, ko.board.idx(2, 2), "resume preserves active ko prohibition")
    t.eq(resumed_ko.legality(ko.board.idx(2, 2)), GoGame.Legality.KO, "resume rejects immediate recapture")
    t.ok(PracticeSnapshot.take_back(resumed_ko, GoBoard.BLACK), "undo capture returns previous decision")
    t.eq(resumed_ko.captures[GoBoard.BLACK], 0, "undo restores captured stone and prisoner count")
    t.eq(resumed_ko.board.get_at(2, 2), GoBoard.WHITE, "captured white stone restored")
    t.ok(resumed_ko.play_xy(3, 2), "capture remains legal after undo")
    t.ok(resumed_ko.play_xy(8, 8), "legal ko threat")
    t.ok(resumed_ko.play_xy(8, 7), "legal answer")
    t.ok(resumed_ko.play_xy(2, 2), "recapture legal after threat and answer")
    var recaptured := PracticeSnapshot.restore(PracticeSnapshot.capture(resumed_ko, GoBoard.BLACK))
    t.eq(recaptured.captures, resumed_ko.captures, "both prisoner counts survive recapture/resume")
    t.eq(recaptured.ko_point, resumed_ko.ko_point, "reverse ko prohibition survives resume")
    var invalid := {"size": 8}
    t.eq(PracticeSnapshot.restore(invalid), null, "invalid suspended board rejected")
    var store := PracticeStore.new()
    store.path = "user://practice/test_state.json"
    store.data.active = {"id": "fixture"}
    t.eq(store.complete("fixture", {"summary": "B+R"}), 0, "first completion recorded")
    t.eq(store.complete("fixture", {"summary": "B+R"}), 0, "repeated completion returns same record")
    t.eq(store.data.records.size(), 1, "record once")
    var loaded := PracticeStore.new()
    loaded.path = store.path
    loaded.read()
    t.eq(loaded.data.records.size(), 1, "record survives restart")
    t.ok(loaded.data.active.is_empty(), "completion clears suspended game atomically")
    var temp := FileAccess.open(store.path + ".tmp", FileAccess.WRITE)
    temp.store_string("incomplete write")
    temp.close()
    loaded.read()
    t.eq(loaded.data.records.size(), 1, "interrupted temporary write does not replace good save")
    DirAccess.remove_absolute(store.path)
    DirAccess.remove_absolute(store.path + ".tmp")

    t.eq(PracticeSettings.from_dict({"rank": 90, "board_size": 8, "avatar": "missing"}).rank, 34, "saved rank clamps to supported range")
    t.eq(PracticeSettings.from_dict({"rank": [], "mode": 3}).mode, "ordinary", "wrong settings types use defaults")
    var corrupt := FileAccess.open(store.path, FileAccess.WRITE)
    corrupt.store_string("{broken")
    corrupt.close()
    var damaged := PracticeStore.new()
    damaged.path = store.path
    damaged.read()
    t.ok(not damaged.error.is_empty(), "corrupt practice file reports an error")
    t.ok(not damaged.write(), "corrupt original is never overwritten by defaults")
    t.eq(FileAccess.get_file_as_string(store.path), "{broken", "corrupt original remains recoverable")
    DirAccess.remove_absolute(store.path)
