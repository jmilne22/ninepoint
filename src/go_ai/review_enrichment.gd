## Optional detail payloads. Bad enrichment removes itself, never the legacy card.
class_name ReviewEnrichment
extends RefCounted

const FIELDS := ["facts", "narration", "lesson_id", "own_actual", "own_best"]


static func enrich(findings: Array, raw: Dictionary) -> Array:
    var out: Array = []
    var enriched := false
    for original: Dictionary in findings:
        var finding := original.duplicate(true)
        var move := int(finding["move_number"])
        var details: Dictionary = raw.get("details", {}).get(move, {})
        if ["actual", "best", "pass"].all(func(key: String) -> bool: return details.get(key) is Dictionary):
            var before: Dictionary = raw.get("turns", {}).get(move - 1, {})
            var input := finding.duplicate(true)
            input.merge({"own_actual":details["actual"].get("ownership", []),
                "own_best":details["best"].get("ownership", []),
                "lead_actual":details["actual"].get("score_lead"),
                "lead_best":details["best"].get("score_lead"),
                "lead_pass":details["pass"].get("score_lead"),
                "pv_after_actual":details["actual"].get("pv", []),
                "pv_best":before.get("pv", [])}, true)
            input = ReviewFacts.player_input(input)
            var facts := ReviewFacts.build(input)
            if not facts.is_empty():
                finding["facts"] = facts
                # These detectors explain losses; praise retains its immediate-effect wording.
                var praise := str(finding["kind"]) == "strength"
                finding["narration"] = [] if praise else ReviewNarrator.describe(facts, int(finding["player"]))
                finding["lesson_id"] = "" if praise else facts["lesson_id"]
                for key in ["own_actual", "own_best"]:
                    finding[key] = quantize(input[key])
                finding = clean(finding)
                enriched = enriched or finding.has("facts")
        out.append(finding)
    if not enriched:
        return out
    # Only the already-selected cards have been analysed. No replacement queries.
    var mistake_concept := "unknown"
    var distinct: Array = []
    for finding: Dictionary in out:
        var concept := str(finding.get("facts", {}).get("concept", "unknown"))
        if finding["kind"] == "mistake":
            mistake_concept = concept
        if finding["kind"] == "lesson" and (concept == "unknown" or concept == mistake_concept):
            continue
        distinct.append(finding)
    return distinct


static func quantize(values: Variant) -> PackedFloat32Array:
    var out := PackedFloat32Array()
    for value in values:
        out.append(roundf(float(value) * 10.0) / 10.0)
    return out


static func clean(finding: Dictionary) -> Dictionary:
    var out := finding.duplicate(true)
    if not out.has("facts"):
        return out
    var size := int(out.get("size", 0))
    var facts: Variant = out["facts"]
    var valid := size >= 2 and size <= 19 and facts is Dictionary
    if valid:
        valid = ReviewNarrator.valid(facts, out.get("narration"), size) and _shape(facts,size)
    for key in ["own_actual", "own_best"]:
        var values: Variant = out.get(key)
        if not (values is Array or values is PackedFloat32Array) or values.size() != size * size:
            valid = false
        else:
            for value in values:
                if not (value is int or value is float) or not is_finite(float(value)) or absf(float(value)) > 1.0:
                    valid = false
    if not valid:
        for key in FIELDS:
            out.erase(key)
        return out
    for group: Dictionary in facts["group_died"]:
        if group.has("capture_example") and not _example_valid(out,group):
            for key in FIELDS:
                out.erase(key)
            return out
    var lesson: Dictionary = ReviewFacts.LESSONS.get(str(facts.get("concept", "unknown")), ReviewFacts.LESSONS["unknown"])
    out["lesson_id"] = str(lesson["id"]) if str(out.get("lesson_id", "")) == str(lesson["id"]) else ""
    for key in ["own_actual", "own_best"]:
        out[key] = quantize(out[key])
    return out


static func _shape(facts: Dictionary, size: int) -> bool:
    var board := GoBoard.new(size)
    for key in ["region_lost", "group_died", "group_saved", "refutation"]:
        if not facts.get(key) is Array:
            return false
    for key in ["group_died", "group_saved"]:
        for group in facts[key]:
            if not group is Dictionary or not group.get("stones") is Array or not group.get("liberties") is Array:
                return false
            if group["stones"].is_empty() or not group["stones"].has(group.get("anchor")):
                return false
            if not (group.get("liberties_before") is int or group.get("liberties_before") is float):
                return false
            if float(group["liberties_before"]) != group["liberties"].size():
                return false
            for label in group["stones"] + group["liberties"]:
                if not label is String or board.from_label(label) < 0:
                    return false
    var concept := str(facts.get("concept","unknown"))
    if concept == "liberties" and facts["group_died"].is_empty():
        return false
    if concept == "capture" and facts["group_saved"].is_empty():
        return false
    if concept == "connection" and (facts["region_lost"].is_empty() or facts["refutation"].size() < 2):
        return false
    if concept == "value" and (not facts.get("slow_move") is Dictionary or facts["slow_move"].is_empty()):
        return false
    for region in facts["region_lost"]:
        if not region is Dictionary or not region.get("members") is Array:
            return false
        if region["members"].is_empty() or not region["members"].has(region.get("anchor")):
            return false
        for label in region["members"]:
            if not label is String or board.from_label(label) < 0:
                return false
    return true


## JSON must contain numeric arrays, without float32's binary rounding tails.
static func save_entries(entries: Dictionary) -> Dictionary:
    var out := entries.duplicate(true)
    for payload in out.values():
        if not payload is Dictionary:
            continue
        for finding in payload.get("findings", []):
            if not finding is Dictionary:
                continue
            for key in ["own_actual", "own_best"]:
                if finding.has("facts") and finding.has(key):
                    var numbers: Array = []
                    for value in finding[key]:
                        numbers.append(roundf(float(value) * 10.0) / 10.0)
                    finding[key] = numbers
    return out


static func restore_entries(entries: Dictionary) -> Dictionary:
    var out := entries.duplicate(true)
    for payload in out.values():
        if not payload is Dictionary or not payload.get("findings", []) is Array:
            continue
        var findings: Array = payload.get("findings", [])
        for i in findings.size():
            if findings[i] is Dictionary:
                findings[i] = clean(findings[i])
    return out


## Saved examples are proof-bearing: recheck the line instead of trusting capture labels.
static func _example_valid(finding: Dictionary, group: Dictionary) -> bool:
    var cells: Variant = finding.get("cells")
    var size := int(finding["size"])
    if not cells is Array or cells.size() != size * size:
        return false
    for cell in cells:
        if not (cell is int or cell is float) or float(cell) not in [0.0,1.0,2.0]:
            return false
    if int(finding.get("player",0)) not in [GoBoard.BLACK,GoBoard.WHITE]:
        return false
    var actual: Variant = finding.get("actual")
    if not (actual is int or actual is float) or float(actual) != float(int(actual)):
        return false
    var labels: Array = []
    for move in finding["facts"]["refutation"]:
        if not move is Dictionary or not move.get("label") is String:
            return false
        labels.append(move["label"])
    var line := ReviewContinuation.trace(size,cells,int(finding["player"]),int(actual),labels,true)
    var expected := ReviewContinuation.capture_example(finding,group["stones"],line)
    return not expected.is_empty() and JSON.parse_string(JSON.stringify(expected)) == \
        JSON.parse_string(JSON.stringify(group["capture_example"]))
