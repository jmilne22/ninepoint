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
## What the answer is supposed to achieve. Capture was the only kind for a long
## time and is still the default; a puzzle about living, running or joining has a
## correct move that takes nothing off the board at all.
##
## The list lives here rather than in the test that checks it, because two copies
## of "the kinds the game knows" is two things that can disagree -- and the one
## in the test is the copy that would go on passing.
const KINDS := ["capture", "live", "escape", "connect"]
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


## A problem built from a review finding: the position the player got wrong,
## handed straight back with the move that was there as the answer.
##
## No JSON file and no id in data/puzzles/ -- this is one game's mistake and it
## exists for about a minute. It is the most useful thing the review does,
## because a beginner is never more ready to solve a problem than thirty seconds
## after failing to.
##
## Returns null when the finding has no single correct move to check against,
## which is most of them: praise has no answer, and neither does "this is where
## the game turned".
static func from_finding(f: Dictionary, board_size: int, takeaway: String = "") -> GoPuzzleData:
    if f == null or f.is_empty() or bool(f.get("good", false)):
        return null
    var detail: Dictionary = f.get("detail", {})
    # `save` is the move that would have saved a group; `liberty` is the point
    # that was free all along. Either is a single answer that the rules can
    # check. A finding with neither is a description, not a problem.
    var answer: int = int(detail.get("save", detail.get("liberty", -1)))
    if answer < 0:
        return null
    var cells: PackedByteArray = f.get("cells", PackedByteArray())
    if cells.size() != board_size * board_size:
        return null
    if int(cells[answer]) != GoBoard.EMPTY:
        return null                       # the point is not playable any more

    var p := GoPuzzleData.new()
    p.id = "review_%s" % str(f.get("kind", "moment"))
    p.title = "The Same Position"
    p.size = board_size
    p.cells = cells.duplicate()
    p.to_move = GoBoard.BLACK
    p.solutions = PackedInt32Array([answer])
    p.target = f.get("points", PackedInt32Array())
    p.explanation = takeaway
    match str(f.get("kind", "")):
        "capture_missed":
            p.kind = "capture"
            p.goal = "Take them."
        "own_eye_filled":
            p.kind = "live"
            p.goal = "Make it live."
        _:
            p.kind = "escape"
            p.goal = "Save it."
    p.hint = "One move. Look at the liberties."
    return p
