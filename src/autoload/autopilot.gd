## Drives the real game with synthetic input and captures screenshots.
##
## Inert unless the game is started with:
##   godot --path . -- --autopilot=res://tools/autopilot/<script>.json
## `--katago-trial` is the one visible development route: it opens the same
## fixture for manual play, without enabling automation.
## Used to verify milestones by playing them, not by asserting the code parses.
extends Node

const SHOT_DIR := "user://shots/"

var active: bool = false
var _steps: Array = []
var _shot_index: int = 0


func _ready() -> void:
    var script_path := ""
    var manual_katago_trial := false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--autopilot="):
            script_path = arg.split("=", true, 1)[1]
        elif arg == "--katago-trial":
            manual_katago_trial = true
    if script_path == "":
        if manual_katago_trial:
            _start_katago_trial.call_deferred()
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(script_path))
    if not (parsed is Array):
        push_error("Autopilot: %s is not a JSON array" % script_path)
        return
    _steps = parsed
    active = true
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
    print("AUTOPILOT: %d steps from %s" % [_steps.size(), script_path])
    _run.call_deferred()


func _run() -> void:
    await get_tree().process_frame
    for step in _steps:
        await _do(step)
    print("AUTOPILOT: done")
    await get_tree().create_timer(0.2).timeout
    get_tree().quit()


func _do(step: Dictionary) -> void:
    if step.has("katago_trial"):
        await _start_katago_trial()
    if step.has("match_move"):
        var xy: Array = step["match_move"]
        await _play_match_point(Vector2i(int(xy[0]), int(xy[1])), float(step.get("timeout", 30.0)))
    if step.has("match_resign"):
        await _resign_match(float(step.get("timeout", 30.0)))
    if step.has("match_wait_player"):
        await _wait_for_match_player_turn(float(step.get("timeout", 30.0)))
    if step.has("walk_to"):
        var dest: Array = step["walk_to"]
        await _walk_to_tile(Vector2i(int(dest[0]), int(dest[1])), float(step.get("timeout", 8.0)))
    if step.has("talk_to"):
        await _talk_to(str(step["talk_to"]), float(step.get("timeout", 8.0)))
    # Turning to look at a tile you cannot stand on. Signs, boards, the hooks and
    # the beds all live on solid tiles, so `walk_to` can never reach them and
    # there was no other way to point the player at one.
    if step.has("face"):
        var at: Array = step["face"]
        var w = _world()
        if w != null:
            await _face_towards(w.map.stand_position(Vector2i(int(at[0]), int(at[1]))))
    if step.has("advance"):
        await _advance_dialogue(int(step["advance"]), bool(step.get("stop_at_choice", false)))
    if step.has("choose"):
        await _choose_option(int(step["choose"]))
    if step.has("wait"):
        await get_tree().create_timer(float(step["wait"])).timeout
    if step.has("tap"):
        var times := int(step.get("times", 1))
        for i in times:
            _send(str(step["tap"]), true)
            await get_tree().process_frame
            await get_tree().process_frame
            _send(str(step["tap"]), false)
            await get_tree().create_timer(float(step.get("gap", 0.12))).timeout
    if step.has("hold"):
        var seconds := float(step.get("seconds", 0.4))
        _send(str(step["hold"]), true)
        await get_tree().create_timer(seconds).timeout
        _send(str(step["hold"]), false)
        await get_tree().process_frame
    if step.has("shot"):
        await _shot(str(step["shot"]))
    if step.has("note"):
        print("AUTOPILOT: %s" % str(step["note"]))
    if step.has("trial_assert"):
        _assert_katago_trial()
    if step.has("quit"):
        get_tree().quit()


## This route exists only in autoplay scripts. No world interaction, profile,
## or character can reach it, which keeps the shipped cast on heuristic play.
func _start_katago_trial() -> void:
    var profile := load("res://tools/fixtures/katago_trial_9x9.tres") as OpponentProfile
    if profile == null:
        push_error("KataGo trial fixture profile could not be loaded.")
        return
    var request := MatchRequest.new()
    request.profile = profile
    request.context_id = "dev_katago_trial"
    request.npc_id = "katago_trial"
    request.opponent_name = profile.display_name
    request.opponent_rank = profile.rank_label
    request.intro_line = "Development fixture: bundled KataGo Human SL trial."
    request.unrated = true
    request.player_strength = profile.strength()
    await MatchBridge.start_match(request, Vector2(96, 96))


func _match() -> Node:
    var scene := get_tree().current_scene
    return scene if scene != null and scene.get("game") != null and scene.get("opponent") != null else null


func _play_match_point(xy: Vector2i, timeout: float) -> void:
    var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
    while Time.get_ticks_msec() < deadline:
        var board_scene := _match()
        if board_scene != null and board_scene.is_player_turn_ready():
            var game: GoGame = board_scene.get("game")
            var point := game.board.idx(xy.x, xy.y)
            if game.is_legal(point):
                board_scene._on_point_activated(point)
                return
            push_error("KataGo trial asked to play an illegal fixture point %s." % xy)
            return
        await get_tree().process_frame
    push_error("KataGo trial timed out waiting for the player's turn.")


func _resign_match(timeout: float) -> void:
    var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
    while Time.get_ticks_msec() < deadline:
        var board_scene := _match()
        if board_scene != null and board_scene.is_player_turn_ready():
            _send("go_resign", true)
            await get_tree().process_frame
            _send("go_resign", false)
            await get_tree().process_frame
            _send("go_resign", true)
            await get_tree().process_frame
            _send("go_resign", false)
            return
        await get_tree().process_frame
    push_error("KataGo trial timed out waiting to resign.")


func _wait_for_match_player_turn(timeout: float) -> void:
    var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
    while Time.get_ticks_msec() < deadline:
        var board_scene := _match()
        if board_scene != null and board_scene.is_player_turn_ready():
            return
        await get_tree().process_frame
    push_error("KataGo trial timed out waiting for the engine reply.")


func _assert_katago_trial() -> void:
    var evidence := MatchBridge.dev_trial
    var engine: Dictionary = evidence.get("engine", {})
    var ok := bool(engine.get("started", false)) \
        and not bool(engine.get("fallback", true)) \
        and int(engine.get("legal_replies", 0)) >= 2 \
        and bool(engine.get("shutdown", false)) \
        and bool(evidence.get("has_sgf", false)) \
        and bool(evidence.get("has_match_fields", false))
    if not ok:
        push_error("KataGo trial assertions failed: %s" % evidence)
    else:
        print("KATAGO TRIAL: engine started, %d legal replies, normal result, shutdown confirmed" % int(engine["legal_replies"]))


func _send(action: String, pressed: bool) -> void:
    var ev := InputEventAction.new()
    ev.action = action
    ev.pressed = pressed
    ev.strength = 1.0 if pressed else 0.0
    Input.parse_input_event(ev)


func _shot(name: String) -> void:
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    _shot_index += 1
    var path := "%s%02d_%s.png" % [SHOT_DIR, _shot_index, name]
    img.save_png(path)
    print("AUTOPILOT SHOT: %s" % ProjectSettings.globalize_path(path))


# --- position-aware steps ----------------------------------------------------
# Walking by stopwatch is far too brittle: one extra frame of a held key and the
# player misses a doorway. These steps drive the real nodes instead.

func _world():
    var scene := get_tree().current_scene
    if scene != null and scene.get("map") != null:
        return scene
    return null


func _player() -> Node2D:
    return get_tree().get_first_node_in_group("player") as Node2D


func _release_all() -> void:
    for a in ["move_left", "move_right", "move_up", "move_down"]:
        _send(a, false)


func _tile_of(map, pos: Vector2) -> Vector2i:
    return Vector2i(int(pos.x) / map.tile_size, int(pos.y) / map.tile_size)


## Tiles occupied by people. The solid grid does not know about them, and walking
## into somebody is exactly as blocked as walking into a table.
func _occupied_tiles(map, ignore: Node2D = null) -> Dictionary:
    var out := {}
    for n in get_tree().get_nodes_in_group("npc"):
        if n == ignore or not (n is Node2D):
            continue
        out[_tile_of(map, (n as Node2D).global_position)] = true
    return out


## Breadth-first path over the map's solid grid. The greedy walker on its own
## cannot get around a table, and every club has tables.
func _path(map, from_tile: Vector2i, to_tile: Vector2i, blocked: Dictionary = {}) -> Array:
    if map.is_solid(to_tile.x, to_tile.y):
        return []
    var came := {from_tile: from_tile}
    var queue := [from_tile]
    while not queue.is_empty():
        var cur: Vector2i = queue.pop_front()
        if cur == to_tile:
            var path := [cur]
            while came[cur] != cur:
                cur = came[cur]
                path.push_front(cur)
            return path
        for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var nb: Vector2i = cur + d
            if came.has(nb) or map.is_solid(nb.x, nb.y):
                continue
            if blocked.has(nb) and nb != to_tile:
                continue
            came[nb] = cur
            queue.append(nb)
    return []


## Walks straight at a point. Used one tile at a time, so it never needs to path.
func _step_towards(target: Vector2, timeout: float) -> bool:
    var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
    var last_pos := Vector2.ZERO
    var stuck := 0
    while Time.get_ticks_msec() < deadline:
        var player := _player()
        if player == null:
            _release_all()
            return false        # the scene changed under us
        var d := target - player.global_position
        if d.length() < 3.5:
            break
        _release_all()
        if absf(d.x) > 2.0:
            _send("move_right" if d.x > 0 else "move_left", true)
        if absf(d.y) > 2.0:
            _send("move_down" if d.y > 0 else "move_up", true)
        await get_tree().physics_frame
        await get_tree().process_frame
        if not is_instance_valid(player):
            _release_all()
            return false        # walked through a door mid-step
        if player.global_position.distance_to(last_pos) < 0.3:
            stuck += 1
            if stuck > 12:
                break
        else:
            stuck = 0
        last_pos = player.global_position
    _release_all()
    await get_tree().process_frame
    var p := _player()
    return p != null and (target - p.global_position).length() < 10.0


func _walk_to(target_tile: Vector2i, timeout: float, ignore_npc: Node2D = null) -> bool:
    var world = _world()
    var player := _player()
    if world == null or player == null:
        return false
    var map = world.map
    # Stepping onto a warp tile changes the map mid-walk. The player node is
    # replaced rather than freed, so the arrival check used to measure the new
    # player against the old map's tile and report a failure on every door.
    var from_map: String = str(map.id)
    var blocked := _occupied_tiles(map, ignore_npc)
    var path := _path(map, _tile_of(map, player.global_position), target_tile, blocked)
    if path.is_empty():
        print("AUTOPILOT: no path to %s" % str(target_tile))
        return false
    var per_step: float = maxf(0.6, timeout / float(path.size()))
    for i in range(1, path.size()):
        var ok: bool = await _step_towards(map.stand_position(path[i]), per_step)
        if _player() == null:
            return true         # walked through a door; that counts as arriving
        if not ok:
            # one retry with a fresh path, in case somebody wandered into the way
            var here := _player()
            if here == null:
                return true
            var retry := _path(map, _tile_of(map, here.global_position), target_tile,
                _occupied_tiles(map, ignore_npc))
            if retry.size() > 1:
                for j in range(1, retry.size()):
                    await _step_towards(map.stand_position(retry[j]), per_step)
            break
    var p := _player()
    if p == null:
        return true
    var now = _world()
    if now == null or str(now.map.id) != from_map:
        return true         # walked through a door; that counts as arriving
    # A pixel or two of overshoot must not read as a failure.
    return _tile_of(map, p.global_position).distance_squared_to(target_tile) <= 1 \
        or p.global_position.distance_to(map.stand_position(target_tile)) < 12.0


func _walk_to_tile(tile: Vector2i, timeout: float) -> void:
    if not await _walk_to(tile, timeout):
        print("AUTOPILOT: could not reach tile %s" % str(tile))


## Turns to look at a point. Pressing into a wall or a person still turns you,
## which is exactly what a player does when they walk up to somebody.
func _face_towards(point: Vector2) -> void:
    var player := _player()
    if player == null:
        return
    var d := point - player.global_position
    var action := ""
    if absf(d.x) > absf(d.y):
        action = "move_right" if d.x > 0 else "move_left"
    else:
        action = "move_down" if d.y > 0 else "move_up"
    _send(action, true)
    for i in 5:
        await get_tree().physics_frame
    _send(action, false)
    for i in 3:
        await get_tree().physics_frame


## How many times to chase somebody who has wandered off before giving up. Three
## is enough for a leash of a tile and a half; more would hide a real failure.
const TALK_ATTEMPTS := 3


## Walks to a free tile beside an NPC, turns to face them, and talks.
func _talk_to(npc_id: String, timeout: float) -> void:
    var world = _world()
    if world == null:
        return
    var target: Node2D = null
    for n in get_tree().get_nodes_in_group("npc"):
        if n.get("npc_id") == npc_id:
            target = n
            break
    if target == null:
        print("AUTOPILOT: no npc '%s' here" % npc_id)
        return

    var box: Object = _dialogue_box()
    if box != null and box.running:
        print("AUTOPILOT: cannot walk to '%s' -- a conversation is still open" % npc_id)
        return

    # People move. Since M16 every NPC has an idle behaviour and several of them
    # wander on a leash of a tile and a half, so the tile beside them when the
    # walk started is not necessarily the tile beside them when it ends -- the
    # player arrives, presses [Space] at where Kesh was, and the probe finds
    # nothing. This used to print a warning and carry on, and the rest of the
    # script then ran against a world where the conversation had never happened:
    # `slice_full` walked its whole arc and never played the match it exists to
    # play, at exit 0 with no script errors. Try again from where they are now.
    var map = world.map
    for attempt in TALK_ATTEMPTS:
        var npc_tile := _tile_of(map, target.global_position)
        var reached := false
        for offset in [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
            var beside: Vector2i = npc_tile + offset
            if map.is_solid(beside.x, beside.y):
                continue
            reached = await _walk_to(beside, timeout, target)
            if reached:
                break
            # Bumping into the person we are walking towards counts as arriving.
            var pl := _player()
            if pl != null and pl.global_position.distance_to(target.global_position) < 22.0:
                reached = true
                break
        if not reached:
            print("AUTOPILOT: could not get beside '%s'" % npc_id)
            return

        await _face_towards(target.global_position)
        _send("interact", true)
        await get_tree().process_frame
        _send("interact", false)
        await get_tree().create_timer(0.4).timeout
        # The box being open is the only honest test of "did we talk to them".
        # The interaction probe was the old one and it answers a different
        # question: whether somebody is standing there *now*.
        #
        # ...and "the box is open" is not sufficient either, which M36 found the
        # same way M30 found the first half: by opening the screenshots. A sign
        # runs the same box, so `talk_to abel` walking up to a person who
        # happens to be standing under a readable object, pressing [Space] and
        # getting the OBJECT counted as success -- and the rest of the script
        # then advanced through a paragraph about a folding table under a shot
        # captioned with the character's name. Exit 0, no script errors, nine
        # confident PNGs, and the conversation had never happened. That is the
        # M16 slice_full bug exactly, wearing the fix for the M16 slice_full bug.
        #
        # A narrated sign has no speaker, so the name plate is the thing that
        # tells them apart.
        box = _dialogue_box()
        if box != null and box.running:
            if _speaker_matches(box, target):
                return
            print("AUTOPILOT: [Space] beside '%s' opened something else -- '%s'"
                % [npc_id, _speaker_of(box)])
            # Close it before trying again, or the next attempt refuses to walk.
            while box != null and box.running:
                _send("interact", true)
                await get_tree().process_frame
                _send("interact", false)
                await get_tree().create_timer(0.16).timeout
                box = _dialogue_box()
    print("AUTOPILOT: talked to '%s' %d times and no conversation opened"
        % [npc_id, TALK_ATTEMPTS])


## The name on the plate, or "" for a narrated sign, which has no speaker.
func _speaker_of(box: Object) -> String:
    var label = box.get("_name_label")
    return "" if label == null else str(label.text)


func _speaker_matches(box: Object, target: Node2D) -> bool:
    var want := ""
    var data = target.get("data")
    if data != null:
        want = str(data.display_name)
    var got := _speaker_of(box)
    if want == "":
        # No NpcData to compare against: a speaker plate at all is still a much
        # better answer than "a box is open", because a sign has none.
        return got != ""
    # The plate is "Abel Roos   21k" -- DialogueBox appends the rank -- so this
    # is a prefix test and not an equality one. Written down because equality
    # was the first version and it rejected the right person, which reads in the
    # log exactly like the bug it was added to catch.
    return got.begins_with(want)


## Taps through a conversation until the box closes, rather than guessing how
## many presses a piece of writing needs. Counting taps by hand meant the next
## step ran while the player was still locked in dialogue.
func _advance_dialogue(max_taps: int = 60, stop_at_choice: bool = false) -> void:
    var box: Object = _dialogue_box()
    # give it a moment to open
    var waited := 0
    while (box == null or not box.running) and waited < 30:
        await get_tree().process_frame
        waited += 1
        box = _dialogue_box()
    if box == null:
        return
    var taps := 0
    while box != null and box.running and taps < max_taps:
        if stop_at_choice and bool(box.get("_awaiting_choice")):
            return
        _send("interact", true)
        await get_tree().process_frame
        _send("interact", false)
        await get_tree().create_timer(0.16).timeout
        taps += 1
        box = _dialogue_box()
    await get_tree().create_timer(0.15).timeout
    # Re-read the box before complaining. Spending the whole tap budget is not a
    # failure if the box closed on the last tap, or if that tap landed on a
    # choice -- both are the script doing exactly what it was told. Warning on
    # success is the mirror of the _talk_to bug: that one hid a real failure,
    # this one manufactured a false alarm, and both end with nobody reading the
    # log.
    #
    # Still noisy in one case, left rather than guessed at: a script writing
    # `advance: 1` means "step one line and screenshot", not "close this", and
    # gets a truthful-but-useless warning. `advance: 20` means "get through
    # this". Nothing in the step distinguishes the two intents, and inventing a
    # budget threshold to tell them apart would be a guess -- the scripts should
    # say which they mean.
    box = _dialogue_box()
    if taps >= max_taps and box != null and box.running \
            and not (stop_at_choice and bool(box.get("_awaiting_choice"))):
        print("AUTOPILOT: dialogue did not close after %d taps" % taps)


func _dialogue_box() -> Object:
    var world = _world()
    if world == null:
        return null
    var box: Object = world.get("dialogue")
    return box if box != null and is_instance_valid(box) else null


## Picks the nth option of an open choice. Blind tapping always takes the first
## one, which in this game means accepting every rematch you are offered.
func _choose_option(index: int) -> void:
    var box: Object = _dialogue_box()
    var waited := 0
    while (box == null or not bool(box.get("_awaiting_choice"))) and waited < 60:
        await get_tree().process_frame
        waited += 1
        box = _dialogue_box()
    if box == null:
        print("AUTOPILOT: no choice to make")
        return
    for i in index:
        _send("move_down", true)
        await get_tree().process_frame
        _send("move_down", false)
        await get_tree().create_timer(0.12).timeout
    _send("interact", true)
    await get_tree().process_frame
    _send("interact", false)
    await get_tree().create_timer(0.3).timeout
