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
    "theme_arches", "theme_club", "theme_street", "theme_night"]
const BEDS := ["amb_rain", "amb_room", "amb_canal"]

var _failed: Array[String] = []


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

    if _failed.is_empty():
        print("all %d tracks audible" % (MUSIC.size() + BEDS.size()))
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
