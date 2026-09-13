## Shared result construction, independent of the destination's record store.
class_name MatchCompletion
extends RefCounted

static func result(scene: Control) -> MatchResult:
    var res := MatchResult.new()
    res.context_id = scene.request.context_id
    res.league_division = scene.request.league_division
    res.league_attempt = scene.request.league_attempt
    res.league_fixture = scene.request.league_fixture
    res.npc_id = scene.request.npc_id
    res.player_color = scene.player_color
    res.winner = int(scene.game.result.get("winner", GoBoard.EMPTY))
    res.player_won = res.winner == scene.player_color
    res.margin = float(scene.game.result.get("margin", 0.0))
    res.by_resignation = bool(scene.game.result.get("by_resignation", false))
    res.by_capture = bool(scene.game.result.get("by_capture", false))
    res.capture_goal = scene.game.capture_goal
    res.practice_ended = bool(scene.game.result.get("practice_ended", false))
    res.capture_review = CaptureGuide.final_capture(scene.game)
    res.board_size = scene.game.size()
    res.handicap = scene.game.handicap
    # In a handicap game the stones belong to whoever is Black. Which side that
    # was is the difference between beating a 1 dan and being given five stones
    # by one, and the rank ladder cannot tell them apart afterwards without this.
    res.handicap_taken = scene.game.handicap if scene.player_color == GoBoard.BLACK else 0
    res.komi = scene.game.komi
    res.move_count = scene.game.move_number()
    res.unrated = scene.request.unrated or scene.game.capture_goal > 0
    res.opponent_name = scene.request.opponent_name
    res.opponent_strength = scene.request.profile.strength() if scene.request.profile != null else -1
    res.sgf = GoSgf.to_sgf(scene.game, {
        "PB": scene.context.player_name if scene.player_color == GoBoard.BLACK else scene.request.opponent_name,
        "PW": scene.request.opponent_name if scene.player_color == GoBoard.BLACK else scene.context.player_name,
        "RE": str(scene.game.result.get("text", "")),
    })
    res.summary = str(scene.game.result.get("text", ""))

    return res
