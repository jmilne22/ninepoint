## Re-analyse an actually played SGF, optionally colour-mirrored for White acceptance.
extends SceneTree

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    var path := OS.get_environment("REV01_PLAY_FILE")
    var played: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
    var mirror := OS.get_environment("REV01_MIRROR") == "1"
    var sgf := str(played["sgf"])
    var player := int(played["player"])
    var komi := float(played["komi"])
    if mirror:
        sgf = sgf.replace(";B[",";X[").replace(";W[",";B[").replace(";X[",";W[")
        var first := sgf.find(";W[")
        sgf = sgf.insert(first,";B[]")
        sgf = sgf.replace("KM[%s]" % str(komi),"KM[%s]" % str(-komi))
        komi = -komi
        player = GoBoard.opponent(player)
    var record := {"sgf":sgf,"komi":komi,"player_color":player,"board_size":9,
        "npc_id":"wren","opponent_name":"Wren Calloway","context_id":"rev01_fixture",
        "by_capture":false,"handicap":0,"unrated":true,"developer_fixture":true}
    var runner := KataGoAnalysis.new()
    var raw: Dictionary = await runner.run(record,true)
    raw = await runner.run_details(record,raw)
    print("REV-01 fixture: pass-1 %.3f s; pass-2 %.3f s" % [raw.get("pass1_seconds",0),raw.get("pass2_seconds",0)])
    if float(raw.get("pass2_seconds",0)) > 45.0:
        printerr("REV-01 BUDGET EXCEEDED: stop and ask owner before adjusting visits.")
        quit(2)
        return
    var moments := MatchAnalysis.moments_from_turns(MatchAnalysis.replay(sgf),player,raw["turns"])
    for f in MatchAnalysis.select_moments(moments):
        print("REV-01 SELECT " + JSON.stringify({"move":f["move_number"],"loss":f["point_loss"],"concept":f.get("concept",""),"best":f["best"]}))
    var payload := MatchAnalysis.from_turns(0,record,raw)
    var file := FileAccess.open("user://rev01_fixture.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"record":record,"review":ReviewEnrichment.save_entries({"0":payload})["0"],"target":played["target"]},"  "))
    for finding in payload.get("findings",[]):
        print("REV-01 CARD " + JSON.stringify({"move":finding["move_number"],"narration":finding.get("narration",[])}))
    quit(0)
