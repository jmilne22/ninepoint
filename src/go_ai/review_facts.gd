## Board-grounded comparisons, pure and independent of the engine and world.
## build() takes player-relative numbers; player_input() normalizes Black-positive data once.
class_name ReviewFacts
extends RefCounted

const MEANINGFUL_LOSS := 0.75
const LESSONS := {
    "liberties": {"id":"escape", "teacher":"Kesh", "topic":"escaping"},
    "capture": {"id":"capture", "teacher":"Wren", "topic":"capturing"},
    "connection": {"id":"connection", "teacher":"Kesh", "topic":"connecting"},
    "value": {"id":"finishing", "teacher":"Wren", "topic":"finishing"},
    "unknown": {"id":"", "teacher":"", "topic":""},
}


static func player_input(black: Dictionary) -> Dictionary:
    var out := black.duplicate(true)
    var player := int(out.get("player", 0))
    if player not in [GoBoard.BLACK, GoBoard.WHITE]:
        return {}
    var sign_value := 1.0 if player == GoBoard.BLACK else -1.0
    for key in ["own_actual", "own_best"]:
        if not out.get(key) is Array:
            return {}
        for i in out[key].size():
            if not _number(out[key][i]):
                return {}
            out[key][i] = float(out[key][i]) * sign_value
    for key in ["lead_actual", "lead_best"] + (["lead_pass"] if out.has("lead_pass") else []):
        if not _number(out.get(key)):
            return {}
        out[key] = float(out[key]) * sign_value
    return out


static func build(input: Dictionary, position: GoGame = null) -> Dictionary:
    if not _valid(input):
        return {}
    var board := GoBoard.new(int(input["size"]))
    board.cells = PackedByteArray(input["cells"])
    if position != null:
        if position.size() != board.size or position.to_move != int(input["player"]) \
                or position.board.cells != board.cells or not position.is_legal(int(input["actual"])) \
                or not position.is_legal(int(input["best"])):
            return {}
    var actual := int(input["actual"])
    var best := int(input["best"])
    var player := int(input["player"])
    var out := {"region_lost":[], "group_died":[], "group_saved":[], "refutation":[],
        "slow_move":{}, "urgent_elsewhere":{}, "concept":"unknown", "lesson_id":""}
    if actual == best:
        return out
    out["region_lost"] = _regions(board, input["own_actual"], input["own_best"])
    var actual_line := ReviewContinuation.trace(board.size, input["cells"], player, actual,
        input.get("pv_after_actual", []), true, position)
    var best_line := ReviewContinuation.trace(board.size, input["cells"], player, actual,
        input.get("pv_best", []), false, position)
    # A best PV must begin with the compared move, not a later independent search's choice.
    if not best_line.is_empty() and int(best_line[0]["point"]) != best:
        best_line = []
    for chain in board.all_chains():
        var stones: PackedInt32Array = chain["stones"]
        var before_mean := 0.0
        var after_mean := 0.0
        for point in stones:
            before_mean += float(input["own_best"][point])
            after_mean += float(input["own_actual"][point])
        if before_mean / stones.size() < 0.3 or after_mean / stones.size() > -0.3:
            continue
        var ours := int(chain["color"]) == player
        var labels := _labels(board, stones)
        var line: Array = actual_line if ours else best_line
        var group := {"anchor":labels[0], "stones":labels,
            "liberties_before":chain["liberties"].size(), "liberties":_labels(board, chain["liberties"]),
            "captured_at":ReviewContinuation.captured_at(labels, line)}
        if ours and group["captured_at"] == "" and position == null:
            var example := ReviewContinuation.capture_example(input,labels,actual_line)
            if not example.is_empty():
                group["capture_example"] = example
        out["group_died" if ours else "group_saved"].append(group)
    if (not out["region_lost"].is_empty() or not out["group_died"].is_empty()) and actual_line.size() >= 2:
        out["refutation"] = actual_line
    var loss := float(input["lead_best"]) - float(input["lead_actual"])
    var worth := float(input["lead_actual"]) - float(input.get("lead_pass", input["lead_actual"]))
    if input.has("lead_pass") and loss >= MEANINGFUL_LOSS and worth < 1.0:
        out["slow_move"] = {"actual":board.label(actual), "best":board.label(best),
            "worth_actual":roundi(worth), "worth_best":roundi(float(input["lead_best"]) - float(input["lead_pass"]))}
    var distance := board.point(actual) - board.point(best)
    if abs(distance.x) + abs(distance.y) >= board.size / 2.0 and not out["group_died"].is_empty():
        out["urgent_elsewhere"] = {"actual":board.label(actual), "best":board.label(best),
            "anchor":out["group_died"][0]["anchor"]}
    out["concept"] = _concept(board, player, out)
    out["lesson_id"] = LESSONS[out["concept"]]["id"]
    if not out["region_lost"].is_empty() or not out["group_died"].is_empty() \
            or not out["group_saved"].is_empty() or not out["slow_move"].is_empty():
        out["moves"] = {"actual":board.label(actual), "best":board.label(best), "point_loss":roundi(maxf(0.0, loss))}
        out["best_line"] = best_line
    return out


static func _regions(board: GoBoard, actual: Array, best: Array) -> Array:
    var pending := {}
    for i in board.cells.size():
        if float(best[i]) - float(actual[i]) > 0.5:
            pending[i] = true
    var regions: Array = []
    while not pending.is_empty():
        var start: int = pending.keys()[0]
        var stack: Array[int] = [start]
        pending.erase(start)
        var members := PackedInt32Array()
        var sum := 0.0
        var centroid := Vector2.ZERO
        var anchor := start
        var largest := -1.0
        while not stack.is_empty():
            var point: int = stack.pop_back()
            members.append(point)
            centroid += Vector2(board.point(point))
            var delta := float(best[point]) - float(actual[point])
            sum += delta
            if delta > largest or (delta == largest and point < anchor):
                largest = delta
                anchor = point
            for neighbour in board.neighbours(point):
                if pending.has(neighbour):
                    pending.erase(neighbour)
                    stack.append(neighbour)
        if roundi(sum) >= 2:
            regions.append({"anchor":board.label(anchor), "points":roundi(sum),
                "area":_area(centroid / members.size(), board.size), "members":_labels(board, members)})
    regions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if int(a["points"]) != int(b["points"]):
            return int(a["points"]) > int(b["points"])
        return board.from_label(a["anchor"]) < board.from_label(b["anchor"]))
    return regions.slice(0, 2)


static func _area(centroid: Vector2, size: int) -> String:
    var x := clampi(int(centroid.x * 3.0 / size), 0, 2)
    var y := clampi(int(centroid.y * 3.0 / size), 0, 2)
    return [["upper-left corner", "upper side", "upper-right corner"],
        ["left side", "centre", "right side"],
        ["lower-left corner", "lower side", "lower-right corner"]][y][x]


static func _concept(board: GoBoard, player: int, facts: Dictionary) -> String:
    if not facts["group_died"].is_empty():
        return "liberties"
    if not facts["group_saved"].is_empty():
        return "capture"
    var line: Array = facts["refutation"]
    if not facts["region_lost"].is_empty() and line.size() >= 2 and int(line[1]["point"]) >= 0:
        for neighbour in board.neighbours(int(line[1]["point"])):
            if board.cells[neighbour] == player:
                return "connection"
    if not facts["slow_move"].is_empty():
        return "value"
    return "unknown"


static func _labels(board: GoBoard, points: PackedInt32Array) -> Array:
    var sorted := points.duplicate()
    sorted.sort()
    var labels: Array = []
    for point in sorted:
        labels.append(board.label(point))
    return labels


static func _number(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value))


static func _valid(input: Dictionary) -> bool:
    var size := int(input.get("size", 0))
    if size < 2 or size > 19 or int(input.get("player",0)) not in [GoBoard.BLACK,GoBoard.WHITE]:
        return false
    for key in ["cells", "own_actual", "own_best"]:
        if not input.get(key) is Array or input[key].size() != size * size:
            return false
        for value in input[key]:
            if not _number(value):
                return false
            if key == "cells":
                if float(value) not in [0.0,1.0,2.0]:
                    return false
            elif absf(float(value)) > 1.0:
                return false
    for key in ["lead_actual", "lead_best"] + (["lead_pass"] if input.has("lead_pass") else []):
        if not _number(input.get(key)):
            return false
    for key in ["pv_after_actual", "pv_best"]:
        if not input.get(key, []) is Array:
            return false
    var game := GoGame.new(size)
    game.set_position(PackedByteArray(input["cells"]),int(input["player"]))
    for key in ["actual", "best"]:
        if not _number(input.get(key)) or float(input[key]) != float(int(input[key])) or game.legality(int(input[key])) != GoGame.Legality.LEGAL:
            return false
    return true
