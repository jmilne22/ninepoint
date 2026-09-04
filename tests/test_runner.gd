## Headless test entry point:
##   godot --headless --path . --script res://tests/test_runner.gd
extends SceneTree

## A suite that errors out would otherwise leave the process running forever.
const WATCHDOG_SECONDS := 180.0

var _elapsed := 0.0


func _process(delta: float) -> bool:
    _elapsed += delta
    if _elapsed > WATCHDOG_SECONDS:
        printerr("test_runner: watchdog fired -- a suite did not finish")
        quit(2)
    return false


func _initialize() -> void:
    var kit := TestKit.new()
    var suites := {
        "go rules": GoRulesTests, "go scoring": GoScoringTests,
        "go ai": GoAiTests, "go setup": GoSetupTests,
        "league": LeagueTests, "content data": GoDataTests,
        "ambience": WorldAmbienceTests, "match music": MatchMusicTests,
        "exam": ExamTests,
        "save": SaveTests,
        "rating": RatingTests, "cup": CupTests, "table talk": TableTalkTests,
    }
    for name in suites:
        var before := kit.passed + kit.failed
        suites[name].run(kit)
        print("  %-14s %d checks" % [name, kit.passed + kit.failed - before])
    print(kit.report())
    print("")
    quit(0 if kit.failed == 0 else 1)
