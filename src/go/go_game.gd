## A game of Go: turn order, legality, ko, passing, resignation, history.
##
## Pure logic. No Node, no signals, no scene tree. See ARCHITECTURE.md section 1.
class_name GoGame
extends RefCounted

enum State { PLAYING, SCORING, FINISHED }
enum Legality { LEGAL, OCCUPIED, OUT_OF_BOUNDS, SUICIDE, KO, SUPERKO, GAME_OVER }
enum KoRule { SIMPLE, POSITIONAL_SUPERKO }

const PASS := -1
const RESIGN := -2

var board: GoBoard
var to_move: int = GoBoard.BLACK
var komi: float = 6.5
var handicap: int = 0
var ko_rule: int = KoRule.SIMPLE

## Point that may not be played by `to_move` this turn (simple ko), or -1.
var ko_point: int = -1
var consecutive_passes: int = 0
var state: int = State.PLAYING
## Stones captured *by* each colour, indexed by GoBoard.BLACK / GoBoard.WHITE.
var captures := {GoBoard.BLACK: 0, GoBoard.WHITE: 0}
## Set when the game ends. See GoScoring.score() for the scoring payload.
var result: Dictionary = {}

## Capture Go ("atari go", "first capture"): the first player to capture this
## many stones wins outright and scoring never happens. 0 plays a normal game.
## This is the standard way Go is taught to beginners -- same rules, one clear
## goal -- so the tutorial uses it before it uses territory.
var capture_goal: int = 0

## One entry per played move: {color, point, captured: PackedInt32Array, label}
var moves: Array[Dictionary] = []

var _snapshots: Array[Dictionary] = []
var _seen_hashes: Dictionary = {}


func _init(size: int = 9, komi_value: float = 6.5, handicap_stones: int = 0) -> void:
    board = GoBoard.new(size)
    komi = komi_value
    handicap = handicap_stones
    if handicap >= 2:
        for i in handicap_points(size, handicap):
            board.set_idx(i, GoBoard.BLACK)
        to_move = GoBoard.WHITE
    _seen_hashes[GoZobrist.hash_board(board)] = true


## Replaces the position wholesale (setup positions, puzzles, tests) and
## re-seeds the repetition table so superko is measured from here.
func set_position(cells: PackedByteArray, side_to_move: int = GoBoard.BLACK) -> void:
    assert(cells.size() == board.cells.size())
    board.cells = cells.duplicate()
    to_move = side_to_move
    ko_point = -1
    consecutive_passes = 0
    moves.clear()
    _snapshots.clear()
    _seen_hashes = {GoZobrist.hash_board(board): true}


func size() -> int:
    return board.size


func move_number() -> int:
    return moves.size()


func last_move() -> Dictionary:
    return moves[-1] if not moves.is_empty() else {}


# --- legality ----------------------------------------------------------------

func legality(i: int, color: int = -1) -> int:
    if color == -1:
        color = to_move
    if state != State.PLAYING:
        return Legality.GAME_OVER
    if i < 0 or i >= board.cells.size():
        return Legality.OUT_OF_BOUNDS
    if not board.is_empty(i):
        return Legality.OCCUPIED
    if board.is_suicide(i, color):
        return Legality.SUICIDE
    if ko_rule == KoRule.SIMPLE and i == ko_point and color == to_move:
        return Legality.KO
    if ko_rule == KoRule.POSITIONAL_SUPERKO:
        var probe := board.duplicate_board()
        probe.place(i, color)
        if _seen_hashes.has(GoZobrist.hash_board(probe)):
            return Legality.SUPERKO
    return Legality.LEGAL


func is_legal(i: int, color: int = -1) -> bool:
    return legality(i, color) == Legality.LEGAL


func legality_reason(code: int) -> String:
    match code:
        Legality.OCCUPIED: return "There is already a stone there."
        Legality.OUT_OF_BOUNDS: return "That is off the board."
        Legality.SUICIDE: return "That would be self-capture."
        Legality.KO: return "Ko: you cannot take back immediately."
        Legality.SUPERKO: return "That would repeat a previous position."
        Legality.GAME_OVER: return "The game is over."
        _: return ""


func legal_moves(color: int = -1) -> PackedInt32Array:
    if color == -1:
        color = to_move
    var out := PackedInt32Array()
    for i in board.cells.size():
        if legality(i, color) == Legality.LEGAL:
            out.append(i)
    return out


# --- playing -----------------------------------------------------------------

func play(i: int) -> bool:
    if not is_legal(i):
        return false
    _push_snapshot()
    var color := to_move
    var captured := board.place(i, color)
    captures[color] += captured.size()
    consecutive_passes = 0

    # Simple ko: a single-stone capture by a single stone left with one liberty.
    ko_point = -1
    if captured.size() == 1:
        var ch := board.chain_at(i)
        if ch["stones"].size() == 1 and ch["liberties"].size() == 1:
            ko_point = captured[0]

    moves.append({
        "color": color, "point": i, "captured": captured, "label": board.label(i),
    })
    to_move = GoBoard.opponent(color)
    _seen_hashes[GoZobrist.hash_board(board)] = true
    _check_capture_goal(color)
    return true


func _check_capture_goal(color: int) -> void:
    if capture_goal <= 0 or captures[color] < capture_goal:
        return
    state = State.FINISHED
    var stones := "a stone" if capture_goal == 1 else "%d stones" % capture_goal
    result = {
        "winner": color,
        "by_resignation": false,
        "by_capture": true,
        "margin": float(captures[color]),
        "text": "%s wins by capturing %s" % [GoBoard.color_name(color), stones],
    }


func play_xy(x: int, y: int) -> bool:
    if not board.in_bounds(x, y):
        return false
    return play(board.idx(x, y))


func pass_turn() -> void:
    if state != State.PLAYING:
        return
    _push_snapshot()
    moves.append({"color": to_move, "point": PASS, "captured": PackedInt32Array(), "label": "pass"})
    consecutive_passes += 1
    ko_point = -1
    to_move = GoBoard.opponent(to_move)
    if consecutive_passes >= 2:
        state = State.SCORING


func resign(color: int = -1) -> void:
    if color == -1:
        color = to_move
    moves.append({"color": color, "point": RESIGN, "captured": PackedInt32Array(), "label": "resign"})
    state = State.FINISHED
    result = {
        "winner": GoBoard.opponent(color),
        "by_resignation": true,
        "margin": 0.0,
        "text": "%s wins by resignation" % GoBoard.color_name(GoBoard.opponent(color)),
    }


## Finalises a game that has reached SCORING. `dead` holds board indices judged dead.
func finish_with_score(scoring: Dictionary) -> void:
    result = scoring
    state = State.FINISHED


func undo() -> bool:
    if _snapshots.is_empty():
        return false
    var s: Dictionary = _snapshots.pop_back()
    board.cells = s["cells"]
    to_move = s["to_move"]
    ko_point = s["ko_point"]
    consecutive_passes = s["passes"]
    captures = s["captures"]
    state = s["state"]
    result = {}
    moves.resize(moves.size() - 1)
    return true


func _push_snapshot() -> void:
    _snapshots.append({
        "cells": board.cells.duplicate(),
        "to_move": to_move,
        "ko_point": ko_point,
        "passes": consecutive_passes,
        "captures": captures.duplicate(),
        "state": state,
    })


# --- handicap ----------------------------------------------------------------

## Standard handicap points, in the conventional placement order.
static func handicap_points(size: int, count: int) -> PackedInt32Array:
    var out := PackedInt32Array()
    if count < 2:
        return out
    var e := 2 if size < 13 else 3
    var m := size / 2
    var l := size - 1 - e
    var corners := [
        Vector2i(l, e), Vector2i(e, l), Vector2i(l, l), Vector2i(e, e),
    ]
    var edges := [Vector2i(e, m), Vector2i(l, m), Vector2i(m, e), Vector2i(m, l)]
    var pts: Array[Vector2i] = []
    for i in mini(count, 4):
        pts.append(corners[i])
    if count >= 5 and count % 2 == 1:
        pts.append(Vector2i(m, m))
    if count >= 6:
        pts.append(edges[0])
        pts.append(edges[1])
    if count >= 8:
        pts.append(edges[2])
        pts.append(edges[3])
    if count >= 9 and not pts.has(Vector2i(m, m)):
        pts.append(Vector2i(m, m))
    var b_size := size
    for p in pts:
        out.append(p.y * b_size + p.x)
    return out


## Komi convention: an even game carries full komi, a handicap game carries 0.5.
static func default_komi(size: int, handicap_stones: int) -> float:
    if handicap_stones >= 2:
        return 0.5
    return 6.5 if size >= 19 else 5.5
