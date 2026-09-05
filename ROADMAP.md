# Ninepoint — Product roadmap

This document explains **why** future work matters and the trade-offs around it.
`WORKBOARD.md` is the operational source of truth: it owns task status, priority,
dependencies, and acceptance criteria. `MILESTONES.md` is the append-only delivery history.
Do not select work from this document without checking its linked board ticket first.

The build is green: `tools/test.sh` runs 12505 checks plus three real-engine gates,
`tools/check_lessons.py` reports no problems, and the game is playable from the cold open
to the exam and the Cup.

**M37 cut more than any milestone built.** The review, the hooks ladder, the borrowed
book, the performance rating and the whole calendar — hours, days, weekdays, weather,
sleep and schedules — are gone, and the sections below that used to describe them are
collapsed to one line each. Read `MILESTONES.md` M37 for why.

---

## 1. The engine — ENG-01 through ENG-05

**Decision (season-finale foundation):** ship a bundled KataGo integration for Linux x64.
`packaging/katago-linux-x64.json` is the release manifest for the verified binary,
normal and human-style models/configuration, checksums, licences and arguments. The
first engine-backed play target remains 9x9 and 13x13; 19x19 remains an ending horizon.

**State (M38–M41).** Every cast profile plays through KataGo's Human-SL model at the
character's rank and temperament, warmed while the player walks to the board, with the
heuristic as the fallback for a missing or misbehaving engine. The review is back: the
person you played offers to go over the game, KataGo's analysis mode prices every
position, and at most three cards come out of it. Two things below are still open.

**What it buys.** The heuristic opponent (`src/go_ai/heuristic_opponent.gd`, with
`GoEndgame` deciding when it stops) plays plausibly and blunders on a ranked shortlist,
and it cannot tell a ten-point move from a two-point one. Dead-stone marking at the end
of a game is a heuristic with a player override. There is no review at all since M37,
because the one that existed could say a group had one liberty and never what a move
was worth. An engine answers all three: KataGo's human-style model can be told to play
*like a 20 kyu* rather than as a crippled 5 kyu, `final_status_list` settles the dead
stones, and a review becomes the three biggest point swings in the game, which is what
every real Go app shows.

**What it costs.** A binary per platform, a model file on the order of a hundred
megabytes in a repo whose whole asset pipeline is generated Python, an external process
to babysit, and on the development machine everything runs through `steam-run`, so
whether a subprocess works at all is unproven. GNU Go is tiny and ships easily, but its
level 10 measured 12 kyu on the Human-SL ladder (M41) and it has no way to play like a 20
kyu, which makes Pip and Wren unplayable for a beginner.

**What the review costs, measured.** One KataGo evaluation of one position is about a
core-second on the bundled Eigen CPU build, at one visit or eight; a finished 9×9 game is
fifty to eighty positions and a 19×19 game two to three hundred. That is why the review is
one `katago analysis` query per game with the results streamed, why the loading card shows
"move N of M" and can be left, and why the first version — two GTP searches per move
inside an eighteen-second budget — timed out on every real game and looked like a hang.

**Strength, measured (M41).** M39's calibration never played a game out. The probe
(`tools/katago_strength_probe.gd`) puts every beginner profile on a ladder of the same
model at temperature 1.0 — a realistic 20, 15 and 10 kyu — anchored by GNU Go from outside.
The finding was not the one the ticket expected. On a 9×9 board the model cannot tell 20k
from 15k, every beginner profile sits in that band, and the temperature dial in its normal
range moves nothing, because it touches only moves under one percent. The cast was within
about three ranks of its labels on the model's own terms; what crushes a beginner is that
the model's *floor* is a realistic online 20 kyu. Two changes: the steady temperament no
longer sits well under KataGo's example, and the two 20k configs (Abel, Wren) apply
temperature 1.5 to every move, the one setting that measured below the floor. The ladder
gives stones once a rank exists; the games before Kesh hands one out do not (ENG-08).

**Still open.** *Dead stones* (ENG-05): `final_status_list` hung on the bundled Human-SL
build, so the count is still the heuristic's proposal with a player override; the analysis
mode's `ownership` output is the honest route. *19×19 at the board* (UI-01): the review
already reads a 19×19 game, the match panel does not yet draw one legibly. Delete the
heuristic and `GoEndgame` when the engine is the only opponent, not before.

## 2. The thin places — WORLD-01 through WORLD-03

- ~~The quay has nobody on it.~~ Decided (WORLD-01) and built (M40): nobody lives there,
  and the noticeboard holds the last game you asked somebody to go over. A review you
  walked away from lands there.
- **Onderbrug is Joos alone.** Walled at both ends, so it can have no crowd route, and
  Pip and Bertie live in the park now. Correct for a dead end under a viaduct; thin.
- **The wassalon's three stand in the room together** at all times. It was built for one
  or two at a time. Fine, and the room is small for three people and a folding table.

## 3. Beyond 9×9 — UI-01

13×13 is built (M28): Tomás's back table opens on three rated wins, Kesh plays on it,
and the Cup's open section is played on it. 19×19 is still only in the fiction — Hana's
`exam_word_passed` names it. Screen space is the reason: at the 192 px match panel a
19×19 gets 8 px cells against a 9 px font. `MISTAKE_BREADTH` in the heuristic makes a
profile mean something different on a bigger board and nobody has measured what it
should be; the engine makes the question go away.

## 4. Content that is still thin — CONTENT-01 through CONTENT-03

- The curriculum runs to competence and stops before judgement: thirteen lessons,
  twelve puzzles, all decidable from the rules because `tools/check_lessons.py` can only
  guard a claim it can decide. Whole-board judgement needs the engine.
- The study-hall students have three-game and six-game arcs and nothing after.
- There is no ending after the exam except Hana's word and the Cup.

## 5. Technical debt — TECH-01 through TECH-10

- **`world.gd` is 517 lines** against a convention of ~300. `SignDesk` took
  the reading and the sitting-down (and, in M37, the tram stop); what is left is the
  tournament routing, which is a second component.
- **`sign_desk.gd` is 200 lines.** The tram stop went in where the hooks and
  the book came out.
- **`LeagueTable.current_rows()` reads `GameState`.** `standings()` is pure and takes
  everything it needs; the convenience exists because the board, the exam and the
  `league_position_at_most` condition must not build the roster three different ways.
- **The exam list and the Cup draw look identical** once you press [Space]: both use
  the `kifu_board` art, and only the panel header tells them apart.
- **A `CanvasLayer` that reads an autoload is invisible to the test suite.** The suite
  runs as `--script`, where autoloads do not exist, so such a script fails to compile,
  its `class_name` resolves to a bare `GDScript`, and every static call on it returns
  null without failing anything. `ExamBoard.summary()` in `test_exam.gd` is a dead
  assertion for this reason. Put anything a test needs on the pure half of a pair.
  Nothing detects it.
- ~~`check_load.gd` never opens a `.json` file.~~ It parses every one since M38.
- **Two test hooks ship in production code**: the `Autopilot` autoload and
  `GoMatch.THINK_DELAY_FAST`. (`GameState.weather_override` went with the weather.)
- **`LESSONS_REACHED_BY_TRACK` and `PUZZLES_REACHED_BY_TRACK` in `tests/test_data.gd`
  are hand-kept copies** of the tracks they guard. Adding a class means remembering two
  places, and the copy in the test is the one that goes on passing.
- **A positional sound reaches no audibility check.** `washer`, `fryer` and
  `stove_crackle` are emitters; `tools/check_audio.sh` walks `MUSIC` and `BEDS` only.
- **Dead-stone estimation is a heuristic** and will misjudge seki and complicated life
  and death. The player can override every call. The engine fixes it, but not through
  `final_status_list` (§1); the analysis mode's ownership map is the route.
- **`go_match.gd` is over 800 lines.** The result, the review offer and the wait under
  the loading card went in where a component should have.
- **The UI is positioned by hand**, in literal coordinates rather than containers. M37
  found that `Label`'s default 3 px `line_spacing` had made every "four rows" in the
  game three rows and a fourth drawn on the frame, in every panel, for the life of the
  project, and nothing that measured text could see it because `UiKit.text_height`
  measures the font and not the Label. It is zero in the theme now.
- **The tram stop awaits the tram prop from `SignDesk`** and then changes scene, which
  frees the World the desk belongs to. Nothing runs after the await, which is the rule;
  it is still a `RefCounted` awaiting a `Node` that a scene change destroys.
- Audio has never been *heard* by an assistant. What is machine-checked: that each
  track renders as written, reaches the master bus, and exists where a map names it.
  Whether it is any good needs a person and headphones.
- Passers-by walk their route with no pathfinding, so `gen_maps.validate()` checks the
  whole segment is clear rather than just the ends.

## 6. Closed context

- ~~The exam~~ — built (M24). ~~Five opponents nobody can play~~ — built (M24).
- ~~Fill the term~~ — closed (M35), then the term itself was cut (M37).
- ~~The thin places~~ — closed (M36) by schedules and a room; the schedules are gone and
  §2 above has the two that reopened.
- ~~The tutorial~~ — built (M27).
- ~~The review~~ — built M25–M28, deleted M37, rebuilt on the engine M40. See §1.
- ~~The engine~~ — decided (ENG-01), hardened (ENG-02), at the board for every character
  (ENG-03, M38–M39), and behind the review (ENG-04, M40).
- ~~A rank that moved the wrong way~~ — the performance rating averaged the opponents'
  strength, so three losses from the provisional 22 kyu were a promotion. Replaced by
  `GoRankLadder` (M37): one step, in the direction the result says.
- ~~Post-match dialogue branched on the lifetime record~~ — every graph read `beat`
  ("ever beaten") as "just beat", so after one win the "you got me" line played after
  every later game the person won. `won_last` / `lost_last` (M37), and a test that runs
  every graph both ways.
- ~~The tram did nothing~~ — it was two walk-on warps at the map's west edge, with a
  prompt nothing displayed, and a decorative tram to wait for. It is a stop you press
  [Space] at, and the tram that passes is the one you board (M37).
- ~~Text ran off panels and covered the people talking~~ — the dialogue box pages, moves
  to the top of the screen when the speakers stand low, and keeps the arrow off the
  text; the toast and journal are sized to their text (M37).
- ~~`pip.json`'s `capture_go` node is orphaned~~ — the graph was rewritten (M37).
- ~~Nothing relates a quest's steps to the hours people stand somewhere~~ — there are
  no hours (M37).
