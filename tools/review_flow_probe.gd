## Supplemental UI/record checks. These fixtures do not measure human difficulty.
class_name ReviewFlowProbe
extends RefCounted

static var checkpoint := ""


static func fingerprint(state: Node) -> String:
    var records: Array = state.match_records.duplicate(true)
    for record in records:
        record.erase("review_requested")
    return JSON.stringify(JSON.parse_string(JSON.stringify({"records": records,
        "rank": state.rank_strength, "leagues": state.league_attempts})))


static func perform(tree: SceneTree, spec: Dictionary, shot: Callable) -> void:
    var state := tree.root.get_node("GameState")
    var mode := str(spec["experience"])
    if mode == "review_snapshot":
        checkpoint = fingerprint(state)
        print("REVIEW FLOW: checkpoint of %d results" % state.match_records.size())
        return
    if mode == "review_unchanged":
        if checkpoint == "" or checkpoint != fingerprint(state):
            BoardPlayProbe.fail(tree, "Review changed a result, rank or league fixture")
        print("REVIEW FLOW: results, rank and league unchanged")
        return
    if mode == "review_availability":
        var index := int(spec.get("index", state.match_records.size() - 1))
        var payload: Dictionary = state.match_analysis.get(str(index), {})
        if str(payload.get("availability", "")) != str(spec["availability"]):
            BoardPlayProbe.fail(tree, "Unexpected review availability: " + str(payload))
        return
    if mode == "review_reopen":
        var index := int(spec.get("index", state.match_records.size() - 1))
        var flow := PostMatchReview.new()
        flow.record_index = index
        flow.opponent_name = str(state.match_records[index].get("opponent_name", ""))
        var player := tree.current_scene.get("player") as Player
        player.input_locked = true
        flow.closed.connect(func(): player.input_locked = false)
        tree.current_scene.add_child(flow)
        return
    var deadline := Time.get_ticks_msec() + int(float(spec.get("timeout", 30)) * 1000)
    while Time.get_ticks_msec() < deadline:
        var flow := tree.root.find_child("PostMatchReview", true, false) as PostMatchReview
        if flow != null and flow._awaiting == &"review":
            await shot.call("review_ready_after_reaction")
            return
        var box := tree.root.find_child("DialogueBox", true, false) as DialogueBox
        if box != null and box.running:
            await tree.create_timer(0.7).timeout
            await shot.call("reaction_before_review")
            await ExperienceProbe.press(tree, "interact")
        await tree.process_frame
    BoardPlayProbe.fail(tree, "No review offer after reaction or completion announcement")
