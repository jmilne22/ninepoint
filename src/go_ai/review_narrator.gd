## Templates only: every coordinate and tactical claim comes from ReviewFacts.
class_name ReviewNarrator
extends RefCounted


static func describe(facts: Dictionary, player: int, immediate: String = "") -> Array[String]:
    var lines: Array[String] = []
    if facts.is_empty() or not facts.has("moves"):
        return lines
    var moves: Dictionary = facts["moves"]
    var actual := str(moves["actual"])
    var best := str(moves["best"])
    var cost := _points(int(moves["point_loss"]))
    var died: Array = facts.get("group_died", [])
    var saved: Array = facts.get("group_saved", [])
    var regions: Array = facts.get("region_lost", [])
    var slow: Dictionary = facts.get("slow_move", {})
    if not died.is_empty():
        var group: Dictionary = died[0]
        lines.append("Before %s, your group at %s had %s." % [actual, group["anchor"], _liberties(group)])
        var line: Array = facts.get("refutation", [])
        if str(group.get("captured_at", "")) != "" and not line.is_empty():
            lines.append("%s captures it; this choice cost about %s." % [_sequence(line,player,group["stones"]),cost])
        elif not group.get("capture_example", []).is_empty():
            lines.append("One legal example: %s captures it; the engine estimates your move cost about %s." % [
                _sequence(group["capture_example"],player,group["stones"]),cost])
        elif not line.is_empty():
            lines.append("After %s, the engine expects that group to die; your choice cost about %s." % [_sequence(line,player),cost])
        else:
            lines.append("The engine expects that group to die after %s; your choice cost about %s." % [actual,cost])
    elif not saved.is_empty():
        var group: Dictionary = saved[0]
        lines.append("Before %s, %s's group at %s had %s." % [actual,_colour(GoBoard.opponent(player)),group["anchor"],_liberties(group)])
        var line: Array = facts.get("best_line", [])
        if str(group.get("captured_at", "")) != "" and not line.is_empty():
            lines.append("%s captures it; after %s the engine expects it to live." % [_sequence(line,player,group["stones"]),actual])
        else:
            lines.append("After %s it is expected to live; the engine preferred %s by about %s." % [actual,best,cost])
    elif not regions.is_empty():
        var region: Dictionary = regions[0]
        lines.append("%s gave up about %s in the %s around %s." % [actual,_points(int(region["points"])),region["area"],region["anchor"]])
        var line: Array = facts.get("refutation", [])
        if not line.is_empty():
            lines.append("The engine continues with %s; it preferred %s instead." % [_sequence(line,player),best])
        else:
            lines.append("The engine preferred %s instead." % best)
    elif not slow.is_empty():
        if immediate != "":
            lines.append("Your move %s." % immediate.trim_suffix("."))
        lines.append("%s was worth about %s; %s was worth about %s, compared with passing." % [actual,
            _points(int(slow["worth_actual"])),best,_points(int(slow["worth_best"]))])
    var lesson: Dictionary = ReviewFacts.LESSONS.get(str(facts.get("concept","unknown")), ReviewFacts.LESSONS["unknown"])
    if str(lesson["id"]) != "" and lines.size() < 3:
        lines.append("%s's lesson on %s covers this." % [lesson["teacher"],lesson["topic"]])
    return lines


static func _sequence(line: Array, player: int, stop_stones: Array = []) -> String:
    var text: Array[String] = []
    var captured: Array = []
    for move in line:
        var colour := player if move["role"] == "player" else GoBoard.opponent(player)
        text.append("%s %s" % [_colour(colour),move["label"]])
        captured.append_array(move["captured"])
        if not stop_stones.is_empty() and stop_stones.all(func(stone: String) -> bool: return captured.has(stone)):
            break
    return ", then ".join(text)


static func _colour(player: int) -> String:
    return "Black" if player == GoBoard.BLACK else "White"


static func _liberties(group: Dictionary) -> String:
    var count := int(group["liberties_before"])
    var labels := ", ".join(group["liberties"])
    return "%d %s (%s)" % [count, "liberty" if count == 1 else "liberties",labels]


static func _points(count: int) -> String:
    return "%d point%s" % [count,"" if count == 1 else "s"]


## Validate both generated prose and saved prose. Failure only removes enrichment.
static func valid(facts: Dictionary, narration: Variant, size: int) -> bool:
    if not narration is Array or narration.size() > 3:
        return false
    var board := GoBoard.new(size)
    var coordinate := RegEx.new()
    coordinate.compile("\\b[A-Z][0-9]+\\b")
    var supported := {}
    _collect_coordinates(facts, coordinate, supported)
    for label in supported:
        if board.from_label(label) < 0:
            return false
    var endings := RegEx.new()
    endings.compile("[.!?]")
    var count := 0
    for sentence in narration:
        if not sentence is String:
            return false
        count += endings.search_all(sentence).size()
        for hit in coordinate.search_all(sentence):
            if not supported.has(hit.get_string()):
                return false
    return count <= 3


static func _collect_coordinates(value: Variant, expression: RegEx, result: Dictionary) -> void:
    if value is Dictionary:
        for child in value.values():
            _collect_coordinates(child,expression,result)
    elif value is Array:
        for child in value:
            _collect_coordinates(child,expression,result)
    elif value is String:
        for hit in expression.search_all(value):
            result[hit.get_string()] = true
