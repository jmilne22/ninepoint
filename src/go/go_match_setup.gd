## Who takes Black, how many stones, and how much komi -- decided the way Go
## actually decides it.
##
## In an even game colours come from *nigiri*: one player grabs a handful of
## stones and the other guesses odd or even. In a handicap game there is no
## nigiri at all -- the weaker player simply takes Black, with 0.5 komi. Pure
## logic, no UI: the match scene performs the ceremony this class describes.
class_name GoMatchSetup
extends RefCounted

## How the colours are decided.
enum Rule {
    BY_RANK,        ## handicap if the ranks warrant one, otherwise nigiri
    NIGIRI,         ## an even game whatever the ranks say, colours by nigiri
    PLAYER_BLACK,   ## fixed, for scripted story matches
    PLAYER_WHITE,
}

const MAX_GRAB := 20

var rule: int = Rule.BY_RANK
var board_size: int = 9
var handicap: int = 0
var komi: float = 5.5
var player_color: int = GoBoard.BLACK

## Nigiri detail, for the ceremony and for the explanation afterwards.
var uses_nigiri: bool = false
var grabbed: int = 0
var guessed_odd: bool = false
var guessed_right: bool = false
## Set once the ceremony has actually been performed.
var resolved: bool = false

## One sentence saying why the colours ended up this way. This is a teaching
## game; the player should never wonder how they became White.
var explanation: String = ""


func opponent_color() -> int:
    return GoBoard.opponent(player_color)


func is_handicap() -> bool:
    return handicap >= 2


## Works out the shape of the game without performing nigiri yet -- the match
## scene needs to know whether to run the ceremony before it can run it.
static func prepare(
    setup_rule: int,
    player_strength: int,
    opponent_strength: int,
    size: int,
    even_komi: float = 5.5
) -> GoMatchSetup:
    var s := GoMatchSetup.new()
    s.rule = setup_rule
    s.board_size = size
    s.komi = even_komi
    s.handicap = 0

    match setup_rule:
        Rule.PLAYER_BLACK:
            s.player_color = GoBoard.BLACK
            s.resolved = true
            s.explanation = "You take Black and move first."
        Rule.PLAYER_WHITE:
            s.player_color = GoBoard.WHITE
            s.resolved = true
            s.explanation = "You take White, and the %s points of komi that come with it." % _fmt(s.komi)
        Rule.NIGIRI:
            s.uses_nigiri = true
        _:
            if player_strength < 0:
                s.uses_nigiri = true
                return s
            var gap := GoRank.handicap_between(player_strength, opponent_strength, size)
            if int(gap["stones"]) >= 2:
                s.handicap = int(gap["stones"])
                s.komi = float(gap["komi"])
                s.player_color = GoBoard.BLACK if str(gap["black"]) == "player" else GoBoard.WHITE
                s.resolved = true
                var who := "You" if s.player_color == GoBoard.BLACK else "Your opponent"
                s.explanation = ("%s take Black and start with %d handicap stones already placed, "
                    + "because of the gap in rank. Komi drops to %s.") % [
                        who, s.handicap, _fmt(s.komi)]
            else:
                s.uses_nigiri = true
    return s


## Performs the ceremony. `guess_odd` is the human's call; `rng` is injected so
## a test can pin the grab.
func run_nigiri(guess_odd: bool, rng: RandomNumberGenerator, player_choice: int = GoBoard.BLACK) -> void:
    if not uses_nigiri:
        return
    grabbed = rng.randi_range(1, MAX_GRAB)
    guessed_odd = guess_odd
    var is_odd := grabbed % 2 == 1
    guessed_right = is_odd == guess_odd

    if guessed_right:
        player_color = player_choice
        explanation = ("Your opponent grabbed %d stones -- %s, so you guessed right and "
            + "took your pick of colours.") % [grabbed, "odd" if is_odd else "even"]
    else:
        # The winner of nigiri takes Black: moving first is worth having.
        player_color = GoBoard.WHITE
        explanation = ("Your opponent grabbed %d stones -- %s, so your guess was wrong. "
            + "They take Black and the first move; you get %s points of komi for it.") % [
                grabbed, "odd" if is_odd else "even", _fmt(komi)]
    resolved = true


## The line shown while the opponent is holding the stones.
func nigiri_prompt(opponent_name: String) -> String:
    return "%s takes a handful of stones. Odd or even?" % opponent_name


static func _fmt(v: float) -> String:
    return "%.1f" % v if absf(v - roundf(v)) > 0.01 else str(int(v))
