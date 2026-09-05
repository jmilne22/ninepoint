"""Writes the .tres content resources (NPCs, opponents, quests).

Godot resources are generated from one table here so a character's rank cannot
say 12k in their NpcData and 8k in their OpponentProfile.
"""
import os
import re

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.join(here, "..")

# id, name, rank, engine knobs, blurb, dialogue, flavour
CAST = [
    dict(id="wren", name="Wren Calloway", rank="20k", mistake=0.45, depth=0,
         aggr=0.6, terr=0.8, resign=0.0, style="steady",
         blurb="Learned last spring. Apologises for her own good moves.",),
    dict(id="kesh", theme="theme_rival", name="Kesh Idowu", rank="12k", mistake=0.24, depth=1,
         aggr=1.6, terr=0.9, resign=40.0,
         cut=1.8, style="fighting",
         blurb="Plays fast, cuts first, counts never. Keeps score of your meetings.",
         on_resign="I'm not finishing that. Take it."),
    dict(id="pip", name="Pip Arnesen", rank="18k", mistake=0.42, depth=0,
         aggr=1.8, terr=0.4, resign=0.0,
         ladder=1.8, style="fighting",
         blurb="Attempts ladders. The ladders do not work. Attempts them again.",),
    dict(id="hana", theme="theme_teacher", name="Hana Oyelaran", rank="5d", mistake=0.02, depth=2,
         aggr=1.0, terr=1.3, resign=0.0, style="steady",
         blurb="Teaches by asking questions she already knows the answer to.",),
    dict(id="bertie", name="Bertie Vale", rank="4k", mistake=0.10, depth=1,
         aggr=0.5, terr=1.9, resign=25.0, style="steady",
         blurb="Forty years in the park. Deals in proverbs of variable relevance.",),
    dict(id="nadia", name="Nadia Ferreira", rank="2k", mistake=0.08, depth=1,
         aggr=1.0, terr=1.4, resign=30.0,
         book=4, cut=0.5, style="steady",
         blurb="Carries a joseki book. Quotes it. Struggles when you leave the book.",),
    dict(id="tomas", name="Tomas Beir", rank="8k", mistake=0.18, depth=1,
         aggr=0.9, terr=1.3, resign=0.0, style="steady",
         blurb="One game a day, and he means it. Suspiciously good endgame.",),
    # --- the arches under the viaduct. No card, no papers, no rank on the wall.
    # strength carries what rank_label refuses to say -- see OpponentProfile.
    dict(id="joos", theme="theme_ghost", name="Joos", rank="?", strength=32, mistake=0.06, depth=2,
         aggr=1.2, terr=1.6, resign=0.0, style="balanced",
         blurb="Plays under the arches for coins. Will not say what he is.",),

    # --- Essenveld Instituut students
    dict(id="ilse", name="Ilse Brandt", rank="9k", mistake=0.15, depth=1,
         aggr=0.7, terr=1.5, resign=35.0,
         book=6, style="steady",
         blurb="Knows the standard sequences cold. Visibly unhappy when you leave them.",),
    dict(id="sunny", name="Sunny Achebe", rank="6k", mistake=0.12, depth=1,
         aggr=1.7, terr=0.8, resign=0.0,
         cut=0.9, ladder=0.6, style="fighting",
         blurb="Nine years old. Reads four moves further than you and does not know it is impressive.",),
    dict(id="orla", theme="theme_wall", name="Orla Finn", rank="4k", mistake=0.08, depth=1,
         aggr=1.1, terr=1.4, resign=28.0,
         cut=0.6, style="balanced",
         blurb="Top of the lower league and in no hurry to explain how.",),

    # --- the Beginner Cup field: strangers from the rest of Verhaven. They exist
    # to be played, not visited, so they are on no map and have a line each.
    dict(id="abel", name="Abel Roos", rank="21k", mistake=0.44, depth=0,
         aggr=0.8, terr=1.1, resign=0.0, style="balanced",
         blurb="Came off the ferry for this. Plays every move like it is the last one.",),
    dict(id="dov", name="Dov Halevi", rank="19k", mistake=0.38, depth=0,
         aggr=0.5, terr=1.6, resign=0.0, style="steady",
         blurb="Counts out loud. Has not yet noticed that everyone can hear him.",),
    dict(id="moss", name="Moss Lindqvist", rank="16k", mistake=0.28, depth=1,
         aggr=1.4, terr=1.0, resign=30.0,
         cut=0.8, style="fighting",
         blurb="Top of the beginners' section three years running and still in it.",),

    dict(id="marguerite", theme="theme_exam", name="Marguerite Sable", rank="1d", mistake=0.05, depth=1,
         aggr=0.9, terr=1.5, resign=20.0, style="steady",
         blurb="Runs the Beginner Cup. Allergic to slow pairing.",),
]

SPRITE_DIR = "res://art/sprites"
KATAGO_COMMAND = "res://packaging/katago/katago-gtp.sh"
KATAGO_MODEL = "res://packaging/katago/models/kata1-b18c384nbt-s9996604416-d4316597426.bin.gz"
KATAGO_HUMAN_MODEL = "res://packaging/katago/models/b18c384nbt-humanv0.bin.gz"
KATAGO_CONFIG_DIR = "res://packaging/katago/config"


def human_profile(c):
    """KataGo Human-SL has 20k..9d profiles; Abel's 21k maps to 20k."""
    strength = c.get("strength")
    if strength is None:
        rank = c["rank"]
        n = int(rank[:-1])
        strength = 30 - n if rank.endswith("k") else 29 + n
    strength = max(10, min(38, strength))
    return "%dk" % (30 - strength) if strength < 30 else "%dd" % (strength - 29)


def _resign_for(points, board):
    """`resign` in CAST is an absolute point count, and it was tuned at 81 of them.

    Kesh giving up forty points behind is decisive on a 9x9 and merely a bad
    afternoon on a 13x13, so the number travels with the area rather than
    staying put. Every zero stays zero: a profile that never resigns does not
    start resigning because the board got bigger.
    """
    return round(points * (board * board) / 81.0, 1)


def opponent_tres(c, board=9, handicap=0, komi=5.5, suffix="",
                  colour_rule="by_rank", capture_goal=0, theme=None):
    # theme=None takes the cast's own; theme="" suppresses it for a variant that
    # is not a fight, which is the whole reason this is a parameter.
    pid = "%s%s" % (c["id"], suffix)
    return pid, """; Generated by tools/gen_content.py -- edit the table there, not this file.
[gd_resource type="Resource" script_class="OpponentProfile" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/go_ai/opponent_profile.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"{pid}"
display_name = "{name}"
rank_label = "{rank}"
strength_override = {strength}
engine = "gtp"
board_size = {board}
komi = {komi}
handicap = {handicap}
colour_rule = "{colour_rule}"
capture_goal = {capture_goal}
mistake_rate = {mistake}
reading_depth = {depth}
aggression = {aggr}
territory_bias = {terr}
resign_threshold = {resign}
ladder_happy = {ladder}
cut_bias = {cut}
book_moves = {book}
rng_seed = 0
gtp_command = "{gtp_command}"
gtp_args = PackedStringArray("gtp", "-config", "{{config}}", "-model", "{{model}}", "-human-model", "{human_model}")
gtp_time_per_move = 2.0
gtp_startup_timeout = 12.0
gtp_model_path = "{model}"
gtp_config_path = "{config}"
gtp_style = "{style}"
theme = "{theme}"
on_resign = "{on_resign}"
""".format(pid=pid, name=c["name"], rank=c["rank"], board=board, komi=komi,
           strength=c.get("strength", -1),
           handicap=handicap, mistake=c["mistake"], depth=c["depth"],
           aggr=c["aggr"], terr=c["terr"], resign=_resign_for(c["resign"], board),
           ladder=c.get("ladder", 0.0), cut=c.get("cut", 0.0),
           book=c.get("book", 0),
           colour_rule=colour_rule, capture_goal=capture_goal,
           theme=c.get("theme", "") if theme is None else theme,
           on_resign=c.get("on_resign", ""), gtp_command=KATAGO_COMMAND,
           model=KATAGO_MODEL, human_model=KATAGO_HUMAN_MODEL,
           style=c["style"],
           config="%s/human_%s_%s.cfg" % (KATAGO_CONFIG_DIR, human_profile(c), c["style"]))


def npc_tres(c):
    return """; Generated by tools/gen_content.py -- edit the table there, not this file.
[gd_resource type="Resource" script_class="NpcData" load_steps=3 format=3]

[ext_resource type="Script" path="res://src/rpg/npc/npc_data.gd" id="1_script"]
[ext_resource type="Resource" path="res://data/opponents/{oid}.tres" id="2_profile"]

[resource]
script = ExtResource("1_script")
id = &"{id}"
display_name = "{name}"
rank_label = "{rank}"
blurb = "{blurb}"
sprite_id = "{id}"
portrait_id = "{id}"
dialogue_path = "res://data/dialogue/{id}.json"
default_dir = "down"
opponent_profile = ExtResource("2_profile")
""".format(id=c["id"], name=c["name"], rank=c["rank"], blurb=c["blurb"],
           # NpcData has one profile slot and it is the person's default game.
           # 9x9 stays canonical however many sizes they gain: it is what
           # world.gd falls back to and what the review reads a strength off.
           oid=c["id"] + "_9x9")


# Who can be drawn in the qualifying exam: the league roster
# (LeagueTable.ROSTER) less Marguerite, who runs it. Kept in step by
# tests/test_data.gd, which will not let the two lists drift apart.
EXAM_FIELD = ["kesh", "ilse", "sunny", "orla", "nadia"]

# Who will sit down over thirteen lines. Tomas because the back table is his and
# counting is the thing a bigger board makes compulsory, Kesh because a rival is
# only worth having on a board with room to lose on. GAME_DESIGN section 9 puts
# chapter 2 here.
#
# The other three are the rest of the Cup's open section (CupBoard.FIELD_OPEN),
# which is played on thirteen lines: a field entry with no profile at the
# section's board size is a push_error in front of the player at round one.
# tests/test_data.gd derives its expectations from CupBoard rather than from a
# second copy of this list, so the two cannot drift.
THIRTEEN_FIELD = ["tomas", "kesh", "ilse", "sunny", "orla"]


QUEST_HEAD = """; Generated by tools/gen_content.py.
[gd_resource type="Resource" script_class="QuestData" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/quest/quest_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"{id}"
title = "{title}"
summary = "{summary}"
steps = [{steps}]
"""

# The enrolment quest used to sit in data/quests/ hand-edited, under a header
# claiming this tool had written it -- so rerunning the tool deleted nothing and
# fixed nothing. Both quests are generated now.
QUESTS = [
    dict(id="first_stones", title="First Stones",
         summary="Take the board to Pip in the park, then learn and play at De Ketel.",
         steps=[
             ('"journal": "Find Pip in the park, across the road."',
              '"advance_on": {"type": "match", "context": "pip_capture"}'),
             ('"journal": "Ask Wren at De Ketel to show you the rules."',
              '"advance_on": {"type": "flag", "key": "knows_the_rules"}'),
             ('"journal": "Play a practice game with Wren at De Ketel."',
              '"advance_on": {"type": "match", "context": "wren_first"}'),
             ('"journal": "Play Kesh by the window at De Ketel for your first rank."',
              '"advance_on": {"type": "match", "context": "kesh_first"}'),
         ]),
    dict(id="beginner_cup", title="The Beginner Cup",
         summary="Four rounds in a hired room at the Bondszaal. Two sections: beginners', fifteen kyu and below on nine lines with no handicap, and open, no ceiling at all on thirteen.",
         steps=[
             ('"journal": "Tell Marguerite at the Bondszaal you are ready to play."',
              '"advance_on": {"type": "flag", "key": "cup_started"}'),
             ('"journal": "Read the draw at the Bondszaal, then see Marguerite."',
              '"advance_on": {"type": "flag", "key": "read_cup_board"}'),
             ('"journal": "Play your four rounds."',
              '"advance_on": {"type": "flag", "key": "cup_finished"}'),
         ]),

    dict(id="qualifying_exam", title="The Qualifying Exam",
         summary="The top four of the lower league can enter. Play three rounds; the top two qualify.",
         steps=[
             ('"journal": "Tell Marguerite you are ready to sit it."',
              '"advance_on": {"type": "flag", "key": "exam_started"}'),
             ('"journal": "Sit Marguerite\'s problem paper at the Bondszaal."',
              '"advance_on": {"type": "flag", "key": "exam_paper_done"}'),
             ('"journal": "Read the exam list, then see Marguerite."',
              '"advance_on": {"type": "flag", "key": "read_exam_board"}'),
             ('"journal": "Play your three rounds."',
              '"advance_on": {"type": "flag", "key": "exam_finished"}'),
         ]),

    dict(id="enrolment", title="The Lower League",
         summary="Hana teaches at the Essenveld Instituut, two stops north. They take beginners.",
         steps=[
             ('"journal": "Take tram 4 north, from the stop at the west end of Ketelsteeg."',
              '"advance_on": {"type": "enter_map", "map": "academy_hall"}'),
             ('"journal": "Find Hana in the classroom, east of the hall."',
              '"advance_on": {"type": "flag", "key": "hana_offered_puzzle"}'),
             ('"journal": "Solve Hana\'s capture problem."',
              '"advance_on": {"type": "puzzle", "id": "capture_1"}'),
             ('"journal": "Ask for Marguerite at the desk in the hall."',
              '"advance_on": {"type": "flag", "key": "enrolled"}'),
             ('"journal": "Read the league board behind the desk."',
              '"advance_on": {"type": "flag", "key": "read_league_board"}'),
             ('"journal": "Take a class. The classroom is east."',
              '"advance_on": {"type": "lesson", "id": "two_eyes"}'),
             ('"journal": "Win a league game. The study hall is west."',
              '"advance_on": {"type": "flag", "key": "won_a_league_game"}'),
         ]),
]


def quest_tres(q):
    steps = "}, {".join("\n%s,\n%s\n" % (j, a) for j, a in q["steps"])
    return QUEST_HEAD.format(id=q["id"], title=q["title"], summary=q["summary"],
                             steps="{%s}" % steps)


def build():
    op_dir = os.path.join(root, "data", "opponents")
    npc_dir = os.path.join(root, "data", "npcs")
    q_dir = os.path.join(root, "data", "quests")
    for d in (op_dir, npc_dir, q_dir):
        os.makedirs(d, exist_ok=True)
    # Keep rank/style config selection generated with the profiles. Every
    # variant keeps its character's temperament while the Human-SL rank profile
    # remains the only calibrated strength selector.
    config_dir = os.path.join(root, "packaging", "katago", "config")
    base_path = os.path.join(config_dir, "gtp_human_fast.cfg")
    base = open(base_path).read()
    # Temperature is the strength knob (search is ignored for move choice while
    # humanSLChosenMoveProp is 1.0): below 1.0 the engine plays the majority
    # vote of that rank and skips the blunders one player of it would make.
    # The base is KataGo's example (0.85 / 0.70), which M41 measured on its
    # label. "steady" used to sit at 0.65 / 0.45 and measured four ranks
    # strong -- Wren, 20 kyu on her card, played like a 14 kyu -- so it now
    # sits a shade under the base, enough to read as cautious and not enough to
    # move the rank. tools/katago_strength_probe.gd is how that claim is checked.
    style_overrides = {
        "steady": {
            "chosenMoveTemperatureEarly": "0.80", "chosenMoveTemperature": "0.65",
            "staticScoreUtilityFactor": "0.45",
        },
        "balanced": {},
        "fighting": {
            "chosenMoveTemperatureEarly": "1.05", "chosenMoveTemperature": "0.90",
            "humanSLRootExploreProbWeightless": "0.10",
            "humanSLRootExploreProbWeightful": "0.10",
            "staticScoreUtilityFactor": "0.15",
        },
    }
    # The floor. preaz_20k is the weakest profile the model has, and at
    # temperature 1.0 it is a realistic online 20 kyu, which is far above a
    # player who learned the rules last week: the owner lost every game to it.
    # Temperature normally touches only moves under one percent, which is why
    # nothing between 0.45 and 1.2 measured any different; applied to every move
    # it flattens the whole policy. M41 measured 1.5-on-all at 2/8 against the
    # realistic 20k, losing by fifteen points a game -- two or three ranks
    # under it -- so the 20k configs, Abel's and Wren's, are the one place the
    # engine is asked to play below its weakest profile. Labels are untouched.
    floor_overrides = {
        "20k": {
            "chosenMoveTemperatureEarly": "1.50", "chosenMoveTemperature": "1.50",
            "chosenMoveTemperatureOnlyBelowProb": "1.0",
        },
    }
    for rank in sorted({human_profile(c) for c in CAST}):
        for style, style_over in style_overrides.items():
            overrides = dict(style_over)
            overrides.update(floor_overrides.get(rank, {}))
            configured = re.sub(r"(?m)^humanSLProfile\s*=.*$", "humanSLProfile = preaz_%s" % rank, base)
            for key, value in overrides.items():
                configured = re.sub(r"(?m)^%s\s*=.*$" % key, "%s = %s" % (key, value), configured)
            configured = configured.replace("# tools/gen_content.py and only replace humanSLProfile below.",
                "# tools/gen_content.py; rank and temperament overrides are generated below.")
            open(os.path.join(config_dir, "human_%s_%s.cfg" % (rank, style)), "w").write(configured)
    n = 0
    for c in CAST:
        # Everybody plays by_rank: the gap decides. GoMatchSetup falls back to
        # nigiri on its own once the two of you are within a stone, so an even
        # game stops being the default and starts being something you climbed to
        # -- and Orla's "you'll get four stones from me" becomes true.
        pid, text = opponent_tres(c, suffix="_9x9", colour_rule="by_rank")
        open(os.path.join(op_dir, pid + ".tres"), "w").write(text)
        # The bigger board, for the two people who offer one. Deliberately
        # not the whole cast: a profile nothing can reach fails
        # test_data.gd's reachability check, and the honest answer to that
        # is fewer profiles rather than a longer allow-list.
        if c["id"] in THIRTEEN_FIELD:
            pid, text = opponent_tres(c, board=13, suffix="_13x13",
                                      colour_rule="by_rank")
            open(os.path.join(op_dir, pid + ".tres"), "w").write(text)
        open(os.path.join(npc_dir, c["id"] + ".tres"), "w").write(npc_tres(c))
        n += 1
    # Kesh's first game is scripted: she says "nine by nine, even game -- nigiri"
    # and then explains komi, which is the game's only teaching of either. An
    # unranked player would otherwise be handed nine stones and hear none of it.
    kesh = [c for c in CAST if c["id"] == "kesh"][0]
    pid, text = opponent_tres(kesh, suffix="_first", colour_rule="nigiri")
    open(os.path.join(op_dir, pid + ".tres"), "w").write(text)
    n += 1
    # Hana's teaching game gives the player nine stones -- the honest way to
    # make a 5 dan playable for a beginner.
    hana = [c for c in CAST if c["id"] == "hana"][0]
    # ...and it is explicitly not a fight, so it keeps the quiet bed rather than
    # her own theme. A nine-stone teaching game scored like a title match would
    # be lying to the player about what is happening.
    pid, text = opponent_tres(hana, board=9, komi=0.5, suffix="_teaching",
                              colour_rule="by_rank", theme="")
    open(os.path.join(op_dir, pid + ".tres"), "w").write(text)

    # The exam is even. Every other game in the Institute is by_rank, because a
    # handicap is the honest expression of a gap -- but an exam is not a game
    # arranged to be fair, it is a measurement, and Marguerite says so. One
    # nigiri variant per student who can be drawn in it.
    for c in CAST:
        if c["id"] not in EXAM_FIELD:
            continue
        pid, text = opponent_tres(c, suffix="_exam", colour_rule="nigiri")
        open(os.path.join(op_dir, pid + ".tres"), "w").write(text)

    # Capture Go against Pip in the park: the standard first game for a complete
    # beginner (Yasuda's "first capture"). Small board, no komi, no counting.
    pip = [c for c in CAST if c["id"] == "pip"][0]
    pid, text = opponent_tres(pip, board=7, komi=0.5, suffix="_capture",
                              colour_rule="player_black", capture_goal=1)
    open(os.path.join(op_dir, pid + ".tres"), "w").write(text)
    for q in QUESTS:
        open(os.path.join(q_dir, q["id"] + ".tres"), "w").write(quest_tres(q))
    return n


if __name__ == "__main__":
    print(build())
