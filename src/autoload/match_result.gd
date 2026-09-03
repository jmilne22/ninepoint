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
## How many of those stones were the player's. GoRating needs to know which side
## was being given the help before it can say what the game was worth.
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
## What the review found in the game, from GoReview. Board positions and all,
## which is why it is deliberately absent from to_dict(): this is for the screen
## that runs next, not for the save file.
var findings: Array = []
## The final position, so the review has a board to open and close on.
var final_cells: PackedByteArray = PackedByteArray()
## The game's own move list, for the replay the review screen offers. Like
## `findings` this is screen payload and deliberately absent from to_dict():
## `sgf` above is the form the record keeps, and re-deriving from that is the
## intended path for reviewing a game after the fact.
var moves: Array = []

## A compact record of what the review found, small enough to keep in the save.
## `findings` above carries board positions and is for the screen that runs next;
## this is what survives into match_records, so a later game can say "that is the
## third time running" and point at the lesson that covers it.
## {"kinds": {<detector kind>: <count>}, "worst": String,
##  "swing_move": int, "lead_at_end": float}
var review_summary: Dictionary = {}


func to_dict() -> Dictionary:
    return {
        "context_id": context_id, "npc_id": npc_id, "player_won": player_won,
        "margin": margin, "by_resignation": by_resignation, "board_size": board_size,
        "handicap": handicap, "handicap_taken": handicap_taken,
        "komi": komi, "move_count": move_count,
        "unrated": unrated, "opponent_strength": opponent_strength,
        "summary": summary, "review_summary": review_summary,
        # The game record was written at go_match.gd and then dropped here,
        # which is the one place it needed to survive. A kifu is what a review
        # is made of; a game with no record can never be looked at again.
        "sgf": sgf,
    }
