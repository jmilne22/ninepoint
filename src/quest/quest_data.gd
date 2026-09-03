## A quest as data: an ordered list of steps, each with a journal line and the
## condition that completes it.
class_name QuestData
extends Resource

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var summary: String = ""
## Each entry: {"journal": String, "advance_on": {"type": ..., ...}}
## Types: flag(key), talk(npc), match(context), puzzle(id), enter_map(map)
@export var steps: Array[Dictionary] = []


func step_count() -> int:
    return steps.size()


func journal_for(step: int) -> String:
    if step < 0 or step >= steps.size():
        return ""
    return str(steps[step].get("journal", ""))
