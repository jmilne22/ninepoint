## All persistent player progress. No scene tree access, no UI knowledge.
extends Node

## The game opens in the attic, because the first thing the story does is
## point at the board the last tenant left on the desk.
const DEFAULT_MAP := "attic"

var player_name: String = "Ro"
## Rank as a GoRank strength value; -1 means unranked.
var rank_strength: int = -1

var flags: Dictionary = {}
var quests: Dictionary = {}             ## quest_id -> {"step": int, "done": bool}
var inventory: Array[String] = []
var match_records: Array = []

var current_map: String = DEFAULT_MAP
var spawn_point: String = "start"
## Set when a match interrupts the world, so the player returns to the same spot.
var return_position: Vector2 = Vector2.ZERO
var has_return_position: bool = false

var playtime: float = 0.0
var started: bool = false

## Which save slot this playthrough belongs to. Deliberately not serialised: the
## file's path is its own identity, and a slot number written inside the file
## would disagree with it the moment somebody copied one.
var active_slot: int = 1


func _process(delta: float) -> void:
    if started:
        playtime += delta


func reset() -> void:
    player_name = "Ro"
    rank_strength = -1
    flags.clear()
    quests.clear()
    inventory.clear()
    match_records.clear()
    current_map = DEFAULT_MAP
    spawn_point = "start"
    return_position = Vector2.ZERO
    has_return_position = false
    playtime = 0.0
    started = true
    # active_slot is left alone on purpose: from_dict() calls reset() first, so
    # clearing it here would wipe the slot the loader has just chosen.


# --- flags -------------------------------------------------------------------

func set_flag(key: String, value: Variant = true) -> void:
    if flags.get(key) == value:
        return
    flags[key] = value
    EventBus.flag_changed.emit(key, value)


func has_flag(key: String) -> bool:
    return bool(flags.get(key, false))


func get_flag(key: String, fallback: Variant = false) -> Variant:
    return flags.get(key, fallback)


func bump_flag(key: String, delta: int = 1) -> int:
    var v := int(flags.get(key, 0)) + delta
    set_flag(key, v)
    return v


# --- rank --------------------------------------------------------------------

func rank_label() -> String:
    return GoRank.to_string_rank(rank_strength)


func set_rank(label: String) -> void:
    var old := rank_label()
    rank_strength = GoRank.from_string(label)
    EventBus.rank_changed.emit(old, rank_label())


func is_ranked() -> bool:
    return rank_strength >= 0


# --- inventory ---------------------------------------------------------------

func give_item(item_id: String, display_name: String = "") -> void:
    if inventory.has(item_id):
        return
    inventory.append(item_id)
    EventBus.item_gained.emit(item_id, display_name if display_name != "" else item_id)


## Hand something back. Borrowing is only borrowing if the object can leave
## again, and until M32 nothing in the game could take one: a quest that ends
## "return the book" would have ended with the book still in your pocket.
func take_item(item_id: String) -> bool:
    if not inventory.has(item_id):
        return false
    inventory.erase(item_id)
    EventBus.item_lost.emit(item_id)
    return true


func has_item(item_id: String) -> bool:
    return inventory.has(item_id)


# --- quests ------------------------------------------------------------------

func quest_step(quest_id: String) -> int:
    var q: Dictionary = quests.get(quest_id, {})
    return int(q.get("step", -1))


func quest_done(quest_id: String) -> bool:
    var q: Dictionary = quests.get(quest_id, {})
    return bool(q.get("done", false))


func set_quest(quest_id: String, step: int, done: bool = false) -> void:
    quests[quest_id] = {"step": step, "done": done}


# --- match history -----------------------------------------------------------

func record_match(result: MatchResult) -> void:
    match_records.append(result.to_dict())
    # Flags dialogue and quests can branch on without knowing about MatchResult.
    if result.npc_id != "":
        bump_flag("record_%s_%s" % [result.npc_id, "win" if result.player_won else "loss"], 1)
        set_flag("%s_match_done" % result.npc_id, true)
    if result.context_id != "":
        set_flag("match_%s_done" % result.context_id, true)
    # League games are the Institute's whole progression system, so the fact of
    # having won one at all is worth a flag of its own.
    if result.player_won and result.context_id.begins_with("league_"):
        set_flag("won_a_league_game", true)
    if result.context_id.begins_with(CupDraw.CONTEXT_PREFIX):
        bump_flag("cup_rounds_played", 1)
    if result.context_id.begins_with(Exam.CONTEXT_PREFIX):
        bump_flag("exam_rounds_played", 1)
    _recompute_rank()


## Rank follows the record, and is never set by anything else once there are
## enough games to say. Below GoRating.PROVISIONAL_GAMES it returns -1 and the
## provisional rank the club gave you stands -- which is why Kesh's 22k survives
## the two games after she hands it over.
func _recompute_rank() -> void:
    var derived := GoRating.performance(match_records)
    if derived < 0 or derived == rank_strength:
        return
    var was := rank_strength
    var old_label := rank_label()
    rank_strength = derived
    EventBus.rank_changed.emit(old_label, rank_label())
    if was < 0:
        EventBus.toast.emit("The club has you at %s." % rank_label())
    elif derived > was:
        EventBus.toast.emit("Rank up: %s." % rank_label())
    else:
        EventBus.toast.emit("Rank: %s." % rank_label())


func head_to_head(npc_id: String) -> Dictionary:
    return {
        "wins": int(flags.get("record_%s_win" % npc_id, 0)),
        "losses": int(flags.get("record_%s_loss" % npc_id, 0)),
    }


# --- serialisation -----------------------------------------------------------

func to_dict() -> Dictionary:
    return {
        "version": 2,
        "player_name": player_name,
        "rank_strength": rank_strength,
        "flags": flags,
        "quests": quests,
        "inventory": inventory,
        "match_records": match_records,
        "current_map": current_map,
        "spawn_point": spawn_point,
        "return_position": [return_position.x, return_position.y],
        "has_return_position": has_return_position,
        "playtime": playtime,
    }


func from_dict(d: Dictionary) -> void:
    reset()
    player_name = str(d.get("player_name", "Ro"))
    rank_strength = int(d.get("rank_strength", -1))
    flags = d.get("flags", {})
    quests = d.get("quests", {})
    inventory.clear()
    for i in d.get("inventory", []):
        inventory.append(str(i))
    match_records = d.get("match_records", [])
    current_map = str(d.get("current_map", DEFAULT_MAP))
    spawn_point = str(d.get("spawn_point", "start"))
    # Indexed unguarded until M31: a short or malformed array crashed the load,
    # which now matters because the player can point the loader at any slot.
    var rp: Array = d.get("return_position", [0, 0])
    return_position = Vector2(float(rp[0]), float(rp[1])) if rp.size() >= 2 else Vector2.ZERO
    has_return_position = bool(d.get("has_return_position", false))
    playtime = float(d.get("playtime", 0.0))
    started = true
