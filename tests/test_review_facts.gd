## Handwritten ownership fixtures. No engine, scene tree, or autoload is involved.
class_name ReviewFactsTests
extends RefCounted


static func run(t: TestKit) -> void:
    t.section("review facts")
    # Written first: the same physical problem for White must tell the same story.
    var black := dying_group()
    var white := mirror(black)
    t.eq(ReviewFacts.build(ReviewFacts.player_input(white)),
        ReviewFacts.build(ReviewFacts.player_input(black)), "White has identical player-relative facts")
    for fixture in [corner(), dying_group(), spared_group(), slow(), quiet()]:
        t.eq(ReviewFacts.build(ReviewFacts.player_input(mirror(fixture))),
            ReviewFacts.build(ReviewFacts.player_input(fixture)), "all detectors preserve colour symmetry")
    var died := ReviewFacts.build(ReviewFacts.player_input(black))
    t.eq(died["group_died"].size(), 1, "one friendly group was lost")
    var group: Dictionary = died["group_died"][0]
    t.eq(group["anchor"], "C3", "the endangered stone is named")
    t.eq(group["stones"], ["C3"], "the entire original group is recorded")
    t.eq(group["liberties_before"], 2, "the group had exactly two liberties")
    t.eq(group["liberties"], ["C4", "D3"], "both liberties are named")
    t.eq(group["captured_at"], "D4", "the PV proves the capture, including the extension")
    t.eq(died["refutation"].size(), 3, "the three-move legal line is retained")
    t.eq(died["refutation"][0]["role"], "opponent", "opponent replies to the actual move")
    t.eq(died["refutation"][1]["role"], "player", "PV roles alternate")
    t.ok(not died["urgent_elsewhere"].is_empty(), "the actual move was far from the rescue")
    t.eq(died["concept"], "liberties", "group loss has priority")
    t.eq(died["lesson_id"], "escape", "the required card offers Kesh's lesson")
    var region := ReviewFacts.build(ReviewFacts.player_input(corner()))
    t.eq(region["region_lost"].size(), 1, "a connected lost corner is one region")
    t.eq(region["region_lost"][0]["area"], "lower-left corner", "top-left storage gives correct region name")
    t.eq(region["region_lost"][0]["points"], 6, "ownership deltas are summed and rounded")
    t.eq(region["region_lost"][0]["anchor"], "A2", "equal deltas have a stable anchor")
    var spared := ReviewFacts.build(ReviewFacts.player_input(spared_group()))
    t.eq(spared["group_saved"].size(), 1, "a missed opponent capture is distinct from losing your group")
    t.eq(spared["group_saved"][0]["captured_at"], "D3", "best move actually captures the named group")
    t.eq(spared["concept"], "capture", "missed capture points to capture")
    var small := ReviewFacts.build(ReviewFacts.player_input(slow()))
    t.eq(small["slow_move"]["worth_actual"], 1, "sub-one-point move rounds to one")
    t.eq(small["slow_move"]["worth_best"], 8, "larger move is priced relative to pass")
    t.eq(small["slow_move"]["actual"], "H8", "value has a coordinate")
    t.eq(small["concept"], "value", "value points to finishing")
    var silent := ReviewFacts.build(ReviewFacts.player_input(quiet()))
    for key in ["region_lost", "group_died", "group_saved", "refutation", "slow_move", "urgent_elsewhere"]:
        t.ok(silent[key].is_empty(), "quiet position has no " + key)
    t.eq(silent["concept"], "unknown", "identical estimates do not invent an idea")
    t.eq(silent["lesson_id"], "", "quiet position does not invent a lesson")
    _examples(t)
    _boundaries(t)


static func quiet() -> Dictionary:
    var cells: Array = []
    var ownership: Array = []
    cells.resize(81)
    cells.fill(0)
    ownership.resize(81)
    ownership.fill(0.0)
    var board := GoBoard.new(9)
    return {"size":9, "cells":cells, "player":GoBoard.BLACK,
        "actual":board.from_label("H8"), "best":board.from_label("D3"),
        "own_actual":ownership.duplicate(), "own_best":ownership.duplicate(),
        "lead_actual":0.0, "lead_best":0.0, "lead_pass":0.0,
        "pv_after_actual":[], "pv_best":[]}


static func dying_group() -> Dictionary:
    var f := quiet()
    var board := GoBoard.new(9)
    f["cells"][board.from_label("C3")] = GoBoard.BLACK
    for label in ["B3", "C2", "B4", "C5"]:
        f["cells"][board.from_label(label)] = GoBoard.WHITE
    for label in ["C3", "C4"]:
        f["own_actual"][board.from_label(label)] = -0.8
        f["own_best"][board.from_label(label)] = 0.8
    f.merge({"lead_actual":-8.0, "lead_best":1.0, "lead_pass":-8.5,
        "pv_after_actual":["D3", "C4", "D4"], "pv_best":["D3", "H7", "E3"]}, true)
    return f


static func corner() -> Dictionary:
    var f := quiet()
    var board := GoBoard.new(9)
    for label in ["A1", "B1", "C1", "A2", "B2", "C2"]:
        f["own_best"][board.from_label(label)] = 0.8
        f["own_actual"][board.from_label(label)] = -0.2
    f["lead_best"] = 6.0
    f["lead_pass"] = -2.0
    return f


static func spared_group() -> Dictionary:
    var f := quiet()
    var board := GoBoard.new(9)
    f["cells"][board.from_label("C3")] = GoBoard.WHITE
    for label in ["B3", "C2", "C4"]:
        f["cells"][board.from_label(label)] = GoBoard.BLACK
    f["own_best"][board.from_label("C3")] = 0.9
    f["own_actual"][board.from_label("C3")] = -0.9
    f["pv_best"] = ["D3", "H7"]
    return f


static func slow() -> Dictionary:
    var f := quiet()
    f.merge({"lead_actual":0.8, "lead_best":8.0, "lead_pass":0.0}, true)
    return f


static func mirror(f: Dictionary) -> Dictionary:
    var out := f.duplicate(true)
    out["player"] = GoBoard.WHITE
    for i in 81:
        if int(out["cells"][i]) != GoBoard.EMPTY:
            out["cells"][i] = GoBoard.opponent(int(out["cells"][i]))
        for key in ["own_actual", "own_best"]:
            out[key][i] = -float(out[key][i])
    for key in ["lead_actual", "lead_best", "lead_pass"]:
        out[key] = -float(out[key])
    return out


static func _boundaries(t: TestKit) -> void:
    var f := dying_group()
    f["pv_after_actual"] = ["D3", "B3", "D4"]
    var facts := ReviewFacts.build(ReviewFacts.player_input(f))
    t.ok(facts["refutation"].is_empty(), "an illegal PV is never a capturing sequence")
    t.eq(facts["group_died"][0]["captured_at"], "", "prediction alone cannot claim a demonstrated capture")
    f = dying_group()
    f["pv_after_actual"] = ["D3"]
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f))["refutation"].is_empty(), "one reply is not a two-move line")
    f = slow()
    f["lead_actual"] = 1.0
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f))["slow_move"].is_empty(), "slow threshold is strictly below one point")
    f = quiet()
    f["own_best"].fill(0.5)
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f))["region_lost"].is_empty(), "delta threshold is strict")
    for key in ["cells", "own_actual", "own_best"]:
        f = dying_group()
        f[key] = []
        t.ok(ReviewFacts.build(ReviewFacts.player_input(f)).is_empty(), "malformed " + key + " yields no claim")
    f = dying_group()
    f["actual"] = 81
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f)).is_empty(), "off-board moves yield no claim")
    f = dying_group()
    f["own_best"][0] = NAN
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f)).is_empty(), "nonfinite ownership yields no claim")
    f = dying_group()
    f["actual"] = 1.5
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f)).is_empty(), "fractional points cannot be silently relocated")
    f = dying_group()
    var board := GoBoard.new(9)
    f["own_best"][board.from_label("C3")] = 0.0
    f["own_actual"][board.from_label("C3")] = 0.0
    t.eq(ReviewFacts.build(ReviewFacts.player_input(f))["concept"], "connection", "adjacent second PV move supports connection")
    f = dying_group()
    f["own_best"][board.from_label("C3")] = 0.3
    f["own_actual"][board.from_label("C3")] = -0.3
    t.eq(ReviewFacts.build(ReviewFacts.player_input(f))["group_died"].size(), 1, "group confidence thresholds include endpoints")
    f["own_best"][board.from_label("C3")] = 0.29
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f))["group_died"].is_empty(), "a group below confidence is not condemned")
    f = quiet()
    for label in ["A1", "B1", "C1", "A9", "B9", "J9"]:
        f["own_best"][board.from_label(label)] = 1.0
        f["own_actual"][board.from_label(label)] = -1.0
    var regions: Array = ReviewFacts.build(ReviewFacts.player_input(f))["region_lost"]
    t.eq(regions.size(), 2, "only the largest two disconnected regions are reported")
    t.eq(regions[0]["points"], 6, "largest region comes first")
    t.eq(regions[1]["points"], 4, "second region is independently flood-filled")
    f = spared_group()
    f["pv_best"] = ["H7", "D3"]
    t.eq(ReviewFacts.build(ReviewFacts.player_input(f))["group_saved"][0]["captured_at"], "", "wrong-start PV cannot prove the preferred capture")


static func capture_example() -> Dictionary:
    var f := dying_group()
    f["pv_after_actual"] = ["D3", "H5", "H7", "D6"]
    return f


static func _examples(t: TestKit) -> void:
    var f := capture_example()
    var facts := ReviewFacts.build(ReviewFacts.player_input(f))
    t.eq(ReviewFacts.build(ReviewFacts.player_input(mirror(f))), facts,
        "illustrative captures preserve exact White orientation")
    var group: Dictionary = facts["group_died"][0]
    t.eq(group["captured_at"], "", "a legal example does not rewrite the engine's proof")
    var example: Array = group.get("capture_example", [])
    t.eq(example.map(func(m: Dictionary) -> String: return m["label"]), ["D3","H5","C4"],
        "example keeps two engine moves then fills the remaining liberty")
    t.eq(ReviewContinuation.captured_at(["C3"],example), "C4", "example captures the named chain by legal replay")
    t.eq(facts["refutation"][2]["label"], "H7", "the engine PV remains separate")
    f["pv_after_actual"] = ["H7", "H5", "D3", "D4"]
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f))["group_died"][0].get("capture_example",[]).is_empty(),
        "no immediate capture is invented for a group with two remaining liberties")
    f["pv_after_actual"] = ["D3", "H5", "B3"]
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f))["group_died"][0].get("capture_example",[]).is_empty(),
        "an illegal engine line cannot seed an example")
    f["pv_after_actual"] = []
    t.ok(ReviewFacts.build(ReviewFacts.player_input(f))["group_died"][0].get("capture_example",[]).is_empty(),
        "ownership alone cannot seed an example")
