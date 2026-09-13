## Six recorded Thwack variations; consecutive placements never repeat a sample.
class_name TableAudioPalette
extends RefCounted

var rng := RandomNumberGenerator.new()
var previous := -1

func _init() -> void:
    rng.randomize()

func next_stone() -> String:
    var index := rng.randi_range(0, 4 if previous >= 0 else 5)
    if previous >= 0 and index >= previous: index += 1
    previous = index
    return "stone_thwack_%d" % index
