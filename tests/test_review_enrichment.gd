class_name ReviewEnrichmentTests
extends RefCounted


static func source(fixture: Dictionary) -> Dictionary:
    var finding := fixture.duplicate(true)
    finding.merge({"kind":"mistake", "move_number":9, "point_loss":9.0,
        "critique":"Yours was elsewhere.", "changed":"D3 would extend.", "habit":"Count liberties."}, true)
    var branches := {}
    for branch in ["actual", "best", "pass"]:
        branches[branch] = {"score_lead":fixture["lead_" + branch],
            "ownership":fixture.get("own_" + branch, fixture["own_actual"]),
            "pv":fixture["pv_after_actual"] if branch == "actual" else []}
    var raw := {"details":{9:branches}, "turns":{8:{"pv":fixture["pv_best"]}}}
    for key in ["own_actual", "own_best", "lead_actual", "lead_best", "lead_pass", "pv_after_actual", "pv_best"]:
        finding.erase(key)
    return {"finding":finding, "raw":raw}


static func run(t: TestKit) -> void:
    t.section("review enrichment")
    var fixture := ReviewFactsTests.dying_group()
    var data := source(fixture)
    var finding: Dictionary = ReviewEnrichment.enrich([data["finding"]], data["raw"])[0]
    var mirror := source(ReviewFactsTests.mirror(fixture))
    var white: Dictionary = ReviewEnrichment.enrich([mirror["finding"]], mirror["raw"])[0]
    t.eq(white["facts"], finding["facts"], "enrichment normalizes White exactly once")
    t.eq(white["own_actual"], finding["own_actual"], "runtime maps remain player-relative")
    t.ok(finding["own_actual"] is PackedFloat32Array, "runtime maps are packed")
    var record := {"sgf":"(;GM[1]SZ[9];B[cg];W[bg];B[];W[ch];B[];W[bf];B[];W[ce];B[hb])", "player_color":GoBoard.BLACK}
    var raw: Dictionary = data["raw"].duplicate(true)
    raw["turns"][8].merge({"score_lead":1.0,"best":"D3","best_lead":1.0})
    raw["turns"][9] = {"score_lead":-8.0,"best":"D3"}
    raw["complete"] = true
    var payload := MatchAnalysis.from_turns(0,record,raw)
    t.eq(payload["findings"][0]["facts"],finding["facts"],"SGF to sealed payload carries the same facts")
    t.eq(payload["availability"], "available", "enriched payload seals")
    var praise: Dictionary = data["finding"].duplicate(true)
    praise["kind"] = "strength"
    var enriched_praise: Dictionary = ReviewEnrichment.enrich([praise],data["raw"])[0]
    t.ok(enriched_praise["narration"].is_empty() and enriched_praise["lesson_id"] == "", "loss detectors do not add negative coaching to a praise card")
    var legacy: Dictionary = data["finding"]
    t.eq(ReviewEnrichment.enrich([legacy],{})[0],legacy,"no details preserves exact legacy payload")
    var broken := finding.duplicate(true)
    broken["narration"] = ["Try J9."]
    var clean := ReviewEnrichment.clean(broken)
    t.ok(not clean.has("facts"), "invalid saved narration removes enrichment")
    t.eq(clean["critique"],legacy["critique"],"invalid prose keeps legacy critique")
    t.eq(MatchAnalysis.available(0,"test",[],[broken])["availability"],"available","invalid enrichment never fails a review")
    for malformed in [null, [], {"region_lost":17}]:
        broken["facts"] = malformed
        t.ok(not ReviewEnrichment.clean(broken).has("facts"), "malformed facts safely fall back")
    broken = finding.duplicate(true)
    broken["facts"]["region_lost"][0]["members"] = ["garbage"]
    t.ok(not ReviewEnrichment.clean(broken).has("facts"),"malformed region coordinates remove enrichment")
    var duplicate := legacy.duplicate(true)
    duplicate.merge({"move_number":11,"kind":"lesson"}, true)
    var duplicate_raw: Dictionary = data["raw"].duplicate(true)
    duplicate_raw["details"][11] = duplicate_raw["details"][9]
    duplicate_raw["turns"][10] = duplicate_raw["turns"][8]
    t.eq(ReviewEnrichment.enrich([legacy,duplicate],duplicate_raw).size(),1,"new duplicate lesson concept omitted")
    duplicate_raw["details"].erase(11)
    t.eq(ReviewEnrichment.enrich([legacy,duplicate],duplicate_raw).size(),1,"unsupported lesson omitted without more queries")
    t.eq(ReviewEnrichment.enrich([legacy,duplicate],{}).size(),2,"complete detail failure retains old cards")
    fixture["own_best"][GoBoard.new(9).from_label("C3")] = 0.299
    var threshold := source(fixture)
    var precise: Dictionary = ReviewEnrichment.enrich([threshold["finding"]],threshold["raw"])[0]
    t.ok(precise["facts"]["group_died"].is_empty(),"facts precede quantization at a confidence boundary")
    t.ok(ReviewSummary.text(payload).contains("Tint estimates"),"enriched tally describes its ownership comparison")
    t.ok(ReviewSummary.text({"tally":{"moves":1},"findings":[legacy]}).contains("Comparisons show immediate changes"),"legacy summary wording is retained")
    var example_source := source(ReviewFactsTests.capture_example())
    var illustrated: Dictionary = ReviewEnrichment.enrich([example_source["finding"]], example_source["raw"])[0]
    t.ok(illustrated.has("facts"), "legally replayed example survives sealing")
    _save(t, illustrated, record)
    var forged := illustrated.duplicate(true)
    forged["facts"]["group_died"][0]["capture_example"][2]["label"] = "H7"
    t.ok(not ReviewEnrichment.clean(forged).has("facts"), "loaded example must really capture the named group")
    forged = illustrated.duplicate(true)
    forged["facts"]["group_died"][0]["capture_example"][2]["captured"] = ["D3"]
    t.ok(not ReviewEnrichment.clean(forged).has("facts"), "loaded capture evidence is checked against legal replay")
    _save(t, finding, record)
    var before := ReviewComparison.overlay(finding,0)
    var actual := ReviewComparison.overlay(finding,1)
    var best := ReviewComparison.overlay(finding,2)
    t.ok(before["ownership"].is_empty(),"original board has no future tint")
    t.eq(actual["ownership"],finding["own_actual"],"actual preview uses actual map")
    t.eq(best["ownership"],finding["own_best"],"best preview uses best map")
    t.ok(not actual["regions"].is_empty(),"region members reach the overlay")
    t.ok(ReviewComparison.overlay(legacy,1)["ownership"].is_empty(),"legacy board receives no tint")


static func _save(t: TestKit, finding: Dictionary, record: Dictionary) -> void:
    var state := (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
    var previous: Dictionary = state.to_dict().duplicate(true)
    state.match_records = [record]
    state.record_analysis(0,MatchAnalysis.available(0,"test",[],[finding]))
    var saved: Dictionary = state.to_dict()
    var numbers: Variant = saved["match_analysis"]["0"]["findings"][0]["own_actual"]
    t.ok(numbers is Array,"save uses JSON-safe numeric arrays")
    t.ok(not JSON.stringify(numbers).contains("000000"),"float32 tails do not bloat JSON")
    var saves := (Engine.get_main_loop() as SceneTree).root.get_node("SaveSystem")
    var existed: bool = saves.has_save(3)
    var backup := FileAccess.get_file_as_string(saves.path_for(3)) if existed else ""
    t.ok(saves.save_game(3),"enriched review writes through SaveSystem")
    state.reset()
    t.ok(saves.load_game(3),"enriched review loads through SaveSystem")
    var loaded: Dictionary = state.match_analysis["0"]["findings"][0]
    t.ok(loaded["own_actual"] is PackedFloat32Array,"load restores packed arrays")
    t.eq(loaded["facts"],JSON.parse_string(JSON.stringify(finding["facts"])),"facts survive save round trip")
    t.eq(loaded["narration"],finding["narration"],"narration survives save round trip")
    t.eq(loaded["lesson_id"],"escape","lesson survives save round trip")
    if existed:
        var file := FileAccess.open(saves.path_for(3),FileAccess.WRITE)
        file.store_string(backup)
        file.close()
    else:
        saves.delete_save(3)
    state.from_dict(previous)
