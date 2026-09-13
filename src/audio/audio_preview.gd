## Session-only audition. Production callers retain their existing sound names.
class_name AudioPreview
extends Node

const DIRECTORY := "res://audio_preview/"
const FAMILIES := ["Original", "Snap", "Thunk", "Deep"]
const MUSIC := {"theme_club": "kettle", "theme_battle": "match", "theme_battle_in": "match_in"}
var family: int = 2
var new_music: bool = true
var music_muted: bool = false
var previous: Dictionary = {}
var originals: Dictionary = {}
var replacements: Dictionary = {}
var audio: Node
var caption: Label
var panel: PanelContainer
var rng := RandomNumberGenerator.new()

static func requested() -> bool:
    return OS.get_environment("NINEPOINT_AUDIO_PREVIEW") in ["1", "baseline"]

func setup(owner_audio: Node) -> void:
    audio = owner_audio
    rng.randomize()
    originals = audio._streams.duplicate()
    var directory := DirAccess.open(DIRECTORY)
    if directory == null:
        push_error("Audio preview assets missing: run tools/build_audio_preview.py")
        get_tree().quit(1)
        return
    for filename in directory.get_files():
        var file := filename.trim_suffix(".remap")
        if file.ends_with(".wav"):
            replacements[file.trim_suffix(".wav")] = load(DIRECTORY + file)
    for key: String in replacements:
        audio._streams["preview_" + key] = replacements[key]
    var required := ["kettle", "match", "match_in", "capture_single", "capture_group", "bowl_rattle"]
    for kind in ["snap", "thunk", "deep"]:
        for i in 6: required.append("stone_%s_%d" % [kind, i])
    for key in required:
        if not replacements.has(key):
            push_error("Incomplete audio preview: " + key)
            get_tree().quit(1)
            return
    if OS.get_environment("NINEPOINT_AUDIO_PREVIEW") == "baseline":
        family = 0
        new_music = false
    apply_music()
    _build_caption()
    if OS.get_environment("NINEPOINT_AUDIO_TRACE") == "1":
        audio.sound_played.connect(_trace_sound)
        audio.music_started.connect(_trace_music)

func _trace_sound(sound: String, pitch: float, volume: float) -> void:
    print("AUDIO TRACE ", JSON.stringify({"frame":Engine.get_process_frames(),
        "ms":Time.get_ticks_msec(), "sound":sound, "pitch":pitch, "db":volume}))

func _trace_music(track: String) -> void:
    print("AUDIO MUSIC ", JSON.stringify({"frame":Engine.get_process_frames(),
        "ms":Time.get_ticks_msec(), "track":track, "new":new_music}))

func next_stone() -> String:
    if family == 0:
        return "stone_place" if rng.randf() < .5 else "stone_place_alt"
    var last: int = int(previous.get(family, -1))
    var index := rng.randi_range(0, 4 if last >= 0 else 5)
    if index >= last and last >= 0: index += 1
    previous[family] = index
    return "preview_stone_%s_%d" % [FAMILIES[family].to_lower(), index]

func capture_name(count: int) -> String:
    if family == 0: return "capture"
    return "preview_capture_single" if count == 1 else "preview_capture_group"

func bowl_name() -> String:
    return "capture" if family == 0 else "preview_bowl_rattle"

func apply_music() -> void:
    for original: String in MUSIC:
        audio._streams[original] = replacements.get(MUSIC[original], originals.get(original)) if new_music else originals.get(original)

func cycle_stone() -> void:
    family = (family + 1) % FAMILIES.size()
    _refresh_caption()

func toggle_music() -> void:
    new_music = not new_music
    apply_music()
    # Restart the current musical context so A/B never retains the old stream.
    var name: String = audio._music_name
    audio._music_name = ""
    if name != "": audio.play_music(name, .15)
    _refresh_caption()

func toggle_mute() -> void:
    music_muted = not music_muted
    audio.mute("Music", music_muted)
    _refresh_caption()

func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    match event.keycode:
        KEY_F6: cycle_stone()
        KEY_F7: toggle_music()
        KEY_F8: toggle_mute()
        _: return
    get_viewport().set_input_as_handled()

func _build_caption() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 110
    add_child(layer)
    panel = PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(panel)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("202e2dee")
    for side in [SIDE_LEFT, SIDE_RIGHT]: style.set_content_margin(side, 6)
    for side in [SIDE_TOP, SIDE_BOTTOM]: style.set_content_margin(side, 2)
    panel.add_theme_stylebox_override("panel", style)
    caption = Label.new()
    caption.add_theme_font_override("font", load("res://art/fonts/DejaVuSans.ttf"))
    caption.add_theme_font_size_override("font_size", 8)
    caption.add_theme_color_override("font_color", Color("eee4cc"))
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(caption)
    _refresh_caption()
    _process(0.0)

func _process(_delta: float) -> void:
    if panel == null: return
    # Keep the world toast area clear; use the spare right side of its HUD.
    var extent := get_viewport().get_visible_rect().size
    panel.position = Vector2(24, 365) if extent.x > 500 else Vector2(extent.x - panel.get_combined_minimum_size().x - 8, extent.y - 17)

func _refresh_caption() -> void:
    if caption == null: return
    caption.text = "F6 %s   F7 %s music   F8 %s" % [FAMILIES[family],
        "New" if new_music else "Original", "Muted" if music_muted else "On"]
