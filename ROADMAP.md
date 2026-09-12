# Ninepoint — Product roadmap

This document explains **why** future work matters and the trade-offs around it.
`WORKBOARD.md` is the operational source of truth: it owns task status, priority,
dependencies, and acceptance criteria. `MILESTONES.md` is the append-only delivery history.
Do not select work from this document without checking its linked board ticket first.

The build is green: `tools/test.sh` passes 18,229 Godot checks, 13 Python art tests,
the teaching protocol/scene gates, a capture-scene gate and three real-engine gates,
`tools/check_lessons.py` reports no problems, and the game is playable from the cold open
to the exam and the Cup.

**M37 cut more than any milestone built.** It removed the rules-only review, the hooks
ladder, the borrowed book, the performance rating and the calendar. M40 rebuilt the
review on engine analysis; the other cuts remain. Read `MILESTONES.md` M37 for why.

---

## Beginner and premise baseline — CAP-01 / DESIGN-01

The September 12 owner walkthrough exposed a first-capture rules mismatch and a world
framed as though everyone in the city plays Go. The [played audit](docs/design-audit/PLAN.md)
led to an approved implementation: a newcomer meets a local club, learns enough to try a
first amateur Cup, and has a place with the group regardless of results.

Pip now offers an explicit demonstration before optional empty-board Capture Go. A simple
variant-aware policy, factual H help, retry, exact capture replay and a neutral two-pass
exit make that encounter internally honest. Pip's ordinary rank and full-game profile
remain unchanged. Practice does not require an engine and never reaches territory counting.

The Kettle lends tables to the club; teaching takes place in rented community-centre rooms.
Kesh and Hana point to Noor before registration, and Noor offers company toward the Cup.
Ordinary conversations and notices give the selected hobby community everyday context.
Existing cast, rendered geometry, internal map IDs, ranks and honest competition remain.

[Implementation and played evidence](docs/baseline/PLAYTEST.md) distinguish technical
coverage from acceptance by people. CONTENT-05, ENG-09 and PROG-01 retain the full-game
strength, stopping and independent beginner questions. The [human playtest packet](docs/baseline/BEGINNER-PLAYTEST.md)
is ready; no recruitment, human comprehension or rank calibration is claimed complete.

## ART-08: full-game rendered presentation

After reviewing ART-07, the owner approved this style for the whole game, including
Go assets. All twelve maps and the full cast share a repeatable Blender/Python method.
The overhead Go surface preserves fast, unambiguous intersection reading; rendered
materials, stones, bowls and table carry the visual direction into matches.

The simulation keeps its logical coordinates. Projection, camera following and per-pixel
furniture occlusion sit above it, preserving saves and avoiding a second implementation
of doors, interactions or progression. Large rooms pan at a fixed angle to keep people
legible at 384×216. Sela remains the setting; this approval supersedes SELA's art freeze.
[Production method](docs/ps1/world/README.md).

## ART-09: coastal polish

Owner play feedback exposed disconnected arm poses, sunset-like exterior lighting,
missing door art and black scene edges. The follow-up corrects those and develops the
approved regional references: varied White City building forms on Market Lane and a
Jaffa-inspired working harbor on Sea Walk. Variation comes from massing and shade,
with restrained small detail at 384×216. Existing routes and the Go loop stay stable.
[Reference study](docs/ps1/polish/references.md).

## ART-07: fixed-view 2.5D experiment

The owner approved a single De Ketel room to test PS1-inspired presentation before
committing to a town-wide conversion. The experiment uses Blender/Python room layers
and original character models shared by sprites and portraits. Its cost is chiefly
asset production and navigation/occlusion authoring; the Go loop remains the same.
Sela remains the shipped setting. [Prototype guide](docs/ps1/README.md).

## Sela coastal setting — SELA-01 through SELA-03

The owner approved a fictional Tel Aviv-inspired setting with warm, worn, leafy streets,
a neighborhood walking loop and Tram 4 retained for the institute and Cup. All characters,
portraits, sprite sheets, ranks, Go rules and teaching order stay fixed. Three equally valid
Go cultures replace the old above/below opposition: familiar bar practice, organized
institute learning and everyday laundry company. Architecture and shade improve readability;
return visits remain meaningful through existing progress-based details.

This explicitly supersedes the previous art facelift's navigation freeze. Map IDs and
spawn names remain stable, and old exact coordinates migrate once to a safe entrance.
Delivery evidence belongs in the workboard and `docs/sela/PLAYTEST.md`. Earlier sections
retain their original project history; current setting truth is in GAME_DESIGN/ART_DIRECTION.
The new setting does not close beginner-strength or whole-board teaching decisions.

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
one `katago analysis` process per game with the results streamed, why the loading card shows
position/comparison progress and can be left, and why the first version — two GTP searches per move
inside an eighteen-second budget — timed out on every real game and looked like a hang.

REV-01 adds deeper analysis only for selected review moments: at most nine
comparisons (200 visits actual/best, 50 pass) after the eight-visit score pass. The 9×9 detail budget is 45 seconds; lowering
visits requires the owner’s decision with measurements. REV-02 now implements optional live teaching with a separate match-owned process:
30 visits, four-point factual triggers, bounded waits and reconsideration before the
opponent sees a move. It preserves the review budgets above and the human-strength gates.
The extra CPU/memory cost applies only to chosen teaching practice. Independent beginner
transfer and interruption-fatigue observations remain pending; the local LLM narrator
stays deferred until this flow has been evaluated.

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

- The early curriculum now teaches a demonstrated finish before the full game, with
  seventeen lesson files including Pip’s demonstration, optional refreshers and twelve puzzles. These locally
  checkable decisions and factual Help do not establish whole-board judgement or human readiness.
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
- **`go_match.gd` remains over 800 lines.** Review offers/loading now belong to
  `PostMatchReview`, and practice help to `MatchTeaching`; further extraction remains useful.
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


## Reading the town — POLISH-02

The owner played the build and named nine presentation faults, none of which any gate
could see. The unifying one is that the world did not tell the player what it was: the
street ran off the edge of the map with nothing at either end, doorways carried a
destination string that no code had ever read, the tram stop was a lamp post with a sign
beside it, the way down to the water was two grey steps in thirty-four tiles of railing,
and the board on the attic desk was three times the width of the person looking at it.

The fixes are presentation and level composition only: no engine, rank, progression,
curriculum or dialogue-content change. Two of them are structural rather than cosmetic and
are worth stating as rules. **The map boundary is closed unless it is a door**, enforced in
`gen_maps.validate()` — three separate places could have caught the twenty open tiles on
Ketelsteeg and none of them looked. Closing it does not mean building something there: the
street runs on off the frame and the boundary column is simply not walkable. And **a board is two tiles deep while the interaction
probe reaches one**, so every seated opponent declares the chair on the far side of their
board; before that you could speak to Wren from three sides and not from the one a second
player sits at, and at Bertie's stone table the far side did nothing at all.

The opponent's portrait now changes with the board. It is driven by `GoMood`, a pure
mapping from the tags `GoTableTalk` has always emitted, which finally gives `standing()`
and both `edge_early` tags a consumer. The line M25 drew still holds: these are reactions
to what happened, not to what should have been played. Judgement belongs to the review.

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


## Early-game revision — EARLY-01 through EARLY-05

The owner approved teaching and story-order changes after the September 6 walkthrough.
Preserve Verhaven, its cast, the honest rank ladder, optional practice and leagues. Fellow
beginners motivate school entry: Hana points toward Noor, Noor wants company through the
league, and the Cup becomes a shared goal. Registration follows the welcome class; the
arrival capture problem remains an optional reminder. No additional win gate is introduced.

The club demonstrates finishing before the first full game. Short rule decisions replace
repetition, while optional longer refreshers remain available. Result explanations keep the
board visible. Wren’s actual practice uses position-aware guidance, Help and a score preview;
her engine strength and stopping policy stay unchanged until human experience warrants a
different decision. Proposed dead marks remain manually editable and are still heuristic.

Reactions now precede analysis. Review language reports immediate verifiable changes and coordinate-grounded engine
estimates, with
independent board comparisons and qualified engine preferences. Requesting analysis never
records another result. Visual novice belongings, contrasting HUD text and league-derived
progress make the existing setting and competition readable without another progression.

The observed long endings and an early-pass handicap ending are separate evaluation work
(ENG-09 and ENG-05). This revision does not resolve them by altering engine behaviour.
See `docs/early-game/PLAYTEST.md` for before/after evidence and the independent beginner gate.


## Preserve the portraits; enrich the town — ART-01 through ART-04

Owner approved a richer version of the existing Python art on 2026-09-08. The intended
contrast remains a wet working port and informal Go rooms against the Instituut's more
formal materials. The investment is in readable volume, specific furniture, contextual
wear and deliberate silhouettes. Increasing texture everywhere would obscure people and
routes, so central floors stay quiet and Go boards retain the strongest local contrast.

This pass preserves portraits exactly, existing scale and navigation, all progression,
engine profiles, teaching, dialogue, font metrics and audio. Shared drawing operations,
geometry metadata and selective preview builds make future art iteration safer; they do
not replace visual judgement. The workboard owns delivery status and the art playtest
records the actual screens inspected.

## Portrait-led sprite preview — ART-06

The owner likes the portraits but rejected the overworld figures' likeness and rigid
style. Shared colours alone do not preserve identity. The selected direction uses
rounded hair/face silhouettes, shaped garments and distinct working postures at the
existing world scale. The first package covers Ro, Wren, Kesh, Tomás, Nadia and Sunny;
remaining characters keep their current artwork until the six-person direction is reviewed.
The owner subsequently chose a consistent floating neckline for portraits, with scarves
remaining connected. Tomás, Bertie, Abel and Emil receive that shoulder-only correction;
faces and expressions stay exact. This is a visual revision, not a
change to the cast, progression, environment or animation interfaces.
