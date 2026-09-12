## Drives projected eight-way people, with the original four-way grid fallback.
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

var _character_id := ""
var _rendered_actions: Texture2D
var _rendered_walk: Texture2D
var motion_vector := Vector2.ZERO
var _room: RoomProjection
var _rendered := false
var _shadow: Polygon2D
var activity := ""
var _walk_texture: Texture2D
var _action_texture: Texture2D
var direction: int = Facing.Dir.DOWN
var walking: bool = false
## Player running changes this; NPCs retain the default walking gait.
var gait_scale: float = 1.0

var _step := 0
var _timer := 0.0
var _idle := 0.0
var _base_offset := Vector2.ZERO


func _ready() -> void:
    if _rendered:
        return
    hframes = 3
    vframes = 4
    centered = true
    offset = Vector2(0, -FRAME_H / 2.0)
    _base_offset = offset
    # A room full of people breathing in unison is one person.
    _idle = randf() * IDLE_PERIOD
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    if _character_id != "":
        set_sheet(_character_id)
    _apply()


func set_sheet(character_id: String) -> void:
    _character_id = character_id
    var node: Node = get_parent()
    while node != null:
        if "map" in node and node.get("map") is MapData:
            _room = node.map.presentation
            break
        node = node.get_parent()
    var rendered_path := "res://art/rendered/people/%s_sheet.png" % character_id
    if _room != null and ResourceLoader.exists(rendered_path):
        _rendered = true
        texture = load(rendered_path)
        _rendered_walk = texture
        var actions_path := "res://art/rendered/people/%s_actions.png" % character_id
        if ResourceLoader.exists(actions_path):
            _rendered_actions = load(actions_path)
        hframes = 6
        vframes = 8
        offset = Vector2(0, -22)
        top_level = true
        material = _room.material_for_actor()
        _shadow = Polygon2D.new()
        var points := PackedVector2Array()
        for i in 16:
            points.append(Vector2(cos(i * TAU / 16.0) * 6, sin(i * TAU / 16.0) * 2))
        _shadow.polygon = points
        _shadow.color = Color(0.04, 0.035, 0.025, 0.38)
        _shadow.show_behind_parent = true
        _shadow.use_parent_material = true
        add_child(_shadow)
        return
    var path := "res://art/sprites/%s.png" % character_id
    if ResourceLoader.exists(path):
        texture = load(path)
        _walk_texture = texture
        var action_path := "res://art/sprites/%s_actions.png" % character_id
        if ResourceLoader.exists(action_path):
            _action_texture = load(action_path)
    else:
        push_warning("CharacterSprite: no sheet for '%s'" % character_id)


func _process(delta: float) -> void:
    if _rendered:
        _idle += delta
        var feet: Vector2 = get_parent().global_position
        global_position = _room.project(feet).round()
        z_as_relative = false
        z_index = clampi(int(global_position.y), 0, 4000)
        (material as ShaderMaterial).set_shader_parameter("actor_depth", _room.ground_depth(feet))
        var vector := motion_vector if motion_vector != Vector2.ZERO else Facing.to_vector(direction)
        var screen_vector := _room.project_vector(vector)
        var facing_eight := posmod(roundi(atan2(screen_vector.x, screen_vector.y) / (PI / 4)), 8)
        texture = _rendered_walk
        hframes = 6
        var pose := 0
        if walking:
            pose = [1, 2, 3, 2][int(_idle / gait_step_time(gait_scale)) % 4]
        elif activity != "":
            pose = 4 + int(_idle / 0.8) % 2
        if not walking and activity != "" and _rendered_actions != null:
            texture = _rendered_actions
            hframes = 10
            pose = maxi(0, ["play", "read", "fold", "wipe", "arrange"].find(activity)) * 2 + int(_idle / 0.8) % 2
        frame = facing_eight * hframes + pose
        return
    if activity != "" and _action_texture != null and not walking:
        texture = _action_texture
        hframes = 2
        vframes = 20
        _idle += delta
        frame = (["play", "read", "fold", "wipe", "arrange"].find(activity) * 4 + direction) * 2 + int(_idle / 0.8) % 2
        offset = _base_offset
        return
    if texture != _walk_texture:
        texture = _walk_texture
        hframes = 3
        vframes = 4
        _apply()
    if walking:
        # The walk frames carry their own bob, drawn into the sheet.
        offset = _base_offset
        _timer += delta
        var frame_time := gait_step_time(gait_scale)
        if _timer >= frame_time:
            _timer -= frame_time
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
    motion_vector = Vector2.ZERO
    if dir != direction:
        direction = dir
        _apply()


static func gait_step_time(scale: float) -> float:
    return STEP_TIME / maxf(scale, 0.01)


func _apply() -> void:
    if _rendered:
        return
    if activity != "" or (_action_texture != null and texture == _action_texture):
        return
    frame = direction * 3 + _step
