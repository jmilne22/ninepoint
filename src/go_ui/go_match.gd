## A game of Go, played. Owns the turn loop, the HUD around the board, the
## scoring phase, and the result -- then hands a MatchResult back to the world.
extends Control

## A pause before the opponent answers, so a move reads as a decision rather than
## a flicker. The autopilot turns it down so a scripted game does not take a minute.
const THINK_DELAY := 0.35
const THINK_DELAY_FAST := 0.05

## How long the last word before the count stays up. See _opponent_turn.
const PASS_BEAT := 1.1


func _think_delay() -> float:
    return THINK_DELAY_FAST if Autopilot.active else THINK_DELAY

var request: MatchRequest
var profile: OpponentProfile
## What the person across the board says about what just happened.
var voice: TableTalkVoice
var game: GoGame
var opponent: GoOpponent
var player_color: int = GoBoard.BLACK
var result_sent: bool = false

var board_view: GoBoardView
var _panel: NinePatchRect
var _portrait: TextureRect
var _name: Label
var _rank: Label
var _turn: Label
var _captures: Label
var _details: Label
var _message: Label
var _hints: Label
var _overlay: Control
var _card: NinePatchRect
var _overlay_text: Label

## The match is a short ceremony, not a character: an explicit state with
## enter/exit and its own input handling, as godot-gdscript-patterns teaches,
## but held in one scene rather than four State nodes -- there is nothing here
## that needs per-frame update or physics.
enum Phase { SETUP, INTRO, PLAYING, SCORING, CONFIRM, DONE }
var phase: int = Phase.SETUP

var setup: GoMatchSetup
var _last_message := ""

## Per-state input, keyed by phase. Set in _enter_phase, cleared on exit.
var _awaiting: StringName = &""
var _answer: Variant = null


func _ready() -> void:
    request = MatchBridge.pending_request
    if request == null:
        request = _debug_request()
    profile = request.profile
    setup = GoMatchSetup.prepare(profile.setup_rule(), request.player_strength,
        profile.strength(), profile.board_size, profile.komi)
    if profile.colour_rule != "by_rank" and profile.handicap >= 2:
        setup.handicap = profile.handicap        # a scripted match may pin stones
        setup.komi = profile.komi

    # The board had no music of its own: world.gd was the only caller of
    # play_music(), so whatever the street happened to be playing carried on
    # underneath a game. Returning to the world re-applies the map's track, so
    # nothing has to put this back.
    #
    # Which track depends on who this is and what is at stake -- see MatchMusic.
    # It starts here rather than after _setup_phase() on purpose: the nigiri
    # ceremony is part of the occasion and should have the occasion's music.
    var track := MatchMusic.theme_for(request)
    # play_music() on a name it does not have returns without touching the
    # player, so a typo in a profile's `theme` would leave the street's track
    # running under a title match and never say a word about it.
    if not Audio.has_track(track):
        push_warning("go_match: no audio/%s.wav -- falling back to the bed" % track)
        track = MatchMusic.DEFAULT
    Audio.play_music(track)

    _build_ui()
    # Show the empty board straight away. The colours are not settled yet, but
    # the board you are about to play on is, and a blank half-screen during the
    # ceremony reads as a bug.
    board_view.set_game(GoGame.new(setup.board_size, setup.komi, 0))
    board_view.interactive = false
    set_process_unhandled_input(true)
    _run()


func _debug_request() -> MatchRequest:
    var r := MatchRequest.new()
    var path := OpponentProfile.path_for("kesh", 9)
    r.profile = load(path) if ResourceLoader.exists(path) else OpponentProfile.new()
    r.opponent_name = r.profile.display_name
    r.opponent_rank = r.profile.rank_label
    r.npc_id = "kesh"
    r.context_id = "debug"
    r.portrait_path = "res://art/portraits/kesh.png"
    return r


# --- layout ------------------------------------------------------------------

func _build_ui() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color("#2a2633")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    board_view = GoBoardView.new()
    board_view.position = Vector2(6, 12)
    board_view.size = Vector2(192, 192)
    board_view.point_activated.connect(_on_point_activated)
    add_child(board_view)

    _panel = NinePatchRect.new()
    _panel.texture = load("res://art/ui/panel.png")
    for m in ["left", "top", "right", "bottom"]:
        _panel.set("patch_margin_%s" % m, 6)
    _panel.position = Vector2(202, 8)
    _panel.size = Vector2(176, 182)
    _panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(_panel)

    _portrait = TextureRect.new()
    _portrait.position = Vector2(8, 8)
    _portrait.size = Vector2(64, 64)
    _portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    if request.portrait_path != "" and ResourceLoader.exists(request.portrait_path):
        var at := AtlasTexture.new()
        at.atlas = load(request.portrait_path)
        at.region = Rect2(0, 0, 64, 64)
        _portrait.texture = at
    _panel.add_child(_portrait)

    _name = _label(_panel, Vector2(76, 10), 92, 9, "#14121a")
    _name.text = request.opponent_name
    _name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _name.size.y = 22
    _rank = _label(_panel, Vector2(76, 34), 92, 9, "#8a6023")
    _rank.text = request.opponent_rank
    _turn = _label(_panel, Vector2(76, 50), 92, 9, "#45404f")

    _captures = _label(_panel, Vector2(10, 74), 156, 9, "#2a2633")
    # Rows measured against the font's 11 px line height: captures at 74, the
    # details from 90, and the table talk's four rows from 132 to 176, the
    # panel's inner edge. They used to overlap by a pixel at the top and sit on
    # the frame at the bottom.
    _details = _label(_panel, Vector2(10, 90), 156, 9, "#6b6577")
    _details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _details.size.y = 40

    _message = _label(_panel, Vector2(10, 132), 156, 9, "#45404f")
    _message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _message.size.y = 44

    _hints = _label(self, Vector2(204, 194), 176, 9, "#8a8494")
    _hints.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _hints.size.y = 22

    _overlay = Control.new()
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.visible = false
    add_child(_overlay)
    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.07, 0.1, 0.72)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.add_child(dim)
    _card = UiKit.panel(_overlay, Rect2(52, 62, 288, 92))
    _overlay_text = UiKit.label(_card, Vector2(10, 10), 268, UiKit.INK, 72)


func _label(parent: Node, pos: Vector2, width: int, font_size: int, colour: String) -> Label:
    var l := Label.new()
    l.position = pos
    l.size = Vector2(width, font_size + 6)
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color(colour))
    parent.add_child(l)
    return l


# --- the game ----------------------------------------------------------------

## Waits for the player to answer whatever the current state asked. One helper
## replaces the three loose booleans the flow used to juggle.
func _ask(what: StringName) -> Variant:
    _awaiting = what
    _answer = null
    while _awaiting == what and is_inside_tree():
        await get_tree().process_frame
    return _answer


func _answered(value: Variant) -> void:
    _answer = value
    _awaiting = &""


func _run() -> void:
    await _setup_phase()
    if not is_inside_tree():
        return

    # Only now do the colours, the stones and the komi exist.
    game = GoGame.new(setup.board_size, setup.komi, setup.handicap)
    game.capture_goal = profile.capture_goal
    player_color = setup.player_color
    opponent = OpponentFactory.create(profile, game)
    voice = TableTalkVoice.load_voice(request.npc_id)
    board_view.set_game(game)
    board_view.interactive = true

    phase = Phase.INTRO
    var intro := request.intro_line
    if intro == "":
        intro = "%s -- %s. %dx%d." % [request.opponent_name, request.opponent_rank,
            game.size(), game.size()]
    if game.capture_goal > 0:
        intro = "Capture Go. First to take %s wins." % (
            "a stone" if game.capture_goal == 1 else "%d stones" % game.capture_goal)
    _set_message(intro)
    _refresh()
    await get_tree().create_timer(0.6).timeout

    phase = Phase.PLAYING
    _refresh()
    while game.state == GoGame.State.PLAYING:
        if game.to_move == player_color:
            _refresh()
            await _ask(&"move")
        else:
            _refresh()
            await get_tree().create_timer(_think_delay()).timeout
            await _opponent_turn()
        await get_tree().process_frame

    if game.state == GoGame.State.SCORING:
        await _scoring_phase()
    await _finish()


# --- setup: who takes black --------------------------------------------------

## Nigiri, or the handicap explanation. The even-game path is a set piece; see
## NigiriCeremony.
func _setup_phase() -> void:
    phase = Phase.SETUP
    _refresh()

    if not setup.uses_nigiri:
        if setup.is_handicap():
            _set_message(setup.explanation)
            await get_tree().create_timer((1.4 if not Autopilot.active else 0.2)).timeout
        return

    var ceremony: NigiriCeremony = NigiriCeremony.new()
    add_child(ceremony)
    var tone := "skinD"
    var npc_path := "res://data/npcs/%s.tres" % request.npc_id
    if ResourceLoader.exists(npc_path):
        tone = _skin_tone_for(request.npc_id)
    var portrait_tex: Texture2D = null
    if request.portrait_path != "" and ResourceLoader.exists(request.portrait_path):
        portrait_tex = load(request.portrait_path)
    ceremony.setup(request.opponent_name, tone, portrait_tex)

    await ceremony.wipe_in()
    if not is_inside_tree():
        return
    await ceremony.plunge()

    var guessed_odd: bool = await ceremony.ask_guess()
    if not is_inside_tree():
        return

    # The outcome is decided by GoMatchSetup, not by the animation; the animation
    # is told what happened and plays it.
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var seed_value := rng.seed
    var probe := GoMatchSetup.prepare(GoMatchSetup.Rule.NIGIRI, 0, 0,
        setup.board_size, setup.komi)
    var probe_rng := RandomNumberGenerator.new()
    probe_rng.seed = seed_value
    probe.run_nigiri(guessed_odd, probe_rng, GoBoard.BLACK)

    await ceremony.reveal(probe.grabbed)
    if not is_inside_tree():
        return

    var choice := GoBoard.BLACK
    if probe.guessed_right:
        await ceremony.verdict(probe.grabbed, true, "You called it. Your pick.")
        choice = await ceremony.ask_colour()
        if not is_inside_tree():
            return

    var final_rng := RandomNumberGenerator.new()
    final_rng.seed = seed_value
    setup.run_nigiri(guessed_odd, final_rng, choice)

    if not probe.guessed_right:
        await ceremony.verdict(probe.grabbed, false, setup.explanation)
    else:
        await ceremony.announce("You take %s." % GoBoard.color_name(setup.player_color))

    await ceremony.wipe_out()
    if not is_inside_tree():
        return
    ceremony.queue_free()
    _set_message(setup.explanation)
    _refresh()


## The ceremony draws the opponent's own hand, so it needs their skin tone. The
## character records live in the art tool; the mapping is mirrored here.
func _skin_tone_for(npc_id: String) -> String:
    const TONES := {
        "wren": "skinD", "kesh": "skinB", "pip": "skinA", "bertie": "skinD",
        "nadia": "skinA", "hana": "skinB", "tomas": "skinA", "marguerite": "skinD",
        "joos": "skinC",
    }
    return str(TONES.get(npc_id, "skinD"))


# --- turns --------------------------------------------------------------------

func _opponent_turn() -> void:
    var move: Dictionary = await _await_move()
    match str(move.get("type", "pass")):
        "pass":
            game.pass_turn()
            Audio.play("pass")
            _set_message("%s passes." % request.opponent_name)
            _react()
            # A pass that ends the game is followed immediately by the counting
            # screen, which writes its own message over this one -- so what they
            # said about stopping would never be on screen long enough to read.
            # Not _think_delay(): under autopilot that is 0.05s, and a beat
            # nobody can screenshot is a beat nobody can check.
            if game.state == GoGame.State.SCORING:
                board_view.queue_redraw()
                _refresh()
                await get_tree().create_timer(PASS_BEAT).timeout
        "resign":
            game.resign(GoBoard.opponent(player_color))
            _set_message(profile.on_resign if profile.on_resign != "" \
                else "%s resigns." % request.opponent_name)
        _:
            var point := int(move["point"])
            if not game.play(point):
                push_warning("Opponent proposed an illegal move; passing instead.")
                game.pass_turn()
            else:
                _announce_move(game.last_move())
                _react()
    board_view.queue_redraw()
    _refresh()


func _await_move() -> Dictionary:
    var move = opponent.choose_move(game)
    if move is Dictionary:
        return move
    return await move


## What the opponent says about the move that was just played -- theirs or the
## player's. Tags come from the rules (GoTableTalk), lines from data/banter/, and
## most moves produce nothing at all, which is the point: somebody who remarks on
## everything is a tutorial rather than a person.
##
## Reactions are to OUTCOMES only: what happened, never what should have been
## played instead.
func _react() -> void:
    if voice == null:
        return
    var speaker := GoBoard.opponent(player_color)
    var line := voice.speak(GoTableTalk.events(game, speaker), game.move_number())
    if line == "":
        # Nothing happened worth remarking on, so occasionally say how it is going.
        if game.move_number() >= 8:
            line = voice.idle_line(GoTableTalk.standing(game, speaker), game.move_number())
    if line != "":
        _set_message(line)


func _on_point_activated(point: int) -> void:
    if phase == Phase.SCORING:
        _toggle_dead(point)
        return
    if phase != Phase.PLAYING or _awaiting != &"move" or game.to_move != player_color:
        return
    var code := game.legality(point)
    if code != GoGame.Legality.LEGAL:
        _set_message(game.legality_reason(code))
        Audio.play("illegal")
        return
    game.play(point)
    _announce_move(game.last_move())
    _react()
    _answered(point)
    board_view.queue_redraw()
    _refresh()


## Sound and motion for a move that has just been played. The board view owns
## the animation; this only says what happened.
func _announce_move(move: Dictionary) -> void:
    if move.is_empty() or int(move.get("point", -1)) < 0:
        return
    Audio.play_stone()
    board_view.animate_placement(int(move["point"]))
    var captured: PackedInt32Array = move.get("captured", PackedInt32Array())
    if captured.size() > 0:
        board_view.animate_capture(captured)
        Audio.play("capture")


# --- counting -----------------------------------------------------------------

func _toggle_dead(point: int) -> void:
    if game.board.get_idx(point) == GoBoard.EMPTY:
        return
    var chain := game.board.chain_at(point)
    var currently: bool = board_view.dead.has(point)
    for s in chain["stones"]:
        if currently:
            board_view.dead.erase(s)
        else:
            board_view.dead[s] = true
    _update_scoring_preview()


func _scoring_phase() -> void:
    phase = Phase.SCORING
    board_view.dead = GoScoring.estimate_dead(game.board)
    board_view.show_territory = true
    _set_message("Both players passed. Stones marked with a cross are dead.")
    _update_scoring_preview()
    _refresh()
    await _ask(&"scoring")


func _update_scoring_preview() -> void:
    var live := GoScoring.board_without_dead(game.board, board_view.dead)
    board_view.territory = GoScoring.territory_map(live)
    var s := GoScoring.score(game.board, board_view.dead, game.captures, game.komi)
    _details.text = "Black %s   White %s" % [_num(s["black"]), _num(s["white"])]
    board_view.queue_redraw()


func _num(v: float) -> String:
    return "%.1f" % v if absf(v - roundf(v)) > 0.01 else str(int(v))


# --- the result ---------------------------------------------------------------

func _finish() -> void:
    if result_sent:
        return
    result_sent = true
    phase = Phase.DONE
    if game.state != GoGame.State.FINISHED:
        var s := GoScoring.score(game.board, board_view.dead, game.captures, game.komi)
        game.finish_with_score(s)

    var res := MatchResult.new()
    res.context_id = request.context_id
    res.npc_id = request.npc_id
    res.player_color = player_color
    res.winner = int(game.result.get("winner", GoBoard.EMPTY))
    res.player_won = res.winner == player_color
    res.margin = float(game.result.get("margin", 0.0))
    res.by_resignation = bool(game.result.get("by_resignation", false))
    res.by_capture = bool(game.result.get("by_capture", false))
    res.board_size = game.size()
    res.handicap = game.handicap
    # In a handicap game the stones belong to whoever is Black. Which side that
    # was is the difference between beating a 1 dan and being given five stones
    # by one, and the rank ladder cannot tell them apart afterwards without this.
    res.handicap_taken = game.handicap if player_color == GoBoard.BLACK else 0
    res.komi = game.komi
    res.move_count = game.move_number()
    res.unrated = request.unrated
    res.opponent_strength = request.profile.strength() if request.profile != null else -1
    res.sgf = GoSgf.to_sgf(game, {
        "PB": GameState.player_name if player_color == GoBoard.BLACK else request.opponent_name,
        "PW": request.opponent_name if player_color == GoBoard.BLACK else GameState.player_name,
        "RE": str(game.result.get("text", "")),
    })
    res.summary = str(game.result.get("text", ""))

    var headline := "You win" if res.player_won else "You lose"
    if res.winner == GoBoard.EMPTY:
        headline = "A draw"
    var body := res.summary
    if not res.by_resignation and not res.by_capture and game.result.has("detail"):
        var d: Dictionary = game.result["detail"]
        body += "\n\nBlack: %d territory + %d prisoners\nWhite: %d territory + %d prisoners + %s komi" % [
            d["black_territory"], d["black_prisoners"],
            d["white_territory"], d["white_prisoners"], _num(d["komi"])]
    UiKit.fit_card(_card, _overlay_text,
        "%s.\n%s\n\n[Space] to carry on" % [headline, body], 288)
    _overlay.visible = true
    _hints.text = ""

    await _ask(&"dismiss")
    opponent.shutdown()
    # Not awaited: finishing the match frees this scene, and awaiting our own
    # destruction leaves a dead coroutine behind.
    MatchBridge.finish_match(res)


# --- presentation ------------------------------------------------------------

func _set_message(text: String) -> void:
    _last_message = text
    if _message != null:
        _message.text = text


func _refresh() -> void:
    if _turn == null:
        return
    var my_name := GameState.player_name
    var black_name := my_name if player_color == GoBoard.BLACK else request.opponent_name
    var white_name := request.opponent_name if player_color == GoBoard.BLACK else my_name

    # During setup there is no game yet -- the colours are still being decided.
    if game == null:
        _turn.text = "Nigiri" if setup.uses_nigiri else "Setting up"
        _captures.text = ""
        _details.text = "%dx%d  komi %s" % [
            setup.board_size, setup.board_size, _num(setup.komi)]
        return

    match phase:
        Phase.PLAYING:
            var who := "Your move" if game.to_move == player_color else "%s is thinking" % request.opponent_name
            _turn.text = "%s (%s)" % [who, GoBoard.color_name(game.to_move)]
            _hints.text = "Arrows: move   Space: place\nP: pass   R: resign"
        Phase.SCORING:
            _turn.text = "Counting"
            _hints.text = "Space: toggle a dead group\nP: accept the count"
        Phase.DONE:
            _turn.text = "Finished"
        _:
            _turn.text = ""
    _captures.text = "Prisoners  B %d   W %d" % [
        game.captures[GoBoard.BLACK], game.captures[GoBoard.WHITE]]
    if phase != Phase.SCORING:
        # Four short lines rather than two long ones: the panel is 156px wide and
        # a single line of names ran off the end of it.
        var handicap_text := "   H%d" % game.handicap if game.handicap >= 2 else ""
        var goal_text := ""
        if game.capture_goal > 0:
            goal_text = "   first %d" % game.capture_goal
        _details.text = "%dx%d  komi %s%s%s\nB %s\nW %s\nmove %d" % [
            game.size(), game.size(), _num(game.komi), handicap_text, goal_text,
            black_name, white_name, game.move_number()]


## Input is routed by state. Each state answers its own question and nothing
## else reads the keyboard, which is what the phase flags used to get wrong.
func _unhandled_input(event: InputEvent) -> void:
    if not is_inside_tree():
        return
    var handled := false
    match phase:
        Phase.SETUP:
            handled = _input_setup(event)
        Phase.CONFIRM:
            handled = _input_confirm(event)
        Phase.DONE:
            handled = _input_done(event)
        _:
            handled = _input_board(event)
    if handled:
        get_viewport().set_input_as_handled()


## During setup the ceremony reads the keyboard itself, so the match keeps out
## of the way.
func _input_setup(_event: InputEvent) -> bool:
    return false


## R sits one key away from P, and resignation is the only irreversible thing on
## the board: a mistyped pass used to lose the game outright, with no way back.
## The turn loop stays parked in _ask(&"move") throughout, so cancelling needs
## to do nothing but put the phase back.
func _prompt_resign() -> void:
    phase = Phase.CONFIRM
    UiKit.fit_card(_card, _overlay_text,
        "Resign to %s?\n\nThe game is scored as a loss and goes on your record.\n\n[R] resign   [Esc] keep playing" % request.opponent_name,
        288)
    _overlay.visible = true
    _hints.text = "R: resign   Esc: keep playing"


func _input_confirm(event: InputEvent) -> bool:
    if event.is_action_pressed("go_resign"):
        _overlay.visible = false
        phase = Phase.PLAYING
        game.resign(player_color)
        _answered(-2)
        return true
    if event.is_action_pressed("cancel"):
        _overlay.visible = false
        phase = Phase.PLAYING
        _refresh()
        return true
    # Anything else is swallowed: an arrow key must not move the cursor behind
    # the card, and Space must not fall through to placing a stone.
    return event is InputEventKey and event.pressed


func _input_done(event: InputEvent) -> bool:
    if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
        _answered(true)
        return true
    return false


func _input_board(event: InputEvent) -> bool:
    if board_view == null or not is_instance_valid(board_view):
        return false
    if event.is_action_pressed("move_left"):
        board_view.move_cursor(Vector2i(-1, 0))
    elif event.is_action_pressed("move_right"):
        board_view.move_cursor(Vector2i(1, 0))
    elif event.is_action_pressed("move_up"):
        board_view.move_cursor(Vector2i(0, -1))
    elif event.is_action_pressed("move_down"):
        board_view.move_cursor(Vector2i(0, 1))
    elif event.is_action_pressed("interact"):
        board_view.activate_cursor()
    elif event.is_action_pressed("go_pass"):
        if phase == Phase.SCORING:
            _answered(true)
        elif _awaiting == &"move" and game.to_move == player_color:
            game.pass_turn()
            Audio.play("pass")
            _answered(-1)
            _set_message("You pass.")
            # They have something to say about it, and it is the only warning a
            # beginner gets that passing does not end a game on its own.
            _react()
            _refresh()
    elif event.is_action_pressed("go_resign"):
        if phase == Phase.PLAYING and _awaiting == &"move":
            _prompt_resign()
    else:
        return false
    return true



