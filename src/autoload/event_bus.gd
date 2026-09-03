## Global signal hub. Holds no state; systems talk through here rather than
## reaching across the scene tree. See ARCHITECTURE.md section 3.
extends Node

# --- dialogue
signal dialogue_started(npc_id: String)
signal dialogue_finished(npc_id: String)

# --- world
signal map_changed(map_path: String, spawn_name: String)
signal interaction_available(text: String)
signal interaction_cleared()
signal toast(text: String)
## The hour changed, because the day was spent down to it. Ambient listens;
## nothing reaches into the scene tree to repaint the light.
signal time_block_changed(block: String)
## A new day of term. The Cup is CUP_DAY, and this is what counts towards it.
signal day_changed(day: int)
signal weather_changed(raining: bool)

# --- progression
signal flag_changed(key: String, value: Variant)
signal quest_started(quest_id: String)
signal quest_advanced(quest_id: String, step: int, journal: String)
signal quest_completed(quest_id: String)
signal rank_changed(old_label: String, new_label: String)
signal item_gained(item_id: String, item_name: String)

# --- go
signal match_started(context_id: String)
signal match_finished(result: MatchResult)
signal puzzle_finished(puzzle_id: String, solved: bool)
signal lesson_finished(lesson_id: String, completed: bool)

# --- save
signal game_saved(slot: int)
signal game_loaded(slot: int)
