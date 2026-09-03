## A taught lesson: a sequence of small positions, each with something for the
## player to do and a sentence explaining what just happened.
##
## Pure data and rules, like GoPuzzleData -- the runner in src/go_ui draws it.
## The teaching order these express is Yasuda's: liberties, then capture, then a
## real Capture Go game, before territory is ever mentioned.
class_name GoLessonData
extends RefCounted

const DIR := "res://data/lessons/"

## What a step accepts as "done".
##   any_legal       -- any legal move at all (for "just put a stone down")
##   points          -- only the listed points
##   capture         -- any move that captures something
##   illegal_attempt -- the player must *try* the marked point and be refused
enum Accept { ANY_LEGAL, POINTS, CAPTURE, ILLEGAL_ATTEMPT }

var id: String = ""
var title: String = ""
var teacher: String = ""
var size: int = 9
var intro: PackedStringArray = PackedStringArray()
var outro: PackedStringArray = PackedStringArray()
## Each: {cells, to_move, instruction, accept, points, show_liberties,
##        explanation, hint, target}
var steps: Array[Dictionary] = []


static func load_lesson(lesson_id: String) -> GoLessonData:
    var path := DIR + lesson_id + ".json"
    if not FileAccess.file_exists(path):
        push_error("GoLessonData: no such lesson '%s'" % lesson_id)
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (parsed is Dictionary):
        push_error("GoLessonData: %s is not valid JSON" % path)
        return null

    var l := GoLessonData.new()
    l.id = str(parsed.get("id", lesson_id))
    l.title = str(parsed.get("title", ""))
    l.teacher = str(parsed.get("teacher", ""))
    l.size = int(parsed.get("size", 9))
    l.intro = PackedStringArray(parsed.get("intro", []))
    l.outro = PackedStringArray(parsed.get("outro", []))

    for raw in parsed.get("steps", []):
        var board := GoBoard.from_ascii("\n".join(PackedStringArray(raw.get("board", []))))
        var points := PackedInt32Array()
        for xy in raw.get("points", []):
            points.append(int(xy[1]) * l.size + int(xy[0]))
        var target := PackedInt32Array()
        for xy in raw.get("target", []):
            target.append(int(xy[1]) * l.size + int(xy[0]))
        var pre := -1
        if raw.has("pre"):
            pre = int(raw["pre"][1]) * l.size + int(raw["pre"][0])
        l.steps.append({
            "pre": pre,
            # Read by the runner to show the pocket the step claims to enclose,
            # and by tools/check_lessons.py to prove the claim is true.
            "encloses": int(raw.get("encloses", 0)),
            "region_at": (int(raw["region_at"][1]) * l.size + int(raw["region_at"][0])) \
                if raw.has("region_at") else -1,
            "cells": board.cells,
            "to_move": GoBoard.BLACK if str(raw.get("to_move", "black")) == "black" else GoBoard.WHITE,
            "instruction": str(raw.get("instruction", "")),
            "accept": _accept_from(str(raw.get("accept", "any_legal"))),
            "points": points,
            "show_liberties": bool(raw.get("show_liberties", false)),
            "explanation": str(raw.get("explanation", "")),
            "hint": str(raw.get("hint", "")),
            "target": target,
        })
    return l


static func _accept_from(name: String) -> int:
    match name:
        "points": return Accept.POINTS
        "capture": return Accept.CAPTURE
        "illegal_attempt": return Accept.ILLEGAL_ATTEMPT
        _: return Accept.ANY_LEGAL


func step_count() -> int:
    return steps.size()


## The position a step starts from.
##
## `pre` is a move the opponent plays before the player's turn. It exists for ko:
## the rule is about history, not about the position, so a board handed straight
## to set_position has no ko on it and the engine will happily allow the retake.
## Playing the capture for real is the only way the lesson can be refused by the
## same rule that refuses it in a game.
func make_game(index: int) -> GoGame:
    var step: Dictionary = steps[index]
    var g := GoGame.new(size, 0.5, 0)
    var pre: int = int(step.get("pre", -1))
    if pre >= 0:
        g.set_position(step["cells"], GoBoard.opponent(int(step["to_move"])))
        g.play(pre)
    else:
        g.set_position(step["cells"], int(step["to_move"]))
    return g


## Was this the move the step was waiting for? `captured` is how many stones the
## move took, so a "capture" step does not have to enumerate every answer.
func step_accepts(index: int, point: int, legal: bool, captured: int) -> bool:
    var step: Dictionary = steps[index]
    match int(step["accept"]):
        Accept.POINTS:
            return legal and step["points"].has(point)
        Accept.CAPTURE:
            return legal and captured > 0
        Accept.ILLEGAL_ATTEMPT:
            return not legal and step["points"].has(point)
        _:
            return legal


## True when the step wants the player to try something the rules forbid.
func step_wants_refusal(index: int) -> bool:
    return int(steps[index]["accept"]) == Accept.ILLEGAL_ATTEMPT
