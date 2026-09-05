## UI-driven league checks shared by the explicit playtest routes.
class_name LeaguePlayProbe
extends RefCounted

static func perform(tree: SceneTree, spec: Dictionary, shot: Callable) -> void:
    var mode := str(spec["experience"])
    var deadline := Time.get_ticks_msec() + int(float(spec.get("timeout", 60)) * 1000)
    while Time.get_ticks_msec() < deadline:
        match mode:
            "rank_card":
                var scene := tree.current_scene
                var hud: Object = scene.get("hud")
                var box: Object = tree.root.get_node("Autopilot")._dialogue_box()
                if hud != null and hud.get("_rank_card") != null:
                    await tree.create_timer(2.0).timeout
                    await shot.call("rank_card_before_practice")
                    var words: String = box.get("_text").text
                    var advance: bool = box.get("_awaiting_advance")
                    await ExperienceProbe.press(tree, "move_down")
                    await ExperienceProbe.press(tree, "interact")
                    if hud.get("_rank_card") != null or box.get("_text").text != words or bool(box.get("_awaiting_advance")) != advance:
                        push_error("Experience rank card did not consume input before dialogue.")
                        tree.quit(1)
                        return
                    await shot.call("welcome_after_card")
                    print("EXPERIENCE: rank card dismissed without advancing underlying dialogue")
                    return
                if box != null and bool(box.get("running")):
                    await ExperienceProbe.press(tree, "interact")
            "choice":
                var box: Object = tree.root.get_node("Autopilot")._dialogue_box()
                if box != null and bool(box.get("_awaiting_choice")):
                    var options: Array = box.get("_choice_nodes")
                    var wanted := -1
                    var texts: Array = spec.get("alternatives", [str(spec["text"])])
                    for i in options.size():
                        for candidate in texts:
                            if str(options[i].text).contains(str(candidate)):
                                wanted = i
                                break
                        if wanted >= 0:
                            break
                    if wanted < 0:
                        push_error("Experience choice '%s' was not offered." % spec["text"])
                        tree.quit(1)
                        return
                    while int(box.get("_choice_index")) != wanted:
                        await ExperienceProbe.press(tree, "move_down")
                    await shot.call("choice_%s" % str(spec["text"]).validate_filename())
                    await ExperienceProbe.press(tree, "interact")
                    return
                if box != null and bool(box.get("running")):
                    await ExperienceProbe.press(tree, "interact")
            "assert_progress":
                var state := tree.root.get_node("GameState")
                for key in spec.get("flags", []):
                    if not state.has_flag(str(key)):
                        push_error("Experience expected saved flag: %s" % key)
                        tree.quit(1)
                        return
                var attempt := LeagueProgress.active(state)
                if spec.has("played") and LeagueAttempt.played(attempt) != int(spec["played"]):
                    push_error("Experience fixture count disagrees with the route.")
                    tree.quit(1)
                    return
                if spec.has("rank") and state.rank_label() != str(spec["rank"]):
                    push_error("Experience rank disagrees with the route.")
                    tree.quit(1)
                    return
                print("EXPERIENCE: verified progress %s" % JSON.stringify(spec))
                return
            "reload":
                var state := tree.root.get_node("GameState")
                # JSON parses numbers as floats; normalise before comparing
                # instead of treating 3 and 3.0 as a changed result.
                var attempts := JSON.stringify(JSON.parse_string(JSON.stringify(state.league_attempts)))
                var records := JSON.stringify(JSON.parse_string(JSON.stringify(state.match_records)))
                var saves := tree.root.get_node("SaveSystem")
                if not saves.load_game(int(spec.get("slot", 1))):
                    tree.quit(1)
                    return
                if attempts != JSON.stringify(state.league_attempts) or records != JSON.stringify(state.match_records):
                    push_error("Experience reload changed saved league fixtures or history.")
                    tree.quit(1)
                    return
                var router := tree.root.get_node("SceneRouter")
                router.go_to_map(state.current_map, state.spawn_point)
                await tree.create_timer(1.0).timeout
                while router.is_busy():
                    await tree.process_frame
                print("EXPERIENCE: disk reload preserved every league fixture and history index")
                return
        await tree.process_frame
    push_error("Experience route timed out waiting for %s." % mode)
    tree.quit(1)
