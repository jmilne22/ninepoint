## Pure JSON protocol for both review passes. Scores and ownership remain Black-positive.
class_name KataGoReviewQuery
extends RefCounted


static func query_for(replay: Dictionary, komi: float, id: String = "review") -> Dictionary:
    var size := int(replay.get("size", 0))
    var board := GoBoard.new(size)
    var moves: Array = []
    for move_value in replay.get("moves", []):
        var move: Dictionary = move_value
        var point := int(move.get("point", GoGame.PASS))
        moves.append(["B" if int(move["color"]) == GoBoard.BLACK else "W",
            "pass" if point < 0 else board.label(point)])
    var turns: Array = []
    for turn in moves.size() + 1:
        turns.append(turn)
    var query := {
        "id": id, "moves": moves, "rules": "japanese", "komi": komi,
        "boardXSize": size, "boardYSize": size, "analyzeTurns": turns,
        "includePolicy": false, "includeOwnership": false, "maxVisits": 8,
    }
    var handicap := int(replay.get("handicap", 0))
    if handicap >= 2:
        var stones: Array = []
        for point in GoGame.handicap_points(size, handicap):
            stones.append(["B", board.label(point)])
        query["initialStones"] = stones
        query["initialPlayer"] = "W"
    return query


## One line of KataGo analysis output -> {turn, score_lead, best, best_lead,
## second_lead}. Anything that is not a turn result is {}; an engine error
## comes back as {"error": ...}. Malformed lines never become a lesson.
static func parse_line(line: String, size: int = 0) -> Dictionary:
    var text := line.strip_edges()
    if not text.begins_with("{"):
        return {}
    var parsed: Variant = JSON.parse_string(text)
    if not (parsed is Dictionary):
        return {}
    if parsed.has("error"):
        return {"error": str(parsed["error"]), "id": str(parsed.get("id", ""))}
    if bool(parsed.get("isDuringSearch", false)):
        return {}
    if not parsed.has("turnNumber") or not (parsed.get("rootInfo") is Dictionary):
        return {}
    var root: Dictionary = parsed["rootInfo"]
    if not (root.get("scoreLead") is float or root.get("scoreLead") is int):
        return {}
    var out := {"turn": int(parsed["turnNumber"]), "score_lead": float(root["scoreLead"]),
        "winrate": float(root.get("winrate", 0.5)), "best": "", "best_lead": float(root["scoreLead"]),
        "second_lead": null, "id": str(parsed.get("id", "review"))}
    var infos: Array = parsed.get("moveInfos", []) if parsed.get("moveInfos") is Array else []
    if infos.size() > 0 and infos[0] is Dictionary:
        out["best"] = str(infos[0].get("move", ""))
        out["best_lead"] = float(infos[0].get("scoreLead", root["scoreLead"]))
        if infos[0].get("pv") is Array:
            out["pv"] = infos[0]["pv"].slice(0, 6)
    if infos.size() > 1 and infos[1] is Dictionary and infos[1].has("scoreLead"):
        out["second_lead"] = float(infos[1]["scoreLead"])
    if parsed.get("ownership") is Array:
        var ownership := ownership_to_board(parsed["ownership"], size)
        if not ownership.is_empty():
            out["ownership"] = ownership
    return out


## v1.15 docs/Analysis_Engine.md: A9..J9, A8..J8, ... A1..J1.
## GoBoard also indexes top-left first. Do not apply the GTP label row flip here.
## Real A1 and off-diagonal B3 probes are recorded in docs/review/OWNERSHIP.md.
static func ownership_to_board(values: Array, size: int) -> Array[float]:
    var out: Array[float] = []
    if size < 2 or size > 19 or values.size() != size * size:
        return out
    for value in values:
        if not (value is float or value is int) or not is_finite(float(value)) or absf(float(value)) > 1.0:
            return []
        out.append(float(value))
    return out


static func detail_queries(replay: Dictionary, komi: float, findings: Array) -> Array[Dictionary]:
    var base := query_for(replay, komi)
    var board := GoBoard.new(int(replay["size"]))
    var queries: Array[Dictionary] = []
    for n in mini(findings.size(), 3):
        var finding: Dictionary = findings[n]
        var i := int(finding["move_number"]) - 1
        for branch in ["actual", "best", "pass"]:
            var query := base.duplicate(true)
            var moves: Array = base["moves"].slice(0, i)
            var point := -1 if branch == "pass" else int(finding[branch])
            moves.append([base["moves"][i][0], "pass" if point < 0 else board.label(point)])
            query.merge({"id": "f%d_%s" % [n, branch], "moves": moves,
                "analyzeTurns": [moves.size()], "includeOwnership": true, "maxVisits": 50 if branch == "pass" else 200}, true)
            queries.append(query)
    return queries
