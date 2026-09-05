## Compact, save-safe payload for an optional whole-game review.
## KataGoAnalysis produces the per-turn numbers; everything here is pure, so old
## saves, a missing binary and the unit suite all work without an engine.
##
## A finding is one board and one sentence's worth of claim: the position before
## a move, the move played, the move the engine preferred, and what it cost.
## Three at most: the biggest loss, a second loss about a different idea, and,
## when the engine agreed with the player at a moment that mattered, one
## strength. A quiet game is an honest "steady" and never three invented cards.
class_name MatchAnalysis
extends RefCounted

const FINDING_KINDS := ["strength", "mistake", "lesson"]
## Below this many points a difference is noise at eight visits, not a lesson.
const MEANINGFUL_LOSS := 0.75
const MIN_SIZE := 7
const MAX_SIZE := 19


static func pending(record_index: int) -> Dictionary:
    return {"source_match": record_index, "availability": "pending",
        "positions": [], "findings": []}


static func eligible(record: Dictionary) -> bool:
    var size := int(record.get("board_size", 9))
    return not bool(record.get("by_capture", false)) \
        and not bool(record.get("incomplete", false)) \
        and size >= MIN_SIZE and size <= MAX_SIZE \
        and str(record.get("sgf", "")) != ""


static func unavailable(record_index: int, reason: String, engine_version: String = "") -> Dictionary:
    return {
        "source_match": record_index, "availability": "failed", "reason": reason,
        "engine_version": engine_version, "positions": [], "findings": [],
    }


## Validates and seals a payload. `meta` carries partial-coverage facts
## (`partial`, `analysed_moves`, `total_moves`) so a card can say how much of
## the game it saw. Anything malformed becomes "failed" rather than a wrong card.
static func available(record_index: int, engine_version: String, positions: Array,
        findings: Array, meta: Dictionary = {}) -> Dictionary:
    var partial := bool(meta.get("partial", false))
    if findings.is_empty():
        var summary := "A steady game. No single move gave much away."
        if partial:
            summary = "The first %d moves were looked at. None of them gave much away." % int(meta.get("analysed_moves", 0))
        return _with_meta({"source_match": record_index, "availability": "steady",
            "engine_version": engine_version, "positions": [], "findings": [],
            "summary": summary}, meta)
    if findings.size() > 3:
        return unavailable(record_index, "Analysis produced too many moments.", engine_version)
    var seen_moves := {}
    for finding_value in findings:
        if not (finding_value is Dictionary):
            return unavailable(record_index, "Analysis findings were incomplete.", engine_version)
        var finding: Dictionary = finding_value
        var kind := str(finding.get("kind", ""))
        if not FINDING_KINDS.has(kind):
            return unavailable(record_index, "Analysis finding had an unknown kind.", engine_version)
        var move_number := int(finding.get("move_number", 0))
        var size := int(finding.get("size", 0))
        var actual := int(finding.get("actual", -1))
        var best := int(finding.get("best", -1))
        var shape_ok: bool = move_number > 0 and not seen_moves.has(move_number) \
            and size >= 2 and size <= MAX_SIZE and finding.get("cells", []).size() == size * size \
            and actual >= 0 and actual < size * size
        var claim_ok := false
        if kind == "strength":
            claim_ok = best == actual and float(finding.get("stake", 0.0)) >= MEANINGFUL_LOSS
        else:
            claim_ok = best >= 0 and best < size * size and best != actual \
                and float(finding.get("point_loss", 0.0)) >= MEANINGFUL_LOSS
        if not shape_ok or not claim_ok:
            return unavailable(record_index, "Analysis findings were invalid.", engine_version)
        seen_moves[move_number] = true
    return _with_meta({"source_match": record_index, "availability": "available",
        "engine_version": engine_version, "positions": positions.duplicate(true),
        "findings": findings.duplicate(true)}, meta)


static func _with_meta(payload: Dictionary, meta: Dictionary) -> Dictionary:
    for key in ["partial", "analysed_moves", "total_moves"]:
        if meta.has(key):
            payload[key] = meta[key]
    return payload


## SGF emitted by GoSgf is deliberately small. Replaying that subset here keeps
## the review independent from a match scene and makes each position portable
## in a save file. Each move records the board *before* it was played.
static func replay(sgf: String) -> Dictionary:
    var size := 0
    var size_rx := RegEx.new()
    size_rx.compile("SZ\\[(\\d+)\\]")
    var size_match := size_rx.search(sgf)
    if size_match != null:
        size = int(size_match.get_string(1))
    if size < 2 or size > MAX_SIZE:
        return {}
    var handicap := 0
    var handicap_rx := RegEx.new()
    handicap_rx.compile("HA\\[(\\d+)\\]")
    var handicap_match := handicap_rx.search(sgf)
    if handicap_match != null:
        handicap = int(handicap_match.get_string(1))
    var game := GoGame.new(size, 5.5, handicap)
    var moves: Array = []
    var rx := RegEx.new()
    rx.compile(";([BW])\\[([^\\]]*)\\]")
    for hit in rx.search_all(sgf):
        var colour := GoBoard.BLACK if hit.get_string(1) == "B" else GoBoard.WHITE
        var coord := hit.get_string(2)
        var point := GoGame.PASS
        if coord.length() == 2:
            var x := "abcdefghijklmnopqrstuvwxyz".find(coord[0])
            var y := "abcdefghijklmnopqrstuvwxyz".find(coord[1])
            if x < 0 or y < 0 or x >= size or y >= size:
                return {}
            point = game.board.idx(x, y)
        if game.to_move != colour:
            return {}
        moves.append({"color": colour, "point": point,
            "cells": Array(game.board.cells), "move_number": moves.size() + 1})
        if point == GoGame.PASS:
            game.pass_turn()
        elif not game.play(point):
            return {}
    return {"size": size, "handicap": handicap, "moves": moves}


static func position(size: int, cells: Array) -> GoGame:
    var game := GoGame.new(size)
    if cells.size() != size * size:
        return null
    var packed := PackedByteArray()
    for cell in cells:
        packed.append(int(cell))
    game.set_position(packed)
    return game


## KataGo reports scoreLead from Black's view. Keeping this conversion here
## prevents the classic White-review bug where a worse move looks better.
static func player_relative(player: int, black_score_lead: float) -> float:
    return black_score_lead if player == GoBoard.BLACK else -black_score_lead


static func player_relative_loss(player: int, best_score_lead: float,
        played_score_lead: float) -> float:
    return maxf(0.0, player_relative(player, best_score_lead) - player_relative(player, played_score_lead))


## One line of KataGo analysis output -> {turn, score_lead, best, best_lead,
## second_lead}. Anything that is not a turn result is {}; an engine error
## comes back as {"error": ...}. Malformed lines never become a lesson.
static func parse_analysis_line(line: String) -> Dictionary:
    var text := line.strip_edges()
    if not text.begins_with("{"):
        return {}
    var parsed: Variant = JSON.parse_string(text)
    if not (parsed is Dictionary):
        return {}
    if parsed.has("error"):
        return {"error": str(parsed["error"])}
    if not parsed.has("turnNumber") or not (parsed.get("rootInfo") is Dictionary):
        return {}
    var root: Dictionary = parsed["rootInfo"]
    if not root.has("scoreLead"):
        return {}
    var out := {"turn": int(parsed["turnNumber"]), "score_lead": float(root["scoreLead"]),
        "winrate": float(root.get("winrate", 0.5)), "best": "", "best_lead": float(root["scoreLead"]),
        "second_lead": null}
    var infos: Array = parsed.get("moveInfos", []) if parsed.get("moveInfos") is Array else []
    if infos.size() > 0 and infos[0] is Dictionary:
        out["best"] = str(infos[0].get("move", ""))
        out["best_lead"] = float(infos[0].get("scoreLead", root["scoreLead"]))
    if infos.size() > 1 and infos[1] is Dictionary and infos[1].has("scoreLead"):
        out["second_lead"] = float(infos[1]["scoreLead"])
    return out


## Every player decision the engine saw both sides of. Move m (1-based) is
## judged by the position at turn m-1 (before) and turn m (after); losing a
## turn to the watchdog just drops that decision, it never invents one.
static func moments_from_turns(replay: Dictionary, player: int, turns: Dictionary) -> Array:
    var size := int(replay.get("size", 0))
    var board := GoBoard.new(size)
    var moments: Array = []
    var moves: Array = replay.get("moves", [])
    for i in moves.size():
        var move: Dictionary = moves[i]
        var actual := int(move.get("point", GoGame.PASS))
        if int(move.get("color", -1)) != player or actual < 0:
            continue
        if not turns.has(i) or not turns.has(i + 1):
            continue
        var before: Dictionary = turns[i]
        var after: Dictionary = turns[i + 1]
        var best := board.from_label(str(before.get("best", "")))
        var loss := player_relative_loss(player, float(before["score_lead"]), float(after["score_lead"]))
        var stake := 0.0
        if before.get("second_lead") != null:
            stake = maxf(0.0, player_relative(player, float(before["best_lead"]))
                - player_relative(player, float(before["second_lead"])))
        var moment := {"move_number": i + 1, "actual": actual, "best": best,
            "point_loss": loss, "stake": stake, "size": size, "cells": move["cells"]}
        if best >= 0 and best != actual:
            moment.merge(explain_position(size, move["cells"], player, actual, best))
        moments.append(moment)
    return moments


## Pick the largest genuine loss, then a loss about a different idea, then the
## one moment the engine agreed with the player and the alternative was worse.
## Sorting makes saved reviews deterministic.
static func select_moments(moments: Array) -> Array:
    var mistakes: Array = []
    var strengths: Array = []
    for moment_value in moments:
        if not (moment_value is Dictionary):
            continue
        var moment: Dictionary = moment_value
        var actual := int(moment.get("actual", -1))
        var best := int(moment.get("best", -1))
        if actual < 0:
            continue
        if best == actual and float(moment.get("stake", 0.0)) >= MEANINGFUL_LOSS:
            strengths.append(moment)
        elif best >= 0 and best != actual and float(moment.get("point_loss", 0.0)) >= MEANINGFUL_LOSS:
            mistakes.append(moment)
    mistakes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if float(a["point_loss"]) == float(b["point_loss"]):
            return int(a["move_number"]) < int(b["move_number"])
        return float(a["point_loss"]) > float(b["point_loss"]))
    strengths.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if float(a["stake"]) == float(b["stake"]):
            return int(a["move_number"]) < int(b["move_number"])
        return float(a["stake"]) > float(b["stake"]))
    var picked: Array = []
    if not strengths.is_empty():
        var strength: Dictionary = strengths[0].duplicate(true)
        strength["kind"] = "strength"
        picked.append(strength)
    if mistakes.is_empty():
        return picked
    var biggest: Dictionary = mistakes[0].duplicate(true)
    biggest["kind"] = "mistake"
    picked.append(biggest)
    for candidate_value in mistakes.slice(1):
        var candidate: Dictionary = candidate_value
        var concept := str(candidate.get("concept", "unknown"))
        if concept != "unknown" and concept != str(biggest.get("concept", "unknown")):
            var lesson: Dictionary = candidate.duplicate(true)
            lesson["kind"] = "lesson"
            picked.append(lesson)
            break
    return picked.slice(0, 3)


## The whole conversion, pure: a record plus what KataGoAnalysis.run returned.
static func from_turns(record_index: int, record: Dictionary, raw: Dictionary) -> Dictionary:
    var version := str(raw.get("engine_version", "KataGo"))
    var turns: Dictionary = raw.get("turns", {})
    if turns.is_empty():
        return unavailable(record_index, str(raw.get("reason", "no analysis")), version)
    var replay := replay(str(record.get("sgf", "")))
    if replay.is_empty():
        return unavailable(record_index, "malformed sgf", version)
    var player := int(record.get("player_color", GoBoard.BLACK))
    var moments := moments_from_turns(replay, player, turns)
    var total_moves := 0
    for move in replay["moves"]:
        if int(move["color"]) == player and int(move["point"]) >= 0:
            total_moves += 1
    if moments.is_empty():
        return unavailable(record_index, "not enough of the game was analysed", version)
    var meta := {"partial": not bool(raw.get("complete", false)),
        "analysed_moves": moments.size(), "total_moves": total_moves}
    return available(record_index, version, [], select_moments(moments), meta)


## Deliberately conservative local vocabulary. If the stones do not prove one
## of these ideas, the review says "a local alternative" rather than bluffing.
static func explain_position(size: int, cells: Array, player: int, _actual: int, best: int) -> Dictionary:
    var game := position(size, cells)
    if game == null or best < 0 or best >= size * size or game.board.get_idx(best) != GoBoard.EMPTY:
        return {"concept": "unknown", "changed": "This is a local alternative.", "habit": "Pause and compare one nearby reply."}
    var board := game.board
    var friendly := 0
    var enemy_atari := false
    for neighbour in board.neighbours(best):
        if board.get_idx(neighbour) == player:
            friendly += 1
        elif board.get_idx(neighbour) == GoBoard.opponent(player) and board.liberty_count(neighbour) == 1:
            enemy_atari = true
    if enemy_atari:
        return {"concept": "capture", "changed": "It takes stones that have one liberty left.", "habit": "When stones touch, count their liberties before playing elsewhere."}
    if friendly >= 2:
        return {"concept": "connect", "changed": "It joins your nearby stones so they share liberties.", "habit": "Before a fight, look for the move that connects your stones."}
    if friendly == 1:
        var friend_point := -1
        for neighbour in board.neighbours(best):
            if board.get_idx(neighbour) == player:
                friend_point = neighbour
                break
        if friend_point >= 0 and board.liberty_count(friend_point) <= 2:
            return {"concept": "defend", "changed": "It gives your short-of-liberties group room to live.", "habit": "Check your groups with two or fewer liberties first."}
        return {"concept": "extend", "changed": "It extends from your stone and gives it more room.", "habit": "After contact, extend when your stones need room."}
    var adjacent_enemy := false
    for neighbour in board.neighbours(best):
        adjacent_enemy = adjacent_enemy or board.get_idx(neighbour) == GoBoard.opponent(player)
    if adjacent_enemy:
        return {"concept": "attack", "changed": "It leans on a nearby group of theirs.", "habit": "When you approach a group, check whether it can answer locally."}
    return {"concept": "unknown", "changed": "It is a different local choice, without a simple forced claim.", "habit": "Pause and compare one nearby reply."}
