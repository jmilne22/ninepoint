## In-match reactions: the rules decide what happened, the data decides what
## anybody says about it, and most moves produce nothing at all.
class_name TableTalkTests
extends RefCounted


static func _game_from(rows: Array, to_move := GoBoard.BLACK) -> GoGame:
    var board := GoBoard.from_ascii("\n".join(PackedStringArray(rows)))
    var g := GoGame.new(rows.size(), 5.5, 0)
    g.set_position(board.cells, to_move)
    return g


static func run(t: TestKit) -> void:
    _test_nothing_to_say(t)
    _test_captures(t)
    _test_atari(t)
    _test_perspective(t)
    _test_passing(t)
    _test_voices(t)
    _test_cooldown(t)


static func _test_nothing_to_say(t: TestKit) -> void:
    t.section("table talk: silence is the common case")
    var g := GoGame.new(9, 5.5, 0)
    t.eq(GoTableTalk.events(g, GoBoard.WHITE).size(), 0,
        "a game with no moves has nothing to react to")
    g.play(g.board.idx(4, 4))
    t.eq(GoTableTalk.events(g, GoBoard.WHITE).size(), 0,
        "and an ordinary move in the centre is not an event")


static func _test_captures(t: TestKit) -> void:
    t.section("table talk: captures")
    # One white stone on one liberty, black to take it.
    var g := _game_from([
        ".........", "...X.....", "..XOX....", "...X.....",
        ".........", ".........", ".........", ".........", "........."])
    # The board above already has it surrounded; rebuild with the last point open.
    g = _game_from([
        ".........", "...X.....", "..XO.....", "...X.....",
        ".........", ".........", ".........", ".........", "........."])
    g.play(g.board.idx(4, 2))
    var tags := GoTableTalk.events(g, GoBoard.WHITE)
    t.ok(Array(tags).has("you_captured"),
        "the opponent notices the player taking a stone off them")
    t.ok(not Array(tags).has("i_captured"), "and does not claim it as their own")


static func _test_atari(t: TestKit) -> void:
    t.section("table talk: atari")
    var g := _game_from([
        ".........", "...X.....", "..XO.....", ".........",
        ".........", ".........", ".........", ".........", "........."])
    g.play(g.board.idx(3, 3))          # black fills the third liberty
    var tags := GoTableTalk.events(g, GoBoard.WHITE)
    t.ok(Array(tags).has("you_atari"),
        "putting a chain on one liberty is worth remarking on")

    # A move that touches nothing is not atari.
    var quiet := GoGame.new(9, 5.5, 0)
    quiet.play(quiet.board.idx(2, 2))
    t.ok(not Array(GoTableTalk.events(quiet, GoBoard.WHITE)).has("you_atari"),
        "and an unrelated move is not")


static func _test_perspective(t: TestKit) -> void:
    t.section("table talk: whose move was it")
    var g := _game_from([
        ".........", "...X.....", "..XO.....", "...X.....",
        ".........", ".........", ".........", ".........", "........."])
    g.play(g.board.idx(4, 2))          # black captures
    var white_view := Array(GoTableTalk.events(g, GoBoard.WHITE))
    var black_view := Array(GoTableTalk.events(g, GoBoard.BLACK))
    t.ok(white_view.has("you_captured"), "from White's side the player took them")
    t.ok(black_view.has("i_captured"), "from Black's side they were taken by me")
    t.ok(not black_view.has("you_captured"), "and the two readings do not overlap")


## A pass is an event, and until M29 it was the only thing that happened at the
## board and produced no tag at all -- so the match scene said "Ilse passes." in
## the same flat words whoever was sitting there, and the player who passed first
## got silence where the one warning that a pass does not end a game belongs.
static func _test_passing(t: TestKit) -> void:
    t.section("table talk: passing")
    var g := GoGame.new(9, 5.5, 0)
    g.play(g.board.idx(4, 4))
    g.pass_turn()
    t.ok(Array(GoTableTalk.events(g, GoBoard.WHITE)).has("i_pass"),
        "White passed, so White has something to say about passing")
    t.ok(Array(GoTableTalk.events(g, GoBoard.BLACK)).has("you_pass"),
        "and from the other side of the board it is the opponent who stopped")

    g.pass_turn()
    t.ok(Array(GoTableTalk.events(g, GoBoard.WHITE)).has("you_pass"),
        "the second pass belongs to Black, and the tags swap with it")

    # Resignation is not a pass. It ends the game and the scene says so itself.
    var quit_game := GoGame.new(9, 5.5, 0)
    quit_game.play(quit_game.board.idx(4, 4))
    quit_game.resign(GoBoard.WHITE)
    t.eq(GoTableTalk.events(quit_game, GoBoard.WHITE).size(), 0,
        "resigning produces no table talk at all")

    var tomas := TableTalkVoice.load_voice("tomas")
    t.ok(tomas.speak(PackedStringArray(["i_pass"]), 60) != "",
        "and somebody who stops playing says why")


static func _test_voices(t: TestKit) -> void:
    t.section("table talk: every voice loads and stays in character")
    var dir := DirAccess.open("res://data/banter")
    t.ok(dir != null, "there is a banter directory")
    if dir == null:
        return
    var files := dir.get_files()
    t.ok(files.size() >= 10, "and a voice for most of the cast")
    for f in files:
        if not f.ends_with(".json"):
            continue
        var id := f.trim_suffix(".json")
        var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/banter/" + f))
        t.ok(parsed is Dictionary, "%s is valid JSON" % f)
        if not (parsed is Dictionary):
            continue
        var lines: Dictionary = parsed.get("lines", {})
        t.ok(not lines.is_empty(), "%s has something to say" % id)
        for tag in lines:
            t.ok(lines[tag] is Array and not (lines[tag] as Array).is_empty(),
                "%s's '%s' is a non-empty list" % [id, tag])
            for line in lines[tag]:
                t.ok(str(line).strip_edges() != "", "%s has no blank lines" % id)

    # Hana teaches by asking; she does not crow about taking stones. That is
    # expressed by which tags she has lines for, not by special-casing her.
    var hana := TableTalkVoice.load_voice("hana")
    var gloat := hana.speak(PackedStringArray(["i_captured"]), 40)
    t.ok(gloat != "" and not gloat.contains("ahead"), "Hana reacts to an observed capture without guessing the score")


static func _test_cooldown(t: TestKit) -> void:
    t.section("table talk: nobody talks over the board")
    var v := TableTalkVoice.load_voice("pip")
    var first := v.speak(PackedStringArray(["i_captured"]), 20)
    t.ok(first != "", "Pip says something when he takes a stone")
    t.eq(v.speak(PackedStringArray(["i_captured"]), 21), "",
        "and then says nothing for a few moves")
    t.eq(v.speak(PackedStringArray(["i_captured"]), 20 + TableTalkVoice.COOLDOWN), "",
        "and never repeats the same remark twice running")
    t.ok(v.speak(PackedStringArray(["you_captured"]), 20 + TableTalkVoice.COOLDOWN) != "",
        "but a different thing happening is worth a different line")

    # A character with no line for a tag is silent rather than falling back to
    # somebody else's voice for the specific tags they do define.
    var joos := TableTalkVoice.load_voice("joos")
    t.eq(joos.speak(PackedStringArray(["i_edge_early"]), 30), "",
        "Joos has no line about the first line, so Joos says nothing")
