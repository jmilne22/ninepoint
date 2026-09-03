## The town. Builds whichever map GameState points at, places the player and the
## people, and routes interactions to dialogue, doors and the Go layer.
extends Node2D

const PLAYER_SCENE := preload("res://src/rpg/player/player.tscn")
const HUD_SCENE := preload("res://src/ui/hud.gd")
const DIALOGUE_SCENE := preload("res://src/ui/dialogue_box.gd")

var map: MapData
var player: Player
var camera: Camera2D
var ambient: Ambient
var soundscape: Soundscape
var animator: TileAnimator
var crowd: CrowdSpawner
var hud: Hud
var dialogue: DialogueBox
var pause_menu: PauseMenu
var league_board: LeagueBoard
var cup_board: CupBoard
var entities: Node2D
var npcs: Array[Npc] = []

var _talking := false


func _ready() -> void:
    map = MapData.load_map(GameState.current_map)
    if map == null:
        push_error("World: could not load map '%s'" % GameState.current_map)
        return

    MapBuilder.build_backdrop(map, self)
    var ground := MapBuilder.build_layers(map, self)
    MapBuilder.build_collision(map, self)

    # Light, movement and sound. All three read the map's own tiles and none of
    # them ever writes the hour back -- GameState.time_block stays read-only
    # here, as it has been since Ambient was written.
    ambient = MapBuilder.build_ambient(map, self)
    animator = MapBuilder.build_animator(map, self, ground)
    soundscape = MapBuilder.build_soundscape(map, self)

    entities = Node2D.new()
    entities.name = "Entities"
    entities.y_sort_enabled = true
    add_child(entities)

    npcs = MapBuilder.build_npcs(map, entities, _on_talk_requested)
    MapBuilder.build_signs(map, self, _read_sign)
    MapBuilder.build_warps(map, self)

    Tram.build(map, entities)
    crowd = MapBuilder.build_crowd(map, entities)

    _spawn_player()
    _build_ui()

    _apply_music()
    EventBus.time_block_changed.connect(func(_b: String) -> void: _apply_music())
    EventBus.match_finished.connect(_on_match_finished)
    EventBus.map_changed.emit(map.id, GameState.spawn_point)
    await get_tree().process_frame
    _after_load()


func _spawn_player() -> void:
    player = PLAYER_SCENE.instantiate()
    var spawn := SceneRouter.take_spawn()
    if spawn["use_position"]:
        player.position = spawn["position"]
    else:
        var name := str(spawn["spawn"])
        if name == "":
            name = GameState.spawn_point
        player.position = map.spawn_position(name)
    entities.add_child(player)
    player.map = map
    player.wants_interaction.connect(_on_interaction)

    camera = Camera2D.new()
    camera.name = "Camera"
    var view := Vector2(384, 216)
    var size := map.pixel_size()
    # A map smaller than the screen used to be pinned to the top-left, with the
    # void showing along the bottom and right and reading as a broken tileset.
    # Widen the limits equally on both sides instead, so a small room sits in
    # the middle of the screen with the backdrop framing it.
    var pad := Vector2(maxf((view.x - size.x) * 0.5, 0.0),
        maxf((view.y - size.y) * 0.5, 0.0))
    camera.limit_left = int(-pad.x)
    camera.limit_top = int(-pad.y)
    camera.limit_right = int(size.x + pad.x)
    camera.limit_bottom = int(size.y + pad.y)
    camera.position_smoothing_enabled = false
    player.add_child(camera)
    camera.make_current()


## The street has two tracks and the hour picks one. Same key, same tempo, so
## the swap does not announce itself.
func _apply_music() -> void:
    var track := map.music
    var after_dark := GameState.time_block == "dusk" or GameState.time_block == "night"
    if after_dark and map.music_night != "":
        track = map.music_night
    if track != "":
        Audio.play_music(track)
    else:
        Audio.stop_music()


func _build_ui() -> void:
    hud = Hud.new()
    hud.name = "Hud"
    add_child(hud)
    dialogue = DialogueBox.new()
    dialogue.name = "DialogueBox"
    add_child(dialogue)
    league_board = LeagueBoard.new()
    league_board.name = "LeagueBoard"
    add_child(league_board)
    cup_board = CupBoard.new()
    cup_board.name = "CupBoard"
    add_child(cup_board)
    pause_menu = PauseMenu.new()
    pause_menu.name = "PauseMenu"
    add_child(pause_menu)
    pause_menu.opened.connect(func(): player.input_locked = true)
    pause_menu.closed.connect(func(): player.input_locked = _talking)


## Anything that has to happen the moment the player arrives on this map.
func _after_load() -> void:
    var result := MatchBridge.last_result
    if result != null:
        MatchBridge.last_result = null
        await _post_match(result)
        return
    if MatchBridge.last_lesson != "":
        var taught := MatchBridge.last_lesson
        MatchBridge.last_lesson = ""
        await _post_lesson(taught)
        return
    if map.id == "attic" and not GameState.has_flag("intro_seen"):
        GameState.set_flag("intro_seen", true)
        await _play_graph("res://data/dialogue/intro.json", {"name": "", "portrait": null})
        EventBus.quest_started.emit("first_stones")


## After a game, the opponent has something to say about it.
func _post_match(result: MatchResult) -> void:
    var npc := _find_npc(result.npc_id)
    if npc == null:
        return
    await get_tree().create_timer(0.25).timeout
    player.face_towards(npc.global_position)
    npc.look_at_point(player.global_position)
    await _talk(npc, "post_match")


## The demonstration board at the front of the classroom. Which class it gives
## depends on what the player has already been taught.
## What Hana teaches at the demonstration board, in order. The tutorial track in
## MatchBridge is the rulebook Wren gives you at the club; this is the course,
## and it starts where the rulebook stops. The board hands out the first one the
## player has not finished, so a class is never repeated by accident and can
## always be repeated on purpose from the study desk.
## Hana's course, taught at the demonstration board. Counting is not on it: it
## belongs to Tomas at De Ketel, who has a suspiciously good endgame and now,
## finally, a map to stand on.
const CLASS_TRACK := ["openings", "two_eyes", "life_and_death"]


func _next_class() -> String:
    for lesson in CLASS_TRACK:
        if not GameState.has_flag("lesson_%s_done" % lesson):
            return lesson
    # Everything taught. The last one is the one worth sitting through twice.
    return CLASS_TRACK[CLASS_TRACK.size() - 1]


func _start_class() -> void:
    var lesson := _next_class()
    if not GameState.can_act():
        EventBus.toast.emit("Hana has gone home. Sleep, and come to the morning class.")
        return
    player.input_locked = true
    player.clear_target()
    GameState.spend_slot()
    MatchBridge.start_lesson(lesson, player.global_position)


## The teacher says something after a lesson, so it does not end in mid-air.
func _post_lesson(lesson_id: String) -> void:
    var lesson := GoLessonData.load_lesson(lesson_id)
    if lesson == null or lesson.teacher == "":
        return
    var npc := _find_npc(lesson.teacher)
    if npc == null:
        return
    await get_tree().create_timer(0.25).timeout
    player.face_towards(npc.global_position)
    npc.look_at_point(player.global_position)
    await _talk(npc, "taught")


func _find_npc(npc_id: String) -> Npc:
    for n in npcs:
        if n.npc_id == npc_id:
            return n
    return null


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("menu") and not _talking and not SceneRouter.is_busy():
        pause_menu.toggle()
        get_viewport().set_input_as_handled()


# --- interaction -------------------------------------------------------------

func _on_interaction(target: Interactable) -> void:
    if _talking or SceneRouter.is_busy():
        return
    target.interact(player)


func _on_talk_requested(npc: Npc) -> void:
    _talk(npc)


## Two signs are not signs. The map data marks them with sentinels so the map
## generator does not need to know about UI scenes.
func _read_sign(text: String) -> void:
    if _talking:
        return
    if text == "__LEAGUE_BOARD__":
        player.clear_target()
        league_board.show_board()
        return
    if text == "__CUP_BOARD__":
        player.clear_target()
        cup_board.show_board()
        return
    if text == "__CLASS_BOARD__":
        await _start_class()
        return
    if text.begins_with("__DESK__"):
        await _study_desk(text.trim_prefix("__DESK__"))
        return
    if text.begins_with("__HOOKS__"):
        await _read_hooks(text.trim_prefix("__HOOKS__"))
        return
    if text.begins_with("__BED__"):
        await _offer_sleep(text.trim_prefix("__BED__"))
        return
    _talking = true
    player.input_locked = true
    player.clear_target()
    var graph := DialogueGraph.new()
    graph.nodes = {"start": {"speaker": "narrator", "text": [text]}}
    await dialogue.run(graph, {"name": "", "portrait": null})
    player.input_locked = false
    _talking = false


## The study desk. GAME_DESIGN promised that the board in your room replays the
## problems you have been set, and until now it was a sign you could read.
##
## Order matters more than choice here: the problems run in the order the concepts
## are taught, so the desk hands out the first one you have not solved and only
## repeats itself once you have solved them all.
const PUZZLE_TRACK := ["capture_1", "capture_2", "capture_3", "escape_1",
                       "escape_2", "live_1", "capture_4", "live_2"]


func _next_puzzle() -> String:
    for puzzle in PUZZLE_TRACK:
        if not GameState.has_flag("%s_solved" % puzzle):
            return puzzle
    return PUZZLE_TRACK[GameState.day % PUZZLE_TRACK.size()]


func _study_desk(prose: String) -> void:
    if not GameState.has_flag("knows_the_rules"):
        await _narrate([prose.strip_edges(),
            "You still do not know what any of it is for. Somebody will have to show you."])
        return
    var puzzle := _next_puzzle()
    var solved_all := GameState.has_flag("%s_solved" % PUZZLE_TRACK[PUZZLE_TRACK.size() - 1])
    var lines: Array = [prose.strip_edges()]
    lines.append("You could sit down with a problem." if not solved_all
        else "You have done all of them. You could do one again -- it is not the same twice, because you are not.")
    var graph := DialogueGraph.new()
    graph.nodes = {
        "start": {"speaker": "narrator", "text": lines, "choices": [
            {"text": "Set a problem.", "exit": {"type": "study"}},
            {"text": "Leave it.", "goto": "no"},
        ]},
        "no": {"speaker": "narrator", "text": ["The stones stay in the bowl."]},
    }
    _talking = true
    player.input_locked = true
    player.clear_target()
    var exit: Dictionary = await dialogue.run(graph, {"name": "", "portrait": null})
    _talking = false
    if str(exit.get("type", "")) != "study":
        player.input_locked = false
        return
    # Studying alone is free. It is the one thing in the game that costs no hours,
    # because an evening spent on problems is not what a day is for spending.
    # Input stays locked through the scene change: releasing it first let the same
    # keypress that chose this option re-trigger the desk behind the dialogue.
    MatchBridge.start_puzzle(puzzle, player.global_position)


## A narrator aside, with no choices and nothing to decide.
func _narrate(lines: Array) -> void:
    _talking = true
    player.input_locked = true
    player.clear_target()
    var graph := DialogueGraph.new()
    graph.nodes = {"start": {"speaker": "narrator", "text": lines}}
    await dialogue.run(graph, {"name": "", "portrait": null})
    player.input_locked = false
    _talking = false


## The hooks are the club's rank board, and the only place in the game that ever
## explains what a rank is or how it moves. A player who has never met kyu grading
## has no way to guess that the number counts downwards.
func _read_hooks(prose: String) -> void:
    var lines: Array = [prose.strip_edges()]
    if not GameState.is_ranked():
        lines.append("There is no card with your name on it yet.")
        lines.append("Play a rated game against somebody who has one, and Tomas will write you a card whether you ask him to or not.")
    else:
        lines.append("Your card is on the hooks: %s." % GameState.rank_label())
        lines.append("Ranks count downwards. Twenty kyu is a beginner, twelve kyu is better, one kyu is better still -- and then it turns over into dan and counts up again.")
        lines.append("One rank is one handicap stone. That is what the number is for: it says how many stones make a game with you fair.")
        lines.append(GoRating.explain(GameState.match_records))
        lines.append("The club works it out the way every club does: who you have been playing, and how often you beat them.")
        lines.append("An even score against a rank leaves you at that rank. Win more and you move up it. Lose more and you move down.")
        lines.append("Stones count against you. Winning on four stones from a nine kyu is a thirteen kyu result, not a nine kyu one.")
        lines.append("Which is why the stones thin out as you get better, and why that is the thing worth watching.")
        lines.append("Only rated games. The park and the arches are for playing, not for counting.")
    _talking = true
    player.input_locked = true
    player.clear_target()
    var graph := DialogueGraph.new()
    graph.nodes = {"start": {"speaker": "narrator", "text": lines}}
    await dialogue.run(graph, {"name": "", "portrait": null})
    player.input_locked = false
    _talking = false


## The bed is the only thing that moves the calendar, so it asks first: a night
## lost to a mistimed [Space] would be a real one.
func _offer_sleep(prose: String) -> void:
    var left := GameState.SLOTS_PER_DAY - GameState.slots_used
    var state := "Today is gone." if left <= 0 else (
        "There is still the rest of today." if left > 1 else "There is an hour left in today.")
    var choices: Array = [{"text": "Sleep.", "exit": {"type": "sleep"}}]
    # Six weeks is six weeks, and nobody should press [Space] forty times to
    # cross it. Once there is a fixed thing to wait for, you can wait for it.
    var to_cup := GameState.CUP_DAY - GameState.day
    if GameState.has_flag("cup_entered") and to_cup > 0:
        choices.append({"text": "Sleep until the Cup (%d days)." % to_cup,
                        "exit": {"type": "sleep_until_cup"}})
    choices.append({"text": "Not yet.", "goto": "not_yet"})
    var graph := DialogueGraph.new()
    graph.nodes = {
        "start": {
            "speaker": "narrator",
            "text": [prose.strip_edges(), state],
            "choices": choices,
        },
        "not_yet": {"speaker": "narrator", "text": ["You leave it for now."]},
    }
    _talking = true
    player.input_locked = true
    player.clear_target()
    var exit: Dictionary = await dialogue.run(graph, {"name": "", "portrait": null})
    _talking = false
    var kind := str(exit.get("type", ""))
    if kind != "sleep" and kind != "sleep_until_cup":
        player.input_locked = false
        return
    # Turn the day over first, then hand the player back: unlocking here let the
    # keypress that chose "Sleep" read the bed sign again on the way out.
    player.input_locked = false
    GameState.sleep()
    if kind == "sleep_until_cup":
        while GameState.day < GameState.CUP_DAY:
            GameState.sleep()
        EventBus.toast.emit("The last week of term. Day %d -- the Cup." % GameState.day)
        return
    var days := GameState.days_until_cup()
    if days > 0 and GameState.has_flag("wren_told_about_cup"):
        EventBus.toast.emit("Day %d. %d days to the Cup." % [GameState.day, days])
    else:
        EventBus.toast.emit("Day %d." % GameState.day)


func _play_graph(path: String, speaker: Dictionary) -> Dictionary:
    var graph := DialogueGraph.load_graph(path)
    if graph == null:
        return {"type": "end"}
    _talking = true
    player.input_locked = true
    player.clear_target()
    var exit: Dictionary = await dialogue.run(graph, speaker)
    player.input_locked = false
    _talking = false
    return exit


func _talk(npc: Npc, start_node: String = "start") -> void:
    if _talking or npc.data == null:
        npc.release()
        return
    _talking = true
    player.input_locked = true
    player.clear_target()
    EventBus.dialogue_started.emit(npc.npc_id)

    var graph := DialogueGraph.load_graph(npc.data.dialogue_path)
    var exit := {"type": "end"}
    if graph != null:
        var speaker := {
            "name": npc.data.display_name,
            "portrait": npc.data.portrait_texture(),
            "rank": npc.data.rank_label,
        }
        exit = await dialogue.run(graph, speaker, start_node)

    npc.release()
    EventBus.dialogue_finished.emit(npc.npc_id)
    _talking = false
    player.input_locked = false
    await _handle_exit(exit, npc)


## Leaving the world is deliberately not awaited -- see go_match._finish().
func _handle_exit(exit: Dictionary, npc: Npc) -> void:
    match str(exit.get("type", "end")):
        "start_match":
            _start_match(exit, npc)
        "start_puzzle":
            player.input_locked = true
            MatchBridge.start_puzzle(str(exit.get("puzzle", "")), player.global_position)
        "start_lesson":
            player.input_locked = true
            MatchBridge.start_lesson(str(exit.get("lesson", "")), player.global_position,
                bool(exit.get("track", false)))
        "cup_round":
            _start_cup_round()
        _:
            pass


## The Cup ends the moment its last round is recorded, so the player is told
## where they finished by the tournament rather than by asking the desk.
func _on_match_finished(result: MatchResult) -> void:
    if result == null or not result.context_id.begins_with(CupDraw.CONTEXT_PREFIX):
        return
    var state := CupDraw.run(CupBoard.field(), GameState.match_records, CupBoard.PLAYER_ID)
    if not bool(state["complete"]):
        return
    GameState.set_flag("cup_finished", true)
    var place := CupDraw.placing(state["rows"], CupBoard.PLAYER_ID)
    if place == 1:
        EventBus.toast.emit("You won the Steenbeek Beginner Cup.")
    else:
        EventBus.toast.emit("The Cup is over. You finished %d of %d." % [
            place, state["rows"].size()])


## A Cup round. Who the player meets is not written in the dialogue file, because
## it is not knowable until the previous round has been played -- CupDraw works it
## out from the record, and this turns that answer into a game.
func _start_cup_round() -> void:
    var state := CupDraw.run(CupBoard.field(), GameState.match_records, CupBoard.PLAYER_ID)
    if bool(state["complete"]):
        GameState.set_flag("cup_finished", true)
        EventBus.toast.emit("The Cup is over.")
        return
    # One round a day, which is how a weekend tournament runs and what stops the
    # whole Cup being played in a single afternoon.
    if int(GameState.get_flag("cup_round_day", 0)) == GameState.day:
        EventBus.toast.emit("One round a day. Come back tomorrow.")
        return
    if not GameState.can_act():
        EventBus.toast.emit("Too late in the day for a tournament game. Sleep.")
        return

    var opponent_id := str(state["next_opponent"])
    var npc_path := "res://data/npcs/%s.tres" % opponent_id
    var profile_path := "res://data/opponents/%s_9x9.tres" % opponent_id
    if opponent_id == "" or not ResourceLoader.exists(npc_path) \
            or not ResourceLoader.exists(profile_path):
        push_error("World: no Cup opponent for '%s'" % opponent_id)
        return
    var data: NpcData = load(npc_path)

    var req := MatchRequest.new()
    req.profile = load(profile_path)
    req.context_id = CupDraw.context_for(int(state["next_round"]))
    req.npc_id = opponent_id
    req.opponent_name = data.display_name
    req.opponent_rank = data.rank_label
    req.portrait_path = "res://art/portraits/%s.png" % data.portrait_id
    req.intro_line = "Round %d. Board %d." % [int(state["next_round"]) + 1, 1]
    req.player_strength = GameState.rank_strength
    GameState.set_flag("cup_round_day", GameState.day)
    player.input_locked = true
    MatchBridge.start_match(req, player.global_position)


func _start_match(exit: Dictionary, npc: Npc) -> void:
    var profile: OpponentProfile = npc.data.opponent_profile
    if exit.has("profile"):
        var path := "res://data/opponents/%s.tres" % str(exit["profile"])
        if ResourceLoader.exists(path):
            profile = load(path)
    if profile == null:
        push_error("World: no opponent profile for %s" % npc.npc_id)
        return
    var req := MatchRequest.new()
    req.profile = profile
    req.context_id = str(exit.get("context", npc.npc_id))
    req.npc_id = npc.npc_id
    req.opponent_name = npc.data.display_name
    req.opponent_rank = npc.data.rank_label
    req.portrait_path = "res://art/portraits/%s.png" % npc.data.portrait_id
    req.intro_line = str(exit.get("intro", ""))
    req.unrated = bool(exit.get("unrated", false))
    # The day runs out. Park and arch games do not cost one, so there is always
    # something left to do -- being out of hours must never mean being stuck.
    if not req.unrated and not GameState.can_act():
        EventBus.toast.emit("Not tonight. Sleep, and play it properly tomorrow.")
        return
    req.player_strength = GameState.rank_strength
    player.input_locked = true
    MatchBridge.start_match(req, player.global_position)
