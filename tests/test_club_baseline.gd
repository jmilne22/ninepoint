class_name ClubBaselineTests
extends RefCounted


static func run(t: TestKit) -> void:
    var state = (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
    var backup: Dictionary = state.to_dict().duplicate(true)
    state.reset()
    var noor := DialogueGraph.load_graph("res://data/dialogue/noor.json")
    t.eq(noor.resolve("start"), "hello", "Noor can meet the player before registration")
    DialogueGraph.apply(noor.node("hello").get("actions", []))
    t.ok(state.has_flag("noor_introduced"), "a conversation is remembered")
    t.ok(not state.has_flag("enrolled"), "meeting Noor does not register a league")
    t.eq(state.match_records.size(), 0, "social invitation creates no game or result")
    t.eq(noor.resolve("start"), "offer", "return visits do not repeat the invitation")
    state.set_flag("novice_league_completed", true)
    t.eq(noor.resolve("start"), "league_return", "completion has its own conversation")
    state.set_flag("cup_finished", true)
    t.eq(noor.resolve("start"), "cup_return", "Cup payoff takes priority over a missed league conversation")
    DialogueGraph.apply(noor.node("cup_return").get("actions", []))
    t.eq(noor.resolve("start"), "offer", "no stale first-Cup invitation after completing it")
    for result in ["win", "loss"]:
        state.set_flag("last_result", result)
        t.eq(noor.resolve("post_match"), "lost" if result == "win" else "won", "event progress cannot override the actual game reaction")
    var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
    state.from_dict(saved)
    t.eq(noor.resolve("start"), "offer", "payoff acknowledgement survives loading")
    for spec in [["tomas", "neighbour"], ["tomas", "bar_work"], ["abel", "basket_thanks"], ["noor", "postcard"]]:
        var graph := DialogueGraph.load_graph("res://data/dialogue/%s.json" % spec[0])
        var node := graph.node(str(spec[1]))
        t.ok(not node.has("goto") and not node.has("choices") and not node.has("exit"), "ordinary exchange can finish without a game/referral")
        t.ok(not node.has("actions"), "ordinary exchange adds no reward or progression counter")
    var hana := DialogueGraph.load_graph("res://data/dialogue/hana.json")
    DialogueGraph.apply(hana.node("meet_noor").get("actions", []))
    t.ok(not state.has_flag("institute_class_ready"), "visiting Noor first does not silently skip the class")
    state.from_dict(backup)
