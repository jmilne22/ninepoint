## Asserts that every looping track actually reaches the master bus.
##
## This exists because music and ambience were inaudible for the life of the
## project and nothing caught it: setting loop_mode on a QOA-imported
## AudioStreamWAV stops playback within milliseconds, Audio._loop_music()
## restarted it on `finished`, and the result was a track that relaunched
## forever with `playing == true` and a master bus at -97 dB. No error, no
## warning, no failing test -- it only shows up if you measure the output or
## put on headphones.
##
## MUST NOT run under --headless: that forces the Dummy audio driver, which
## reports silence for everything. tools/check_audio.sh gives it a display.
extends SceneTree

## Silence measures about -97 dB or lower; a real track sits between -8 and -25.
const FLOOR_DB := -45.0
const LISTEN := 2.5

const MUSIC := ["theme_title", "theme_match", "theme_institute", "theme_quay",
    "theme_arches", "theme_club", "theme_street", "theme_night",
    # The battle themes. Four of these ship a "<track>_in" sting that plays
    # first and hands over, and the stings are deliberately NOT listed
    # separately: each is about two seconds long against a LISTEN of 2.5, so on
    # its own it would have finished and read as a track that stopped. Listening
    # to the loop covers the sting AND the handover to it, which is the part
    # that could actually break.
    "theme_battle", "theme_rival", "theme_ghost", "theme_teacher",
    "theme_wall", "theme_exam", "theme_cup"]
const BEDS := ["amb_rain", "amb_room", "amb_canal"]

## Tracks that ship a "<track>_in" sting. Audio.play_music() starts the sting
## and _loop_music() swaps the loop in when it ends, which is the one piece of
## that mechanism with no other witness: the loop above listens for LISTEN
## seconds and two of these stings are longer than that, so it proves the
## handover for theme_battle and assumes it for theme_cup. Assuming is what
## this file exists because of.
const INTROS := ["theme_battle", "theme_rival", "theme_ghost", "theme_cup"]
## Longest sting is under three seconds; this is slack, not a real wait.
const HANDOVER_TIMEOUT := 8.0

var _failed: Array[String] = []


## Play each sting and wait for the loop it introduces to take over. Failure
## here is silent in the worst way: the sting plays, stops, and the board sits
## in silence for the rest of the game with `playing == false` and no error --
## which is precisely the shape of the QOA bug this file was written for.
func _check_intros(audio) -> void:
    for track in INTROS:
        var loop: AudioStream = audio._streams[track]
        var sting: AudioStream = audio._streams[track + "_in"]
        audio.play_music(track, 0.05)
        await process_frame
        var began_on_sting: bool = audio._music.stream == sting
        # Wall time, not a frame count. The first version of this added 1/60 per
        # process_frame and called it a second, but nothing here is vsynced --
        # the loop spins thousands of times a second, so eight "seconds" elapsed
        # in about four tenths of one and every sting was reported as never
        # handing over. _check() above had it right all along.
        var until := Time.get_ticks_msec() + int(HANDOVER_TIMEOUT * 1000.0)
        while Time.get_ticks_msec() < until and audio._music.stream != loop:
            await process_frame
        var waited := (HANDOVER_TIMEOUT * 1000.0 - (until - Time.get_ticks_msec())) / 1000.0
        var handed: bool = audio._music.stream == loop and audio._music.playing
        var verdict := "ok" if began_on_sting and handed else "FAIL"
        if verdict == "FAIL":
            _failed.append(track + "_in")
        print("  %-18s sting first %s, loop took over %s after %.1fs   %s"
            % [track + "_in", began_on_sting, handed, waited, verdict])
        audio.stop_music(0.05)
        await process_frame


func _init() -> void:
    await process_frame
    if AudioServer.get_driver_name() == "Dummy":
        print("check_audio: audio driver is Dummy -- run through tools/check_audio.sh")
        quit(2)
        return
    var audio = get_root().get_node_or_null("Audio")
    if audio == null:
        print("check_audio: no Audio autoload")
        quit(1)
        return
    print("driver: %s" % AudioServer.get_driver_name())

    for track in MUSIC:
        audio.play_music(track, 0.05)
        await _check(track, audio._music)
    audio.stop_music(0.05)
    for bed in BEDS:
        audio.play_ambience(bed, 0.05)
        await _check(bed, audio._ambience)
    audio.stop_ambience(0.05)
    await _check_intros(audio)

    if _failed.is_empty():
        print("all %d tracks audible, %d intro stings hand over"
            % [MUSIC.size() + BEDS.size(), INTROS.size()])
        quit(0)
    else:
        print("SILENT: %s" % ", ".join(_failed))
        quit(1)


func _check(name: String, player: AudioStreamPlayer) -> void:
    var until := Time.get_ticks_msec() + int(LISTEN * 1000.0)
    var peak := -200.0
    while Time.get_ticks_msec() < until:
        await process_frame
        peak = maxf(peak, AudioServer.get_bus_peak_volume_left_db(0, 0))
    var ok := peak > FLOOR_DB and player.playing
    print("  %-18s peak %7.1f dB  playing %-5s  %s" % [
        name, peak, str(player.playing), "ok" if ok else "SILENT"])
    if not ok:
        _failed.append(name)
