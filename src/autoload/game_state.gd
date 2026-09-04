## All persistent player progress. No scene tree access, no UI knowledge.
extends Node

## The game opens in the attic, because the first thing the story does is
## point at the board the last tenant left on the desk.
const DEFAULT_MAP := "attic"

var player_name: String = "Ro"
## Rank as a GoRank strength value; -1 means unranked.
var rank_strength: int = -1

## The term is a fortnight, and the Cup is at the end of it. Wren says so on the
## day you arrive.
##
## It was six weeks until M26, which was four times the content that exists to
## fill it -- three classes and a first game against each of eight reachable
## opponents is eleven slots, call it four days at three slots a day. A term the
## player sleeps through in one keypress is a term that has overstated itself, so
## the number came down to meet the game rather than the other way round. Widen
## it again when there is something to widen it for; every day count in the game
## is derived from these two constants, so it is this line and its neighbour.
const CUP_DAY := 14

## The Instituut's qualifying exam, in the last week of term. It sits before the
## Cup rather than after it because the two belong to the two Go cultures the
## city is built on: the exam is the Instituut deciding who it keeps, and the Cup
## is the open city event you are free to enter afterwards whatever it decided.
## Swapping them is this constant and nothing else.
const EXAM_DAY := 10

## What a day holds. Three is enough that choosing between a league game and a
## class costs something, without making an afternoon feel like paperwork.
const SLOTS_PER_DAY := 3

## The hours a day passes through, one per slot spent. The last one is where a
## day ends up once it is spent, which is why there are four of them and three
## slots: you arrive at night rather than spending a slot to get there.
const BLOCKS := ["morning", "afternoon", "dusk", "night"]

## The week the term runs on. A fortnight is exactly two of these, so the period
## needs no constant of its own to justify it -- CUP_DAY is fourteen and always
## was. Day 1 is a Monday.
##
## This is the other half of the calendar. M26 built the clock and stopped: the
## hour decided who was in the room and the day decided nothing, so day 3 and day
## 8 were the same day with a different number on the HUD. `weekday()` is what a
## map entry's "days" key is matched against, exactly as `time_block` is what its
## "blocks" key is matched against.
const WEEKDAYS := ["monday", "tuesday", "wednesday", "thursday",
                   "friday", "saturday", "sunday"]

## Which night the back room at De Ketel fills up. Wednesday because the Cup and
## the exam both land midweek and a club night the term keeps colliding with is a
## club night nobody attends.
const CLUB_NIGHT := "wednesday"

## Which day of term it is. Sleeping is the only thing that advances it.
var day: int = 1
## How much of today is gone. `time_block` is derived from this and never set
## independently -- the light in the street is a function of what you have done.
var slots_used: int = 0

var flags: Dictionary = {}
var quests: Dictionary = {}             ## quest_id -> {"step": int, "done": bool}
var inventory: Array[String] = []
var match_records: Array = []
var time_block: String = "afternoon"

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
    day = 1
    slots_used = 0
    time_block = "afternoon"
    current_map = DEFAULT_MAP
    spawn_point = "start"
    return_position = Vector2.ZERO
    has_return_position = false
    playtime = 0.0
    started = true
    # active_slot is left alone on purpose: from_dict() calls reset() first, so
    # clearing it here would wipe the slot the loader has just chosen.


# --- the calendar ------------------------------------------------------------

## True while there is still something left of today. A day that is spent is not
## a failure state: it is the reason tomorrow is worth having.
func can_act() -> bool:
    return slots_used < SLOTS_PER_DAY


## Spends one of today's hours. Rated games and classes cost one; lessons,
## puzzles and the unrated games in the park and under the arches are free,
## which is the distinction Go culture already draws and the game inherits.
func spend_slot() -> void:
    slots_used += 1
    _sync_time_block()


## Sleeping is the only way the day advances, so the player is never punished
## for sitting and thinking about a position.
func sleep() -> void:
    day += 1
    slots_used = 0
    _sync_time_block()
    if day >= EXAM_DAY and has_flag("exam_entered"):
        set_flag("exam_started", true)
    if day >= CUP_DAY and has_flag("cup_entered"):
        set_flag("cup_started", true)
    EventBus.day_changed.emit(day)


## Derived from `day` and stored nowhere, like every other progression number in
## this game -- a cached copy would start meaning whatever next wrote to it,
## which is precisely how `knows_the_rules` went wrong in M27.
func weekday() -> String:
    return WEEKDAYS[(day - 1) % WEEKDAYS.size()]


## True on the night the room fills. The hour is not part of it: who is standing
## where is the map's business, and this only answers "which day".
func is_club_night() -> bool:
    return weekday() == CLUB_NIGHT


## How many sleeps until the next club night, 0 when it is tonight. The
## noticeboard and the HUD both want to say it and neither should do the
## modular arithmetic itself.
func days_until_club_night() -> int:
    var here := (day - 1) % WEEKDAYS.size()
    var there := WEEKDAYS.find(CLUB_NIGHT)
    return (there - here + WEEKDAYS.size()) % WEEKDAYS.size()


func days_until_cup() -> int:
    return maxi(CUP_DAY - day, 0)


func days_until_exam() -> int:
    return maxi(EXAM_DAY - day, 0)


## The hour follows the day's spending. Nothing else writes `time_block`; every
## atmosphere system in src/rpg/ reads it and this is what finally moves it.
func _sync_time_block() -> void:
    var block: String = BLOCKS[mini(slots_used, BLOCKS.size() - 1)]
    if block == time_block:
        return
    time_block = block
    EventBus.time_block_changed.emit(block)


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
    # A rated game is most of an afternoon. The park and the arches are not, and
    # that difference is the reason unrated games exist in the first place.
    if not result.unrated:
        spend_slot()
    _recompute_rank()
    _note_hooks()


## The hooks at De Ketel move when a game is won -- any game, the arches
## included, which is the whole of their argument with the league board.
##
## The order itself stays derived from the record and is stored nowhere (Rule 5);
## these flags only record that a thing *happened*, so the journal has an event
## to advance on, exactly as `won_a_league_game` does above. Nothing reads them
## as a score, and deleting them all and replaying the record gives them back.
func _note_hooks() -> void:
    var rows := HooksLadder.rows_for(self)
    var place := HooksLadder.position(rows)
    if place == 0:
        return
    if HooksLadder.taken(rows) > 0:
        set_flag("took_a_hook", true)
    if place <= 3:
        set_flag("hooks_top_three", true)
    if place == 1:
        set_flag("hooks_top", true)


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
        "version": 1,
        "player_name": player_name,
        "rank_strength": rank_strength,
        "flags": flags,
        "quests": quests,
        "inventory": inventory,
        "match_records": match_records,
        "day": day,
        "slots_used": slots_used,
        "time_block": time_block,
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
    day = int(d.get("day", 1))
    slots_used = int(d.get("slots_used", 0))
    time_block = str(d.get("time_block", "afternoon"))
    current_map = str(d.get("current_map", DEFAULT_MAP))
    spawn_point = str(d.get("spawn_point", "start"))
    # Indexed unguarded until M31: a short or malformed array crashed the load,
    # which now matters because the player can point the loader at any slot.
    var rp: Array = d.get("return_position", [0, 0])
    return_position = Vector2(float(rp[0]), float(rp[1])) if rp.size() >= 2 else Vector2.ZERO
    has_return_position = bool(d.get("has_return_position", false))
    playtime = float(d.get("playtime", 0.0))
    started = true
