## The hour of the day, as light on the city.
##
## Reads `GameState.time_block` and never writes it: this is the setting's
## register, not a clock. Time still advances only on story beats, and the day
## counter is still deliberately deferred -- see GAME_DESIGN.md section 0.
##
## A CanvasModulate takes the whole world down to the colour of the hour, and
## one additive glow sits over every tile that lights itself. Additive is what
## makes a lit window read as lit: the modulate still multiplies the glow, so a
## lamp automatically counts for nothing at noon and for everything at night,
## with no second canvas to keep in step with the camera.
class_name Ambient
extends Node2D

## Ambient tint per time block. Afternoon is white: at the hour the game has
## always been set, the city looks exactly as it did before there were hours.
const TINTS := {
    "morning": Color(0.92, 0.94, 1.0),
    "afternoon": Color(1.0, 1.0, 1.0),
    "dusk": Color(0.74, 0.62, 0.60),
    "night": Color(0.38, 0.42, 0.60),
}

## How much of its own light a glow keeps. A lamp at noon is invisible.
const GLOW_STRENGTH := {
    "morning": 0.0,
    "afternoon": 0.0,
    "dusk": 0.6,
    "night": 1.0,
}

## Indoors the hour barely lands: someone has turned the lights on. Without
## this, De Ketel at eleven at night was as blue as the street outside it, which
## is not what a lit bar looks like from inside.
const INDOOR_TINTS := {
    "morning": Color(0.98, 0.98, 1.0),
    "afternoon": Color(1.0, 1.0, 1.0),
    "dusk": Color(0.94, 0.90, 0.88),
    "night": Color(0.82, 0.78, 0.82),
}

## Rain takes the colour out of whatever hour it falls in.
const RAIN_TINT := Color(0.88, 0.90, 0.95)

## Tiles that light themselves, and the colour they throw.
const LIGHT_SOURCES := {
    "lamp_post": Color("#e0b25c"),
    "tram_pole": Color("#c08f3a"),
    "snack_window": Color("#f2d791"),
    "neon_sign": Color("#9fe4ec"),
    "stove": Color("#e0b25c"),
    "wall_plaster_win": Color("#f2d791"),
    "wall_brick_win": Color("#e0b25c"),
    "wall_int_win": Color("#f2d791"),
    "glass_curtain": Color("#a8cbe0"),
}

## How far each kind of light throws, as a multiple of the base disc. A street
## lamp lights a junction; a window lights its own sill and no more.
const GLOW_SCALE := {
    "lamp_post": 2.2,
    "tram_pole": 1.4,
    "snack_window": 1.8,
    "neon_sign": 1.3,
    "stove": 1.6,
    "glass_curtain": 1.2,
}

const GLOW_RADIUS := 24

## How a light behaves once it is on. A real lamp is never quite steady, and a
## perfectly steady one is the thing that makes a night scene look painted.
##
##   amp/hz   depth and speed of a sine hum, as a fraction of the base strength
##   fault    the neon: mostly on, and occasionally not. Its timing is taken
##            from TileAnimator so the tube and the light it throws go out
##            together -- a lit blob over a dark tube is worse than neither.
const FLICKER := {
    "lamp_post": {"amp": 0.05, "hz": 0.7},
    "tram_pole": {"amp": 0.04, "hz": 0.5},
    "snack_window": {"amp": 0.06, "hz": 1.3},
    "stove": {"amp": 0.18, "hz": 1.9},
    "neon_sign": {"amp": 0.03, "hz": 2.2, "fault": true},
}

var block: String = "afternoon"
var raining: bool = false
var indoors: bool = false

var _modulate: CanvasModulate
var _glows: Array[Sprite2D] = []
var _flicker: Array[Dictionary] = []
var _rain: CanvasLayer
var _strength: float = 0.0
var _t: float = 0.0
var _neon_on: float = 4.50
var _neon_cycle: float = 4.66

static var _tex: ImageTexture = null


func setup(map: MapData) -> void:
    block = GameState.time_block
    raining = GameState.has_flag("raining")
    indoors = map.indoors

    _modulate = CanvasModulate.new()
    _modulate.name = "Tint"
    add_child(_modulate)

    var hold: Array = TileAnimator.ANIMATIONS.get("neon_sign", {}).get("hold", [4.5, 0.16])
    if hold.size() >= 2:
        _neon_on = float(hold[0])
        _neon_cycle = _neon_on + float(hold[1])

    _place_glows(map)
    apply()
    EventBus.time_block_changed.connect(set_block)
    EventBus.weather_changed.connect(set_raining)


## One soft disc per self-lit tile, so a window is a smear of warm light on a
## dark street rather than a bright rectangle.
func _place_glows(map: MapData) -> void:
    var t := map.tile_size
    var mat := CanvasItemMaterial.new()
    mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    for y in map.height:
        for x in map.width:
            var tile_name := map.tile_name_at(map.ground, x, y)
            if not LIGHT_SOURCES.has(tile_name):
                continue
            var g := Sprite2D.new()
            g.texture = _glow_texture()
            g.material = mat
            g.modulate = LIGHT_SOURCES[tile_name]
            g.position = Vector2(x * t + t * 0.5, y * t + t * 0.5)
            g.scale = Vector2.ONE * float(GLOW_SCALE.get(tile_name, 1.0))
            g.z_index = 30
            add_child(g)
            _glows.append(g)
            var f: Dictionary = FLICKER.get(tile_name, {})
            _flicker.append({
                "amp": float(f.get("amp", 0.0)),
                "hz": float(f.get("hz", 0.0)),
                "fault": bool(f.get("fault", false)),
                # Two lamps on the same street humming in unison is one lamp.
                "phase": randf() * TAU,
            })


## A radial falloff, generated here: there is no image tool on this machine and
## none is wanted -- ART_DIRECTION section 0.
static func _glow_texture() -> ImageTexture:
    if _tex != null:
        return _tex
    var r := GLOW_RADIUS
    var img := Image.create(r * 2, r * 2, false, Image.FORMAT_RGBA8)
    for y in r * 2:
        for x in r * 2:
            var d := Vector2(x - r + 0.5, y - r + 0.5).length() / float(r)
            var a: float = clampf(1.0 - d, 0.0, 1.0)
            img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * a * 0.8))
    _tex = ImageTexture.create_from_image(img)
    return _tex


func set_block(new_block: String) -> void:
    block = new_block
    apply()


func set_raining(wet: bool) -> void:
    raining = wet
    apply()


func apply() -> void:
    var table: Dictionary = INDOOR_TINTS if indoors else TINTS
    var tint: Color = table.get(block, Color.WHITE)
    var wet := raining and not indoors
    if wet:
        tint = tint * RAIN_TINT
    _modulate.color = tint

    _strength = float(GLOW_STRENGTH.get(block, 0.0))
    for g in _glows:
        g.visible = _strength > 0.0
        g.self_modulate.a = _strength

    if wet and _rain == null:
        _rain = _make_rain()
        add_child(_rain)
    elif not wet and _rain != null:
        _rain.queue_free()
        _rain = null


## apply() owns the *base* strength of every light; this only ever multiplies
## it. So a lamp still counts for exactly nothing at noon, whatever it is doing.
func _process(delta: float) -> void:
    if _strength <= 0.0:
        return
    _t += delta
    for i in _glows.size():
        var f: Dictionary = _flicker[i]
        var amp: float = f["amp"]
        var out := 1.0
        if amp > 0.0:
            out += amp * sin(_t * float(f["hz"]) * TAU + float(f["phase"]))
        if f["fault"] and fmod(_t, _neon_cycle) > _neon_on:
            out *= 0.22
        _glows[i].self_modulate.a = _strength * out


## Drizzle, not a storm: Verhaven rain is the kind you stop noticing. It lives
## on its own canvas layer so it falls across the screen rather than across the
## map, and so the ambient tint does not put it out.
func _make_rain() -> CanvasLayer:
    var layer := CanvasLayer.new()
    layer.name = "Drizzle"
    layer.layer = 2

    var p := GPUParticles2D.new()
    p.amount = 80
    p.lifetime = 1.2
    p.preprocess = 1.2
    p.position = Vector2(192, -8)

    var mat := ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    mat.emission_box_extents = Vector3(260, 4, 1)
    mat.direction = Vector3(-0.22, 1.0, 0.0)
    mat.spread = 1.5
    mat.initial_velocity_min = 200.0
    mat.initial_velocity_max = 250.0
    mat.gravity = Vector3.ZERO
    mat.scale_min = 0.6
    mat.scale_max = 1.0
    mat.color = Color("#a8cbe0")
    p.process_material = mat

    var img := Image.create(1, 5, false, Image.FORMAT_RGBA8)
    img.fill(Color(1.0, 1.0, 1.0, 0.45))
    p.texture = ImageTexture.create_from_image(img)

    layer.add_child(p)

    # Rain you only ever see falling reads as a filter over the picture. The
    # splash is what puts it on the ground the player is standing on.
    var up := GPUParticles2D.new()
    up.amount = 26
    up.lifetime = 0.35
    up.preprocess = 0.5
    up.position = Vector2(192, 200)

    var umat := ParticleProcessMaterial.new()
    umat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    umat.emission_box_extents = Vector3(210, 26, 1)
    umat.direction = Vector3(0.0, -1.0, 0.0)
    umat.spread = 28.0
    umat.initial_velocity_min = 22.0
    umat.initial_velocity_max = 46.0
    umat.gravity = Vector3(0.0, 120.0, 0.0)
    umat.scale_min = 0.4
    umat.scale_max = 0.8
    umat.color = Color("#a8cbe0")
    up.process_material = umat

    var uimg := Image.create(1, 1, false, Image.FORMAT_RGBA8)
    uimg.fill(Color(1.0, 1.0, 1.0, 0.5))
    up.texture = ImageTexture.create_from_image(uimg)
    layer.add_child(up)

    return layer
