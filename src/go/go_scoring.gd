## Scoring: empty regions, territory, area, prisoners, and a dead-stone estimate.
##
## Japanese (territory + prisoners) and Chinese (area) rules are both provided.
## Dead stones are supplied by the caller -- estimate_dead() only proposes them,
## the player confirms. See ARCHITECTURE.md section 11 for why.
class_name GoScoring
extends RefCounted

enum Rule { JAPANESE, CHINESE }

## An empty region and the stone colours that touch it.
## {points: PackedInt32Array, borders: {color: true}}
static func empty_regions(board: GoBoard) -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    var seen := {}
    for start in board.cells.size():
        if not board.is_empty(start) or seen.has(start):
            continue
        var pts := PackedInt32Array()
        var borders := {}
        var stack := [start]
        seen[start] = true
        while not stack.is_empty():
            var cur: int = stack.pop_back()
            pts.append(cur)
            for nb in board.neighbours(cur):
                var c := board.get_idx(nb)
                if c == GoBoard.EMPTY:
                    if not seen.has(nb):
                        seen[nb] = true
                        stack.append(nb)
                else:
                    borders[c] = true
        out.append({"points": pts, "borders": borders})
    return out


## Board with the given dead stones lifted off, as scoring requires.
static func board_without_dead(board: GoBoard, dead: Dictionary) -> GoBoard:
    var b := board.duplicate_board()
    for i in dead.keys():
        if dead[i]:
            b.set_idx(int(i), GoBoard.EMPTY)
    return b


## territory[i] = BLACK / WHITE / EMPTY, computed on a board with dead stones removed.
static func territory_map(board: GoBoard) -> PackedByteArray:
    var t := PackedByteArray()
    t.resize(board.cells.size())
    for region in empty_regions(board):
        var borders: Dictionary = region["borders"]
        if borders.size() == 1:
            var owner: int = borders.keys()[0]
            for p in region["points"]:
                t[p] = owner
    return t


## Full scoring pass. `captures` is the in-game prisoner count per colour.
## Returns a dictionary shared by both rule sets:
##   black, white (float scores), winner, margin, text, territory (PackedByteArray),
##   detail {black_territory, white_territory, black_stones, white_stones,
##           black_prisoners, white_prisoners}
static func score(
    board: GoBoard,
    dead: Dictionary,
    captures: Dictionary,
    komi: float,
    rule: int = Rule.JAPANESE
) -> Dictionary:
    var live := board_without_dead(board, dead)
    var terr := territory_map(live)

    var bt := 0
    var wt := 0
    for i in terr.size():
        if terr[i] == GoBoard.BLACK: bt += 1
        elif terr[i] == GoBoard.WHITE: wt += 1

    # Dead stones become prisoners for the opponent under Japanese rules.
    var dead_black := 0
    var dead_white := 0
    for i in dead.keys():
        if not dead[i]:
            continue
        if board.get_idx(int(i)) == GoBoard.BLACK: dead_black += 1
        elif board.get_idx(int(i)) == GoBoard.WHITE: dead_white += 1

    var bs := live.count_color(GoBoard.BLACK)
    var ws := live.count_color(GoBoard.WHITE)
    var b_pris: int = int(captures.get(GoBoard.BLACK, 0)) + dead_white
    var w_pris: int = int(captures.get(GoBoard.WHITE, 0)) + dead_black

    var black_score := 0.0
    var white_score := 0.0
    if rule == Rule.JAPANESE:
        black_score = float(bt + b_pris)
        white_score = float(wt + w_pris) + komi
    else:
        black_score = float(bt + bs)
        white_score = float(wt + ws) + komi

    var margin: float = absf(black_score - white_score)
    var winner := GoBoard.EMPTY
    if black_score > white_score: winner = GoBoard.BLACK
    elif white_score > black_score: winner = GoBoard.WHITE

    var text := "Draw (jigo)"
    if winner != GoBoard.EMPTY:
        text = "%s wins by %s" % [GoBoard.color_name(winner), _fmt(margin)]

    return {
        "black": black_score,
        "white": white_score,
        "winner": winner,
        "margin": margin,
        "by_resignation": false,
        "text": text,
        "rule": "japanese" if rule == Rule.JAPANESE else "chinese",
        "territory": terr,
        "detail": {
            "black_territory": bt, "white_territory": wt,
            "black_stones": bs, "white_stones": ws,
            "black_prisoners": b_pris, "white_prisoners": w_pris,
            "komi": komi,
        },
    }


static func _fmt(v: float) -> String:
    return "%.1f" % v if absf(v - roundf(v)) > 0.01 else str(int(v))


## Proposes dead stones for the scoring phase.
##
## A chain is judged dead when it has fewer than two eyes in the region it can
## reach (own colour plus empty points, walled off by enemy stones) *and* that
## region is either cramped or the chain is badly outnumbered by its besiegers.
## This is a heuristic for beginner-level 9x9 games; the player may override every
## call, and a GTP engine would answer this far better via `final_status_list dead`.
static func estimate_dead(board: GoBoard) -> Dictionary:
    const SMALL_REGION := 8
    var dead := {}
    for chain in board.all_chains():
        var color: int = chain["color"]
        var reach := _reachable_region(board, chain["stones"], color)
        var empties: PackedInt32Array = reach["empty"]
        var own: int = reach["stones"].size()
        var enemies: int = reach["enemy"].size()

        var eyes := 0
        for e in empties:
            if board.is_eye_like(e, color):
                eyes += 1
        if eyes >= 2:
            continue                                   # two eyes: unconditionally alive
        var cramped: bool = empties.size() < SMALL_REGION
        var outnumbered: bool = own * 2 <= enemies     # surrounded and badly outnumbered
        if cramped or outnumbered:
            for s in chain["stones"]:
                dead[s] = true
    return dead


## Flood fill from a chain across friendly stones and empty points, stopping at
## enemy stones. Returns {empty: PackedInt32Array, stones: PackedInt32Array}.
static func _reachable_region(board: GoBoard, seed_stones: PackedInt32Array, color: int) -> Dictionary:
    var seen := {}
    var stack := []
    var empties := PackedInt32Array()
    var stones := PackedInt32Array()
    var enemy := {}
    for s in seed_stones:
        seen[s] = true
        stack.append(s)
        stones.append(s)
    while not stack.is_empty():
        var cur: int = stack.pop_back()
        for nb in board.neighbours(cur):
            if seen.has(nb):
                continue
            var c := board.get_idx(nb)
            if c == GoBoard.EMPTY:
                seen[nb] = true
                empties.append(nb)
                stack.append(nb)
            elif c == color:
                seen[nb] = true
                stones.append(nb)
                stack.append(nb)
            else:
                enemy[nb] = true
    return {"empty": empties, "stones": stones, "enemy": enemy.keys()}
