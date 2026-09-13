## Explicit boundary for shared activities. Callbacks own persistence and routing.
class_name ActivityContext
extends RefCounted

var standalone := false
var player_name := "You"
var request: MatchRequest
var lesson_id := ""
var puzzle_id := ""
var match_finished: Callable
var match_cancelled: Callable
var lesson_finished: Callable
var puzzle_finished: Callable
var flag_read: Callable
var flag_written: Callable

func has_flag(key: String) -> bool:
    return bool(flag_read.call(key)) if flag_read.is_valid() else false

func set_flag(key: String, value: bool) -> void:
    if flag_written.is_valid(): flag_written.call(key, value)
