## A Go problem, loaded from data/puzzles/<id>.json.
##
## Pure data + rules; the puzzle scene is what draws it. Lives in src/go/ so the
## headless tests can check every shipped puzzle is actually solvable.
class_name GoPuzzleData
extends RefCounted

const DIR := "res://data/puzzles/"

var id: String = ""
var title: String = ""
var teacher: String = ""
var size: int = 9
var to_move: int = GoBoard.BLACK
## What the answer is supposed to achieve: "capture", "live" or "escape".
## Capture was the only kind for a long time and is still the default; a puzzle
## about living or running has a correct move that takes nothing off the board.
var kind: String = "capture"
var goal: String = ""
var hint: String = ""
var explanation: String = ""
var solutions: PackedInt32Array = PackedInt32Array()
var target: PackedInt32Array = PackedInt32Array()
var cells: PackedByteArray = PackedByteArray()


static func load_puzzle(puzzle_id: String) -> GoPuzzleData:
    var path := DIR + puzzle_id + ".json"
    if not FileAccess.file_exists(path):
        push_error("GoPuzzleData: no such puzzle '%s'" % puzzle_id)
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (parsed is Dictionary):
        push_error("GoPuzzleData: %s is not valid JSON" % path)
        return null

    var p := GoPuzzleData.new()
    p.id = str(parsed.get("id", puzzle_id))
    p.title = str(parsed.get("title", ""))
    p.teacher = str(parsed.get("teacher", ""))
    p.kind = str(parsed.get("kind", "capture"))
    p.goal = str(parsed.get("goal", ""))
    p.hint = str(parsed.get("hint", ""))
    p.explanation = str(parsed.get("explanation", ""))
    p.to_move = GoBoard.BLACK if str(parsed.get("to_move", "black")) == "black" else GoBoard.WHITE

    var rows: Array = parsed.get("board", [])
    var art := "\n".join(PackedStringArray(rows))
    var board := GoBoard.from_ascii(art)
    p.size = int(parsed.get("size", board.size))
    p.cells = board.cells
    if board.size != p.size:
        push_error("GoPuzzleData: %s declares size %d but the art is %d" % [path, p.size, board.size])

    for s in parsed.get("solutions", []):
        p.solutions.append(int(s[1]) * p.size + int(s[0]))
    for t in parsed.get("target", []):
        p.target.append(int(t[1]) * p.size + int(t[0]))
    return p


func make_game() -> GoGame:
    var g := GoGame.new(size, 0.5, 0)
    g.set_position(cells, to_move)
    return g


func is_solution(point: int) -> bool:
    return solutions.has(point)
