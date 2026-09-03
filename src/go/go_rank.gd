## Kyu/dan ranks as a first-class domain type.
##
## Internally a rank is a single integer "strength" value:
##   30k = 0, 20k = 10, 1k = 29, 1d = 30, 5d = 34.
## The gap between two ranks in strength points is the conventional handicap.
class_name GoRank
extends RefCounted

const KYU_ZERO := 30      ## 30 kyu is strength 0
const MAX_STRENGTH := 39  ## 10 dan


static func from_string(s: String) -> int:
    var text := s.strip_edges().to_lower()
    if text == "" or text == "unranked" or text == "-":
        return -1
    var num := int(text.substr(0, text.length() - 1))
    if text.ends_with("k"):
        return KYU_ZERO - num
    if text.ends_with("d"):
        return KYU_ZERO + num - 1
    return -1


static func to_string_rank(strength: int) -> String:
    if strength < 0:
        return "unranked"
    if strength < KYU_ZERO:
        return "%dk" % (KYU_ZERO - strength)
    return "%dd" % (strength - KYU_ZERO + 1)


## How many ranks one handicap stone is worth on a board of this size.
##
## One stone per rank is the 19x19 convention and it does not travel. A 9x9 board
## is a quarter of the area, so a stone on it is worth roughly three ranks -- nine
## stones on a small board is not a teaching game, it is a board with no room left
## on it, which is what the Institute's league produced before this existed.
static func ranks_per_stone(board_size: int) -> int:
    if board_size <= 9:
        return 3
    if board_size <= 13:
        return 2
    return 1


## The most stones a board will carry: its star points, and no more. A 9x9 has
## five of them -- four corners and tengen -- and that is the honest ceiling.
static func max_handicap(board_size: int) -> int:
    return 5 if board_size <= 9 else 9


## Conventional handicap for the weaker player, and who takes black.
## Returns {stones: int, black: "player"|"opponent", komi: float}
static func handicap_between(player_strength: int, opponent_strength: int,
        board_size: int = 19) -> Dictionary:
    if player_strength < 0:
        player_strength = 0
    var diff: int = opponent_strength - player_strength
    var weaker_is_player := diff > 0
    var stones := int(roundf(float(absi(diff)) / float(ranks_per_stone(board_size))))
    if stones <= 1:
        return {
            "stones": 0,
            "black": "player" if weaker_is_player else "opponent",
            # A gap too small for a stone is still a gap: the weaker player takes
            # Black and the komi goes with it.
            "komi": 5.5 if absi(diff) == 0 else 0.5,
        }
    stones = mini(stones, max_handicap(board_size))
    return {
        "stones": stones,
        "black": "player" if weaker_is_player else "opponent",
        "komi": 0.5,
    }


static func is_stronger(a: int, b: int) -> bool:
    return a > b


## A short human phrase for a rank gap, used in dialogue and match previews.
static func describe_gap(player_strength: int, opponent_strength: int) -> String:
    var d: int = opponent_strength - player_strength
    if d >= 8: return "far beyond you"
    if d >= 4: return "much stronger than you"
    if d >= 2: return "stronger than you"
    if d >= 1: return "a little stronger than you"
    if d == 0: return "about your strength"
    if d >= -2: return "a little weaker than you"
    return "weaker than you"
