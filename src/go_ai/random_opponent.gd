## The floor of the ladder: any legal move that is not one of its own eyes.
class_name RandomOpponent
extends GoOpponent

var _rng := RandomNumberGenerator.new()


func setup(p: OpponentProfile, game: GoGame) -> void:
    super.setup(p, game)
    if p != null and p.rng_seed != 0:
        _rng.seed = p.rng_seed
    else:
        _rng.randomize()


func choose_move(game: GoGame) -> Dictionary:
    var color := game.to_move
    var candidates := PackedInt32Array()
    for i in game.legal_moves(color):
        if not game.board.is_eye_like(i, color):
            candidates.append(i)
    if candidates.is_empty():
        return GoOpponent.pass_move()
    return GoOpponent.point_move(candidates[_rng.randi_range(0, candidates.size() - 1)])
