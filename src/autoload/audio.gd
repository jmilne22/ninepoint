## Everything you can hear. Buses, a small pool of players, and one music track.
##
## Buses are built at runtime rather than in the editor's Audio dock, because
## this project builds its UI and its assets in code and a binary bus layout
## would be the only thing here nobody could diff.
extends Node

const DIR := "res://audio/"
const SFX_VOICES := 8
const MUSIC_FADE := 0.9
const AMBIENCE_FADE := 1.6

## Footstep pairs by surface. A pair, not a sample, because one footstep played
## over and over is a metronome -- the same reason play_stone() alternates two.
const FOOTSTEPS := {
    "": ["step_a", "step_b"],
    "wood": ["step_wood_a", "step_wood_b"],
    "gravel": ["step_gravel_a", "step_gravel_b"],
}

## How far a positional sound carries, in pixels. The viewport is 384 wide, so
## this is a little over one screen: the fryer is audible from the tram stop and
## inaudible from the park, which is the whole point of it being positional.
const AMBIENCE_REACH := 260.0

var enabled: bool = true

var _streams: Dictionary = {}          ## name -> AudioStream
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music: AudioStreamPlayer
var _music_name: String = ""
var _ambience: AudioStreamPlayer
var _ambience_name: String = ""
## The bed's pending fade. Leaving a map stops the bed and arriving on the next
## one starts it, often in the same frame -- and without this the stop's tween
## carries on running over the new track and mutes it a second and a half later.
var _ambience_fade: Tween = null
## The music's pending fade, for the same reason. Leaving a silent map and
## arriving on a scored one in the same frame used to leave the stop's tween
## running over the new track and mute it a second later. Harmless while only
## world.gd played music; the title screen and the match board both do now.
var _music_fade: Tween = null


func _ready() -> void:
    _make_buses()
    _load_streams()

    for i in SFX_VOICES:
        var p := AudioStreamPlayer.new()
        p.bus = &"SFX"
        add_child(p)
        _voices.append(p)

    _music = AudioStreamPlayer.new()
    _music.bus = &"Music"
    add_child(_music)
    _music.finished.connect(_loop_music)

    _ambience = AudioStreamPlayer.new()
    _ambience.bus = &"Ambience"
    add_child(_ambience)
    _ambience.finished.connect(_loop_ambience)

    EventBus.toast.connect(func(_t): play("toast"))
    # Rank follows results now, so it can fall as well as rise. Playing the
    # promotion sting at somebody who has just been demoted would be cruel.
    EventBus.rank_changed.connect(func(o, n):
        if GoRank.from_string(n) > GoRank.from_string(o):
            play("rank_up"))
    EventBus.item_gained.connect(func(_i, _n): play("ui_confirm"))
    EventBus.map_changed.connect(func(_m, _s): play("door"))
    EventBus.match_finished.connect(_on_match_finished)


func _make_buses() -> void:
    for bus_name in ["SFX", "Music", "Ambience"]:
        if AudioServer.get_bus_index(bus_name) != -1:
            continue
        var idx := AudioServer.get_bus_count()
        AudioServer.add_bus(idx)
        AudioServer.set_bus_name(idx, bus_name)
        AudioServer.set_bus_send(idx, &"Master")
    set_bus_volume("SFX", 0.85)
    set_bus_volume("Music", 0.45)
    # The bed sits under the music, not beside it. If you can tell the rain
    # from the track, the rain is too loud.
    set_bus_volume("Ambience", 0.5)


func _load_streams() -> void:
    var d := DirAccess.open(DIR)
    if d == null:
        push_warning("Audio: no %s -- run python3 tools/build_assets.py" % DIR)
        return
    for f in d.get_files():
        var file_name := f.trim_suffix(".remap")
        if not file_name.ends_with(".wav"):
            continue
        var stream = load(DIR + file_name)
        if stream is AudioStream:
            _streams[file_name.trim_suffix(".wav")] = stream


# --- playing -----------------------------------------------------------------

## Fire-and-forget. `pitch_jitter` keeps a sound that plays hundreds of times --
## a stone, a footstep -- from turning into a metronome.
func play(sound_name: String, pitch_jitter: float = 0.0, volume_db: float = 0.0) -> void:
    if not enabled or not _streams.has(sound_name):
        return
    var voice := _voices[_next_voice]
    _next_voice = (_next_voice + 1) % _voices.size()
    voice.stream = _streams[sound_name]
    voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
    voice.volume_db = volume_db
    voice.play()


## A stone going down. Alternates two samples and jitters the pitch, because a
## real board never makes the same sound twice.
func play_stone() -> void:
    play("stone_place" if randf() < 0.5 else "stone_place_alt", 0.06)


## `surface` comes from the tile under the player's feet. An unknown surface
## falls back to the cobbles, so a new tile is never silent.
func play_footstep(surface: String = "") -> void:
    var pair: Array = FOOTSTEPS.get(surface, FOOTSTEPS[""])
    play(str(pair[0] if randf() < 0.5 else pair[1]), 0.09, -4.0)


## A sound that comes from somewhere. The player owns the Camera2D, which is
## what an AudioStreamPlayer2D measures distance against, so this needs no
## listener of its own.
##
## The player frees itself when the sound ends: these fire every few seconds at
## most, and a pool would be state to keep correct for no measurable gain.
func play_at(sound_name: String, parent: Node2D, pitch_jitter: float = 0.0,
        volume_db: float = 0.0, reach: float = AMBIENCE_REACH) -> void:
    if not enabled or parent == null or not _streams.has(sound_name):
        return
    var p := AudioStreamPlayer2D.new()
    p.stream = _streams[sound_name]
    p.bus = &"Ambience"
    p.max_distance = reach
    p.attenuation = 1.0
    p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
    p.volume_db = volume_db
    parent.add_child(p)
    p.finished.connect(p.queue_free)
    p.play()


func play_music(track: String, fade: float = MUSIC_FADE) -> void:
    if _music_name == track and _music.playing:
        return
    if not _streams.has(track):
        return
    _music_name = track
    _music.stream = _streams[track]
    _music.volume_db = -40.0
    _music.play()
    _music_fade = _fade(_music, 0.0, fade, _music_fade)


func stop_music(fade: float = MUSIC_FADE) -> void:
    if not _music.playing:
        return
    _music_name = ""
    _music_fade = _fade(_music, -40.0, fade, _music_fade)
    _music_fade.tween_callback(_music.stop)


## The looping bed under a map: rain, a room tone, the canal. One at a time.
## Unlike music this crossfades properly -- swapping beds is a thing that
## happens when the weather turns, and a hard cut announces the mechanism.
func play_ambience(track: String, fade: float = AMBIENCE_FADE) -> void:
    if _ambience_name == track and _ambience.playing:
        return
    if not _streams.has(track):
        stop_ambience(fade)
        return
    _ambience_name = track
    _ambience.stream = _streams[track]
    _ambience.volume_db = -40.0
    _ambience.play()
    _ambience_fade = _fade_ambience(0.0, fade)


func stop_ambience(fade: float = AMBIENCE_FADE) -> void:
    if not _ambience.playing:
        return
    _ambience_name = ""
    _ambience_fade = _fade_ambience(-40.0, fade)
    _ambience_fade.tween_callback(_ambience.stop)


func _fade_ambience(to_db: float, fade: float) -> Tween:
    return _fade(_ambience, to_db, fade, _ambience_fade)


## Start a volume fade, cancelling whatever fade that player already had. Two
## live tweens on one volume_db is the bug both callers exist to avoid.
func _fade(player: AudioStreamPlayer, to_db: float, fade: float, pending: Tween) -> Tween:
    if pending != null and pending.is_valid():
        pending.kill()
    var tw := create_tween()
    tw.tween_property(player, "volume_db", to_db, fade)
    return tw


func _loop_ambience() -> void:
    # Same trap as the music, and the same rule: never set loop_mode here.
    if _ambience_name != "" and not _ambience.playing:
        _ambience.play()


## Looping is done by replaying on `finished`, and must stay that way.
##
## The obvious version -- set loop_mode = LOOP_FORWARD on the stream -- is worse
## than useless here: these import as QOA (AudioStreamWAV.FORMAT_QOA), and
## setting a loop mode on a QOA stream stops playback within a few milliseconds.
## Because this handler then restarts it on `finished`, the track relaunched
## forever and the master bus sat at -97 dB while `playing` read true. Music and
## ambience were inaudible for the life of the project and it never once looked
## like an error. Measured with AudioServer.get_bus_peak_volume_left_db().
##
## Leaving the stream alone plays it correctly (peak -8 dB) at the cost of one
## buffer's gap at the seam -- which is why the beds are built with
## Sound.loopify() so the join is level.
func _loop_music() -> void:
    if _music_name != "" and not _music.playing:
        _music.play()


func _on_match_finished(result: MatchResult) -> void:
    play("game_win" if result.player_won else "game_lose")


# --- mixing ------------------------------------------------------------------

func set_bus_volume(bus_name: String, linear: float) -> void:
    var i := AudioServer.get_bus_index(bus_name)
    if i >= 0:
        AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))


func mute(bus_name: String, muted: bool) -> void:
    var i := AudioServer.get_bus_index(bus_name)
    if i >= 0:
        AudioServer.set_bus_mute(i, muted)
