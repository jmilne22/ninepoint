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
    var next := GameState.quest_step(quest_id) + 1
    if next >= q.steps.size():
        GameState.set_quest(quest_id, q.steps.size() - 1, true)
        EventBus.quest_completed.emit(quest_id)
        EventBus.toast.emit("Quest complete: %s" % q.title)
    else:
        GameState.set_quest(quest_id, next, false)
        EventBus.quest_advanced.emit(quest_id, next, q.journal_for(next))
        EventBus.toast.emit(q.journal_for(next))
