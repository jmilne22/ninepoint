## Developer player only. Wren keeps her shipped profile and chooses every reply.
class_name ReviewPlayProbe
extends RefCounted

static var _pipe: EnginePipe
static var _query_id := 0
static var target: Dictionary = {}


static func run(tree: SceneTree, shot: Callable, require_black: bool = false) -> void:
    _pipe = EnginePipe.new()
    _pipe.open(KataGoAnalysis.COMMAND, PackedStringArray(["analysis", "-config",KataGoAnalysis.CONFIG,
        "-model",KataGoAnalysis.MODEL,"-override-config","numAnalysisThreads=1"]))
    target = {}
    var deadline := Time.get_ticks_msec() + 900000
    var played := 0
    while Time.get_ticks_msec() < deadline:
        var scene := tree.current_scene
        if scene == null or not scene.has_method("is_player_turn_ready"):
            await tree.process_frame
            continue
        if scene.is_counting() or str(scene.get("_awaiting")) == "dismiss":
            _pipe.close()
            if target.is_empty():
                BoardPlayProbe.fail(tree, "No demonstrated two-liberty abandonment found in this Wren game")
                return
            var file := FileAccess.open("user://rev01_play.json",FileAccess.WRITE)
            file.store_string(JSON.stringify({"target":target,"sgf":GoSgf.to_sgf(scene.game),
                "player":scene.player_color,"komi":scene.game.komi},"  "))
            print("REV-01 PLAY: " + JSON.stringify(target))
            return
        if not scene.is_player_turn_ready():
            await tree.process_frame
            continue
        var game: GoGame = scene.game
        var progress_file := FileAccess.open("user://rev01_progress.json",FileAccess.WRITE)
        progress_file.store_string(JSON.stringify({"sgf":GoSgf.to_sgf(game),"player":scene.player_color,"komi":game.komi}))
        progress_file.close()
        var player: int = scene.player_color
        if require_black and player != GoBoard.BLACK:
            _pipe.close()
            BoardPlayProbe.fail(tree,"Nigiri assigned White; Black acceptance needs another game")
            return
        var analysis := await query(game, -2, 8)
        var point := game.board.from_label(str(analysis.get("best","pass")))
        if target.is_empty():
            if played == 0:
                point = game.board.from_label("C3")
            elif game.board.cells[game.board.from_label("C3")] == player:
                var avoid: Array = []
                for neighbour in game.board.cells.size():
                    var distance := game.board.point(neighbour) - game.board.point(game.board.from_label("C3"))
                    if absi(distance.x)+absi(distance.y) <= 3:
                        avoid.append(game.board.label(neighbour))
                var away_analysis := await query(game,-2,8,avoid)
                point = game.board.from_label(str(away_analysis.get("best","pass")))
                var preferred := game.board.from_label(str(analysis.get("best","pass")))
                var chain := game.board.chain_at(game.board.from_label("C3"))
                if chain["liberties"].size() <= 2 and avoid.has(game.board.label(preferred)):
                    point = preferred
            var abandonment := await find_abandonment(game, player, analysis)
            if not abandonment.is_empty():
                target = abandonment
                point = int(target["actual"])
                await shot.call("two_liberties_before_abandonment")
                print("REV-01 PLAY target: " + JSON.stringify(target))
        else:
            var surviving := false
            for stone in target["stones"]:
                surviving = surviving or game.board.cells[int(stone)] == player
            if not surviving and not bool(target.get("captured",false)):
                target["captured"] = true
                await shot.call("abandoned_group_captured")
            # Deliberately keep playing elsewhere while the named chain remains.
            if surviving and point >= 0:
                for liberty in target["liberties"]:
                    if point == int(liberty):
                        point = elsewhere(game, int(target["anchor"]), point)
                        break
        if played >= 100 or point < 0:
            await ExperienceProbe.press(tree,"go_pass")
        else:
            await BoardPlayProbe.place(tree,point)
        played += 1
        print("REV-01 player move %d: %s" % [played,game.board.label(point) if point >= 0 else "pass"])
        await tree.create_timer(0.1).timeout
    _pipe.close()
    BoardPlayProbe.fail(tree,"Wren abandonment game timed out")


static func find_abandonment(game: GoGame, player: int, before: Dictionary) -> Dictionary:
    var own: Array = before.get("ownership",[])
    if own.is_empty():
        return {}
    var sign_value := 1.0 if player == GoBoard.BLACK else -1.0
    var best := game.board.from_label(str(before.get("best","pass")))
    if best < 0:
        return {}
    for chain in game.board.all_chains():
        if int(chain["color"]) != player or chain["liberties"].size() != 2:
            continue
        var stones: PackedInt32Array = chain["stones"]
        var average := 0.0
        for stone in stones:
            average += float(own[stone]) * sign_value / stones.size()
        if average < 0.3:
            continue
        var away := elsewhere(game,stones[0],best,own)
        if away < 0:
            continue
        var actual := await query(game,away,200)
        print("REV-01 candidate %s: before %.2f; best %s; away %s; pv %s" % [game.board.label(stones[0]),average,game.board.label(best),game.board.label(away),str(actual.get("pv",[]))])
        var line := ReviewContinuation.trace(game.size(),Array(game.board.cells),player,away,actual.get("pv",[]),true)
        var labels: Array = []
        for stone in stones:
            labels.append(game.board.label(stone))
        if ReviewContinuation.captured_at(labels,line) == "":
            continue
        var preferred := await query(game,best,200)
        var input := {"size":game.size(),"cells":Array(game.board.cells),"player":player,"actual":away,"best":best,
            "own_actual":actual.get("ownership",[]),"own_best":preferred.get("ownership",[]),
            "lead_actual":actual.get("score_lead",0),"lead_best":preferred.get("score_lead",0),
            "lead_pass":actual.get("score_lead",0),"pv_after_actual":actual.get("pv",[]),"pv_best":before.get("pv",[])}
        var facts := ReviewFacts.build(ReviewFacts.player_input(input))
        for group in facts.get("group_died",[]):
            if group["anchor"] == game.board.label(stones[0]) and str(group["captured_at"]) != "" and int(group["liberties_before"]) == 2:
                return {"move_number":game.moves.size()+1,"actual":away,"best":best,"anchor":stones[0],
                    "stones":Array(stones),"liberties":Array(chain["liberties"]),"captured":false,"facts":facts}
    return {}


static func elsewhere(game: GoGame, anchor: int, excluded: int, ownership: Array = []) -> int:
    var best := -1
    var distance := -1
    for point in game.board.cells.size():
        if point == excluded or not game.is_legal(point):
            continue
        var delta := game.board.point(point) - game.board.point(anchor)
        var value := absi(delta.x) + absi(delta.y)
        var xy := game.board.point(point)
        var quiet := xy.x > 0 and xy.y > 0 and xy.x < game.size()-1 and xy.y < game.size()-1
        var friendly := 0
        for neighbour in game.board.neighbours(point):
            quiet = quiet and game.board.cells[neighbour] != GoBoard.opponent(game.to_move)
            friendly += 1 if game.board.cells[neighbour] == game.to_move else 0
        if not ownership.is_empty():
            var sign_value := 1.0 if game.to_move == GoBoard.BLACK else -1.0
            quiet = quiet and float(ownership[point])*sign_value > 0.6
        if quiet and friendly > 0 and friendly < 4 and value >= game.size()/2:
            value += 100
        if value > distance:
            best = point
            distance = value
    return best


static func query(game: GoGame, extra: int, visits: int, avoid: Array = []) -> Dictionary:
    var replay := MatchAnalysis.replay(GoSgf.to_sgf(game))
    var query := KataGoAnalysis.query_for(replay,game.komi,"play%d" % _query_id)
    _query_id += 1
    if extra >= -1:
        query["moves"].append(["B" if game.to_move == GoBoard.BLACK else "W", "pass" if extra < 0 else game.board.label(extra)])
    query.merge({"analyzeTurns":[query["moves"].size()],"includeOwnership":true,"maxVisits":visits},true)
    if not avoid.is_empty():
        query["avoidMoves"] = [{"player":"B" if game.to_move == GoBoard.BLACK else "W","moves":avoid,"untilDepth":1}]
    _pipe.write_line(JSON.stringify(query))
    var deadline := Time.get_ticks_msec()+90000
    while Time.get_ticks_msec() < deadline:
        var read: Dictionary = await _pipe.read_line(0.25)
        if not bool(read.get("ready",false)):
            continue
        var parsed := KataGoAnalysis.parse_line(str(read["line"]),game.size())
        if str(parsed.get("id","")) == query["id"]:
            return parsed
    return {}


## Same disposable colour pin as the existing KataGo trial; all Wren strength fields
## come from her shipped resource. The normal world bridge records/reacts/reviews.
static func start_wren(tree: SceneTree) -> void:
    var world := tree.current_scene
    var npc: Npc = world._find_npc("wren")
    var data := npc.data.duplicate(true) as NpcData
    data.opponent_profile = data.opponent_profile.duplicate(true) as OpponentProfile
    data.opponent_profile.colour_rule = "player_black"
    npc.data = data
    world._start_match({"context":"wren_club"},npc)
