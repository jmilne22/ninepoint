## The shipped opponent: a move-scoring policy tuned by OpponentProfile.
##
## It is not strong. It is *legible* -- it captures when it can, saves stones in
## atari, avoids self-atari and its own eyes, prefers the third line early, and
## refuses to fill its own settled territory. Different profiles genuinely play
## differently, and none of them get worse because the human "levelled up".
class_name HeuristicOpponent
extends GoOpponent

const CAPTURE_WEIGHT := 12.0
const SAVE_WEIGHT := 9.0
const ATARI_WEIGHT := 5.0
const CONNECT_WEIGHT := 1.5
const CONTACT_WEIGHT := 1.2
const SELF_ATARI_PENALTY := 20.0
const PASS_THRESHOLD := 2.0

## How wide a weak player's shortlist gets. A 20 kyu does not play a random point
## on the board; they play the fourth-best move, confidently. mistake_rate scales
## the width of the list they choose from, so weakness reads as misjudgement
## rather than as noise -- and a weak opponent stays a person you can learn from.
const MISTAKE_BREADTH := 12.0

## Weight on the stones the opponent could take straight back. Only read at
## reading_depth 2, which until now behaved exactly like 1.
const REPLY_WEIGHT := 9.0

var _rng := RandomNumberGenerator.new()


func setup(p: OpponentProfile, game: GoGame) -> void:
    super.setup(p, game)
    if p != null and p.rng_seed != 0:
        _rng.seed = p.rng_seed
    else:
        _rng.randomize()


func choose_move(game: GoGame) -> Dictionary:
    var color := game.to_move
    var board := game.board
    var candidates := _candidates(game, color)
    if candidates.is_empty():
        return GoOpponent.pass_move()

    if profile != null and profile.resign_threshold > 0.0 and game.move_number() > 12:
        if _area_lead(board, color, game.komi) < -profile.resign_threshold:
            return GoOpponent.resign_move()

    var book := _book_move(game, color, candidates)
    if book >= 0:
        return GoOpponent.point_move(book)

    var ranked: Array = []
    for i in candidates:
        ranked.append({"point": i, "score": _score_move(game, i, color)})
    ranked.sort_custom(func(a, b): return a["score"] > b["score"])

    var chosen: Dictionary = _pick(ranked)
    var best: int = int(chosen["point"])
    var best_score: float = float(chosen["score"])

    # If the opponent has passed and nothing here is worth much, pass back.
    var last := game.last_move()
    if not last.is_empty() and last["point"] == GoGame.PASS and best_score < PASS_THRESHOLD:
        return GoOpponent.pass_move()

    return GoOpponent.point_move(best)


## The corner star points, in order, while the book is still open. Ilse does not
## consider these moves -- she knows them, which is different, and is exactly why
## she comes apart when the position leaves the page.
func _book_move(game: GoGame, color: int, candidates: PackedInt32Array) -> int:
    var moves: int = profile.book_moves if profile != null else 0
    if moves <= 0 or game.move_number() >= moves:
        return -1
    for point in GoGame.handicap_points(game.size(), 4):
        if game.board.is_empty(point) and Array(candidates).has(point):
            return point
    return -1


## Which of the ranked moves actually gets played.
##
## The old version replaced the best move with a uniformly random legal one, which
## is not what a weak player does -- it is what no player does. A 20 kyu chooses
## between moves that all look reasonable to them and picks the wrong one; the
## shortlist is how wide "looks reasonable" is, and mistake_rate sets it.
func _pick(ranked: Array) -> Dictionary:
    if ranked.size() <= 1:
        return ranked[0]
    var mistake: float = profile.mistake_rate if profile != null else 0.0
    if mistake <= 0.0 or _rng.randf() >= mistake:
        return ranked[0]
    var width: int = mini(ranked.size(), 1 + int(round(mistake * MISTAKE_BREADTH)))
    if width <= 1:
        return ranked[0]
    # Anywhere in the shortlist except the top of it -- they have already decided
    # against the best move; this is which of the others they talked themselves into.
    return ranked[_rng.randi_range(1, width - 1)]


# --- candidate generation ----------------------------------------------------

func _candidates(game: GoGame, color: int) -> PackedInt32Array:
    var board := game.board
    var own_territory := _own_small_territory(board, color)
    var out := PackedInt32Array()
    for i in game.legal_moves(color):
        if board.is_eye_like(i, color):
            continue
        if own_territory.has(i):
            continue
        var probe := board.duplicate_board()
        var taken := probe.place(i, color)
        if taken.is_empty() and probe.chain_at(i)["liberties"].size() <= 1:
            continue        # self-atari for nothing
        out.append(i)
    return out


## Empty regions enclosed solely by `color` and small enough to be settled.
func _own_small_territory(board: GoBoard, color: int) -> Dictionary:
    var limit: int = maxi(8, board.cells.size() / 4)
    var out := {}
    for region in GoScoring.empty_regions(board):
        var borders: Dictionary = region["borders"]
        var pts: PackedInt32Array = region["points"]
        if borders.size() == 1 and borders.has(color) and pts.size() <= limit:
            for p in pts:
                out[p] = true
    return out


# --- move scoring ------------------------------------------------------------

func _score_move(game: GoGame, i: int, color: int) -> float:
    var board := game.board
    var enemy := GoBoard.opponent(color)
    var aggr: float = profile.aggression if profile != null else 1.0
    var terr: float = profile.territory_bias if profile != null else 1.0
    var depth: int = profile.reading_depth if profile != null else 0
    var score := 0.0

    var probe := board.duplicate_board()
    var taken := probe.place(i, color)

    # Captures are always worth having.
    score += CAPTURE_WEIGHT * float(taken.size()) * (0.6 + 0.4 * aggr)

    # Rescuing a friendly chain that was in atari.
    for nb in board.neighbours(i):
        if board.get_idx(nb) == color:
            var ch := board.chain_at(nb)
            if ch["liberties"].size() == 1:
                var after := probe.chain_at(i)
                if after["liberties"].size() >= 2:
                    score += SAVE_WEIGHT * float(ch["stones"].size())

    # Putting an enemy chain in atari.
    var seen := {}
    for nb in probe.neighbours(i):
        if probe.get_idx(nb) != enemy or seen.has(nb):
            continue
        var ech := probe.chain_at(nb)
        for s in ech["stones"]:
            seen[s] = true
        if ech["liberties"].size() == 1:
            score += ATARI_WEIGHT * float(ech["stones"].size()) * aggr

    # Chasing something that can still get away. A ladder is exactly this move,
    # played by somebody who has not read it to the end.
    var ladder: float = profile.ladder_happy if profile != null else 0.0
    if ladder > 0.0:
        for nb in probe.neighbours(i):
            if probe.get_idx(nb) != enemy:
                continue
            var chased := probe.chain_at(nb)
            if chased["liberties"].size() != 1:
                continue
            for liberty in chased["liberties"]:
                var escape := probe.duplicate_board()
                if escape.is_suicide(liberty, enemy):
                    continue
                escape.place(liberty, enemy)
                if escape.chain_at(liberty)["liberties"].size() >= 2:
                    score += ATARI_WEIGHT * ladder      # it can run, and off we go
                break

    # The point that separates two enemy groups. Cutting and connecting are the
    # same point, so this is also what makes them defend their own thin shapes.
    var cut: float = profile.cut_bias if profile != null else 0.0
    if cut > 0.0:
        var groups := {}
        for nb in board.neighbours(i):
            if board.get_idx(nb) != enemy:
                continue
            var stones: PackedInt32Array = board.chain_at(nb)["stones"]
            groups[stones[0]] = true
        if groups.size() >= 2:
            score += CONTACT_WEIGHT * 4.0 * cut * float(groups.size() - 1)

    # Shape: stay connected, stay in contact.
    var friends := 0
    var foes := 0
    for nb in board.neighbours(i):
        match board.get_idx(nb):
            GoBoard.EMPTY: pass
            _:
                if board.get_idx(nb) == color: friends += 1
                else: foes += 1
    score += CONNECT_WEIGHT * float(friends)
    score += CONTACT_WEIGHT * float(foes) * aggr

    # Position: the third line is worth more than the first.
    score += _line_value(board, i) * terr

    # One ply of safety: do not leave the new chain short of liberties.
    if depth >= 1:
        var my_chain := probe.chain_at(i)
        var libs: int = my_chain["liberties"].size()
        if libs == 1 and taken.is_empty():
            score -= SELF_ATARI_PENALTY
        elif libs == 2 and my_chain["stones"].size() >= 3:
            score -= 3.0

    # Two plies: what can they take straight back? Until now reading_depth 2 was
    # read by nothing, so the 5 dan and the 9 kyu played an identical policy and
    # differed only in how often they blundered.
    if depth >= 2:
        score -= REPLY_WEIGHT * float(_worst_reply(probe, i, color))

    score += _rng.randf() * 0.75
    return score


## The most stones the opponent could capture immediately after this move.
##
## Only the liberties of chains that the move actually touches are examined -- a
## full reply search is not affordable per candidate, and a move that endangers a
## group somewhere else on the board was not going to be found by this AI anyway.
func _worst_reply(after: GoBoard, played: int, color: int) -> int:
    var enemy := GoBoard.opponent(color)
    var at_risk := {}
    for point in [played] + Array(after.neighbours(played)):
        if after.get_idx(point) != color:
            continue
        var chain := after.chain_at(point)
        if chain["liberties"].size() != 1:
            continue
        for liberty in chain["liberties"]:
            at_risk[liberty] = true
    var worst := 0
    for liberty in at_risk:
        var probe := after.duplicate_board()
        if probe.is_suicide(liberty, enemy):
            continue
        var taken := probe.place(liberty, enemy)
        worst = maxi(worst, taken.size())
    return worst


func _line_value(board: GoBoard, i: int) -> float:
    var p := board.point(i)
    var n := board.size
    var d: int = mini(mini(p.x, p.y), mini(n - 1 - p.x, n - 1 - p.y))
    match d:
        0: return -4.0
        1: return 1.0
        2: return 4.0
        3: return 3.0
        _: return 2.0


## Crude area balance from `color`'s point of view, used only for resignation.
func _area_lead(board: GoBoard, color: int, komi: float) -> float:
    var s := GoScoring.score(board, {}, {GoBoard.BLACK: 0, GoBoard.WHITE: 0}, komi, GoScoring.Rule.CHINESE)
    var mine: float = s["black"] if color == GoBoard.BLACK else s["white"]
    var theirs: float = s["white"] if color == GoBoard.BLACK else s["black"]
    return mine - theirs
