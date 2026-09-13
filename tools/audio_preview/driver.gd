## Production audio output, long-loop seam and intro handover, with no opt-in.
extends SceneTree
var t := TestKit.new()

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    await process_frame
    var audio := root.get_node("Audio")
    t.ok(AudioServer.get_driver_name() != "Dummy", "real audio driver")
    for name in ["stone_thwack_0", "stone_thwack_1", "stone_thwack_2", "stone_thwack_3",
            "stone_thwack_4", "stone_thwack_5", "capture_single", "capture", "bowl_rattle"]:
        audio.play(name)
        var peak := await _peak("SFX", 20)
        t.ok(peak > -45, name + " audible")
        print("AUDIO EFFECT %s peak %.1f dB" % [name,peak])
    for track in ["theme_club", "theme_battle"]:
        audio.play_music(track, .05)
        if track == "theme_battle":
            t.eq(audio._music.stream.resource_path, "res://audio/theme_battle_in.wav", "production intro starts")
            await create_timer(3).timeout
        t.eq(audio._music.stream.resource_path, "res://audio/%s.wav" % track, "production loop active")
        var peak := await _peak("Music", 60)
        t.ok(peak > -45, "music audible")
        print("AUDIO MUSIC %s peak %.1f dB" % [track,peak])
        audio._music.seek(audio._music.stream.get_length() - .25)
        await create_timer(.7).timeout
        t.ok(audio._music.playing and audio._music.get_playback_position() < 1, "loop restarts at seam")
    var active: AudioStream = audio._music.stream
    for code in [KEY_F6, KEY_F7, KEY_F8]:
        var event := InputEventKey.new()
        event.keycode = code
        event.pressed = true
        Input.parse_input_event(event)
        await process_frame
    t.eq(audio._music.stream, active, "removed audition keys cannot restore old music")
    t.ok(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "removed audition keys cannot mute music")
    print("AUDIO DRIVER: ", t.report())
    audio.stop_music(.1)
    await create_timer(.3).timeout
    quit(0 if t.failed == 0 else 1)

func _peak(bus: String, frames: int) -> float:
    var peak := -100.0
    for frame in frames:
        await process_frame
        peak = maxf(peak, AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index(bus), 0))
    return peak
