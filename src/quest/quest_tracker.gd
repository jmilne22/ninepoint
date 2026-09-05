## Watches the event bus and walks quests forward. Autoloaded as `Quests`.
extends Node

const DIR := "res://data/quests/"

var quests: Dictionary = {}          ## id -> QuestData


func _ready() -> void:
    _load_all()
    EventBus.flag_changed.connect(func(key, _v): _advance_on({"type": "flag", "key": key}))
    EventBus.dialogue_finished.connect(func(npc): _advance_on({"type": "talk", "npc": npc}))
    EventBus.match_finished.connect(func(r: MatchResult): _advance_on(
        {"type": "match", "context": r.context_id, "won": r.player_won}))
    EventBus.puzzle_finished.connect(func(pid, solved): _advance_on(
        {"type": "puzzle", "id": pid, "solved": solved}))
    EventBus.lesson_finished.connect(func(lid, done): _advance_on(
        {"type": "lesson", "id": lid, "completed": done}))
    EventBus.map_changed.connect(func(m, _s): _advance_on({"type": "enter_map", "map": m}))
    EventBus.quest_started.connect(start)
    EventBus.game_loaded.connect(func(_slot): _reconcile_all())


func _load_all() -> void:
    var d := DirAccess.open(DIR)
    if d == null:
        return
    for f in d.get_files():
        var name := f.trim_suffix(".remap")
        if not name.ends_with(".tres"):
            continue
        var res = ResourceLoader.load(DIR + name)
        if res is QuestData:
            quests[str(res.id)] = res


func start(quest_id: String) -> void:
    if not quests.has(quest_id):
        push_warning("Quests: unknown quest '%s'" % quest_id)
        return
    if GameState.quest_step(quest_id) >= 0:
        return
    GameState.set_quest(quest_id, 0, false)
    var q: QuestData = quests[quest_id]
    EventBus.quest_advanced.emit(quest_id, 0, q.journal_for(0))
    _reconcile(quest_id, q)


func journal_line(quest_id: String) -> String:
    if not quests.has(quest_id):
        return ""
    var q: QuestData = quests[quest_id]
    if GameState.quest_done(quest_id):
        return "%s -- complete" % q.title
    return q.journal_for(GameState.quest_step(quest_id))


## Started and unfinished, **in the order they were started**.
##
## Deliberately walks `GameState.quests` rather than `quests`: the latter is
## whatever order DirAccess handed the .tres files back in, so the journal was
## picking what to display by filename. `page_forty` starts days after
## `enrolment` and sorts after it either way, so a quest taken on later than
## another was invisible for as long as the older one ran. GameState's dictionary
## is insertion-ordered and is saved and reloaded in that order, so this survives
## a save; the tracker's own dictionary never could.
func active_quest_ids() -> Array:
    var out := []
    for qid in GameState.quests.keys():
        if quests.has(qid) and not GameState.quest_done(qid) \
                and GameState.quest_step(qid) >= 0:
            out.append(qid)
    return out


## The one the journal shows: the last quest started that is still running.
##
## There is one line of journal and the thing you took on most recently is the
## thing you are doing. It lives here rather than in the Hud so that it can be
## tested -- the Hud has no suite, and this was a real bug found by opening a
## screenshot.
func journal_quest_id() -> String:
    var active := active_quest_ids()
    return "" if active.is_empty() else str(active[active.size() - 1])


func _advance_on(event: Dictionary) -> void:
    _reconcile_opening()
    _reconcile_events()
    for quest_id in quests.keys():
        var step := GameState.quest_step(quest_id)
        if step < 0 or GameState.quest_done(quest_id):
            continue
        var q: QuestData = quests[quest_id]
        if step >= q.steps.size():
            continue
        var cond: Dictionary = q.steps[step].get("advance_on", {})
        if _matches(cond, event):
            _advance(quest_id, q)


func _matches(cond: Dictionary, event: Dictionary) -> bool:
    if cond.is_empty() or str(cond.get("type", "")) != str(event.get("type", "")):
        return false
    match str(cond["type"]):
        "flag":
            return str(cond.get("key", "")) == str(event.get("key", "")) \
                and GameState.has_flag(str(cond.get("key", "")))
        "talk":
            return str(cond.get("npc", "")) == str(event.get("npc", ""))
        "match":
            if str(cond.get("context", "")) != str(event.get("context", "")):
                return false
            if cond.has("won"):
                return bool(cond["won"]) == bool(event.get("won", false))
            return true
        "puzzle":
            return str(cond.get("id", "")) == str(event.get("id", "")) \
                and bool(event.get("solved", false))
        "lesson":
            return str(cond.get("id", "")) == str(event.get("id", "")) \
                and bool(event.get("completed", false))
        "enter_map":
            return str(cond.get("map", "")) == str(event.get("map", ""))
    return false


func _advance(quest_id: String, q: QuestData) -> void:
    _advance_one(quest_id, q)
    _reconcile(quest_id, q)


func _advance_one(quest_id: String, q: QuestData) -> void:
    var next := GameState.quest_step(quest_id) + 1
    if next >= q.steps.size():
        GameState.set_quest(quest_id, q.steps.size() - 1, true)
        EventBus.quest_completed.emit(quest_id)
        EventBus.toast.emit("Quest complete: %s" % q.title)
    else:
        GameState.set_quest(quest_id, next, false)
        EventBus.quest_advanced.emit(quest_id, next, q.journal_for(next))
        EventBus.toast.emit(q.journal_for(next))


## A player can do something before its quest step becomes current. Events only
## happen once, but the durable facts behind them live in GameState, so check
## those facts whenever a new step opens rather than leaving the journal stale.
func _reconcile(quest_id: String, q: QuestData) -> void:
    while not GameState.quest_done(quest_id):
        var step := GameState.quest_step(quest_id)
        if step < 0 or step >= q.steps.size():
            return
        var cond: Dictionary = q.steps[step].get("advance_on", {})
        if not _is_already_satisfied(cond):
            return
        _advance_one(quest_id, q)


## Loading an older save can resume on a step whose prerequisite was completed
## before that step opened. Reconcile every live quest once its saved state is
## in GameState, so existing stuck journals repair themselves on Continue.
func _reconcile_all() -> void:
    _reconcile_opening()
    _reconcile_events()
    for quest_id in quests.keys():
        if GameState.quest_step(quest_id) < 0 or GameState.quest_done(quest_id):
            continue
        _reconcile(quest_id, quests[quest_id])


## Only conditions represented in a save can be recovered. A conversation is
## deliberately event-only: the game records no general fact that it happened.
func _is_already_satisfied(cond: Dictionary) -> bool:
    match str(cond.get("type", "")):
        "flag":
            return GameState.has_flag(str(cond.get("key", "")))
        "lesson":
            return GameState.has_flag("lesson_%s_done" % str(cond.get("id", "")))
        "puzzle":
            return GameState.has_flag("%s_solved" % str(cond.get("id", "")))
        "match":
            for record in GameState.match_records:
                if not (record is Dictionary):
                    continue
                if str(record.get("context_id", "")) != str(cond.get("context", "")):
                    continue
                if not cond.has("won") or bool(record.get("player_won", false)) == bool(cond["won"]):
                    return true
        "enter_map":
            return GameState.current_map == str(cond.get("map", ""))
    return false


## Old steps 1-3 already represent arriving at the club, preparing to play and
## finishing practice. Preserve that progress; durable facts can advance it.
func _reconcile_opening() -> void:
    if GameState.quest_step("first_stones") < 0 or GameState.quest_done("first_stones"):
        return
    var step := maxi(0, GameState.quest_step("first_stones"))
    var complete := GameState.has_flag("ranked_by_club") or GameState.has_flag("kesh_match_done")
    if complete:
        step = 3
    elif GameState.has_flag("wren_match_done"):
        step = 3
    elif GameState.has_flag("knows_the_rules") or GameState.has_flag("said_knows_the_rules"):
        step = maxi(step, 2)
    elif GameState.has_flag("match_pip_capture_done"):
        step = maxi(step, 1)
    for record in GameState.match_records:
        match str(record.get("context_id", "")):
            "kesh_first":
                complete = true
                step = 3
            "wren_first": step = maxi(step, 3)
            "pip_capture": step = maxi(step, 1)
    var changed := step != GameState.quest_step("first_stones") or complete
    GameState.set_quest("first_stones", step, complete)
    if changed:
        if complete:
            EventBus.quest_completed.emit("first_stones")
        elif quests.has("first_stones"):
            EventBus.quest_advanced.emit("first_stones", step, quests["first_stones"].journal_for(step))


## Completing an event supersedes preparatory steps a player chose to postpone.
func _reconcile_events() -> void:
    for pair in [["beginner_cup", "cup_finished"], ["qualifying_exam", "exam_finished"]]:
        var id: String = pair[0]
        if GameState.quest_step(id) >= 0 and not GameState.quest_done(id) and GameState.has_flag(pair[1]):
            GameState.set_quest(id, quests[id].steps.size() - 1, true)
            EventBus.quest_completed.emit(id)
