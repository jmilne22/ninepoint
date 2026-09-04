"""Writes a save file in a chosen state, so branches that are hard to reach by
playing (beating the rival, for instance) can still be exercised in the real game.

    python3 tools/make_test_save.py beat_kesh
    python3 tools/make_test_save.py beat_kesh 2 Ada 42   # slot, name, minutes
    python3 tools/make_test_save.py --script tools/autopilot/saves.json

The last form builds whatever the script's own {"save": ...} entry declares --
one preset, or a slot-by-slot set for a screen that lists more than one -- and
clears the slots it does not name. A screen that reads all three slots inherits
the last run's leftovers otherwise, which is the same fault the per-script save
was introduced to fix.
"""
import json
import os
import re
import sys
import time

GAME_STATE = os.path.join(os.path.dirname(__file__), "..", "src", "autoload", "game_state.gd")
GO_RANK = os.path.join(os.path.dirname(__file__), "..", "src", "go", "go_rank.gd")
SAVE_SYSTEM = os.path.join(os.path.dirname(__file__), "..", "src", "autoload", "save_system.gd")


def _const(name, path=GAME_STATE):
    """Read an int constant out of a script rather than repeating it here."""
    src = open(path, encoding="utf-8").read()
    m = re.search(r"^const %s\s*:=\s*(\d+)" % re.escape(name), src, re.M)
    if not m:
        raise SystemExit("make_test_save: no `const %s` in %s" % (name, path))
    return int(m.group(1))


def _rank_tables():
    """`ranks_per_stone` and `max_handicap`, read out of GoRank rather than retyped.

    Same reason as `_const` above, and the fault it prevents is worse: these
    fixtures carried `handicap: 9` on a 9x9 board, which `max_handicap(9) = 5`
    says is a position no game could ever have dealt. It errored nowhere, and a
    save built from an impossible record screenshots exactly as confidently as
    one built from a real one.
    """
    src = open(GO_RANK, encoding="utf-8").read()
    try:
        body = src[src.index("static func ranks_per_stone"):src.index("static func max_handicap")]
    except ValueError:
        raise SystemExit("make_test_save: GoRank has no ranks_per_stone/max_handicap")
    steps = [(int(a), int(b)) for a, b in
             re.findall(r"if board_size <= (\d+):\s*\n\s*return (\d+)", body)]
    tail = re.findall(r"^\s*return (\d+)\s*$", body, re.M)
    cap = re.search(r"return (\d+) if board_size <= (\d+) else (\d+)", src)
    if not steps or not tail or not cap:
        raise SystemExit("make_test_save: cannot read the rank tables out of %s" % GO_RANK)
    return steps, int(tail[-1]), (int(cap.group(2)), int(cap.group(1)), int(cap.group(3)))


_RPS_STEPS, _RPS_TAIL, _CAP = _rank_tables()


def _ranks_per_stone(board):
    for limit, value in _RPS_STEPS:
        if board <= limit:
            return value
    return _RPS_TAIL


def _max_handicap(board):
    boundary, below, above = _CAP
    return below if board <= boundary else above


def _handicap_fields(player_strength, opponent_strength, board=9):
    """The stones GoRank.handicap_between would actually have dealt, as record fields.

    The player is the weaker side in every fixture that uses this, so the stones
    they took are all the stones on the board. roundf() rounds half away from
    zero; Python's round() does not, hence the floor.
    """
    diff = opponent_strength - player_strength
    if diff <= 0:
        return {"handicap": 0, "handicap_taken": 0, "komi": 5.5 if diff == 0 else 0.5}
    stones = int((float(diff) / _ranks_per_stone(board)) + 0.5)
    if stones <= 1:
        return {"handicap": 0, "handicap_taken": 0, "komi": 0.5}
    stones = min(stones, _max_handicap(board))
    return {"handicap": stones, "handicap_taken": stones, "komi": 0.5}




def _rated_wins(n):
    """A record with `n` rated wins in it, against the study hall.

    Written rather than hand-listed because two presets want the same thing and
    because `rated_wins_at_least` counts these: a preset that says it is past the
    ceiling and carries no games is a save the dialogue conditions disagree with.
    """
    who = ["wren", "pip", "kesh", "ilse", "sunny", "orla"]
    return [{
        "context_id": "league_%s" % who[i % len(who)],
        "npc_id": who[i % len(who)], "player_won": True, "margin": 6.5,
        "by_resignation": False, "board_size": 9, "handicap": 0,
        "handicap_taken": 0, "komi": 5.5, "move_count": 52, "unrated": False,
        "opponent_strength": 12 + i, "summary": "Black wins by 6.5",
    } for i in range(n)]

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
             **_handicap_fields(8, 18), "move_count": 60,
             "unrated": False, "opponent_strength": 18,
             "summary": "White wins by 8.5"},
            {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
             "margin": 3.5, "by_resignation": False, "board_size": 9,
             **_handicap_fields(8, 18), "move_count": 72,
             "unrated": False, "opponent_strength": 18,
             "summary": "Black wins by 3.5"},
            {"context_id": "league_ilse", "npc_id": "ilse", "player_won": True,
             "margin": 1.5, "by_resignation": False, "board_size": 9,
             **_handicap_fields(8, 21), "move_count": 80,
             "unrated": False, "opponent_strength": 21,
             "summary": "Black wins by 1.5"},
        ],
    },
    # Three rated games won, which is the chapter-2 gate in GAME_DESIGN section
    # 9 and the condition Tomas and Kesh read before either of them mentions a
    # thirteen. In the study hall, in the afternoon, because that is where Kesh
    # is at that hour and the board has to be reachable without a tram ride.
    "thirteen_ready": {
        "rank_strength": 12,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "pip_taught_capture": True, "match_pip_capture_done": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "record_kesh_loss": 1,
            "record_kesh_win": 1, "hana_offered_puzzle": True,
            "capture_1_solved": True, "club_member": True,
            "invited_to_institute": True, "knows_the_rules": True,
            "lesson_capture_done": True, "lesson_liberties_done": True,
            "lesson_self_capture_done": True, "lesson_counting_done": True,
            "tomas_match_done": True, "enrolled": True, "read_league_board": True,
            "ranked_by_club": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 3, "done": False}},
        "summary": "Black wins by 6.5",
        "won": True,
        "map": "academy_study",
        "spawn": "from_hall",
        "records": [
            {"context_id": "kesh_first", "npc_id": "kesh", "player_won": False,
             "margin": 12.5, "by_resignation": False, "board_size": 9,
             "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 48,
             "unrated": False, "opponent_strength": 18,
             "summary": "White wins by 12.5"},
            {"context_id": "tomas_club", "npc_id": "tomas", "player_won": True,
             "margin": 2.5, "by_resignation": False, "board_size": 9,
             **_handicap_fields(12, 22), "move_count": 71,
             "unrated": False, "opponent_strength": 22,
             "summary": "Black wins by 2.5"},
            {"context_id": "league_ilse", "npc_id": "ilse", "player_won": True,
             "margin": 4.5, "by_resignation": False, "board_size": 9,
             **_handicap_fields(12, 21), "move_count": 66,
             "unrated": False, "opponent_strength": 21,
             "summary": "Black wins by 4.5"},
            {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
             "margin": 6.5, "by_resignation": False, "board_size": 9,
             **_handicap_fields(12, 18), "move_count": 74,
             "unrated": False, "opponent_strength": 18,
             "summary": "Black wins by 6.5"},
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
    # Cup day, entered, standing in the Bondszaal: the Cup about to start.
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
    },
    # Past the ceiling and nothing entered: the state the second section exists
    # for. Thirteen kyu is too strong for the beginners' section, which used to
    # be the end of the conversation -- `cup_outgrown` said "I can no longer
    # enter you" and offered nothing. Standing at the federation desk two days
    # out, so Marguerite can be asked.
    "open_ready": {
        "rank_strength": 17,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True}},
        "records": _rated_wins(6),
        "map": "bondszaal",
        "spawn": "from_tram",
    },
    # Under the ceiling and past the three-rated-wins gate: the only state in
    # which both sections are open at once, and therefore the only one in which
    # Marguerite has to be asked rather than consulted. Eighteen kyu.
    "playing_up": {
        "rank_strength": 12,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True}},
        "records": _rated_wins(4),
        "map": "bondszaal",
        "spawn": "from_tram",
    },
    # Past the ceiling, standing in the Instituut hall rather than at the
    # federation: this is where the greeting line fires, and the greeting line is
    # the one that used to end the conversation.
    "outgrown": {
        "rank_strength": 17,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True}},
        "records": _rated_wins(6),
        "map": "academy_hall",
        "spawn": "from_tram",
    },
    # Cup day, entered in the open section, standing in the Bondszaal: four
    # rounds on thirteen lines against the club and the Instituut at once.
    "open_day": {
        "rank_strength": 17,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
            "cup_entered": True, "cup_started": True, "cup_section": "open",
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True},
                   "beginner_cup": {"step": 1, "done": False}},
        "records": _rated_wins(6),
        "map": "bondszaal",
        "spawn": "from_tram",
    },
    # Two days out, enrolled, and third in the lower league on three wins -- inside the
    # four, standing at the federation desk, with nothing entered yet. This is the
    # state the exam gate is actually interesting in: Marguerite can say yes.
    "exam_ready": {
        "rank_strength": 22,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
            "read_league_board": True, "record_kesh_win": 1,
            "record_ilse_win": 1, "record_sunny_win": 1,
            "lesson_openings_done": True, "won_a_league_game": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True}},
        "records": [
        {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 18,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_ilse", "npc_id": "ilse", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 21,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_sunny", "npc_id": "sunny", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 24,
         "summary": "Black wins by 6.5"},
        ],
        "map": "bondszaal",
        "spawn": "from_tram",
    },
    # The same record, on the day itself, entered and started: the paper and then
    # the rounds. Slots are untouched so a round can actually be sat.
    "exam_day": {
        "rank_strength": 22,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
            "read_league_board": True, "record_kesh_win": 1,
            "record_ilse_win": 1, "record_sunny_win": 1,
            "lesson_openings_done": True, "won_a_league_game": True,
            "exam_entered": True, "exam_started": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True},
                   "qualifying_exam": {"step": 1, "done": False}},
        "records": [
        {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 18,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_ilse", "npc_id": "ilse", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 21,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_sunny", "npc_id": "sunny", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 24,
         "summary": "Black wins by 6.5"},
        ],
        "map": "bondszaal",
        "spawn": "from_tram",
    },
    # One win and three losses: sixth of seven, outside the four, and told so.
    # Act 2's other ending has to be played rather than reasoned about.
    "exam_missed": {
        "rank_strength": 16,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
            "read_league_board": True, "record_kesh_win": 1,
            "record_ilse_loss": 1, "record_sunny_loss": 1, "record_orla_loss": 1,
            "lesson_openings_done": True, "won_a_league_game": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True}},
        "records": [
        {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 18,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_ilse", "npc_id": "ilse", "player_won": False,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 21,
         "summary": "White wins by 6.5"},
        {"context_id": "league_sunny", "npc_id": "sunny", "player_won": False,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 24,
         "summary": "White wins by 6.5"},
        {"context_id": "league_orla", "npc_id": "orla", "player_won": False,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 26,
         "summary": "White wins by 6.5"},
        ],
        "map": "bondszaal",
        "spawn": "from_tram",
    },
    # Paper sat, round one won, round two waiting -- the state the exam
    # actually spends most of its time in, and the one where the review screen
    # sits between the last round and the next.
    "exam_round2": {
        "rank_strength": 22,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
            "read_league_board": True, "record_kesh_win": 1,
            "record_ilse_win": 1, "record_sunny_win": 1,
            "lesson_openings_done": True, "won_a_league_game": True,
            "exam_entered": True, "exam_started": True,
            "exam_paper_done": True, "exam_paper_index": 2,
            "live_2_solved": True, "capture_4_solved": True,
            "exam_field": ["nadia", "player", "orla", "ilse"],
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True},
                   "qualifying_exam": {"step": 3, "done": False}},
        "records": [
        {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 18,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_ilse", "npc_id": "ilse", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 21,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_sunny", "npc_id": "sunny", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 24,
         "summary": "Black wins by 6.5"},
        {"context_id": "exam_r1", "npc_id": "nadia", "player_won": True,
         "margin": 3.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 71,
         "unrated": False, "opponent_strength": 28,
         "summary": "Black wins by 3.5"},
        ],
        "map": "bondszaal",
        "spawn": "from_tram",
    },
    # All three rounds won: first of four, and through.
    "exam_passed": {
        "rank_strength": 22,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
            "read_league_board": True, "record_kesh_win": 1,
            "record_ilse_win": 1, "record_sunny_win": 1,
            "lesson_openings_done": True, "won_a_league_game": True,
            "exam_entered": True, "exam_started": True,
            "exam_paper_done": True, "exam_paper_index": 2,
            "live_2_solved": True, "capture_4_solved": True,
            "exam_field": ["nadia", "player", "orla", "ilse"],
            "exam_finished": True, "exam_passed": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True},
                   "qualifying_exam": {"step": 3, "done": True}},
        "records": [
        {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 18,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_ilse", "npc_id": "ilse", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 21,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_sunny", "npc_id": "sunny", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 24,
         "summary": "Black wins by 6.5"},
        {"context_id": "exam_r1", "npc_id": "nadia", "player_won": True,
         "margin": 3.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 71,
         "unrated": False, "opponent_strength": 28,
         "summary": "Black wins by 3.5"},
        {"context_id": "exam_r2", "npc_id": "ilse", "player_won": True,
         "margin": 3.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 71,
         "unrated": False, "opponent_strength": 21,
         "summary": "Black wins by 3.5"},
        {"context_id": "exam_r3", "npc_id": "orla", "player_won": True,
         "margin": 3.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 71,
         "unrated": False, "opponent_strength": 26,
         "summary": "Black wins by 3.5"},
        ],
        "map": "bondszaal",
        "spawn": "from_tram",
    },
    # All three lost: Act 2's other ending, which has to be seen too.
    "exam_failed": {
        "rank_strength": 22,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
            "read_league_board": True, "record_kesh_win": 1,
            "record_ilse_win": 1, "record_sunny_win": 1,
            "lesson_openings_done": True, "won_a_league_game": True,
            "exam_entered": True, "exam_started": True,
            "exam_paper_done": True, "exam_paper_index": 2,
            "live_2_solved": True, "capture_4_solved": True,
            "exam_field": ["nadia", "player", "orla", "ilse"],
            "exam_finished": True, "exam_failed": True,
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True},
                   "qualifying_exam": {"step": 3, "done": True}},
        "records": [
        {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 18,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_ilse", "npc_id": "ilse", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 21,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_sunny", "npc_id": "sunny", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 24,
         "summary": "Black wins by 6.5"},
        {"context_id": "exam_r1", "npc_id": "nadia", "player_won": False,
         "margin": 3.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 71,
         "unrated": False, "opponent_strength": 28,
         "summary": "White wins by 3.5"},
        {"context_id": "exam_r2", "npc_id": "ilse", "player_won": False,
         "margin": 3.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 71,
         "unrated": False, "opponent_strength": 21,
         "summary": "White wins by 3.5"},
        {"context_id": "exam_r3", "npc_id": "orla", "player_won": False,
         "margin": 3.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 71,
         "unrated": False, "opponent_strength": 26,
         "summary": "White wins by 3.5"},
        ],
        "map": "bondszaal",
        "spawn": "from_tram",
    },
    # Two rounds down, the last one to play. The only state in which finishing a
    # game *ends Act 2*, which is the transition nothing had ever driven: the
    # match records exam_r3, _exam_finished_check runs on match_finished, and
    # exam_finished / exam_passed are set by the game rather than by a preset.
    "exam_final": {
        "rank_strength": 22,
        "flags": {
            "opening_seen": True, "intro_seen": True, "carrying_board": True,
            "wren_told_about_cup": True, "kesh_match_done": True,
            "match_kesh_first_done": True, "ranked_by_club": True,
            "knows_the_rules": True, "club_member": True,
            "invited_to_institute": True, "enrolled": True,
            "read_league_board": True, "record_kesh_win": 1,
            "record_ilse_win": 1, "record_sunny_win": 1,
            "lesson_openings_done": True, "won_a_league_game": True,
            "exam_entered": True, "exam_started": True,
            "exam_paper_done": True, "exam_paper_index": 2,
            "live_2_solved": True, "capture_4_solved": True,
            "exam_field": ["nadia", "player", "orla", "ilse"],
        },
        "quests": {"first_stones": {"step": 6, "done": True},
                   "enrolment": {"step": 4, "done": True},
                   "qualifying_exam": {"step": 3, "done": False}},
        "records": [
        {"context_id": "league_kesh", "npc_id": "kesh", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 18,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_ilse", "npc_id": "ilse", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 21,
         "summary": "Black wins by 6.5"},
        {"context_id": "league_sunny", "npc_id": "sunny", "player_won": True,
         "margin": 6.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 62,
         "unrated": False, "opponent_strength": 24,
         "summary": "Black wins by 6.5"},
        {"context_id": "exam_r1", "npc_id": "nadia", "player_won": True,
         "margin": 3.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 71,
         "unrated": False, "opponent_strength": 28,
         "summary": "Black wins by 3.5"},
        {"context_id": "exam_r2", "npc_id": "ilse", "player_won": True,
         "margin": 3.5, "by_resignation": False, "board_size": 9,
         "handicap": 0, "handicap_taken": 0, "komi": 5.5, "move_count": 71,
         "unrated": False, "opponent_strength": 21,
         "summary": "Black wins by 3.5"},
        ],
        "map": "bondszaal",
        "spawn": "from_tram",
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


SLOT_COUNT = _const("SLOT_COUNT", SAVE_SYSTEM)
USER_DIR = os.path.expanduser("~/.local/share/godot/app_userdata/Ninepoint")


def slot_path(slot):
    return os.path.join(USER_DIR, "save_%d.json" % slot)


def clear_all():
    for slot in range(1, SLOT_COUNT + 1):
        if os.path.exists(slot_path(slot)):
            os.remove(slot_path(slot))


def build(name, slot=1, who="Ro", minutes=None):
    st = STATES[name]
    save = {
        "version": 1,
        "saved_at": "2026-09-03T12:00:00",
        "player_name": who,
        "rank_strength": st["rank_strength"],
        "flags": st["flags"],
        "quests": st["quests"],
        # A preset may carry things: `page_forty` is about an object, and a
        # save that starts mid-quest has to be holding it.
        "inventory": st.get("inventory", []),
        # dict.get evaluates its default eagerly, so a state that supplies its
        # own records must not have the Kesh one built for it -- it reads "won"
        # and "summary", which such a state has no reason to carry.
        "match_records": st["records"] if "records" in st else [{
            "context_id": "kesh_first", "npc_id": "kesh", "player_won": st["won"],
            "margin": 4.5, "by_resignation": False, "board_size": 9, "handicap": 0,
            "handicap_taken": 0, "komi": 5.5, "move_count": 48, "unrated": False,
            "opponent_strength": 18, "summary": st["summary"],
        }],
        # A preset may name its hour: schedules decide who is standing in the
        # room, so "afternoon" is a default rather than a fact about every state.
        "current_map": st.get("map", "de_ketel"),
        "spawn_point": st.get("spawn", "from_street"),
        "return_position": [0, 0],
        "has_return_position": False,
        "playtime": 640.0 if minutes is None else float(minutes) * 60.0,
    }
    os.makedirs(USER_DIR, exist_ok=True)
    path = slot_path(slot)
    json.dump(save, open(path, "w"), indent=2)
    return path


def build_declared(decl):
    """Build the slots a `{"save": ...}` entry declares, and clear the rest.

    A string is the one-slot form every script used before M31. A dict maps a
    slot number to a preset, or to {"preset", "name", "minutes"} where the
    screen under test needs the three rows to look like three different people
    rather than three copies of Ro at 10 min.
    """
    clear_all()
    if isinstance(decl, str):
        return [build(decl)]
    built = []
    for slot in sorted(decl, key=int):
        spec = decl[slot]
        if isinstance(spec, str):
            spec = {"preset": spec}
        built.append(build(spec["preset"], int(slot),
                           spec.get("name", "Ro"), spec.get("minutes")))
    # Stamped a minute apart in slot order, so the highest-numbered slot is the
    # one most recently played. Three files written inside the same second give
    # `SaveSystem.newest_slot()` a tie to break arbitrarily, and it feeds both
    # Continue and where the list opens its cursor -- so the whole run walks the
    # wrong rows and screenshots them just as confidently.
    now = int(time.time())
    for i, path in enumerate(built):
        stamp = now - 60 * (len(built) - 1 - i)
        os.utime(path, (stamp, stamp))
    return built


def declared_by(script_path):
    """The `save` entry of an autopilot script, or None if it declares none."""
    for step in json.load(open(script_path, encoding="utf-8")):
        if isinstance(step, dict) and "save" in step:
            return step["save"]
    return None


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--script":
        declared = declared_by(args[1])
        if declared is None:
            sys.exit(0)
        for made in build_declared(declared):
            print(made)
    else:
        which = args[0] if args else "beat_kesh"
        slot = int(args[1]) if len(args) > 1 else 1
        who = args[2] if len(args) > 2 else "Ro"
        mins = args[3] if len(args) > 3 else None
        clear_all()
        print(build(which, slot, who, mins))
