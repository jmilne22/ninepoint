## An openly simple practice partner: nearby moves and immediate captures.
## No territory estimate, ranked-engine impersonation, or hidden adaptive strength.
class_name CaptureOpponent
extends GoOpponent

var rng := RandomNumberGenerator.new()


func setup(value: OpponentProfile, game: GoGame) -> void:
    super.setup(value, game)
    if value.rng_seed != 0:
        rng.seed = value.rng_seed
    else:
        rng.randomize()


func choose_move(game: GoGame) -> Dictionary:
    # Passing offers a neutral end to this practice, even if a capture is available.
    if game.state != GoGame.State.PLAYING or game.consecutive_passes > 0:
        return pass_move()
    var legal := game.legal_moves()
    if legal.is_empty():
        return pass_move()
    var nearby := PackedInt32Array()
    for point in legal:
        var board := game.board.duplicate_board()
        if not board.place(point, game.to_move).is_empty():
            return point_move(point)
        for neighbor in game.board.neighbours(point):
            if game.board.get_idx(neighbor) == GoBoard.opponent(game.to_move):
                nearby.append(point)
                break
    # Keeping legal self-atari candidates is deliberate: this partner sees one
    # move, so learners can create and notice threats without outreading a solver.
    var choices := nearby if not nearby.is_empty() else legal
    return point_move(choices[rng.randi_range(0, choices.size() - 1)])
