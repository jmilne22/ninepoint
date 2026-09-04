## Keeps a trickle of people crossing the map.
##
## Routes are declared per map in tools/gen_maps.py and validated there: every
## waypoint must be on a walkable tile, so a passer cannot be launched into a
## wall. A map with no routes builds this and it does nothing.
class_name CrowdSpawner
extends Node2D

## How many may be on a map at once.
const CAP := 3
## The street's default cast of nobodies. A route may name its own instead --
## the Instituut's hall gets students, and a dockworker in it would be a
## costume error nobody would be able to name but everybody would feel.
const SHEETS := ["extra_commuter", "extra_shopper", "extra_docker", "extra_kid"]

var _map: MapData
var _routes: Array = []
var _timers: Array[float] = []


func setup(map: MapData) -> void:
    _map = map
    _routes = map.routes
    for r in _routes:
        # Stagger the first arrival, or the whole street arrives on frame one.
        _timers.append(randf_range(1.0, float(r.get("rate", 12.0))))


func _process(delta: float) -> void:
    if _routes.is_empty():
        return
    var cap := CAP
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
