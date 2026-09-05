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
    _run_suites.call_deferred()


func _run_suites() -> void:
    var kit := TestKit.new()
    var suites := {
        "go rules": "res://tests/test_go_rules.gd", "go scoring": "res://tests/test_go_scoring.gd",
        "go ai": "res://tests/test_go_ai.gd", "go setup": "res://tests/test_go_setup.gd",
        "league": "res://tests/test_league.gd", "content data": "res://tests/test_data.gd",
        "ambience": "res://tests/test_world_ambience.gd", "match music": "res://tests/test_match_music.gd",
        "exam": "res://tests/test_exam.gd",
        "save": "res://tests/test_save.gd",
        "rating": "res://tests/test_rating.gd", "cup": "res://tests/test_cup.gd", "table talk": "res://tests/test_table_talk.gd",
        "match analysis": "res://tests/test_match_analysis.gd",
        "board view": "res://tests/test_board_view.gd", "onboarding": "res://tests/test_onboarding.gd",
    }
    for name in suites:
        var before := kit.passed + kit.failed
        var suite = load(suites[name])
        if suite == null:
            push_error("Cannot load suite: " + name)
            quit(1)
            return
        suite.run(kit)
        print("  %-14s %d checks" % [name, kit.passed + kit.failed - before])
    print(kit.report())
    print("")
    quit(0 if kit.failed == 0 else 1)
