## The atmosphere tables, checked against the things they name.
##
## Every one of these fails silently in play, which is the only reason this
## file exists. A tile name that is not in the atlas draws nothing; a sound
## name that is not in audio/ plays nothing; a converse partner who is not on
## the map stands there facing the wrong way forever. None of it errors, and
## none of it shows up in a screenshot as anything but "hmm, quiet".
class_name WorldAmbienceTests
extends RefCounted

## Audio is an autoload, and an autoload may not exist in a --script run.
## Its constants are reachable through the script itself either way.
const AudioScript := preload("res://src/autoload/audio.gd")
const Presence := preload("res://src/rpg/world_presence.gd")

## Every map, and it has to stay every map. The Bondszaal was missing from the
## hand-kept version of this list and spent its whole life declaring a track
## name that did not exist ("institute", where the file is theme_institute.wav)
## -- so the hall the Cup and the exam are held in played whatever the last map
## had been playing.
##
## It is read off the directory now rather than retyped, because the failure
## mode of a hand-kept copy is that the *test* goes on passing: a map missing
## from the list is not checked and nothing says so. That is the shape ROADMAP
## section 8 records for LESSONS_REACHED_BY_TRACK, and
## the fix is M30's -- derive it. M36's wassalon was the eleventh map and would
## have been the second Bondszaal.
static func _maps() -> Array:
    var ids: Array = []
    for f in DirAccess.get_files_at(MAP_DIR):
        if f.ends_with(".json"):
            ids.append(f.get_basename())
    ids.sort()
    return ids

const MAP_DIR := "res://data/maps"
const IDLE_MODES := ["wander", "study", "tend", "watch", "converse"]


static func run(t: TestKit) -> void:
    _test_tiles_exist(t)
    _test_sounds_exist(t)
    _test_animations_well_formed(t)
    _test_sprites_exist(t)
    _test_interaction_priority(t)
    _test_map_idles(t)
    _test_map_routes(t)
    _test_presence_states(t)
    _test_music(t)


static func _sound_exists(name: String) -> bool:
    return name != "" and FileAccess.file_exists("res://audio/%s.wav" % name)


static func _tile_exists(name: String) -> bool:
    return TileAtlas.at(name).x >= 0


static func _test_tiles_exist(t: TestKit) -> void:
    t.section("ambience: every tile named is in the atlas")
    for name in Soundscape.SOUND_SOURCES:
        t.ok(_tile_exists(name), "sound source '%s' is a real tile" % name)
    for name in Soundscape.BED_CANAL_TILES:
        t.ok(_tile_exists(str(name)), "canal bed tile '%s' is a real tile" % name)
    for name in TileAnimator.ANIMATIONS:
        t.ok(_tile_exists(name), "animated tile '%s' is a real tile" % name)
        var spec: Dictionary = TileAnimator.ANIMATIONS[name]
        for f in spec.get("frames", []):
            t.ok(_tile_exists(str(f)),
                "'%s' frame '%s' is a real tile" % [name, str(f)])
    for name in Player.SURFACES:
        t.ok(_tile_exists(str(name)), "footstep surface '%s' is a real tile" % name)


static func _test_sounds_exist(t: TestKit) -> void:
    t.section("ambience: every sound named has a wav")
    for name in Soundscape.SOUND_SOURCES:
        var spec: Dictionary = Soundscape.SOUND_SOURCES[name]
        t.ok(_sound_exists(str(spec.get("sound", ""))),
            "'%s' plays a real sound" % name)
    for bed in ["amb_room", "amb_rain", "amb_canal"]:
        t.ok(_sound_exists(bed), "bed '%s' exists" % bed)
    for pair_name in AudioScript.FOOTSTEPS:
        for s in AudioScript.FOOTSTEPS[pair_name]:
            t.ok(_sound_exists(str(s)), "footstep '%s' exists" % str(s))
    for s in ["tram_bell", "amb_tram"]:
        t.ok(_sound_exists(s), "the tram's '%s' exists" % s)


static func _test_animations_well_formed(t: TestKit) -> void:
    t.section("ambience: animations are well formed")
    for name in TileAnimator.ANIMATIONS:
        var spec: Dictionary = TileAnimator.ANIMATIONS[name]
        var frames: Array = spec.get("frames", [])
        var hold: Array = spec.get("hold", [])
        t.ok(frames.size() >= 2, "'%s' has at least two frames" % name)
        t.eq(hold.size(), frames.size(), "'%s' holds one duration per frame" % name)
        var total := 0.0
        for h in hold:
            total += float(h)
        t.ok(total > 0.0, "'%s' has a non-zero cycle" % name)
        t.ok(str(frames[0]) == name,
            "'%s' frame 0 is the tile itself, so parking it is a no-op" % name)


## A person outranks a notice, and it is asserted rather than remembered because
## the two numbers are set in two different files and were the wrong way round
## from the day signs got a priority at all. The symptom is somebody standing in
## front of a character, pressing [Space] and being read a paragraph about the
## furniture -- with the dialogue box opening exactly as it should, so nothing
## anywhere reports it.
static func _test_interaction_priority(t: TestKit) -> void:
    t.section("ambience: a person outranks a notice")
    t.ok(Interactable.PRIORITY_PERSON > Interactable.PRIORITY_SIGN,
        "an NPC wins the probe against a sign they are standing beside")


static func _test_sprites_exist(t: TestKit) -> void:
    t.section("ambience: the crowd has sheets to wear")
    for sheet in CrowdSpawner.SHEETS:
        t.ok(FileAccess.file_exists("res://art/sprites/%s.png" % str(sheet)),
            "passer sheet '%s' exists" % str(sheet))
    t.ok(FileAccess.file_exists(NpcIdle.BUBBLE), "the conversation bubble exists")
    t.ok(FileAccess.file_exists(Tram.SPRITE), "the tram sprite exists")


static func _test_map_idles(t: TestKit) -> void:
    t.section("ambience: every idle a map asks for is one that exists")
    for map_id in _maps():
        var map := MapData.load_map(map_id)
        if map == null:
            t.ok(false, "map '%s' loads" % map_id)
            continue
        var here := {}
        for spec in map.npcs:
            here[str(spec.get("id", ""))] = true
        for spec in map.npcs:
            var idle := str(spec.get("idle", ""))
            if idle == "":
                continue
            var bits := idle.split(":")
            t.ok(IDLE_MODES.has(bits[0]),
                "%s: '%s' idle '%s' is a known mode" % [map_id, spec.get("id"), bits[0]])
            if bits[0] == "converse":
                # A partner who is not on this map is a person talking to
                # nobody, forever, in total silence.
                t.ok(bits.size() > 1 and here.has(bits[1]),
                    "%s: %s converses with somebody on this map" % [map_id, spec.get("id")])


## A map naming a track that was never generated is a silent map, not an error
## -- Audio.play_music() returns quietly on an unknown name.
static func _test_music(t: TestKit) -> void:
    t.section("ambience: every track a map asks for exists")
    var used := {}
    for map_id in _maps():
        var map := MapData.load_map(map_id)
        if map == null:
            continue
        for track in [map.music, map.music_night]:
            if track == "":
                continue
            used[track] = true
            t.ok(FileAccess.file_exists("res://audio/%s.wav" % track),
                "%s: track '%s' exists" % [map_id, track])
    # The scenes that are not maps and so have no map to declare them. The
    # battle themes are chosen by MatchMusic and checked in its own suite; the
    # intro stings are named by nobody at all -- Audio.play_music() finds them
    # by appending INTRO_SUFFIX -- so this is the only place they can be
    # required to exist.
    for track in ["theme_title", "theme_match", "theme_battle_in",
            "theme_rival_in", "theme_ghost_in", "theme_cup_in"]:
        t.ok(FileAccess.file_exists("res://audio/%s.wav" % track),
            "'%s' exists for the scene that plays it" % track)
    # The bar and the Instituut are the setting's two halves and must not be
    # the same track; that was true for four maps until this pass.
    var ketel := MapData.load_map("de_ketel")
    var hall := MapData.load_map("academy_hall")
    if ketel != null and hall != null:
        t.ok(ketel.music != hall.music,
            "De Ketel and the Instituut do not share a theme")


static func _test_map_routes(t: TestKit) -> void:
    t.section("ambience: crowd routes are usable")
    for map_id in _maps():
        var map := MapData.load_map(map_id)
        if map == null:
            continue
        for r in map.routes:
            var path: Array = r.get("path", [])
            t.ok(path.size() >= 2, "%s: a route has two or more waypoints" % map_id)
            t.ok(float(r.get("rate", 0.0)) > 0.0, "%s: a route has a rate" % map_id)
            for sheet in r.get("sheets", []):
                t.ok(FileAccess.file_exists("res://art/sprites/%s.png" % str(sheet)),
                    "%s: route sheet '%s' exists" % [map_id, str(sheet)])


## A presence state is the social life of a map after a persistent beat. These
## checks intentionally inspect every authored state rather than only the one
## a fresh save selects: a bad late-game position otherwise surfaces months
## after the map first shipped.
static func _test_presence_states(t: TestKit) -> void:
    t.section("ambience: presence states are complete")
    for map_id in _maps():
        var map := MapData.load_map(map_id)
        if map == null:
            continue
        t.ok(not map.presence_states.is_empty(), "%s: has a routine presence state" % map_id)
        var ids := {}
        for raw in map.presence_states:
            var state: Dictionary = raw
            var id := str(state.get("id", ""))
            t.ok(id != "" and not ids.has(id), "%s: presence id '%s' is unique" % [map_id, id])
            ids[id] = true
            var when: Dictionary = state.get("when", {})
            for key in when.get("all", []):
                t.ok(str(key) != "", "%s/%s: required flag is named" % [map_id, id])
            for key in when.get("none", []):
                t.ok(str(key) != "", "%s/%s: excluded flag is named" % [map_id, id])
            for key in when.get("equals", {}):
                t.ok(str(key) != "", "%s/%s: compared flag is named" % [map_id, id])
            var here := {}
            var people: Array = state.get("npcs", map.npcs)
            for spec in people:
                var npc_id := str(spec.get("id", ""))
                var at: Array = spec.get("tile", [])
                t.ok(npc_id != "" and not here.has(npc_id),
                    "%s/%s: npc '%s' appears once" % [map_id, id, npc_id])
                here[npc_id] = true
                t.ok(at.size() >= 2 and not map.is_solid(int(at[0]), int(at[1])),
                    "%s/%s: %s stands on a walkable tile" % [map_id, id, npc_id])
            for spec in people:
                var idle := str(spec.get("idle", ""))
                var bits := idle.split(":")
                t.ok(idle == "" or IDLE_MODES.has(bits[0]),
                    "%s/%s: %s has a known idle" % [map_id, id, spec.get("id", "")])
                if bits[0] == "converse":
                    t.ok(bits.size() > 1 and here.has(bits[1]),
                        "%s/%s: conversation partner is present" % [map_id, id])
            for prop in state.get("tiles", []):
                t.ok(_tile_exists(str(prop.get("name", ""))),
                    "%s/%s: prop '%s' is in the atlas" % [map_id, id, prop.get("name", "")])
            var flags := {}
            for key in when.get("all", []):
                flags[str(key)] = true
            for key in when.get("equals", {}):
                flags[str(key)] = when["equals"][key]
            t.eq(str(Presence.select(map.presence_states, flags).get("id", "")), id,
                "%s/%s: its required flags select it" % [map_id, id])
        t.eq(str(Presence.select(map.presence_states, {}).get("id", "")), "routine",
            "%s: a fresh save selects routine" % map_id)
