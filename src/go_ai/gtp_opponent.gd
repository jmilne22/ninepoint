## Adapter for any GTP engine (KataGo, GNU Go, Leela) over stdio.
##
## Unused by the vertical slice, but the protocol is implemented so that pointing
## an OpponentProfile at a binary is the only work required. See ARCHITECTURE.md 5.
class_name GtpOpponent
extends GoOpponent

var _pipe: Dictionary = {}
var _stdio: FileAccess
var _pid: int = -1
var _ready := false


func is_available() -> bool:
    return profile != null and profile.gtp_command != "" \
        and FileAccess.file_exists(profile.gtp_command)


func setup(p: OpponentProfile, game: GoGame) -> void:
    super.setup(p, game)
    if not is_available():
        push_warning("GtpOpponent: engine '%s' not found; caller should fall back." % p.gtp_command)
        return
    _pipe = OS.execute_with_pipe(p.gtp_command, p.gtp_args)
    if _pipe.is_empty():
        push_error("GtpOpponent: failed to launch %s" % p.gtp_command)
        return
    _stdio = _pipe["stdio"]
    _pid = _pipe["pid"]
    _ready = true
    _command("boardsize %d" % game.size())
    _command("clear_board")
    _command("komi %s" % str(game.komi))
    if game.handicap >= 2:
        _command("fixed_handicap %d" % game.handicap)


func choose_move(game: GoGame) -> Dictionary:
    if not _ready:
        return GoOpponent.pass_move()
    # Replay anything the engine has not seen. The slice keeps it simple and
    # replays the whole game each turn; a long-lived engine would track an index.
    _command("clear_board")
    for m in game.moves:
        if m["point"] == GoGame.RESIGN:
            continue
        var colour := "b" if m["color"] == GoBoard.BLACK else "w"
        var where := "pass" if m["point"] == GoGame.PASS else game.board.label(m["point"])
        _command("play %s %s" % [colour, where])
    var colour_to_move := "b" if game.to_move == GoBoard.BLACK else "w"
    var reply := _command("genmove %s" % colour_to_move).strip_edges().to_upper()
    if reply == "PASS":
        return GoOpponent.pass_move()
    if reply == "RESIGN":
        return GoOpponent.resign_move()
    var i := _parse_vertex(game.board, reply)
    return GoOpponent.point_move(i) if i >= 0 else GoOpponent.pass_move()


func should_accept_dead_marks(_game: GoGame, _dead: Dictionary) -> bool:
    # A real engine would answer with `final_status_list dead` and compare.
    return true


func shutdown() -> void:
    if _ready:
        _command("quit")
        _ready = false
    if _pid > 0:
        OS.kill(_pid)
        _pid = -1


func _command(text: String) -> String:
    if _stdio == null or not _stdio.is_open():
        return ""
    _stdio.store_line(text)
    _stdio.flush()
    var out := ""
    while _stdio.is_open():
        var line := _stdio.get_line()
        if line.begins_with("="):
            out = line.substr(1).strip_edges()
        elif line.begins_with("?"):
            push_error("GTP error: %s" % line)
            return ""
        elif line.strip_edges() == "":
            break
    return out


static func _parse_vertex(board: GoBoard, vertex: String) -> int:
    if vertex.length() < 2:
        return -1
    var letters := "ABCDEFGHJKLMNOPQRSTUVWXYZ"
    var x := letters.find(vertex[0])
    var row := int(vertex.substr(1))
    if x < 0 or row <= 0 or row > board.size:
        return -1
    return board.idx(x, board.size - row)
