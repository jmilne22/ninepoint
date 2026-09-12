## UI acceptance uses saved engine evidence; it never fabricates review facts.
class_name ReviewAcceptanceProbe
extends RefCounted

static func perform(tree: SceneTree, spec: Dictionary, shot: Callable) -> void:
    var state := tree.root.get_node("GameState")
    var mode := str(spec["experience"])
    if mode == "review_fixture":
        var path := OS.get_environment("REV01_REVIEW_FILE")
        var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
        state.match_records = [data["record"]]
        state.match_analysis = ReviewEnrichment.restore_entries({"0":data["review"]})
        state.set_flag("quay_review_available",true)
        return
    var cards := tree.root.find_child("ReviewCards",true,false) as ReviewCards
    if cards == null:
        BoardPlayProbe.fail(tree,"Acceptance requires a review card")
        return
    var portable := cards.review.duplicate(true)
    var source := int(portable["source_match"])
    portable["source_match"] = 0
    var evidence := FileAccess.open("user://rev01_review.json",FileAccess.WRITE)
    evidence.store_string(JSON.stringify({"record":state.match_records[source],
        "review":ReviewEnrichment.save_entries({"0":portable})["0"],"target":ReviewPlayProbe.target},"  "))
    evidence.close()
    if mode == "review_focus_best":
        var offset := 1 if cards.review.has("tally") else 0
        var f: Dictionary = cards.review["findings"][cards._index-offset]
        await BoardPlayProbe.navigate(tree,int(f["best"]))
        return
    if mode == "review_legacy_assert":
        if cards.get("_lesson_id") != "" or not cards.get("_board").review_ownership.is_empty():
            BoardPlayProbe.fail(tree,"Legacy review gained enrichment controls")
        await shot.call("legacy_controls")
        return
    var target_index := -1
    var finding: Dictionary = {}
    var offset := 1 if cards.review.has("tally") else 0
    for i in cards.review["findings"].size():
        var f: Dictionary = cards.review["findings"][i]
        for group in f.get("facts",{}).get("group_died",[]):
            if int(group["liberties_before"]) == 2 and (str(group["captured_at"]) != "" or not group.get("capture_example",[]).is_empty()):
                target_index = i+offset
                finding = f
                break
    if target_index < 0:
        BoardPlayProbe.fail(tree,"Review has no proven two-liberty abandonment card")
        return
    while cards._index < target_index:
        await ExperienceProbe.press(tree,"move_right")
    while cards._index > target_index or cards._text_page > 0:
        await ExperienceProbe.press(tree,"move_left")
    for page in cards._text_pages.size():
        await shot.call("abandonment_page_%d" % (page+1))
        if page+1 < cards._text_pages.size():
            await ExperienceProbe.press(tree,"move_right")
    var text := " ".join(finding["narration"])
    for required in ["2 liberties","captures","about","points","Kesh","escaping"]:
        if not text.contains(required):
            BoardPlayProbe.fail(tree,"Abandonment card is missing " + required)
            return
    await ExperienceProbe.press(tree,"go_compare")
    await shot.call("ownership_actual")
    await ExperienceProbe.press(tree,"go_compare")
    await shot.call("ownership_best")
    var checkpoint := ReviewFlowProbe.fingerprint(state)
    if bool(spec.get("click",true)):
        await BoardPlayProbe.click_button(tree,"go_lesson")
    else:
        await ExperienceProbe.press(tree,"go_lesson")
    var deadline := Time.get_ticks_msec()+15000
    while Time.get_ticks_msec() < deadline:
        if tree.current_scene != null and tree.current_scene.get("lesson") != null:
            if tree.current_scene.lesson.id != "escape":
                BoardPlayProbe.fail(tree,"Lesson L opened the wrong lesson")
            await shot.call("lesson_l_escape")
            await LessonPlayProbe.run(tree,shot)
            if checkpoint != ReviewFlowProbe.fingerprint(state):
                BoardPlayProbe.fail(tree,"Lesson L changed recorded results or rank")
            if state.match_analysis.is_empty():
                BoardPlayProbe.fail(tree,"Lesson L discarded the review")
            print("REV-01 UI: Lesson L opens escape; results/rank/review retained")
            return
        await tree.process_frame
    BoardPlayProbe.fail(tree,"Lesson L did not open a lesson")
