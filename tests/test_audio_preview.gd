## Production audio selection and routing, without any opt-in environment flag.
class_name AudioPreviewTests
extends RefCounted

static func run(t: TestKit) -> void:
    t.section("production table audio")
    var palette := TableAudioPalette.new()
    palette.rng.seed = 901
    var previous := ""
    var seen: Dictionary = {}
    for i in 120:
        var current := palette.next_stone()
        t.ok(current != previous, "no immediate repeated sample")
        seen[current] = true
        previous = current
    t.eq(seen.size(), 6, "all six Thwack variations are reachable")
    for name in seen:
        t.ok(ResourceLoader.exists("res://audio/%s.wav" % name), "production Thwack exists")
    for name in ["capture", "capture_single", "bowl_rattle", "theme_club", "theme_battle", "theme_battle_in"]:
        t.ok(ResourceLoader.exists("res://audio/%s.wav" % name), "production sound exists")
    t.ok(not FileAccess.file_exists("res://audio/stone_place_alt.wav"), "obsolete placement removed")
