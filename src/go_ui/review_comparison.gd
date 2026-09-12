## Each preview starts from the same original position, never from the other move.
class_name ReviewComparison
extends RefCounted


static func position(finding: Dictionary, mode: int) -> GoGame:
    var game := MatchAnalysis.position(int(finding.get("size", 9)), finding.get("cells", []))
    if game == null or mode == 0:
        return game
    var player := int(finding.get("player", GoBoard.BLACK))
    game.to_move = player
    var point := int(finding.get("actual" if mode == 1 else "best", -1))
    if point >= 0 and game.legality(point) == GoGame.Legality.LEGAL:
        game.play(point)
    return game


static func pages(blocks: Array[String], width: int, height: int) -> PackedStringArray:
    var result := PackedStringArray()
    var current := ""
    for block in blocks:
        var combined := block if current == "" else current + "\n\n" + block
        if UiKit.text_height(combined, width) <= height:
            current = combined
            continue
        if current != "":
            result.append(current)
        var parts := UiKit.paginate(block, width, height)
        for i in range(parts.size() - 1):
            result.append(parts[i])
        current = parts[-1] if not parts.is_empty() else ""
    if current != "":
        result.append(current)
    return result


static func overlay(finding: Dictionary, mode: int) -> Dictionary:
    var out := {"ownership":PackedFloat32Array(), "regions":[]}
    var safe := ReviewEnrichment.clean(finding)
    if not safe.has("facts") or mode == 0:
        return out
    out["ownership"] = safe["own_actual" if mode == 1 else "own_best"]
    var board := GoBoard.new(int(safe["size"]))
    for region in safe["facts"]["region_lost"]:
        var points := PackedInt32Array()
        for label in region["members"]:
            var point := board.from_label(label)
            if point >= 0:
                points.append(point)
        out["regions"].append(points)
    return out
