class_name PlayerMovementTests
extends RefCounted


static func run(t: TestKit) -> void:
    t.section("player movement: run input")
    t.ok(InputMap.has_action("run"), "run is registered")
    var shift_bound := false
    for event in InputMap.action_get_events("run"):
        if event is InputEventKey and event.physical_keycode == KEY_SHIFT:
            shift_bound = true
    t.ok(shift_bound, "physical Shift activates running")

    t.section("player movement: speeds")
    t.eq(Player.movement_speed(false), 58.0, "walking keeps its shipped speed")
    t.eq(Player.movement_speed(true), 101.5, "running is exactly 1.75 times walking")
    var diagonal := Player.movement_velocity(Vector2.ONE, true)
    t.eq(diagonal.length(), Player.movement_speed(true),
        "diagonal running is normalized")
    t.eq(Player.movement_velocity(Vector2.ZERO, true), Vector2.ZERO,
        "running without a direction does not move")

    t.section("player movement: gait")
    var sprite := CharacterSprite.new()
    t.eq(sprite.gait_scale, 1.0, "NPC and new-sprite gait defaults to walking")
    t.eq(CharacterSprite.gait_step_time(1.0), CharacterSprite.STEP_TIME,
        "walking retains the existing gait timing")
    t.eq(CharacterSprite.gait_step_time(Player.RUN_MULTIPLIER),
        CharacterSprite.STEP_TIME / Player.RUN_MULTIPLIER,
        "running accelerates the gait proportionally")
