## The save round trip, which had no test at all until M31 -- the one piece of
## the project whose failure costs a playthrough rather than a screenshot.
##
## The suite writes to the real user:// slots, because SaveSystem has no seam
## for a temporary directory and this project has already regretted two test
## hooks in production code. It therefore reads whatever is in the three slots
## first and puts it back at the end: tools/run_game.sh regenerates slot 1
## before every autopilot run, and the files are shared and unnamespaced.
class_name SaveTests
extends RefCounted


## The two autoloads, fetched rather than named.
##
## A bare `GameState.reset()` inside a static function does not compile -- the
## autoload name resolves statically only far enough to read a const, which is
## why `test_data.gd` can say `GameState.BLOCKS` and this cannot say
## `GameState.reset()`. Untyped on purpose: a `var x: Node` annotation would
## turn every call into "Nonexistent function in base 'Node'", which is exactly
## what has been quietly killing `test_data._test_dialogue_branches`.
static var _ss
static var _gs


static func run(t: TestKit) -> void:
    var tree := Engine.get_main_loop() as SceneTree
    _ss = tree.root.get_node("SaveSystem")
    _gs = tree.root.get_node("GameState")
    var backup := _backup()
    _test_round_trip(t)
    _test_slots_are_separate(t)
    _test_slot_info(t)
    _test_corrupt(t)
    _test_counting(t)
    _test_delete(t)
    _test_short_return_position(t)
    _test_borrowing(t)
    _restore(backup)
    _gs.reset()


# --- the borrowed files ------------------------------------------------------

static func _backup() -> Dictionary:
    var b := {}
    for s in range(1, _ss.SLOT_COUNT + 1):
        if _ss.has_save(s):
            b[s] = FileAccess.get_file_as_string(_ss.path_for(s))
    return b


static func _restore(b: Dictionary) -> void:
    for s in range(1, _ss.SLOT_COUNT + 1):
        if b.has(s):
            _write_raw(s, b[s])
        else:
            _ss.delete_save(s)


static func _clear() -> void:
    for s in range(1, _ss.SLOT_COUNT + 1):
        _ss.delete_save(s)


static func _write_raw(slot: int, text: String) -> void:
    var f := FileAccess.open(_ss.path_for(slot), FileAccess.WRITE)
    f.store_string(text)
    f.close()


## A playthrough distinctive enough that a slot which came back as the wrong one
## is obvious rather than plausible.
static func _populate(who: String, rank: String, day: int) -> void:
    _gs.reset()
    _gs.player_name = who
    _gs.set_rank(rank)
    _gs.day = day
    _gs.slots_used = 1
    _gs.time_block = "dusk"
    _gs.current_map = "de_ketel"
    _gs.spawn_point = "from_street"
    _gs.set_flag("carrying_board", true)
    _gs.set_flag("record_kesh_win", 2)
    _gs.inventory.append("old_goban")
    _gs.quests["first_stones"] = {"step": 2, "done": false}
    _gs.match_records.append({"npc_id": "kesh", "player_won": true})
    _gs.return_position = Vector2(7, 9)
    _gs.has_return_position = true
    _gs.playtime = 125.0


## The whole state as one comparable string.
##
## Compared by value rather than by identity because to_dict() hands out the
## live flags and quests dictionaries by reference and reset() clears them; and
## put through JSON both times because JSON has one number type, so a quest step
## that went out as 2 comes back as 2.0 and is not wrong for it.
static func _normal(d: Dictionary) -> String:
    return JSON.stringify(JSON.parse_string(JSON.stringify(d)))


## load_game, called from its own frame.
##
## A GDScript runtime error aborts the function it happens in and hands the
## caller a null, so a crash inside from_dict here costs one assertion instead
## of every assertion after it. Inline, removing the return_position guard made
## this whole test *vanish* rather than fail -- nought failed, and the guard it
## exists to watch was gone.
static func _load(slot: int):
    return _ss.load_game(slot)


# --- the tests ---------------------------------------------------------------

static func _test_round_trip(t: TestKit) -> void:
    t.section("save round trip")
    _clear()
    _populate("Ada", "12k", 6)
    var before := _normal(_gs.to_dict())

    t.ok(_ss.save_game(2), "a slot can be written")
    _gs.reset()
    t.eq(_gs.player_name, "Ro", "reset really did empty the state first")
    t.ok(_ss.load_game(2), "and read back")

    t.eq(_normal(_gs.to_dict()), before, "every field survives the round trip")
    t.eq(_gs.player_name, "Ada", "the name survives")
    t.eq(_gs.rank_label(), "12k", "the rank survives")
    t.eq(_gs.day, 6, "the day survives")
    t.eq(_gs.time_block, "dusk", "the hour survives")
    t.eq(_gs.current_map, "de_ketel", "the map survives")
    t.eq(_gs.spawn_point, "from_street", "the spawn survives")
    t.eq(_gs.get_flag("record_kesh_win"), 2, "a counted flag survives")
    t.ok(_gs.has_flag("carrying_board"), "a set flag survives")
    t.ok(_gs.has_item("old_goban"), "the inventory survives")
    t.eq(_gs.quest_step("first_stones"), 2, "the quest step survives")
    t.eq(_gs.match_records.size(), 1, "the record survives")
    t.eq(_gs.return_position, Vector2(7, 9), "the position in the room survives")
    t.eq(_gs.active_slot, 2, "loading tells the game which slot it now lives in")


static func _test_slots_are_separate(t: TestKit) -> void:
    t.section("slot isolation")
    _clear()
    _populate("Ada", "12k", 6)
    _ss.save_game(1)
    _populate("Bo", "20k", 2)
    _ss.save_game(2)
    _populate("Cass", "4k", 11)
    _ss.save_game(3)

    for pair in [[1, "Ada", 6], [2, "Bo", 2], [3, "Cass", 11]]:
        _gs.reset()
        t.ok(_ss.load_game(pair[0]), "slot %d reads back" % pair[0])
        t.eq(_gs.player_name, pair[1], "slot %d is its own game" % pair[0])
        t.eq(_gs.day, pair[2], "slot %d kept its own day" % pair[0])

    # The failure this is really watching for: a UI that collapses every slot
    # back onto slot 1, which is what the game did before M31.
    _populate("Dee", "1d", 13)
    _ss.save_game(2)
    _gs.reset()
    _ss.load_game(1)
    t.eq(_gs.player_name, "Ada", "writing slot 2 leaves slot 1 alone")


static func _test_slot_info(t: TestKit) -> void:
    t.section("slot info")
    _clear()
    _populate("Ada", "12k", 6)
    _ss.save_game(1)

    var info: Dictionary = _ss.slot_info(1)
    t.eq(info["status"], "ok", "a written slot reads as ok")
    t.eq(info["player_name"], "Ada", "it names the player")
    t.eq(info["rank"], "12k", "it gives the rank as a rank, not a number")
    t.eq(info["day"], 6, "it gives the day")
    t.eq(info["time_block"], "dusk", "it gives the hour")
    t.eq(info["place"], "De Ketel", "it names the place the way the map does")
    t.eq(info["minutes"], 2, "it gives the playtime in minutes")
    t.ok(str(info["saved_at"]) != "", "and when it was written")

    t.eq(_ss.slot_info(2)["status"], "empty", "an unwritten slot reads as empty")
    t.eq(_ss.slot_summary(2), "empty", "and says so in one line")
    t.eq(_ss.slot_summary(1), "Ada  -  12k  -  2 min", "the one-line summary is unchanged")


static func _test_corrupt(t: TestKit) -> void:
    t.section("a slot that cannot be read")
    _clear()
    _populate("Ada", "12k", 6)
    _ss.save_game(1)
    _write_raw(3, "this is not JSON {")

    t.eq(_ss.slot_info(3)["status"], "corrupt", "a broken file reads as corrupt")
    t.eq(_ss.slot_summary(3), "corrupt", "and the summary says so rather than guessing")

    _gs.reset()
    _ss.load_game(1)
    t.ok(not _ss.load_game(3), "loading it refuses")
    # Half-restoring a playthrough from a broken file is worse than refusing.
    t.eq(_gs.player_name, "Ada", "and leaves the running game exactly as it was")
    t.eq(_gs.day, 6, "including the day")

    t.ok(_ss.has_save(3), "a corrupt slot is still a slot")
    t.ok(_ss.delete_save(3), "so it can still be thrown away")


static func _test_counting(t: TestKit) -> void:
    t.section("which slots are taken")
    _clear()
    t.ok(not _ss.any_save(), "nothing saved yet")
    t.eq(_ss.newest_slot(), -1, "and nothing is the newest")
    t.eq(_ss.first_empty_slot(), 1, "the first empty slot is the first slot")

    _populate("Ada", "12k", 6)
    _ss.save_game(1)
    t.ok(_ss.any_save(), "one save counts")
    t.eq(_ss.first_empty_slot(), 2, "the next new game takes the next slot down")

    _ss.save_game(2)
    _ss.save_game(3)
    t.eq(_ss.first_empty_slot(), -1,
        "with all three taken there is no slot to take silently")
    t.ok(_ss.delete_save(2), "delete one")
    t.eq(_ss.first_empty_slot(), 2, "and it is the one on offer again")


static func _test_delete(t: TestKit) -> void:
    t.section("delete")
    _clear()
    _populate("Ada", "12k", 6)
    _ss.save_game(1)
    _populate("Bo", "20k", 2)
    _ss.save_game(2)

    t.ok(_ss.delete_save(1), "deleting a slot reports that it did something")
    t.ok(not _ss.has_save(1), "the file is gone")
    t.eq(_ss.slot_info(1)["status"], "empty", "and the slot reads as empty")

    t.ok(not _ss.delete_save(1), "deleting an empty slot reports that it did not")

    t.ok(_ss.has_save(2), "the other slot is untouched")
    _gs.reset()
    t.ok(_ss.load_game(2), "and still loads")
    t.eq(_gs.player_name, "Bo", "as itself")


static func _test_short_return_position(t: TestKit) -> void:
    t.section("a save written wrong")
    _clear()
    # A one-element return_position used to crash from_dict on rp[1], which
    # only became reachable when the player could aim the loader at any slot.
    _write_raw(1, JSON.stringify({
        "version": _ss.SAVE_VERSION,
        "player_name": "Eze",
        "return_position": [4],
        # Read *after* the position, and that is the whole point of them: an
        # out-of-bounds read does not return a wrong answer, it abandons
        # from_dict where it stands. Assert only on the fields written before
        # the bad line and the guarded and unguarded versions are identical.
        "has_return_position": true,
        "playtime": 99.0,
    }))
    _gs.reset()
    var loaded = _load(1)
    t.ok(loaded == true, "a save with a malformed position still loads")
    t.eq(_gs.player_name, "Eze", "with the fields it does have")
    t.eq(_gs.return_position, Vector2.ZERO, "and the position falls back to nothing")
    t.ok(_gs.has_return_position, "from_dict carries on past it rather than stopping there")
    t.eq(_gs.playtime, 99.0, "so the fields written after it are read as well")
    t.eq(_gs.current_map, _gs.DEFAULT_MAP, "missing fields take their defaults")


## Giving something back.
##
## `give_item` shipped in M6 with no opposite, so until M32 a borrowed object
## could only ever accumulate: Nadia's "thank you for bringing it back" would
## have played with the book still in the player's inventory, and the graph
## branch that reads `has_item` would have gone on saying she wanted it.
static func _test_borrowing(t: TestKit) -> void:
    t.section("borrowing")
    _gs.reset()
    var lost: Array = []
    var bus := (Engine.get_main_loop() as SceneTree).root.get_node("EventBus")
    var listener := func(item_id: String) -> void: lost.append(item_id)
    bus.item_lost.connect(listener)

    t.ok(not _gs.take_item("joseki_book"), "taking what nobody holds does nothing")
    t.eq(lost.size(), 0, "and says nothing about it")

    _gs.give_item("joseki_book", "Nadia's joseki book")
    t.ok(_gs.has_item("joseki_book"), "lent")
    t.ok(_gs.take_item("joseki_book"), "and handed back")
    t.ok(not _gs.has_item("joseki_book"), "so it is no longer carried")
    t.eq(lost, ["joseki_book"], "the bus is told exactly once")

    # The bug this guards is the one M31 found in from_dict: a field written
    # before the interesting line looks identical whether the line ran or not.
    _gs.give_item("old_goban")
    _gs.take_item("joseki_book")
    t.ok(_ss.save_game(2), "a save after giving something back")
    _gs.give_item("joseki_book")
    t.ok(_ss.load_game(2), "and read back")
    t.ok(not _gs.has_item("joseki_book"), "the returned item does not come back with it")
    t.ok(_gs.has_item("old_goban"), "and what is still carried does")

    bus.item_lost.disconnect(listener)
    _gs.reset()
