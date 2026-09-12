class_name ReviewNarratorTests
extends RefCounted


static func run(t: TestKit) -> void:
    t.section("review narrator")
    var fixture := ReviewFactsTests.dying_group()
    var facts := ReviewFacts.build(ReviewFacts.player_input(fixture))
    var lines := ReviewNarrator.describe(facts, GoBoard.BLACK)
    var text := " ".join(lines)
    for required in ["C3", "2 liberties", "White D3", "Black C4", "White D4", "about 9 points", "Kesh", "escaping"]:
        t.ok(text.contains(required), "dying-group card includes " + required)
    t.ok(lines[0].contains("C4, D3"), "the group sentence names its liberty coordinates")
    t.ok(text.contains("captures"), "proven continuation may name the capture")
    t.ok(ReviewNarrator.valid(facts, lines, 9), "generated coordinates are all grounded")
    var white := ReviewNarrator.describe(facts, GoBoard.WHITE)
    t.ok(" ".join(white).contains("Black D3"), "White sees the opponent as Black")
    t.ok(" ".join(white).contains("White C4"), "White sees her reply as White")
    fixture["pv_after_actual"] = ["D3", "B3", "D4"]
    var uncertain := ReviewFacts.build(ReviewFacts.player_input(fixture))
    t.ok(not " ".join(ReviewNarrator.describe(uncertain, GoBoard.BLACK)).contains("captures"),
        "illegal line cannot become capture prose")
    t.ok(" ".join(ReviewNarrator.describe(uncertain, GoBoard.BLACK)).contains("expects"),
        "ownership prediction is qualified")
    for f in [ReviewFactsTests.corner(), ReviewFactsTests.spared_group(), ReviewFactsTests.slow(), ReviewFactsTests.quiet()]:
        var proof := ReviewFacts.build(ReviewFacts.player_input(f))
        var sentences := ReviewNarrator.describe(proof, GoBoard.BLACK)
        t.ok(sentences.size() <= 3, "narration is bounded to three sentences")
        t.ok(ReviewNarrator.valid(proof, sentences, 9), "template uses only fact coordinates")
    var quiet := ReviewFacts.build(ReviewFacts.player_input(ReviewFactsTests.quiet()))
    t.ok(ReviewNarrator.describe(quiet, GoBoard.BLACK).is_empty(), "quiet findings retain legacy summary")
    t.ok(not ReviewNarrator.valid(facts, ["Try J9."], 9), "unmentioned coordinate invalidates narration")
    t.ok(not ReviewNarrator.valid(facts, ["Try I3."], 9), "invalid column is rejected")
    t.ok(not ReviewNarrator.valid(facts, ["Try C30."], 9), "out-of-bounds row is rejected")
    t.ok(not ReviewNarrator.valid(facts, ["One.","Two.","Three.","Four."], 9), "four sentences are rejected")
    t.ok(not ReviewNarrator.valid(facts, ["One. Two. Three. Four."], 9), "array packing cannot bypass sentence limit")

    var illustration := ReviewFacts.build(ReviewFacts.player_input(ReviewFactsTests.capture_example()))
    var example_lines := ReviewNarrator.describe(illustration, GoBoard.BLACK)
    var example_text := " ".join(example_lines)
    for required in ["One legal example", "White D3", "Black H5", "White C4", "captures", "engine estimates", "Kesh"]:
        t.ok(example_text.contains(required), "example identifies its source and includes " + required)
    t.ok(ReviewNarrator.valid(illustration,example_lines,9), "example is grounded and within three sentences")
    t.ok(not example_text.contains("forced"), "example makes no forced-capture claim")
