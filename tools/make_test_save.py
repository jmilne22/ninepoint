"""Writes a save file in a chosen state, so branches that are hard to reach by
playing (beating the rival, for instance) can still be exercised in the real game.

    python3 tools/make_test_save.py beat_kesh
"""
import json
import os
import sys

STATES = {
    # Act 1 complete and invited east, for testing the Institute directly.
    "invited": {
        "rank_strength": 8,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "pip_taught_capture": True, "match_pip_capture_done": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "record_kesh_loss": 1,
            "hana_offered_puzzle": True, "capture_1_solved": True,
            "club_member": True, "invited_to_institute": True,
            "knows_the_rules": True, "lesson_capture_done": True,
            "ranked_by_club": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 0, "done": False}},
        "summary": "White wins by 12.5",
        "won": False,
        "map": "ketelsteeg",
        "spawn": "from_ketel",
    },
    # Enrolled, with enough rated games behind the rank that GoRating owns it.
    # Use this to watch handicap stones appear and then thin out as the record
    # improves -- the thing no amount of unit testing will show you.
    "league_ready": {
        "rank_strength": 8,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "pip_taught_capture": True, "match_pip_capture_done": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "record_kesh_loss": 3,
            "hana_offered_puzzle": True, "capture_1_solved": True,
            "club_member": True, "invited_to_institute": True,
            "knows_the_rules": True, "lesson_capture_done": True,
            "enrolled": True, "read_league_board": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 3, "done": False}},
        "summary": "White wins by 12.5",
        "won": False,
        "map": "academy_study",
        "spawn": "from_hall",
        "records": [
            {"context_id": "kesh_first", "npc_id": "kesh", "player_won": False,
             "margin": 12.5, "by_resignation": False, "board_size": 9,
             "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 48,
             "unrated": False, "opponent_strength": 18,
             "summary": "White wins by 12.5"},
            {"context_id": "league_kesh", "npc_id": "kesh", "player_won": False,
             "margin": 8.5, "by_resignation": False, "board_size": 9,
             "handicap": 9, "handicap_taken": 9, "komi": 0.5, "move_count": 60,
             "unrated": False, "opponent_strength": 18,
             "summary": "White wins by 8.5"},
            {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
             "margin": 3.5, "by_resignation": False, "board_size": 9,
             "handicap": 9, "handicap_taken": 9, "komi": 0.5, "move_count": 72,
             "unrated": False, "opponent_strength": 18,
             "summary": "Black wins by 3.5"},
            {"context_id": "league_ilse", "npc_id": "ilse", "player_won": True,
             "margin": 1.5, "by_resignation": False, "board_size": 9,
             "handicap": 9, "handicap_taken": 9, "komi": 0.5, "move_count": 80,
             "unrated": False, "opponent_strength": 21,
             "summary": "Black wins by 1.5"},
        ],
    },
    # Ranked by the club and standing on Ketelsteeg, which is everything the
    # southbound tram and the Cup's entry desk ask for.
    "cup_ready": {
        "rank_strength": 8,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "pip_taught_capture": True, "match_pip_capture_done": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "record_kesh_loss": 1,
            "ranked_by_club": True, "knows_the_rules": True,
            "hana_offered_puzzle": True, "capture_1_solved": True,
            "club_member": True, "invited_to_institute": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 0, "done": False}},
        "summary": "White wins by 12.5",
        "won": False,
        "map": "ketelsteeg",
        "spawn": "from_ketel",
    },
    # Day 42, entered, standing in the Bondszaal: the Cup about to start.
    "cup_day": {
        "rank_strength": 8,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "record_kesh_loss": 1,
            "ranked_by_club": True, "knows_the_rules": True,
            "club_member": True, "invited_to_institute": True,
            "cup_entered": True, "cup_started": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "beginner_cup": {"step": 1, "done": False}},
        "summary": "White wins by 12.5",
        "won": False,
        "map": "bondszaal",
        "spawn": "from_tram",
        "day": 42,
    },
    "beat_kesh": {
        "rank_strength": 8,               # 22 kyu
        "flags": {
            "intro_seen": True, "wren_told_about_cup": True,
            "kesh_match_done": True, "match_kesh_first_done": True,
            "record_kesh_win": 1,
        },
        "quests": {"first_stones": {"step": 3, "done": False}},
        "summary": "Black wins by 4.5",
        "won": True,
    },
    "lost_to_kesh": {
        "rank_strength": 8,
        "flags": {
            "intro_seen": True, "wren_told_about_cup": True,
            "kesh_match_done": True, "match_kesh_first_done": True,
            "record_kesh_loss": 1,
        },
        "quests": {"first_stones": {"step": 3, "done": False}},
        "summary": "White wins by 12.5",
        "won": False,
    },
}


def build(name, slot=1):
    st = STATES[name]
    save = {
        "version": 1,
        "saved_at": "2026-09-03T12:00:00",
        "player_name": "Ro",
        "rank_strength": st["rank_strength"],
        "flags": st["flags"],
        "quests": st["quests"],
        "inventory": [],
        "match_records": st.get("records", [{
            "context_id": "kesh_first", "npc_id": "kesh", "player_won": st["won"],
            "margin": 4.5, "by_resignation": False, "board_size": 9, "handicap": 0,
            "handicap_taken": 0, "komi": 5.5, "move_count": 48, "unrated": False,
            "opponent_strength": 18, "summary": st["summary"],
        }]),
        "day": st.get("day", 1),
        "slots_used": 0,
        "time_block": "afternoon",
        "current_map": st.get("map", "de_ketel"),
        "spawn_point": st.get("spawn", "from_street"),
        "return_position": [0, 0],
        "has_return_position": False,
        "playtime": 640.0,
    }
    d = os.path.expanduser("~/.local/share/godot/app_userdata/Ninepoint")
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, "save_%d.json" % slot)
    json.dump(save, open(path, "w"), indent=2)
    return path


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "beat_kesh"
    print(build(which))
