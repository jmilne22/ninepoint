## Everything the world tells the Go layer when a game is about to start.
class_name MatchRequest
extends RefCounted

var profile: OpponentProfile
## Identifies this particular encounter so dialogue and quests can react to it.
var context_id: String = ""
var npc_id: String = ""
var opponent_name: String = "Opponent"
var opponent_rank: String = "?"
var portrait_path: String = ""
## Shown on the pre-match card.
var intro_line: String = ""
var unrated: bool = false
var allow_undo: bool = false
## How strong the human is right now, so the setup can work out the handicap.
var player_strength: int = -1
## Set by the match scene once colours are settled; carried back for dialogue.
var setup: GoMatchSetup = null
