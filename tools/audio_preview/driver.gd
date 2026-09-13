## Real audio output, preview controls, long-loop seam and intro handover.
extends SceneTree
var t := TestKit.new()

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    await process_frame
    var audio := root.get_node("Audio")
    t.ok(AudioServer.get_driver_name() != "Dummy", "real audio driver")
    var preview: AudioPreview = audio.preview
    if preview == null:
        push_error("Preview must be enabled")
        quit(1)
        return
    for family in [0, 1, 2, 3]:
        preview.family = family
        var peak := -100.0
        for repeat in 3:
            audio.play_stone()
            for frame in 15:
                await process_frame
                peak = maxf(peak, AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("SFX"), 0))
        t.ok(peak > -45, "stone family audible")
        print("AUDIO FAMILY %s peak %.1f dB" % [AudioPreview.FAMILIES[family],peak])
    for effect in ["preview_capture_single", "preview_capture_group", "preview_bowl_rattle"]:
        audio.play(effect)
        var peak := -100.0
        for frame in 20:
            await process_frame
            peak = maxf(peak, AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("SFX"), 0))
        t.ok(peak > -45, effect + " audible")
        print("AUDIO EFFECT %s peak %.1f dB" % [effect,peak])
    for track in ["theme_club", "theme_battle"]:
        audio.play_music(track, .05)
        var intro: bool = track == "theme_battle"
        if intro:
            t.eq(audio._music.stream, preview.replacements.match_in, "new intro starts")
            await create_timer(3).timeout
        t.eq(audio._music.stream, preview.replacements["match" if intro else "kettle"], "new loop active")
        var peak := -100.0
        for frame in 60:
            await process_frame
            peak = maxf(peak, AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Music"), 0))
        t.ok(peak > -45, "music audible")
        print("AUDIO MUSIC %s peak %.1f dB" % [track,peak])
        audio._music.seek(audio._music.stream.get_length() - .25)
        await create_timer(.7).timeout
        t.ok(audio._music.playing and audio._music.get_playback_position() < 1, "loop restarts at seam")
    var prior: int = preview.family
    await _key(KEY_F6)
    t.eq(preview.family, (prior + 1) % 4, "F6 input reaches preview controls")
    await _key(KEY_F7)
    t.eq(audio._music.stream, preview.originals.theme_battle_in, "F7 restores old intro")
    t.eq(audio._streams.theme_match, preview.originals.theme_match, "practice untouched")
    t.eq(audio._streams.theme_rival, preview.originals.theme_rival, "character cue untouched")
    await _key(KEY_F8)
    t.ok(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "F8 mutes music")
    t.ok(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "effects stay on")
    preview.toggle_mute()
    print("AUDIO DRIVER: ", t.report())
    audio.stop_music(.1)
    await create_timer(.3).timeout
    quit(0 if t.failed == 0 else 1)

func _key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame
    event = InputEventKey.new()
    event.keycode = code
    event.pressed = false
    Input.parse_input_event(event)
    await process_frame
