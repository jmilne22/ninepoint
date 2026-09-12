extends SceneTree
func _initialize() -> void:
    var game := GoGame.new(7, 0.5, 0)
    game.capture_goal = 1
    game.pass_turn()
    game.pass_turn()
    print('CAPTURE_PROBE ', JSON.stringify({'capture_goal': game.capture_goal, 'captures': game.captures, 'state': game.state, 'scoring_state': GoGame.State.SCORING}))
    var s := GoScoring.score(game.board, {}, game.captures, game.komi)
    game.finish_with_score(s)
    print('CAPTURE_SCORE ', JSON.stringify(game.result))
    quit()
