## Approved match presentation; the existing controller owns setup and persistence.
class_name TableSceneMatch
extends "res://src/go_ui/go_match.gd"

var surface: TableSceneBoardSurface
var player_actor: TableSceneActor
var wren_actor: TableSceneActor
var subtitle: Label
var black_info: Label
var white_info: Label
var status: Label
var controls_hint: Label
var previous_resolution := Vector2i.ZERO
var previous_fps := 0

func _ready() -> void:
    previous_fps = Engine.max_fps
    Engine.max_fps = 30
    previous_resolution = get_window().content_scale_size
    get_window().content_scale_size = Vector2i(768, 432)
    super._ready()

func _exit_tree() -> void:
    super._exit_tree()
    Engine.max_fps = previous_fps
    get_window().content_scale_size = previous_resolution

func _build_ui() -> void:
    super._build_ui()
    get_child(0).hide()
    _panel.hide()
    surface = TableSceneBoardSurface.new()
    surface.position = Vector2(0, 64)
    add_child(surface)
    surface.setup(board_view)
    player_actor = _actor("player", Vector2(-34, 88))
    wren_actor = _actor(request.npc_id, Vector2(532, 88))
    _strip(Rect2(0, 0, 768, 63), Color("202e2d"))
    _strip(Rect2(0, 7, 282, 27), Color("eee4cc"))
    _strip(Rect2(458, 7, 310, 27), Color("eee4cc"))
    _strip(Rect2(0, 34, 282, 3), Color("a97b43"))
    _strip(Rect2(458, 34, 310, 3), Color("a97b43"))
    _strip(Rect2(0, 62, 768, 2), Color("c5ac72"))
    _strip(Rect2(0, 364, 768, 68), Color("202e2d"))
    _strip(Rect2(0, 363, 768, 1), Color("c5ac72"))
    _text(GameState.player_name.to_upper(), Vector2(22, 10), 210, 18, Color("24332f"))
    _text(request.opponent_name.to_upper(), Vector2(470, 10), 280, 18, Color("24332f"))
    black_info = _text("", Vector2(22, 40), 250, 9, Color("d9c69e"))
    white_info = _text("", Vector2(470, 40), 285, 9, Color("d9c69e"))
    _text("%d x %d / %s" % [profile.board_size, profile.board_size, "PRACTICE" if request.unrated or request.practice else "RATED"], Vector2(304, 12), 180, 9, Color("d9c69e"))
    status = _text("A table for two", Vector2(286, 34), 205, 9, Color("efe5cc"))
    _text("First capture wins" if profile.capture_goal > 0 else "Komi %s to White" % _num(setup.komi), Vector2(304, 50), 152, 9, Color("d9c69e"))
    subtitle = _text("", Vector2(24, 378), 720, 9, Color("efe5cc"))
    subtitle.size.y = 24
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    controls_hint = _text("Arrows / mouse: choose     Space / click: place", Vector2(24, 413), 430, 9, Color("afc2b9"))
    _mouse_controls._bar.position = Vector2(492, 407)
    _mouse_controls._bar.scale = Vector2.ONE
    _navigation.position = Vector2(373, 350)
    _navigation.size = Vector2(100, 11)
    _navigation.z_index = 5
    _overlay.scale = Vector2(2, 2)
    _overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    _overlay.size = Vector2(384, 216)
    _overlay.z_index = 90
    _mouse_controls._bar.z_index = 95
    _mouse_controls._modal.position.x = 150
    child_entered_tree.connect(_fit_auxiliary)

func _create_ceremony() -> NigiriCeremony:
    var ceremony := TableNigiri.new()
    ceremony.match_scene = self
    return ceremony

func _fit_auxiliary(child: Node) -> void:
    if child is BoardControls:
        child.scale = Vector2(2, 2)
        return
    if child is BoardBrief or child is HandicapHelp or child is NigiriCeremony or child is TeachingChoice:
        child.scale = Vector2(2, 2)
        child.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
        child.size = Vector2(384, 216)

func _actor(who: String, at: Vector2) -> TableSceneActor:
    var actor := TableSceneActor.new()
    actor.position = at
    actor.size = Vector2(270, 286)
    add_child(actor)
    actor.setup(who)
    return actor

func _strip(rect: Rect2, colour: Color) -> void:
    var strip := ColorRect.new()
    strip.position = rect.position
    strip.size = rect.size
    strip.color = colour
    strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(strip)

func _text(value: String, at: Vector2, width: int, font_size: int, colour: Color) -> Label:
    var label := _label(self, at, width, font_size, colour.to_html())
    label.text = value
    label.clip_text = true
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _announce_move(move: Dictionary) -> void:
    super._announce_move(move)
    if move.is_empty() or int(move.get("point", -1)) < 0:
        return
    var by_player := int(move.get("color", 0)) == player_color
    var actor := player_actor if by_player else wren_actor
    var other := wren_actor if by_player else player_actor
    actor.perform("place", 1.6)
    if not move.get("captured", PackedInt32Array()).is_empty():
        other.perform("surprise", 2.0)
        _capture_relief(actor)

func _capture_relief(actor: TableSceneActor) -> void:
    var token := actor.performance_serial
    var actor_ref: WeakRef = weakref(actor)
    var timer := Timer.new()
    timer.one_shot = true
    timer.wait_time = .8
    add_child(timer)
    timer.timeout.connect(func() -> void:
        var target := actor_ref.get_ref() as TableSceneActor
        if target != null and not result_sent and target.performance_serial == token:
            target.perform("pleased", 2.0)
        timer.queue_free())
    timer.start()

func _set_message(value: String) -> void:
    super._set_message(value)
    _message_pages = UiKit.paginate(value, 720, 22)
    if _message != null:
        _message.text = _message_pages[0] if not _message_pages.is_empty() else ""

func _process(delta: float) -> void:
    super._process(delta)
    if subtitle == null: return
    subtitle.text = _message.text
    var teaching := false
    for child in get_children():
        if child is BoardBrief or child is HandicapHelp or child is TeachingChoice:
            teaching = not child.is_queued_for_deletion()
            if teaching: break
    subtitle.visible = phase != Phase.SETUP
    controls_hint.visible = phase in [Phase.PLAYING, Phase.SCORING]
    surface.position.x = -180 if teaching else 0
    player_actor.visible = not teaching
    wren_actor.visible = not teaching

func _refresh() -> void:
    super._refresh()
    if status == null: return
    surface.set_colours(player_color)
    if player_actor.held_stone != null: surface._stone_material(player_actor.held_stone,player_color)
    if wren_actor.held_stone != null: surface._stone_material(wren_actor.held_stone,GoBoard.opponent(player_color))
    var ready := game != null and game.to_move == player_color
    player_actor.resting = "thinking" if ready else "idle"
    wren_actor.resting = "idle" if ready else "thinking"
    var colour := GoBoard.color_name(player_color)
    var other := GoBoard.opponent(player_color)
    status.text = "Your move / " + colour if ready else request.opponent_name.split(" ")[0] + " is thinking..."
    if phase == Phase.SETUP: status.text = "Choosing colours" if game == null and setup.uses_nigiri else "Before we play"
    elif phase == Phase.PREPARING: status.text = "Setting the table..."
    elif phase == Phase.SCORING: status.text = "Counting together"
    elif phase == Phase.DONE: status.text = "Thanks for the game"
    var yours: int = game.captures[player_color] if game != null else 0
    var theirs: int = game.captures[other] if game != null else 0
    var rank := GameState.rank_label() if GameState.is_ranked() else "Unranked"
    black_info.text = "%s / %s / Captured %d" % [rank, colour.to_upper(), yours]
    white_info.text = "%s / %s / Captured %d" % [request.opponent_rank, GoBoard.color_name(other).to_upper(), theirs]
    if game == null and setup.uses_nigiri:
        black_info.text = rank + " / Colours undecided"
        white_info.text = request.opponent_rank + " / Nigiri"

func _update_scoring_preview() -> void:
    super._update_scoring_preview()
    var score := GoScoring.score(game.board, board_view.dead, game.captures, game.komi)
    _set_message("Black %s / White %s (including komi). Click a group to mark or restore it. H: help." % [_num(score["black"]), _num(score["white"])])

func _finish() -> void:
    if result_sent: return
    if game.state != GoGame.State.FINISHED:
        game.finish_with_score(GoScoring.score(game.board, board_view.dead, game.captures, game.komi))
    var winner := int(game.result.get("winner", 0))
    player_actor.perform("pleased" if winner == player_color else "concern", 999)
    wren_actor.perform("pleased" if winner != player_color else "concern", 999)
    super._finish()
    UiKit.fit_card(_card, _overlay_text, _overlay_text.text, 184)
    _refresh()
