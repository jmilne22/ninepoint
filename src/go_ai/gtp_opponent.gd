## Stateful, failure-contained GTP adapter. The rules game remains authoritative.
class_name GtpOpponent
extends GoOpponent

var _pipe := EnginePipe.new()
var _ready := false
var _cancelled := false
var _synced_moves := 0
var _initial_cells := PackedByteArray()
var _fallback := HeuristicOpponent.new()
## Readable by presentation/logging without turning an engine error into a crash.
var unavailable_reason := ""
## Runtime evidence for the development-only integration fixture. These are not
## strength or gameplay knobs; they say whether this particular process did work.
var engine_started := false
var fallback_used := false
var legal_reply_count := 0
var shutdown_complete := false
var startup_ms := -1
var last_move_ms := -1


func is_available() -> bool:
    return profile != null and profile.gtp_command != "" and FileAccess.file_exists(profile.gtp_command)


func setup(p: OpponentProfile, game: GoGame) -> void:
    super.setup(p, game)
    _fallback.setup(p, game)
    # A lease was already started by KataGoService. Rebinding it to the match
    # must not spawn a second process.
    if engine_started:
        return
    if not is_available():
        unavailable_reason = "Engine files are unavailable; using the local opponent."
        return
    var args := PackedStringArray()
    for argument in p.gtp_args:
        args.append(str(argument).replace("{model}", p.gtp_model_path).replace("{config}", p.gtp_config_path))
    if not _pipe.open(p.gtp_command, args):
        unavailable_reason = "The analysis engine could not start; using the local opponent."
        _pipe.close()
        return
    _ready = true
    engine_started = true
    # Synchronisation happens on the first turn, where GoMatch already awaits
    # choose_move(). setup itself must stay usable by the synchronous factory.


## The pool calls this while the player is still entering the match. A real GTP
## reply is a better readiness signal than merely having spawned a process.
func prewarm() -> bool:
    if not _ready:
        return false
    var started_at := Time.get_ticks_msec()
    var limit := maxf(profile.gtp_startup_timeout, 0.1)
    # Loading the network and its first inference are preparation work, not a
    # player's turn. A harmless throwaway move makes the normal two-second
    # command deadline representative of an already-warm engine.
    await _command("protocol_version", limit)
    if _ready:
        await _command("boardsize %d" % profile.board_size, limit)
    if _ready:
        await _command("clear_board", limit)
    if _ready:
        await _command("komi %s" % str(profile.komi), limit)
    if _ready:
        await _command("genmove b", limit)
    if _ready:
        await _command("clear_board", limit)
    startup_ms = Time.get_ticks_msec() - started_at
    return _ready


func choose_move(game: GoGame) -> Dictionary:
    if not _ready:
        return _fallback_move(game)
    await _synchronise(game)
    if not _ready:
        return _fallback_move(game)
    var move_started_at := Time.get_ticks_msec()
    var colour := "b" if game.to_move == GoBoard.BLACK else "w"
    var vertex := (await _command("genmove %s" % colour)).strip_edges().to_upper()
    if not _ready:
        return _fallback_move(game)
    if vertex == "PASS":
        _synced_moves += 1
        return GoOpponent.pass_move()
    if vertex == "RESIGN":
        return GoOpponent.resign_move()
    var point := game.board.from_label(vertex)
    if point < 0 or not game.is_legal(point):
        _fail("The analysis engine sent an invalid move (%s); using the local opponent." % vertex)
        return _fallback_move(game)
    _synced_moves += 1
    legal_reply_count += 1
    last_move_ms = Time.get_ticks_msec() - move_started_at
    return GoOpponent.point_move(point)


func should_accept_dead_marks(_game: GoGame, _dead: Dictionary) -> bool:
    return true


func cancel() -> void:
    _cancelled = true
    _fail("Engine analysis cancelled.")


func shutdown() -> void:
    _cancelled = true
    _pipe.close()
    shutdown_complete = true


func _fallback_move(game: GoGame) -> Dictionary:
    fallback_used = true
    return _fallback.choose_move(game)


## Initial handicap and arbitrary setup positions have no moves, so replay the
## actual coloured stones once. Subsequent calls append only unseen moves.
func _synchronise(game: GoGame) -> void:
    var reset := _synced_moves > game.moves.size() or _initial_cells.is_empty() \
        or (_initial_cells.size() != game.board.cells.size()) \
        or (game.moves.is_empty() and _initial_cells != game.board.cells)
    if reset:
        await _command("boardsize %d" % game.size())
        await _command("clear_board")
        await _command("komi %s" % str(game.komi))
        if game.moves.is_empty():
            # A position with no history is either a handicap opening or an
            # explicit setup position. In both cases its visible stones are the
            # only honest state the engine can be given.
            for point in game.board.cells.size():
                var stone := int(game.board.cells[point])
                if stone == GoBoard.EMPTY:
                    continue
                var colour := "b" if stone == GoBoard.BLACK else "w"
                await _command("play %s %s" % [colour, game.board.label(point)])
                if not _ready:
                    return
            _initial_cells = game.board.cells.duplicate()
        else:
            # Normal games retain only the handicap as setup; move history then
            # reconstructs the rest exactly once below.
            var base := PackedByteArray()
            base.resize(game.board.cells.size())
            for point in GoGame.handicap_points(game.size(), game.handicap):
                base[point] = GoBoard.BLACK
                await _command("play b %s" % game.board.label(point))
                if not _ready:
                    return
            _initial_cells = base
        _synced_moves = 0
    while _ready and _synced_moves < game.moves.size():
        var move: Dictionary = game.moves[_synced_moves]
        if int(move.get("point", GoGame.RESIGN)) == GoGame.RESIGN:
            _synced_moves += 1
            continue
        var colour := "b" if int(move["color"]) == GoBoard.BLACK else "w"
        var point := int(move["point"])
        var where := "pass" if point == GoGame.PASS else game.board.label(point)
        await _command("play %s %s" % [colour, where])
        if not _ready:
            return
        _synced_moves += 1


func _command(text: String, timeout: float = -1.0) -> String:
    if not _pipe.is_open() or _cancelled:
        return ""
    _pipe.write_line(text)
    var limit := timeout if timeout >= 0.0 else maxf(profile.gtp_time_per_move, 0.1)
    var reply := ""
    while _pipe.is_open():
        if _cancelled:
            _fail("Engine analysis cancelled.")
            return ""
        var read: Dictionary = await _pipe.read_line(limit)
        if not bool(read.get("ready", false)):
            _fail("The analysis engine timed out; using the local opponent.")
            return ""
        var line := str(read.get("line", ""))
        if line.begins_with("="):
            reply = line.substr(1).strip_edges()
        elif line.begins_with("?"):
            _fail("The analysis engine rejected a command; using the local opponent.")
            return ""
        elif line.strip_edges() == "":
            return reply
    _fail("The analysis engine timed out; using the local opponent.")
    return ""


func _fail(reason: String) -> void:
    unavailable_reason = reason
    if OS.is_debug_build():
        print("KataGo fallback (%s, startup=%dms, move=%dms)" % [reason, startup_ms, last_move_ms])
    _ready = false
    _pipe.close()
