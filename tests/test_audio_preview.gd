class_name AudioPreviewTests
extends RefCounted

static func run(t: TestKit) -> void:
    t.section("audio preview selection")
    var preview := AudioPreview.new()
    preview.rng.seed = 901
    t.eq(preview.family, 2, "middle thunk is the default")
    for family in [1, 2, 3]:
        preview.family = family
        var previous := ""
        var seen: Dictionary = {}
        for i in 120:
            var current := preview.next_stone()
            t.ok(current != previous, "no immediate repeated sample")
            seen[current] = true
            previous = current
        t.eq(seen.size(), 6, "all six variations are reachable")
    preview.family = 0
    t.eq(preview.capture_name(1), "capture", "baseline restores production capture")
    t.eq(preview.bowl_name(), "capture", "baseline restores production nigiri")
    preview.family = 2
    t.eq(preview.capture_name(1), "preview_capture_single", "one captured stone")
    t.eq(preview.capture_name(5), "preview_capture_group", "group capture")
    t.eq(preview.bowl_name(), "preview_bowl_rattle", "bowl has separate texture")
    t.eq(AudioPreview.MUSIC.size(), 3, "only room, rated loop and rated intro overridden")
    preview.free()
