## Prototype adapter for the existing dialogue graphs and board/review seam.
extends Node

var room: Node2D


func talk(id: String, entry: String = "start") -> void:
    if room.busy:
        return
    room.set_busy(true)
    var actor: KetelActor = room.people[id]
    actor.input_locked = true
    actor.face_towards(room.player.position)
    room.player.face_towards(actor.position)
    var data: NpcData = load("res://data/npcs/%s.tres" % id)
    var graph := DialogueGraph.load_graph(data.dialogue_path)
    var speaker := {"id": id, "name": data.display_name, "rank": data.rank_label}
    EventBus.dialogue_started.emit(id)
    var exit: Dictionary = await room.dialogue.run(graph, speaker, entry)
    EventBus.dialogue_finished.emit(id)
    actor.release()
    room.set_busy(false)
    handle_exit(exit, data)


func handle_exit(exit: Dictionary, data: NpcData) -> void:
    var kind := str(exit.get("type", "end"))
    if kind == "end":
        return
    room.set_busy(true)
    # The router survives scene changes, unlike this conversation adapter.
    SceneRouter.set_meta("ketel_teacher", str(data.id))
    match kind:
        "start_match":
            var request := MatchRequest.new()
            request.profile = data.opponent_profile
            if exit.has("profile"):
                request.profile = load("res://data/opponents/%s.tres" % str(exit.profile))
            request.context_id = str(exit.get("context", data.id))
            request.npc_id = str(data.id)
            request.opponent_name = data.display_name
            request.opponent_rank = data.rank_label
            request.portrait_path = "res://art/portraits/%s.png" % data.portrait_id
            request.intro_line = str(exit.get("intro", ""))
            request.unrated = bool(exit.get("unrated", false))
            request.practice = bool(exit.get("practice", false))
            request.player_strength = GameState.rank_strength
            request.venue_id = "de_ketel"
            for prompt: String in exit.get("guidance", []):
                request.guidance.append(prompt)
            MatchBridge.start_match(request, room.player.position)
        "start_lesson":
            MatchBridge.start_lesson(str(exit.lesson), room.player.position, bool(exit.get("track", false)))
        "start_puzzle":
            MatchBridge.start_puzzle(str(exit.puzzle), room.player.position)
        _:
            room.set_busy(false)


func returned() -> void:
    var result := MatchBridge.last_result
    if result != null:
        var index := MatchBridge.last_record_index
        MatchBridge.last_result = null
        await talk(result.npc_id, "post_match")
        if MatchBridge.pending_request == null:
            await offer_review(index)
    elif not MatchBridge.last_lesson.is_empty():
        var lesson := MatchBridge.last_lesson
        MatchBridge.last_lesson = ""
        var teacher := str(SceneRouter.get_meta("ketel_teacher", "wren"))
        var graph := DialogueGraph.load_graph("res://data/dialogue/%s.json" % teacher)
        var entry := "taught_" + lesson
        if graph.resolve(entry).is_empty():
            entry = "taught"
        if not graph.resolve(entry).is_empty():
            await talk(teacher, entry)


func offer_review(index: int) -> void:
    if index < 0 or index >= GameState.match_records.size():
        return
    var record: Dictionary = GameState.match_records[index]
    if not MatchAnalysis.eligible(record):
        return
    room.set_busy(true)
    var offer := PostMatchReview.new()
    offer.record_index = index
    offer.opponent_name = str(record.opponent_name)
    offer.leave_hint = "Esc: return to the room. Press V there to open this review again."
    room.add_child(offer)
    await offer.closed
    room.set_busy(false)
