## Data-driven description of one opponent at the board.
##
## Everything the Go side needs to know about who it is playing, and nothing
## about who they are in the town. Swapping `engine` to "gtp" is the whole of
## the work needed to put KataGo behind an NPC.
class_name OpponentProfile
extends Resource

## What a rank looks like when its owner will not state it. Joos at the arches
## has never had one written down; the label is withheld, not invented.
const RANK_WITHHELD := "?"

@export var id: StringName = &""
@export var display_name: String = "Opponent"
## Realistic rank label, e.g. "12k", "4k", "1d". Never "easy"/"hard".
## RANK_WITHHELD is the one exception: a player with no card and no papers.
@export var rank_label: String = "20k"

## A withheld rank is still a real strength -- GoMatchSetup cannot work out a
## handicap from a question mark. -1 means "derive it from rank_label", which is
## what everybody with a card does.
@export var strength_override: int = -1

@export_enum("heuristic", "random", "gtp") var engine: String = "heuristic"

@export var board_size: int = 9
@export var komi: float = 5.5
## Only used when colour_rule pins the game; "by_rank" works the handicap out.
@export var handicap: int = 0

## How the colours are decided. "by_rank" is the honest default: a handicap if
## the ranks warrant one, nigiri if they do not. See GoMatchSetup.
@export_enum("by_rank", "nigiri", "player_black", "player_white")
var colour_rule: String = "by_rank"

## Capture Go: first to take this many stones wins, and scoring never happens.
## 0 is a normal game. Used by the tutorial -- see GAME_DESIGN.md.
@export var capture_goal: int = 0

@export_group("Heuristic strength")
## Probability of ignoring the best move and playing a random legal one.
@export_range(0.0, 1.0, 0.01) var mistake_rate: float = 0.25
## 0 = immediate liberties only, 1 = checks the opponent's reply.
@export_range(0, 2) var reading_depth: int = 0
## Weight on contact fighting and cutting versus quiet territorial play.
@export_range(0.0, 2.0, 0.05) var aggression: float = 1.0
@export_range(0.0, 2.0, 0.05) var territory_bias: float = 1.0
## Points behind (by a crude area estimate) before the opponent resigns. 0 = never.
@export var resign_threshold: float = 0.0

@export_group("Style")
## How much this player likes chasing a stone that can still run. Pillar 3 says
## every opponent is a person first, and Pip's whole character is attempting
## ladders that do not work -- which nothing at the board made him do.
@export_range(0.0, 2.0, 0.05) var ladder_happy: float = 0.0
## How much they want the point that separates two enemy groups. Kesh cuts; the
## dialogue has always said so and the board never did.
@export_range(0.0, 2.0, 0.05) var cut_bias: float = 0.0
## Moves spent playing the corners by the book before thinking for themselves.
## Ilse has read four books on the opening and is nine kyu.
@export var book_moves: int = 0
## Fixed seed keeps a given opponent's play reproducible in tests. 0 = random.
@export var rng_seed: int = 0

@export_group("GTP engine")
@export var gtp_command: String = ""
@export var gtp_args: PackedStringArray = PackedStringArray()
@export var gtp_time_per_move: float = 1.0

@export_group("Flavour")
## Which track plays while you are sitting across from them. "" means the game
## decides from the occasion instead -- see MatchMusic.theme_for(), which falls
## back to the upbeat theme for a rated game and to the quiet bed for a free one.
##
## It lives on the profile rather than in a table keyed by character because the
## profile is what distinguishes hana_teaching from hana_9x9: a teaching game is
## not a fight and must not sound like one, and a table keyed by "hana" could
## not say so.
@export var theme: String = ""

## What this opponent says when they give up. Everything else they say at the
## board lives in data/banter/<id>.json -- two lines per character, chosen on
## who was ahead, was not enough for anybody to sound like a person.
@export_multiline var on_resign: String = ""


func strength() -> int:
    return strength_override if strength_override >= 0 else GoRank.from_string(rank_label)


func setup_rule() -> int:
    match colour_rule:
        "nigiri": return GoMatchSetup.Rule.NIGIRI
        "player_black": return GoMatchSetup.Rule.PLAYER_BLACK
        "player_white": return GoMatchSetup.Rule.PLAYER_WHITE
        _: return GoMatchSetup.Rule.BY_RANK
