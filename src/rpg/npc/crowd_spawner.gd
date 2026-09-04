## Keeps a trickle of people crossing the map.
##
## Routes are declared per map in tools/gen_maps.py and validated there: every
## waypoint must be on a walkable tile, so a passer cannot be launched into a
## wall. A map with no routes builds this and it does nothing.
class_name CrowdSpawner
extends Node2D

## How many may be on a map at once, by hour. Steenbeek empties after dark --
## which is the point of Onderbrug being where it is.
const DENSITY := {"morning": 3, "afternoon": 3, "dusk": 2, "night": 1}
## The street's default cast of nobodies. A route may name its own instead --
## the Instituut's hall gets students, and a dockworker in it would be a
## costume error nobody would be able to name but everybody would feel.
const SHEETS := ["extra_commuter", "extra_shopper", "extra_docker", "extra_kid"]

## What a market morning adds and what the drizzle takes away, outdoors only --
## a room's population is not the weather's business, and the indoor maps have
## no routes anyway.
const MARKET_EXTRA := 3
const WET_FEWER := 2

var _map: MapData
var _routes: Array = []
var _timers: Array[float] = []


func setup(map: MapData) -> void:
    _map = map
    _routes = map.routes
    for r in _routes:
        # Stagger the first arrival, or the whole street arrives on frame one.
        _timers.append(randf_range(1.0, float(r.get("rate", 12.0))))


## How many may be on this map at this hour, on this kind of day.
##
## The two occasions pull in opposite directions and the street is where you can
## see it: a market morning has more people on it than an ordinary one, and a wet
## day has fewer. They compose rather than override, so a wet market day is a
## thin market -- which is the honest answer and the one the half-empty stalls in
## Tomas's own dialogue describe.
func _cap() -> int:
    var cap := int(DENSITY.get(GameState.time_block, 2))
    if GameState.is_market_day() and GameState.time_block == "morning" \
            and not _map.indoors:
        cap += MARKET_EXTRA
    if GameState.is_wet() and not _map.indoors:
        cap = maxi(1, cap - WET_FEWER)
    return cap


func _process(delta: float) -> void:
    if _routes.is_empty():
        return
    var cap := _cap()
    for i in _routes.size():
        _timers[i] -= delta
        if _timers[i] > 0.0:
            continue
        var route: Dictionary = _routes[i]
        _timers[i] = float(route.get("rate", 12.0)) * randf_range(0.7, 1.4)
        if get_child_count() >= cap:
            continue
        _send(route)


func _send(route: Dictionary) -> void:
    var points: Array[Vector2] = []
    for t in route.get("path", []):
        points.append(_map.stand_position(Vector2i(int(t[0]), int(t[1]))))
    if points.size() < 2:
        return
    # Half the traffic goes the other way, so a street is not a conveyor belt.
    if randf() < 0.5:
        points.reverse()
    var sheets: Array = route.get("sheets", SHEETS)
    if sheets.is_empty():
        sheets = SHEETS
    Passer.spawn(self, str(sheets[randi() % sheets.size()]), points)
