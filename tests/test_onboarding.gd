class_name OnboardingTests
extends RefCounted

static func run(t: TestKit) -> void:
    t.section("unranked setup never invents a strength")
    for size in [7,9,13,19]:
        for strength in [0,9,18,30,34]:
            var setup := GoMatchSetup.prepare(GoMatchSetup.Rule.BY_RANK,-1,strength,size)
            t.eq(setup.handicap,0,"an unranked player starts without handicap stones")
            t.ok(setup.uses_nigiri,"unranked even games draw for colours")
            t.eq(GoRank.handicap_between(-1,strength,size)["stones"],0,"rank arithmetic preserves unknown strength")

    t.section("resolved presentation and measured handicap teaching")
    var request := MatchRequest.new()
    request.profile = OpponentProfile.new()
    request.opponent_name = "Marguerite Sable"
    request.opponent_rank = "1d"
    request.profile.rank_label = "1d"
    t.eq(MatchPresentation.kind(request),"Rated game","rank consequences decide the default label")
    request.practice = true
    t.eq(MatchPresentation.kind(request),"Rated game","practice cannot override a rated request")
    request.unrated = true
    t.eq(MatchPresentation.kind(request),"Practice","unrated practice has its own label")
    request.practice = false
    t.eq(MatchPresentation.kind(request),"Casual game","unrated alone means casual")
    t.eq(MatchPresentation.kind(request,1),"Capture Go","capture rules are explicit")
    for player_rank in ["22k","9d"]:
        request.player_strength = GoRank.from_string(player_rank)
        var setup := GoMatchSetup.prepare(GoMatchSetup.Rule.BY_RANK,request.player_strength,30,9)
        t.ok(setup.is_handicap(),"both giving and receiving stones are covered")
        var pages := MatchPresentation.handicap_pages(request,setup)
        t.eq(pages.size(),2,"the first explanation has two stages")
        for page in pages:
            t.ok(UiKit.text_height(page,158)<=143,"the full stage fits beside the board")
        var combined := " ".join(pages)
        for fact in ["White makes the first move","captured","Komi","0.5","half-point","rank"]:
            t.ok(combined.contains(fact),"handicap help explains "+fact)
        t.ok(combined.contains(str(setup.handicap)),"the actual stone count is explained")
        var game := GoGame.new(9,setup.komi,setup.handicap)
        var black := 0
        for cell in game.board.cells:
            if cell == GoBoard.BLACK:black += 1
        t.eq(black,setup.handicap,"the visible initial stones match the setup")
        t.eq(game.to_move,GoBoard.WHITE,"White plays after the starting stones")
        var facts := MatchPresentation.details(request,setup,game)
        t.ok(UiKit.text_height(facts,156)<=44,"resolved match facts fit their four rows")
    request.opponent_name="Joos"
    request.opponent_rank="?"
    var joos := GoMatchSetup.prepare(GoMatchSetup.Rule.PLAYER_BLACK,8,34,9,0.5)
    joos.handicap=5
    t.ok(MatchPresentation.handicap_reason(request,joos).contains("agreed"),"Joos uses an agreed head start")

    t.section("old and skipped opening progress")
    var tree := Engine.get_main_loop() as SceneTree
    var state := tree.root.get_node("GameState")
    var quests := tree.root.get_node("Quests")
    if quests.quests.is_empty():quests._load_all()
    for flags in [{"knows_the_rules":true},{"said_knows_the_rules":true,"opening_plan_skipped":true}]:
        state.reset()
        state.set_quest("first_stones",1,false)
        state.flags=flags.duplicate()
        quests._reconcile_all()
        t.eq(state.quest_step("first_stones"),2,"known rules lead to practice even without an opening lesson")
    state.reset()
    state.set_quest("first_stones",0,false)
    state.match_records=[{"context_id":"wren_first","player_won":false}]
    quests._reconcile_all()
    t.eq(state.quest_step("first_stones"),3,"an old recorded practice game points to Kesh")
    state.match_records.append({"context_id":"kesh_first","player_won":false})
    quests._reconcile_all()
    t.ok(state.quest_done("first_stones"),"the first rating completes the opening even after a loss")
    t.eq(state.match_records.size(),2,"reconciliation preserves recorded games")
    state.reset()

    t.section("live objectives and saved teaching state")
    var updates: Array = []
    var bus := tree.root.get_node("EventBus")
    var changed := func(id: String, _step: int, _text: String): updates.append(id)
    bus.quest_advanced.connect(changed)
    state.set_quest("first_stones",0,false)
    state.set_flag("said_knows_the_rules",true)
    t.eq(state.quest_step("first_stones"),2,"a live shortcut advances the objective")
    t.ok(updates.has("first_stones"),"the HUD receives the changed objective")
    bus.quest_advanced.disconnect(changed)
    state.set_quest("beginner_cup",0,false)
    state.set_flag("cup_finished",true)
    t.ok(state.quest_done("beginner_cup"),"finishing the Cup supersedes a postponed draw reading")
    state.reset()
    t.ok(not state.has_flag("handicap_intro_seen"),"old saves receive handicap teaching")
    state.set_flag("handicap_intro_seen",true)
    var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
    state.reset()
    state.from_dict(saved)
    t.ok(state.has_flag("handicap_intro_seen"),"completed teaching survives save and load")
    state.reset()

    t.section("three and six game conversations use the existing record")
    for who in ["ilse","sunny","orla","moss"]:
        state.reset()
        var graph := DialogueGraph.load_graph("res://data/dialogue/%s.json" % who)
        state.set_flag("record_%s_loss" % who,3)
        t.eq(graph.resolve("start"),"stage_3" if who=="moss" else "stage_2",who+" reaches the first record conversation")
        state.set_flag("arc_%s_3" % who,true)
        state.set_flag("record_%s_loss" % who,6)
        t.eq(graph.resolve("start"),"stage_6" if who=="moss" else "stage_3",who+" reaches the second record conversation")
    state.reset()
