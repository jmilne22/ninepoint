## The one interface every Go opponent implements.
##
## `choose_move` may await, so a subprocess engine (KataGo over GTP) and the
## in-process heuristic both fit without the RPG knowing which is which.
class_name GoOpponent
extends RefCounted

var profile: OpponentProfile


func setup(p: OpponentProfile, _game: GoGame) -> void:
    profile = p


## Returns {"type": "move"|"pass"|"resign", "point": int}.
func choose_move(_game: GoGame) -> Dictionary:
    return {"type": "pass", "point": GoGame.PASS}


## Called when the human proposes a set of dead stones at the end of the game.
func should_accept_dead_marks(_game: GoGame, _dead: Dictionary) -> bool:
    return true


func shutdown() -> void:
    pass


static func pass_move() -> Dictionary:
    return {"type": "pass", "point": GoGame.PASS}


static func resign_move() -> Dictionary:
    return {"type": "resign", "point": GoGame.RESIGN}


static func point_move(i: int) -> Dictionary:
    return {"type": "move", "point": i}
