## The review's pure half: eligibility, parsing KataGo's analysis lines, the
## per-move accounting, selection and the sealed payload. No engine needed.
class_name MatchAnalysisTests
extends RefCounted


static func run(t: TestKit) -> void:
    t.section("match analysis")
    _eligibility(t)
    _parsing(t)
    _accounting(t)
    _payload(t)
    _query(t)
    _explain(t)


static func _eligibility(t: TestKit) -> void:
    var rated := {"unrated": false, "by_capture": false, "board_size": 9, "sgf": "(;GM[1])"}
    t.ok(MatchAnalysis.eligible(rated), "a completed rated record can be reviewed")
    var casual := rated.duplicate()
    casual["unrated"] = true
    t.ok(MatchAnalysis.eligible(casual), "a casual board game can be reviewed")
    var capture := rated.duplicate()
    capture["by_capture"] = true
    t.ok(not MatchAnalysis.eligible(capture), "Capture Go stays out of the review")
    for size in [7, 13, 19]:
        var sized := rated.duplicate()
        sized["board_size"] = size
        t.ok(MatchAnalysis.eligible(sized), "%dx%d can be reviewed" % [size, size])
    var too_big := rated.duplicate()
    too_big["board_size"] = 21
    t.ok(not MatchAnalysis.eligible(too_big), "a board the engine cannot take is not offered")
    var empty := rated.duplicate()
    empty["sgf"] = ""
    t.ok(not MatchAnalysis.eligible(empty), "no record of the moves, no review")
    t.eq(MatchAnalysis.unavailable(3, "binary missing")["availability"], "failed",
        "an unavailable engine is saved as a safe state")
    t.eq(MatchAnalysis.pending(3)["availability"], "pending", "requested work has a saved shape")


static func _parsing(t: TestKit) -> void:
    var line := '{"id":"review","turnNumber":4,"rootInfo":{"scoreLead":2.5,"winrate":0.7},"moveInfos":[{"move":"D4","scoreLead":2.6,"order":0},{"move":"C3","scoreLead":0.4,"order":1}]}'
    var parsed := KataGoAnalysis.parse_line(line)
    t.eq(parsed.get("turn"), 4, "the turn number is read")
    t.eq(parsed.get("score_lead"), 2.5, "the root score lead is read")
    t.eq(parsed.get("best"), "D4", "the first candidate is the engine's move")
    t.eq(parsed.get("second_lead"), 0.4, "the runner-up's lead is kept for the stake")
    t.ok(KataGoAnalysis.parse_line("Started, ready to begin handling requests").is_empty(),
        "chatter is not a turn")
    t.ok(KataGoAnalysis.parse_line('{"turnNumber":1}').is_empty(), "a turn without numbers is dropped")
    t.eq(KataGoAnalysis.parse_line('{"error":"bad rules","field":"rules"}').get("error"), "bad rules",
        "an engine error is surfaced, not swallowed")
    t.eq(MatchAnalysis.player_relative_loss(GoBoard.WHITE, 1.0, 3.0), 2.0,
        "score loss is relative to White as well as Black")
    t.eq(MatchAnalysis.player_relative_loss(GoBoard.BLACK, 1.0, 3.0), 0.0,
        "gaining points is never a loss")


## Three moves: Black D6, White E5, Black C7. Turn t is the position after t
## moves; Black's first move is judged by turns 0 and 1, her second by 2 and 3.
static func _accounting(t: TestKit) -> void:
    var replay := MatchAnalysis.replay("(;GM[1]SZ[9];B[dd];W[ee];B[cc])")
    t.eq(replay["moves"].size(), 3, "the saved SGF replays into moves")
    t.eq(int(replay["moves"][1]["cells"][30]), GoBoard.BLACK,
        "each moment stores the position before that move")
    var turns := {
        0: {"turn": 0, "score_lead": 1.0, "best": "D6", "best_lead": 1.0, "second_lead": -1.0},
        1: {"turn": 1, "score_lead": 1.0, "best": "E5", "best_lead": 1.0, "second_lead": null},
        2: {"turn": 2, "score_lead": 1.5, "best": "E7", "best_lead": 1.5, "second_lead": null},
        3: {"turn": 3, "score_lead": -1.5, "best": "F4", "best_lead": -1.5, "second_lead": null},
    }
    var moments := MatchAnalysis.moments_from_turns(replay, GoBoard.BLACK, turns)
    t.eq(moments.size(), 2, "only the player's decisions are accounted")
    t.eq(moments[0]["best"], moments[0]["actual"], "the engine agreed with the first move")
    t.eq(moments[0]["stake"], 2.0, "the stake is the gap to the runner-up")
    t.eq(moments[0]["did_concept"], "corner", "and the stones say what the move did")
    t.eq(moments[1]["point_loss"], 3.0, "the second move's loss is before minus after")
    t.eq(moments[1]["concept"], "side", "the better move is described by where it stands")
    var white := MatchAnalysis.moments_from_turns(replay, GoBoard.WHITE, turns)
    t.eq(white.size(), 1, "White has one decision here")
    t.eq(white[0]["point_loss"], 0.5, "White's loss is measured from White's side")
    var short := turns.duplicate()
    short.erase(3)
    t.eq(MatchAnalysis.moments_from_turns(replay, GoBoard.BLACK, short).size(), 1,
        "a move whose after-position never arrived is dropped, not guessed")
    var chosen := MatchAnalysis.select_moments(moments)
    t.eq(chosen.size(), 2, "one strength and one mistake")
    t.eq(chosen[0]["kind"], "strength", "the agreed move comes first")
    t.eq(chosen[0]["matched"], true, "and says it matched the engine")
    t.eq(chosen[1]["kind"], "mistake", "the loss follows")
    var none_matched := [
        {"move_number": 2, "actual": 4, "best": 5, "point_loss": 0.3, "stake": 0.0, "did_concept": "unknown", "does": "x"},
        {"move_number": 6, "actual": 6, "best": 7, "point_loss": 0.4, "stake": 0.0, "did_concept": "connect", "does": "y"},
        {"move_number": 8, "actual": 8, "best": 9, "point_loss": 5.0, "stake": 0.0, "did_concept": "attack", "does": "z", "concept": "capture"},
    ]
    var sound := MatchAnalysis.select_moments(none_matched)
    t.eq(sound[0]["kind"], "strength", "a move that gave nothing away is still praised")
    t.eq(sound[0]["move_number"], 6, "preferring the one the stones can explain")
    t.eq(sound[0]["matched"], false, "without claiming it was the engine's move")
    var many := [
        {"move_number": 4, "actual": 2, "best": 3, "point_loss": 3.0, "stake": 0.0, "concept": "capture"},
        {"move_number": 6, "actual": 6, "best": 7, "point_loss": 2.0, "stake": 0.0, "concept": "capture"},
        {"move_number": 8, "actual": 8, "best": 9, "point_loss": 1.0, "stake": 0.0, "concept": "attack"},
    ]
    var picked := MatchAnalysis.select_moments(many)
    t.eq(picked.size(), 2, "a second loss about the same idea is not a second card")
    t.eq(picked[0]["move_number"], 4, "the biggest loss is the mistake")
    t.eq(picked[1]["concept"], "attack", "the lesson is a different idea")
    var raw := {"turns": turns, "total": 4, "complete": true, "engine_version": "KataGo test"}
    var record := {"sgf": "(;GM[1]SZ[9];B[dd];W[ee];B[cc])", "player_color": GoBoard.BLACK, "board_size": 9}
    var payload := MatchAnalysis.from_turns(0, record, raw)
    t.eq(payload["availability"], "available", "a complete analysis becomes a review")
    t.eq(payload["tally"]["moves"], 2, "the tally counts every move the engine saw both sides of")
    t.eq(payload["tally"]["best"], 1, "and how many were the best move on the board")
    t.eq(payload["tally"]["best_moves"], [1], "by move number, so the player can find them")
    t.eq(payload["tally"]["fine"], 0, "a three-point loss is not a fine move")
    t.eq(payload["partial"], false, "a complete analysis is not partial")
    raw["complete"] = false
    var cut := MatchAnalysis.from_turns(0, record, raw)
    t.eq(cut["partial"], true, "a cut-short analysis says so")
    t.eq(cut["analysed_moves"], 2, "and says how many moves it saw")
    t.eq(MatchAnalysis.from_turns(0, record, {"turns": {}, "reason": "engine stalled"})["reason"],
        "engine stalled", "no turns is a failure with the engine's reason")


static func _payload(t: TestKit) -> void:
    var cells := [0, 0, 0, 0]
    var findings := [
        {"kind": "strength", "move_number": 1, "size": 2, "cells": cells, "actual": 0, "best": 0, "stake": 1.0, "does": "It takes the corner."},
        {"kind": "mistake", "move_number": 2, "size": 2, "cells": cells, "actual": 1, "best": 2, "point_loss": 2.0},
        {"kind": "lesson", "move_number": 3, "size": 2, "cells": cells, "actual": 2, "best": 3, "point_loss": 1.0},
    ]
    t.eq(MatchAnalysis.available(3, "KataGo", [], findings)["availability"], "available",
        "three sound findings form a review")
    t.eq(MatchAnalysis.available(3, "KataGo", [], findings.slice(1))["availability"], "available",
        "one or two findings are still a review")
    t.eq(MatchAnalysis.available(3, "KataGo", [], [])["availability"], "steady",
        "a quiet game gets one honest steady summary")
    var partial := MatchAnalysis.available(3, "KataGo", [], [], {"partial": true, "analysed_moves": 12})
    t.ok(str(partial["summary"]).begins_with("The first 12 moves"), "a partial steady game says how far it got")
    var weak: Dictionary = findings[0].duplicate()
    weak["does"] = ""
    t.eq(MatchAnalysis.available(3, "KataGo", [], [weak])["availability"], "failed",
        "praise without a reason is not a card")
    var sound_one: Dictionary = findings[0].duplicate()
    sound_one["best"] = 1
    sound_one["point_loss"] = 0.4
    t.eq(MatchAnalysis.available(3, "KataGo", [], [sound_one])["availability"], "available",
        "a move within noise of the best, with a reason, is a strength")
    sound_one["point_loss"] = 2.0
    t.eq(MatchAnalysis.available(3, "KataGo", [], [sound_one])["availability"], "failed",
        "a move that cost two points is not")
    var same: Dictionary = findings[1].duplicate()
    same["best"] = same["actual"]
    t.eq(MatchAnalysis.available(3, "KataGo", [], [same])["availability"], "failed",
        "a mistake needs a different, better move")
    var tiny: Dictionary = findings[1].duplicate()
    tiny["point_loss"] = 0.3
    t.eq(MatchAnalysis.available(3, "KataGo", [], [tiny])["availability"], "failed",
        "a third of a point is noise, not a lesson")
    var four := findings.duplicate()
    four.append({"kind": "lesson", "move_number": 9, "size": 2, "cells": cells, "actual": 0, "best": 1, "point_loss": 1.0})
    t.eq(MatchAnalysis.available(3, "KataGo", [], four)["availability"], "failed",
        "four cards is one too many")


static func _query(t: TestKit) -> void:
    var replay := MatchAnalysis.replay("(;GM[1]FF[4]SZ[9]HA[2];W[ee];B[])")
    var query := KataGoAnalysis.query_for(replay, 0.5)
    t.eq(query["boardXSize"], 9, "the query carries the board size")
    t.eq(query["komi"], 0.5, "and the game's komi")
    t.eq(query["analyzeTurns"].size(), 3, "every position, including the last")
    t.eq(query["initialStones"].size(), 2, "handicap stones are setup, not moves")
    t.eq(query["initialPlayer"], "W", "and White moves first after them")
    t.eq(query["moves"][1][1], "pass", "a pass is written the way KataGo reads it")
    t.eq(query["moves"][0][1], "E5", "coordinates use GTP letters, no I")
    var board := GoBoard.new(9)
    t.eq(board.from_label("A1"), board.idx(0, 8), "A1 is the bottom-left point")
    t.eq(board.from_label("J9"), board.idx(8, 0), "J9 is the top-right point")
    t.eq(board.from_label("pass"), -1, "a pass is not a point")
    t.eq(board.from_label("I5"), -1, "I is not a column")
    t.ok(MatchAnalysis.replay("(;GM[1]SZ[9];B[zz])").is_empty(),
        "malformed coordinates cannot make a review")


static func _explain(t: TestKit) -> void:
    var connection := MatchAnalysis.explain_position(3, [0, 0, 0, 1, 0, 1, 0, 0, 0], GoBoard.BLACK, 0, 4)
    t.eq(connection["concept"], "connect", "two friendly neighbours make a connection explanation")
    var occupied := MatchAnalysis.explain_position(3, [0, 0, 0, 1, 0, 1, 0, 0, 0], GoBoard.BLACK, 0, 3)
    t.eq(occupied["concept"], "unknown", "a point that is not empty gets restrained wording")
    var atari := MatchAnalysis.explain_position(3, [2, 1, 0, 0, 0, 0, 0, 0, 0], GoBoard.BLACK, 8, 3)
    t.eq(atari["concept"], "capture", "a stone in atari next to the better move is a capture")
    var empty9 := []
    for i in 81:
        empty9.append(0)
    var b9 := GoBoard.new(9)
    t.eq(MoveExplainer.describe(9, empty9, GoBoard.BLACK, b9.from_label("C3"))["concept"], "corner",
        "an untouched 3-3 point takes the corner")
    t.eq(MoveExplainer.describe(9, empty9, GoBoard.BLACK, b9.from_label("E3"))["concept"], "side",
        "an untouched third-line point on the side stakes out the side")
    t.eq(MoveExplainer.describe(9, empty9, GoBoard.BLACK, b9.from_label("E5"))["concept"], "centre",
        "the middle is the middle")
    t.eq(MoveExplainer.describe(9, empty9, GoBoard.BLACK, b9.from_label("A1"))["concept"], "first_line",
        "the first line is named for what it is")
    t.ok(str(MoveExplainer.describe(3, [0, 0, 0, 1, 0, 1, 0, 0, 0], GoBoard.BLACK, 4)["does"]).begins_with("It joins"),
        "the played move is described in the past, as something it did")
