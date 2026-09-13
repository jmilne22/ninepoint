## Assertions that distinguish a real-engine run from a successful fallback flow.
class_name KettleNextProbe
extends RefCounted

static var records_before := 0

static func perform(tree: SceneTree, spec: Dictionary) -> void:
    var state := tree.root.get_node("GameState")
    var action := str(spec.get("action", ""))
    if action == "campaign_launcher":
        if not OS.get_environment("XDG_DATA_HOME").contains("ninepoint-campaign-next/play-") or KettleNextProfile.campaign() != bool(spec.get("preview",true)):
            _fail(tree,"campaign launcher isolation/profile mismatch")
            return
        if tree.current_scene.get("map").id != "de_ketel":
            _fail(tree,"campaign launcher fixture did not enter the Kettle")
            return
        print("CAMPAIGN LAUNCHER: disposable save; correct profile and campaign fixture")
    elif action == "launcher":
        if tree.current_scene.get("map").id != "de_ketel" or not OS.get_environment("XDG_DATA_HOME").contains("ninepoint-kettle-next/play-"):
            _fail(tree,"launcher did not enter the Kettle with disposable data")
            return
        print("KETTLE LAUNCHER: actual Kettle; disposable save; prototype=",KettleNextProfile.enabled())
    elif action == "before":
        records_before = state.match_records.size()
    elif action == "engine":
        var scene := tree.current_scene as TableSceneMatch
        if scene == null or not scene.opponent is GtpOpponent:
            _fail(tree,"Wren is not using GTP")
            return
        var opponent := scene.opponent as GtpOpponent
        if not opponent.engine_started or opponent.fallback_used or opponent.legal_reply_count < 1:
            _fail(tree,"Wren used fallback or produced no legal engine reply")
            return
        print("KETTLE ENGINE: ",opponent.legal_reply_count," legal real-engine replies, no fallback")
    elif action == "return":
        if state.match_records.size() != records_before + 1:
            _fail(tree,"world return did not record exactly one match")
            return
        var payload: Dictionary = state.match_analysis.get(str(records_before),{})
        if str(payload.get("availability","")) not in ["available","steady"]:
            _fail(tree,"review is not available: "+str(payload.get("availability","missing")))
            return
        if bool(payload.get("partial",false)):
            _fail(tree,"review was partial")
            return
        print("KETTLE RETURN: one saved result; complete real-engine review; world resumed")

static func _fail(tree: SceneTree, reason: String) -> void:
    push_error("Kettle prototype acceptance: "+reason)
    tree.quit(1)
