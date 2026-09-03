## Drives a 3-frame x 4-direction character sheet (16x24 cells).
##
## Every character in the game -- player and NPC alike -- uses the same sheet
## layout, which is what tools/gen_characters.py emits.
class_name CharacterSprite
extends Sprite2D

const FRAME_W := 16
const FRAME_H := 24
const STEP_TIME := 0.18
## A standing character breathes: one pixel, up and down, slowly.
##
## An integer offset and nothing else -- ART_DIRECTION section 5 forbids any
## non-integer offset, and at 16x24 one pixel is plenty. Doing it here rather
## than as a fourth sprite column means it costs no art and every character in
## the game, player included, gets it for nothing.
const IDLE_PERIOD := 1.25

var direction: int = Facing.Dir.DOWN
var walking: bool = false

var _step := 0
var _timer := 0.0
var _idle := 0.0
var _base_offset := Vector2.ZERO


func _ready() -> void:
    hframes = 3
    vframes = 4
    centered = true
    offset = Vector2(0, -FRAME_H / 2.0)
    _base_offset = offset
    # A room full of people breathing in unison is one person.
    _idle = randf() * IDLE_PERIOD
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _apply()


func set_sheet(character_id: String) -> void:
    var path := "res://art/sprites/%s.png" % character_id
    if ResourceLoader.exists(path):
        texture = load(path)
    else:
        push_warning("CharacterSprite: no sheet for '%s'" % character_id)


func _process(delta: float) -> void:
    if walking:
        # The walk frames carry their own bob, drawn into the sheet.
        offset = _base_offset
        _timer += delta
        if _timer >= STEP_TIME:
            _timer -= STEP_TIME
            _step = 1 if _step != 1 else 2
            _apply()
        return
    if _step != 0:
        _step = 0
        _timer = 0.0
        _apply()
    _idle += delta
    var up := fmod(_idle, IDLE_PERIOD) < IDLE_PERIOD * 0.5
    offset.y = _base_offset.y - (1.0 if up else 0.0)


func face(dir: int) -> void:
    if dir != direction:
        direction = dir
        _apply()


func _apply() -> void:
    frame = direction * 3 + _step
