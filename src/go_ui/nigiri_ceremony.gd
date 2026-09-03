## The nigiri ceremony, as a set piece.
##
## Structured after HammerLock Wrestling (SNES, 1994), whose one memorable idea
## was showing the crowd, the ring and a close-up of the action in three
## horizontal windows at once, animated broadly and slowly. So: the room watches
## along the top, the bowl and the hand play out in the middle, and the bottom
## window holds the close-up -- the call, the stones, the count.
##
## Presentation only. GoMatchSetup decides the outcome; this argues about it.
class_name NigiriCeremony
extends Control

signal guess_made(odd: bool)
signal colour_chosen(colour: int)
signal finished()

const VIEW := Vector2(384, 216)
## The three windows, in HammerLock's order: crowd, ring, close-up.
const CROWD := Rect2(0, 0, 384, 34)
const RING := Rect2(0, 38, 384, 104)
const CLOSE := Rect2(0, 146, 384, 70)

const HAND_W := 26
const HAND_H := 26
## Ring-window art is drawn at 2x. Integer only -- this is pixel art.
const SCALE := 2.0
## Holder positions, in ring-window space. The window clips, so "rest" is the
## only one allowed to sit off the top of it.
const HAND_REST_Y := -54.0
const HAND_RAISED_Y := -58.0
const HAND_IN_BOWL_Y := 30.0
const HAND_HELD_Y := 2.0
const TONES := ["skinA", "skinB", "skinC", "skinD"]
const POSE_OPEN := 0
const POSE_FIST := 1
const POSE_SPILL := 2

var opponent_name: String = "Opponent"
var skin_tone: String = "skinD"
var portrait: Texture2D

var _crowd: TextureRect
var _crowd_band: Control
var _ring_band: Control
var _close_band: Control
var _bowl: TextureRect
var _hand_holder: Control
var _hand: TextureRect
var _portrait_rect: TextureRect
var _headline: Label
var _subline: Label
var _call: Label
var _count: Label
var _stones: Array[Control] = []

var _pick_odd := true
var _pick_black := true
var _awaiting: StringName = &""
var _shake := 0.0
var _shake_power := 0.0


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build()


# --- construction ------------------------------------------------------------

func _build() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#14121a")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    # Window 1: the crowd.
    _crowd_band = _band(CROWD, "#3a2340")
    _crowd = TextureRect.new()
    _crowd.texture = load("res://art/ui/crowd.png")
    _crowd.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _crowd.position = Vector2(0, 0)
    _crowd_band.add_child(_crowd)

    # Window 2: the ring -- the bowl and the hand.
    _ring_band = _band(RING, "#5c4230")
    for i in 6:                                  # tatami-ish floor stripes
        var stripe := ColorRect.new()
        stripe.color = Color("#8a6440") if i % 2 == 0 else Color("#6f4e34")
        stripe.position = Vector2(0, i * 18)
        stripe.size = Vector2(384, 18)
        _ring_band.add_child(stripe)

    # Everything in the ring is drawn at 2x: pixel art, so integer scale only,
    # and at 1x the hand was a thumbnail lost in an empty window.
    _bowl = TextureRect.new()
    _bowl.texture = load("res://art/ui/bowl.png")
    _bowl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _bowl.scale = Vector2(SCALE, SCALE)
    _bowl.position = Vector2(26, 44)
    _ring_band.add_child(_bowl)

    # The holder carries the scale and the travel; the hand inside it carries the
    # squash, so the two never fight over one property.
    _hand_holder = Control.new()
    _hand_holder.scale = Vector2(SCALE, SCALE)
    _hand_holder.position = Vector2(44, HAND_REST_Y)
    _ring_band.add_child(_hand_holder)

    _hand = TextureRect.new()
    _hand.texture = _hand_region(POSE_OPEN)
    _hand.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _hand.pivot_offset = Vector2(HAND_W * 0.5, HAND_H)
    _hand_holder.add_child(_hand)

    # Window 3: the close-up.
    _close_band = _band(CLOSE, "#2a2633")
    _portrait_rect = TextureRect.new()
    _portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _portrait_rect.position = Vector2(4, 3)
    _portrait_rect.size = Vector2(64, 64)
    _close_band.add_child(_portrait_rect)

    _headline = UiKit.label(_close_band, Vector2(76, 6), 224, UiKit.PAPER)
    _subline = UiKit.label(_close_band, Vector2(76, 20), 300, Color("#bda98c"), 44)
    _call = UiKit.label(_close_band, Vector2(300, 8), 80, Color("#f2d791"))
    _count = UiKit.label(_ring_band, Vector2(258, 8), 120, Color("#f2d791"))
    _count.add_theme_font_size_override("font_size", 27)
    _count.visible = false


func _band(rect: Rect2, edge: String) -> Control:
    var holder := Control.new()
    holder.position = rect.position
    holder.size = rect.size
    holder.clip_contents = true
    add_child(holder)
    var frame := ColorRect.new()
    frame.color = Color(edge)
    frame.size = rect.size
    holder.add_child(frame)
    # a one-pixel rule top and bottom, so the windows read as windows
    for y in [0.0, rect.size.y - 1.0]:
        var rule := ColorRect.new()
        rule.color = Color("#14121a")
        rule.position = Vector2(0, y)
        rule.size = Vector2(rect.size.x, 1)
        holder.add_child(rule)
    return holder


func _hand_region(pose: int) -> AtlasTexture:
    var at := AtlasTexture.new()
    at.atlas = load("res://art/ui/hands.png")
    var row: int = maxi(0, TONES.find(skin_tone))
    at.region = Rect2(pose * HAND_W, row * HAND_H, HAND_W, HAND_H)
    return at


func setup(display_name: String, tone: String, portrait_tex: Texture2D) -> void:
    opponent_name = display_name
    skin_tone = tone
    portrait = portrait_tex
    if portrait != null:
        var at := AtlasTexture.new()
        at.atlas = portrait
        at.region = Rect2(0, 0, 64, 64)
        _portrait_rect.texture = at
    _hand.texture = _hand_region(POSE_OPEN)


func set_expression(index: int) -> void:
    if portrait == null:
        return
    var at := AtlasTexture.new()
    at.atlas = portrait
    at.region = Rect2(index * 64, 0, 64, 64)
    _portrait_rect.texture = at


# --- the sequence ------------------------------------------------------------

## The ceremony runs at full speed even under the autopilot: it is a set piece,
## and a screenshot of a sped-up version is not a screenshot of what a player
## sees. The whole thing is about eight seconds.
func _fast() -> float:
    return 1.0


## Windows slide in from alternating sides, which is how the era did it.
func wipe_in() -> void:
    var bands := [_crowd_band, _ring_band, _close_band]
    for i in bands.size():
        var band: Control = bands[i]
        var target := band.position
        band.position.x = (-VIEW.x if i % 2 == 0 else VIEW.x)
        var tw := create_tween()
        tw.tween_interval(i * 0.07 * _fast())
        tw.tween_property(band, "position:x", target.x, 0.32 * _fast()) \
            .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    await get_tree().create_timer(0.55 * _fast()).timeout


func wipe_out() -> void:
    var bands := [_close_band, _ring_band, _crowd_band]
    for i in bands.size():
        var band: Control = bands[i]
        var tw := create_tween()
        tw.tween_interval(i * 0.05 * _fast())
        tw.tween_property(band, "position:x",
            (VIEW.x if i % 2 == 0 else -VIEW.x), 0.26 * _fast()) \
            .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    await get_tree().create_timer(0.45 * _fast()).timeout
    finished.emit()


## The hand rises, hesitates, then dives into the bowl. Anticipation first --
## that pause before the movement is most of what makes it read.
func plunge() -> void:
    _headline.text = "%s reaches for the bowl" % opponent_name
    _subline.text = "In an even game the colours are not decided by rank. They are decided by a handful of stones."
    _hand.texture = _hand_region(POSE_OPEN)

    var tw := create_tween()
    # anticipation: rise, hang, then dive
    tw.tween_property(_hand_holder, "position:y", HAND_RAISED_Y, 0.30 * _fast()) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(_hand, "scale", Vector2(0.92, 1.10), 0.30 * _fast())
    tw.tween_interval(0.20 * _fast())
    tw.tween_property(_hand_holder, "position:y", HAND_IN_BOWL_Y, 0.14 * _fast()) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.parallel().tween_property(_hand, "scale", Vector2(1.15, 0.85), 0.14 * _fast())
    await tw.finished
    Audio.play("capture", 0.05)
    _kick(1.4)
    await get_tree().create_timer(0.3 * _fast()).timeout

    # withdraw, closed
    _hand.texture = _hand_region(POSE_FIST)
    var out := create_tween()
    out.tween_property(_hand, "scale", Vector2(1.0, 1.0), 0.10 * _fast())
    out.parallel().tween_property(_hand_holder, "position:y", HAND_HELD_Y, 0.24 * _fast()) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    await out.finished
    _bob()


## A held pose that breathes, so the moment of waiting is not a still image.
func _bob() -> void:
    var tw := create_tween().set_loops()
    tw.tween_property(_hand_holder, "position:y", HAND_HELD_Y - 3.0, 0.6) \
        .set_trans(Tween.TRANS_SINE)
    tw.tween_property(_hand_holder, "position:y", HAND_HELD_Y, 0.6) \
        .set_trans(Tween.TRANS_SINE)


## Asks for odd or even and waits. Returns true for odd.
func ask_guess() -> bool:
    set_expression(2)
    _headline.text = "A closed fist. Odd, or even?"
    _subline.text = "Call it. Guess right and you choose your colour; Black moves first, which is worth about six points."
    _awaiting = &"guess"
    _pick_odd = true
    _refresh_call()
    while _awaiting == &"guess" and is_inside_tree():
        await get_tree().process_frame
    await _slam_pause()
    return _pick_odd


func _slam_pause() -> void:
    await get_tree().create_timer(0.05).timeout


## Slams the call in, wrestling-style: overshoot, impact, shake.
func _slam(text: String) -> void:
    _call.text = text
    _call.scale = Vector2(3.0, 3.0)
    _call.pivot_offset = Vector2(20, 6)
    var tw := create_tween()
    tw.tween_property(_call, "scale", Vector2(1.0, 1.0), 0.16 * _fast()) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    Audio.play("ui_confirm")
    _kick(2.4)
    await tw.finished


## The fist opens and the stones come out one at a time, counting up.
func reveal(count: int) -> void:
    await _slam("ODD" if _pick_odd else "EVEN")
    _headline.text = "The hand opens"
    _subline.text = ""
    _hand.texture = _hand_region(POSE_SPILL)
    _count.visible = true
    _count.text = "0"

    for i in count:
        _drop_stone(i, count)
        _count.text = str(i + 1)
        Audio.play_stone()
        if i == count - 1:
            _kick(1.2)
        await get_tree().create_timer((0.13 if i < 12 else 0.07) * _fast()).timeout
    await get_tree().create_timer(0.25 * _fast()).timeout


func _drop_stone(index: int, total: int) -> void:
    var stone := ColorRect.new()
    var white := index % 2 == 1
    stone.color = Color("#f7f2e6") if white else Color("#0d0b10")
    stone.size = Vector2(7, 7)
    var col := index % 7
    var row := index / 7
    var target := Vector2(150.0 + col * 13.0, 52.0 + row * 13.0)
    stone.position = Vector2(target.x, 4.0)
    _ring_band.add_child(stone)
    _stones.append(stone)
    var tw := create_tween()
    tw.tween_property(stone, "position:y", target.y, 0.16 * _fast()) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.tween_property(stone, "position:y", target.y - 6.0, 0.07 * _fast())  # bounce
    tw.tween_property(stone, "position:y", target.y, 0.07 * _fast())


## The verdict, held long enough to read.
func verdict(count: int, guessed_right: bool, explanation: String) -> void:
    var parity := "ODD" if count % 2 == 1 else "EVEN"
    await _slam(parity)
    set_expression(2 if guessed_right else 1)
    _headline.text = "%d stones. %s." % [count, parity]
    _subline.text = explanation
    Audio.play("game_win" if guessed_right else "game_lose")
    _kick(3.0)
    await get_tree().create_timer(0.6 * _fast()).timeout


## Offered only to whoever won the call.
func ask_colour() -> int:
    _headline.text = "You called it. Which colour?"
    _subline.text = "Black plays first. White is paid komi for going second. Take whichever you would rather argue with."
    # State before refresh: _refresh_call reads _awaiting to know which pair of
    # words it is showing.
    _awaiting = &"colour"
    _pick_black = true
    _refresh_call()
    while _awaiting == &"colour" and is_inside_tree():
        await get_tree().process_frame
    return GoBoard.BLACK if _pick_black else GoBoard.WHITE


func announce(text: String) -> void:
    _headline.text = text
    _subline.text = ""
    await get_tree().create_timer(0.9 * _fast()).timeout


func _refresh_call() -> void:
    if _awaiting == &"colour":
        _call.text = "BLACK" if _pick_black else "WHITE"
    else:
        _call.text = "ODD" if _pick_odd else "EVEN"
    _call.scale = Vector2.ONE


# --- screen shake ------------------------------------------------------------

func _kick(power: float) -> void:
    _shake_power = power
    _shake = 0.22


func _process(delta: float) -> void:
    if _shake <= 0.0:
        if position != Vector2.ZERO:
            position = Vector2.ZERO
        return
    _shake -= delta
    var p: float = _shake_power * (_shake / 0.22)
    position = Vector2(randf_range(-p, p), randf_range(-p, p)).round()


func _unhandled_input(event: InputEvent) -> void:
    if _awaiting == &"":
        return
    if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
        if _awaiting == &"colour":
            _pick_black = not _pick_black
        else:
            _pick_odd = not _pick_odd
        Audio.play("ui_move")
        _refresh_call()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("interact"):
        if _awaiting == &"colour":
            colour_chosen.emit(GoBoard.BLACK if _pick_black else GoBoard.WHITE)
        else:
            guess_made.emit(_pick_odd)
        _awaiting = &""
        get_viewport().set_input_as_handled()
