## Picks what the opponent says about what just happened.
##
## Tags come from the rules, lines come from data,
## and a character who has no line for a tag simply says nothing -- which is how
## a 5 dan is stopped from crowing about a capture without special-casing her.
class_name TableTalkVoice
extends RefCounted

const DIR := "res://data/banter/"
const FALLBACK := "default"

## Moves between lines. Somebody who comments on everything is not a person,
## they are a tutorial, and the board is meant to be the thing you look at.
const COOLDOWN := 4

var _lines: Dictionary = {}
var _fallback: Dictionary = {}
var _last_move_spoken: int = -99
var _last_tag: String = ""
var _rng := RandomNumberGenerator.new()


static func load_voice(npc_id: String) -> TableTalkVoice:
    var v := TableTalkVoice.new()
    v._rng.randomize()
    v._lines = _read(npc_id)
    v._fallback = _read(FALLBACK)
    return v


static func _read(npc_id: String) -> Dictionary:
    var path := DIR + npc_id + ".json"
    if not FileAccess.file_exists(path):
        return {}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed.get("lines", {}) if parsed is Dictionary else {}


## A line for one of these tags, or "" for silence. Silence is the common case
## and is not a failure: most moves are not worth saying anything about.
func speak(tags: PackedStringArray, move_number: int) -> String:
    if move_number - _last_move_spoken < COOLDOWN:
        return ""
    for tag in tags:
        # Never the same remark twice running, however well it fits.
        if tag == _last_tag:
            continue
        var options: Array = _lines.get(tag, _fallback.get(tag, []))
        if options.is_empty():
            continue
        _last_move_spoken = move_number
        _last_tag = tag
        return str(options[_rng.randi_range(0, options.size() - 1)])
    return ""


## The occasional unprompted line about how it is going, when nothing has
## happened worth reacting to. `standing` comes from GoTableTalk.
func idle_line(standing: String, move_number: int) -> String:
    if move_number - _last_move_spoken < COOLDOWN * 2:
        return ""
    var options: Array = _lines.get(standing, _fallback.get(standing, []))
    if options.is_empty():
        return ""
    _last_move_spoken = move_number
    _last_tag = standing
    return str(options[_rng.randi_range(0, options.size() - 1)])
