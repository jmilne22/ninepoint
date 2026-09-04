## Turns an OpponentProfile into a live opponent, with a safe fallback.
class_name OpponentFactory
extends RefCounted


static func create(profile: OpponentProfile, game: GoGame, warmed: GtpOpponent = null) -> GoOpponent:
    var opponent: GoOpponent
    match profile.engine:
        "random":
            opponent = RandomOpponent.new()
        "gtp":
            if warmed != null:
                opponent = warmed
            else:
                var gtp := GtpOpponent.new()
                gtp.profile = profile
                if gtp.is_available():
                    opponent = gtp
                else:
                    push_warning("Falling back to the heuristic opponent for '%s'." % profile.id)
                    opponent = HeuristicOpponent.new()
        _:
            opponent = HeuristicOpponent.new()
    opponent.setup(profile, game)
    return opponent


## Builds the game a profile describes (size, komi, handicap, who is black).
static func new_game_for(profile: OpponentProfile) -> GoGame:
    var komi: float = profile.komi
    var game := GoGame.new(profile.board_size, komi, profile.handicap)
    return game
