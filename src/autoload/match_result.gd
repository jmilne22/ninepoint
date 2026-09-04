## Everything the Go layer tells the world when a game ends.
## This is the *only* thing the RPG learns from a match.
class_name MatchResult
extends RefCounted

var context_id: String = ""
var npc_id: String = ""
var player_won: bool = false
var winner: int = GoBoard.EMPTY
var player_color: int = GoBoard.BLACK
var margin: float = 0.0
var by_resignation: bool = false
var board_size: int = 9
var handicap: int = 0
## How many of those stones were the player's, so the game can be priced from
## the player's side.
var handicap_taken: int = 0
var komi: float = 5.5
var move_count: int = 0
var unrated: bool = false
## The opponent's strength on the GoRank scale, recorded at the time. Ranks in the
## cast could be edited later; what this game was worth cannot.
var opponent_strength: int = -1
var sgf: String = ""
var summary: String = ""
## True when the game was decided by a capture goal rather than by counting.
var by_capture: bool = false

func to_dict() -> Dictionary:
    return {
        "context_id": context_id, "npc_id": npc_id, "player_won": player_won,
        "margin": margin, "by_resignation": by_resignation, "board_size": board_size,
        "handicap": handicap, "handicap_taken": handicap_taken,
        "komi": komi, "move_count": move_count,
        "unrated": unrated, "opponent_strength": opponent_strength,
        "summary": summary,
        "sgf": sgf,
    }
