# Ninepoint — Product roadmap

This document explains **why** future work matters and the trade-offs around it.
`WORKBOARD.md` is the operational source of truth: it owns task status, priority,
dependencies, and acceptance criteria. `MILESTONES.md` is the append-only delivery history.
Do not select work from this document without checking its linked board ticket first.

The build is green: `tools/test.sh` runs 14235 checks plus three real-engine gates,
`tools/check_lessons.py` reports no problems, and the game is playable from the cold open
to the exam and the Cup.

**M37 cut more than any milestone built.** It removed the rules-only review, the hooks
ladder, the borrowed book, the performance rating and the calendar. M40 rebuilt the
review on engine analysis; the other cuts remain. Read `MILESTONES.md` M37 for why.

---

## Beginner-first progression — PROG-01

Approved: provisional 30k, five novice classmates at target ranks 30k–20k, a complete
novice league attempt and the existing Beginner Cup as the first finale. New beginner
Cups use handicap; the strong Academy League and its even-game exam are optional later.
Attempts start together, record fixtures once and can be repeated after completion.
Existing cast ranks and save histories remain intact. NPC fixture results are simulated
and persisted, not evidence of engine games. No calendar or parallel progression returns.

KataGo's human profiles stop at 20k. Independent novice configurations and whole-game
measurements precede release; human beginner playtesting is still required. These ranks
are calibration targets until then. The implementation branch is a playtest build, not
a claim that configuration names establish playing strength.

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
of a game is a heuristic with a player override. M37 removed the old review, which could say a group had one liberty but never what a
move was worth; M40 restored review through engine analysis. Human-SL supplies ranked
play and the review prices moves, first showing what went well and then up to two costly
positions. Dead-stone adjudication remains unfinished: the bundled engine hung on
`final_status_list`, so ENG-05 needs another route.

**What it costs.** A binary per platform, a model file on the order of a hundred
megabytes in a repo whose whole asset pipeline is generated Python, an external process
to babysit, and on the development machine everything runs through `steam-run`. The subprocess
path is covered by three real-engine gates. GNU Go is tiny and ships easily, but its
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
mode's `ownership` output is the honest route. *19×19* (UI-01): the development UI adds overview and close inspection; introducing it
through the town still needs the teaching transition. Delete the
heuristic and `GoEndgame` when the engine is the only opponent, not before.

## 2. The thin places — WORLD-01 through WORLD-03

- ~~The quay has nobody on it.~~ Decided (WORLD-01) and built (M40): nobody lives there,
  and the noticeboard holds the last game you asked somebody to go over. A review you
  walked away from lands there.
- Onderbrug remains deliberately quiet. M43 gives Joos a dry working corner under strong
  arches, stored port equipment, a readable board and a practical routine. Solitude is its role;
  a new resident, crowd route or errand is unnecessary (WORLD-02).
- The wassalon now fits three permanent occupants: a machine bank, folding counter, bench
  and approachable Go table. Ordered exchanges and interrupted/resumed folding make the
  shared room legible (WORLD-03). All eleven maps received the same composition pass.

## 3. Beyond 9×9 — UI-01

13×13 is built (M28): Tomás's back table opens on three rated wins, Kesh plays on it,
and the Cup's open section is played on it. UI-01 adds a development-only 19×19 match
route with whole-board overview and cursor-following zoom, also available during the
count and in reviews. The existing pixel-art resolution and opponent panel remain.

The remaining gap is a learner's transition, not merely a larger board. CONTENT-01 should
connect the current thirteen-line experience to whole-board decisions before town access
to nineteen lines is introduced (CONTENT-04). No new gate, teacher offer, or chapter is
shipped by UI-01.
Latency and legal play in the development fixture do not establish a nineteen-line cast
strength ladder. Dead-stone adjudication remains ENG-05.

## 4. Content that is still thin — CONTENT-01 through CONTENT-03

- The curriculum runs to competence and stops before judgement: thirteen lessons,
  twelve puzzles, all decidable from the rules because `tools/check_lessons.py` can only
  guard a claim it can decide. Whole-board judgement needs the engine.
- The study-hall students have three-game and six-game arcs and nothing after.
- M43 gives every existing exam and Cup outcome a conclusion, results display and optional
  acknowledgement. A new chapter or nineteen-line teaching transition remains separate.

## 5. Technical debt — TECH-01 through TECH-10

- **`world.gd` remains over 500 lines** against a convention of ~300. `SignDesk` took
  the reading and the sitting-down (and, in M37, the tram stop); what is left is the
  tournament routing, which is a second component.
- **`sign_desk.gd` owns several reading panels.** The tram stop went in where the hooks and
  the book came out.
- **`LeagueTable.current_rows()` reads `GameState`.** `standings()` is pure and takes
  everything it needs; the convenience exists because the board, the exam and the
  `league_position_at_most` condition must not build the roster three different ways.
- **The exam list and the Cup draw look identical** once you press [Space]: both use
  the `kifu_board` art, and only the panel header tells them apart.
- **UI tests now run after autoloads are ready.** M43 fixed dead static assertions by loading
  suites on a deferred turn, and the shell gate rejects script/compile errors. Pure/panel
  extraction is still useful maintenance, but unavailable calls no longer pass silently.
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
- Tram travel now belongs to `SceneRouter`, which survives scene replacement and owns the
  skippable generated destination views. The old World-owned await boundary is gone (TECH-09).
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

## 7. Presentation and beginner experience — POLISH-01

The approved M43 direction keeps the Python pixel pipeline, port setting and human skill
progression. Clear short exchanges take priority over personality slogans. Art distinguishes
places through architecture, furniture and activity rather than a noisier palette. The school
and civic hall have separate exterior views and interior proportions.

Pip's first Capture Go and Wren's first practice start empty; Kesh's optional practice
uses handicap after she issues the novice card (PROG-02). An unknown
rank never becomes numerical strength. This resolves ENG-08's presentation decision; engine
floor calibration remains ENG-06. Later handicap games explain the actual position before
play, including White's first move, ordinary starting stones, komi and rank consequences.
H reopens help without advancing the game. Practice/casual labels describe the occasion;
only `unrated` controls rank consequences.

Acceptance is observed play, with automation supporting branch coverage. See
`docs/overhaul/PLAYTEST.md` for journeys, fixtures, mistakes found and representative screens.


## Board mouse support — UI-02

The board encounter supports mouse targeting and clickable actions through results and
reviews, on every existing board size. Feedback makes the selected intersection and
counting group visible. Hover remains independent of legality: the existing click response
already explains rejected moves. The same distinction keeps ko/self-capture lessons intact.
Mouse targeting keeps nineteen-line close views steady; keyboard selection still follows
the cursor. Town navigation and dialogue/menu mouse support remain separate work.

## Town run mode — UI-03

Crossing Verhaven should not make repeat visits drag. Holding Shift runs at 1.75 times the
normal walking pace everywhere the town controller is active, including interiors. It is a
travel convenience, not progression: there is no stamina, statistic, toggle or saved setting.
The existing player sheet supplies the faster gait, while NPC movement remains unchanged.

PROG-01's implementation candidate and played evidence are collected in
[docs/novice/PLAYTEST.md](docs/novice/PLAYTEST.md). New Cup draws retain entry rank while
handicap uses the current rank at the board. This prevents rank changes from rewriting
past pairings. Release status remains on the workboard; target ranks still require
independent beginner validation.

## Opening follow-up — optional Kesh practice (PROG-02)

The owner found the compulsory even game against 12k Kesh demoralising and the fixed
30k reward misleading even after a win. Kesh now issues the provisional novice card and
Instituut invitation before offering a game. Her optional 9×9 uses rank-based handicap
and is unrated. The card opens access; it is not a measured placement. Wren and the
journal point to the conversation rather than a required match. Existing ranked saves
keep their ranks and histories. This supersedes PROG-01's decision to preserve all three
opening setups. Noor and Ivo both gave the owner close-ish wins; their settings stay fixed.
