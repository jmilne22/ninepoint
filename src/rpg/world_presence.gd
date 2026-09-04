## Chooses the version of a place that the player currently inhabits.
##
## This is deliberately not a schedule. A state changes only when persistent
## progress changes, so a player can always find people and services where the
## map says they are. It is also pure: tests can resolve a map from a flags
## dictionary without needing the GameState autoload.
class_name WorldPresence
extends RefCounted


static func apply(map: MapData, flags: Dictionary) -> String:
    if map == null or map.presence_states.is_empty():
        return ""
    var state := select(map.presence_states, flags)
    if state.is_empty():
        return ""
    if state.has("npcs"):
        map.npcs = state["npcs"]
    if state.has("routes"):
        map.routes = state["routes"]
    map.presence_tiles = state.get("tiles", [])
    map.presence_lines = state.get("lines", [])
    return str(state.get("id", ""))


## First matching state wins. Author maps from most specific to least specific,
## ending in an unconditional "routine" state.
static func select(states: Array, flags: Dictionary) -> Dictionary:
    for raw in states:
        var state: Dictionary = raw
        if matches(state.get("when", {}), flags):
            return state
    return {}


static func matches(when: Dictionary, flags: Dictionary) -> bool:
    for key in when.get("all", []):
        if not bool(flags.get(str(key), false)):
            return false
    for key in when.get("none", []):
        if bool(flags.get(str(key), false)):
            return false
    for key in when.get("equals", {}):
        if flags.get(str(key)) != when["equals"][key]:
            return false
    return true
