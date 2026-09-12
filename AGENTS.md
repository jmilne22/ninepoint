# Ninepoint

A PS1-inspired 2.5D RPG about learning to play **Go (baduk)**, in Godot 4.7 / GDScript.
Original setting and characters — nothing is borrowed from any existing game's world,
cast, art or branding. Combat does not exist; encounters are games of Go.

The loop is the one Pokémon TCG and Yu-Gi-Oh! Tag Force run on: walk around, talk to
people, play, your record climbs, a tournament at the end. Everyone is always where they
live. A rated game moves your rank one step. After a game, the person you played reacts to
the game you just played, and if you ask, goes over it with you: how many of your moves
were the best on the board and which, then your best move with why it was good, then up
to two positions where a move cost points (M40). Nothing else — no clock, no schedules, no
second progression — because M37 cut all of it, and the reasons are in `MILESTONES.md`.

---

## Rules that must not be broken

These are the spine of the design. Check any new feature against them before building it.

1. **The player character gains no statistics.** No experience, no Reading stat, no item
   that makes you better at Go. Progression represents *the human at the keyboard* getting
   better. Rank is a record of results, never a modifier. Handicap, board size, engine
   strength and which concepts are in play are the only difficulty knobs.
2. **`src/go/` may not know a game exists around it.** Pure `RefCounted`: no `Node`, no
   scene tree, no UI, no autoload access except through a looked-up singleton. It must stay
   unit-testable with the rest of the project deleted.
3. **Opponents are labelled with real ranks** — `20k`, `12k`, `4k`, `1d`, `5d`. Never
   Easy/Medium/Hard. `GoRank` handles the arithmetic.
4. **There is no relationship or affection system.** What the game tracks is your
   **record** against each person (`GameState.head_to_head`). A greeting may branch on
   `beat` / `lost_to` (ever); the conversation after a game branches on `won_last` /
   `lost_last` (the game just played) and on nothing else.
5. **The league table is the progression, and it is honest.** `LeagueAttempt` derives
   standings from scheduled fixtures: player results reference `GameState.match_records`;
   NPC results are explicitly simulated and saved once. Each attempt starts at zero.
   Wins first, then frozen entry rank, then name. No hidden effort score or replacement losses.
6. **A dialogue graph that offers a game must have a `post_match` node**, and it must reach
   a different node for a win and a loss. `World._post_match` re-enters the graph there;
   without it `resolve()` returns `""`, the box never opens, and the after-game beat vanishes
   with no error. `tests/test_data.gd` runs every graph both ways.
7. **Art and audio builds are coordinated by Python in `tools/`.** ART-08 authorizes
   Blender/Pillow for the full game's rendered assets, including model-rendered portraits
   and Go presentation. No AI illustration assets. See `docs/ps1/world/README.md`.
   Edit source scripts/identity records, never exported images.
8. **The dialogue follows `data/dialogue/VOICES.md`.** Two lines a node, 110 characters a
   line, no rules taught in speech, nobody mentions a place or person the player has not
   met unless pointing them at it, and none of the shared tics. The machine-checkable half
   is `_test_writing_rules`; the rest is read with `tools/check_dialogue.py`.
9. **Visual, environmental, and gameplay changes must be played and inspected.** A green
   `tools/test.sh` run proves technical safety, not player-facing quality. Before calling
   work complete, run the relevant `tools/run_game.sh` route (or play it directly) and open
   representative screenshots; judge the intended change in the actual game, not from code.

---

## The setting

The campaign follows a small local Go club within **Sela**, a fictional coastal city inspired by Tel Aviv's shaded streets, balconies,
planted setbacks and sea terraces. One warm, mild afternoon; no clock or weather system.
The club uses Tomás’s bar tables and rents teaching/practice rooms at the community centre.
The laundry offers everyday company. The city’s whole population is not presented as Go players. The former institution-above / authentic-players-below opposition is retired.
All portraits, sprites, character identities and ranks are preserved.

Internal map IDs stay stable for saves and match venues:

| ID | Displayed place and role |
|---|---|
| `attic` | Rooftop Room above the closed stationer; abandoned board, study desk, home |
| `ketelsteeg` | Market Lane and Boulevard Garden; Pip, Bertie, shops, Tram 4 at west end |
| `de_ketel` | The Kettle; Wren, Kesh, Tomás, lessons and the back table |
| `wassalon` | The Laundry; Abel, Dov and Moss |
| `onderbrug` | The Arcade; a public passage with Joos's quiet side alcove |
| `quay` | Sea Walk; shaded bench and the asynchronous review noticeboard |
| `academy_*` | Community Centre / Sela Go Club; hall, study, class, novices and guest room |
| `bondszaal` | Assembly Hall; Cup and advanced exam |

Market Lane ↔ Sea Walk ↔ Arcade ↔ Market Lane is a bidirectional ungated walking loop.
Tram 4 retains its existing invitation/entry gates and destination maps. Its marked
five-by-two tile platform accepts Space regardless of facing (`standing_zone` on the sign);
faced people and notices keep priority. All people stay
in their established internal venues. Presence changes still follow existing progress flags.

---

## Structure and script

### Opening — `src/ui/opening.gd`
Hana speaks to the player directly over an empty board (the Professor Oak position), then
asks their name. Sets `player_name`, `opening_seen`, then goes to the attic.

### Act 1 — Sela (quest `first_stones`)
The player begins knowing **nothing**.

1. The previous tenant left a board and a bowl of stones. No instructions
   (`data/dialogue/intro.json`; gives item `old_goban`, flag `carrying_board`).
2. **Pip** in Boulevard Garden offers `pip_first_capture`, a prepared capture demonstration,
   then optional **Capture Go** (`pip_capture`, 7×7, `capture_goal = 1`) or directions to Wren.
   Practice uses `CaptureOpponent`, immediate Help, retries and a saved final-capture replay.
   Two passes end neutrally without counting; resignation remains a loss. Neither changes rank.
3. **Wren** acknowledges Pip and offers four short rules exercises (`first_game_rules`),
   followed by a prepared 7×7 `finishing` lesson and optional two-comparison `openings`.
   Results stay beside the board. Her first full 9×9 is explicitly unrated: position-aware
   guidance and **Help H** identify legal captures or groups in atari, followed by passing
   and proposed-mark counting help. Her strength and stopping policy are unchanged.
4. **Kesh** gives you a provisional 30 kyu novice card and a club invitation
   before offering any game (`first_rating`: `rank`, `ranked_by_club`,
   `invited_to_institute`, starts `enrolment`). You may leave immediately or play an
   optional **unrated** 9×9 with rank-based handicap. The card is a starting entry,
   not a placement assessment. Existing ranks and match records are preserved.

### Act 2 — the Sela Go Club rooms (quest `enrolment`)
Tram 4 north from the west end of Market Lane → **Hana** welcomes the player and offers the
first class directly (or an explicit skip / a visit to Noor first) → enrol with **Marguerite** → back-wall league board
→ Noor, Ivo and the remaining novice fixtures, at any placing → the **Beginner Cup**
ending. Hana’s capture puzzle remains optional. Noor wants company through the league and
toward the Cup. Novice classmates occupy the new `academy_novice` room through the hall's lower
west door. Existing early Cup eligibility remains available. After completing the Cup,
Marguerite offers optional Academy League registration. Complete all six fixtures; the
four highest eligible entrants excluding Marguerite may sit the advanced exam.

Attempts are repeatable after completion; past results remain browsable. NPC games are
simulated once per player round, including scheduled byes in Academy's odd field.
Legacy saves retain their old Academy table and may explicitly enrol in novices.

### The cast (ranks are load-bearing)

| id | name | rank | where |
|---|---|---|---|
| `wren` | Wren Calloway | 20k | The Kettle — teaches the rules and ko; considerate host, uncertain about her Go |
| `pip` | Pip Arnesen | 18k | Boulevard Garden — teaches Capture Go; attempts ladders that never work |
| `kesh` | Kesh Idowu | 12k | The Kettle — the rival; hands out the first rank; teaches escape and connection |
| `ilse` | Ilse Brandt | 9k | study hall — plays out of a book, stiffens when you leave it |
| `tomas` | Tomás Beir | 8k | The Kettle — owns the bar, teaches counting, keeps the 13×13 |
| `sunny` | Sunny Achebe | 6k | study hall — nine years old, alarmingly strong |
| `orla` | Orla Finn | 4k | study hall — an advanced Academy League player; blunt |
| `bertie` | Bertie Vale | 4k | Boulevard Garden — teaches ladders; one proverb |
| `nadia` | Nadia Ferreira | 2k | classroom — senior student |
| `marguerite` | Marguerite Sable | 1d | hall and Assembly Hall — registrar, runs the league, the exam and the Cup |
| `hana` | Hana Oyelaran | 5d | classroom — the teacher; asks questions |
| `joos` | Joos | **`?`** | The Arcade — no card; `rank_label = "?"`, a real `strength_override`, games `unrated` |
| `abel` | Abel Roos | 21k | wassalon — the weakest of the original town cast |
| `dov` | Dov Halevi | 19k | wassalon — counts out loud |
| `moss` | Moss Lindqvist | 16k | wassalon — three years under the section ceiling, on purpose |
| `noor` | Noor Dekker | 30k target | novice room — postcard under her bowl |
| `ivo` | Ivo Maas | 27k target | novice room — bicycle courier with a tiny pencil |
| `lea` | Lea Vos | 25k target | novice room — print-shop scrap paper |
| `emil` | Emil Bakker | 23k target | novice room — repairs lamps |
| `sora` | Sora Meijer | 20k target | novice room — a spare cushion |

Novice ranks are targets pending independent beginner playtesting. Their fixed engine
settings are separate from temperament and existing cast configs. PROG-01 must not be
marked shipped based on automated strength games alone.


---

## Before you start

**Pull `main` first, and then *prove* you are on its head. Every time, before touching
anything.** Pulling is not the check; the check is that the two hashes match.

```bash
git fetch origin
git rev-parse HEAD origin/main           # THESE TWO MUST BE THE SAME HASH
git checkout -b <branch>                 # work goes on a branch, never on main
```

If they differ, you are not on the head of `main` and **everything downstream of that is
suspect** — most of all `WORKBOARD.md`, which is how you choose what to build. Building an
item that was finished and merged two days ago costs a whole session and looks exactly
like working: the tests pass, the docs sweep cleanly, and the diff conflicts with somebody
else's merged milestone at the very end. A `git pull` that says `Already up to date.` is
only as true as your last `fetch`, and `git pull` on a branch that is not `main` does not
touch `main` at all.

Do it **again before opening a PR**: `origin/main` can move while you work, and the branch
you sized against a stale base is described wrongly in the PR body.

This is not housekeeping. Several sessions have worked in this tree and the merges
happen on GitHub, so a local `main` goes stale without ever saying so.

What it actually cost, exactly: when M30 was branched, local `main` sat at the PR #2
merge while `origin/main` had already taken PR #3 — M29. So `git log main..hooks-ladder`
reported **three** commits, one of them a milestone that had shipped a week earlier, as
though the branch contained it. The PR was right only because `gh` compares against
`origin/main` rather than the local copy; had anybody sized or described the work from
the local number, they would have described somebody else's milestone as part of theirs.
Nothing errored and nothing warned. `git status` will not catch it either: it reports
against the remote-tracking branch, which is only as fresh as your last fetch.

The same applies before reading `WORKBOARD.md` to pick an item. Deciding what to build
next out of a two-merge-old file is how the same thing gets built twice — and you find
out at the end of the session, not the start.

## Commands

```bash
tools/play.sh                                    # play it, on the real display
tools/play.sh -- --katago-trial=res://tools/fixtures/katago_trial_19x19.tres # development board
tools/play_ps1.sh                                # isolated De Ketel 2.5D experiment; never saves
tools/run_ps1.sh tools/autopilot/ps1_tour.json     # disposable user data, rendered-room acceptance
tools/test.sh                                    # compile gate + load check + all suites
tools/test_review_pure.sh                        # facts/narrator with the game and engine absent
tools/run_game.sh tools/autopilot/<script>.json  # drive the game, screenshot each beat
python3 tools/build_assets.py                    # regenerate ALL assets (Blender + Pillow required)
python3 tools/build_world_art.py --maps de_ketel   # selective rendered room rebuild
python3 tools/build_world_art.py --tram           # TLV-inspired articulated vehicle only
python3 tools/build_world_art.py --motion         # all locomotion cells; optionally list identities
python3 tools/build_world_art.py --stills         # title, opening and travel images only
tools/run_rendered.sh tools/autopilot/rendered_doors.json # isolated doorway + shader/movement gate
python3 tools/build_assets.py --groups environments --output /home/user/.cache/ninepoint-preview
python3 tools/art_contact_sheet.py --root /home/user/.cache/ninepoint-preview --output /home/user/.cache/ninepoint-props.png
python3 tests/test_art.py                         # art contracts, also included in test.sh
python3 tools/check_lessons.py                   # verify every taught position vs the rules
python3 tools/check_melody.py                    # does each track's wav match its note list?
python3 tools/check_dialogue.py [id ...]         # print a graph as a script a person can read
godot --headless --path . --script res://tools/ai_endgame.gd     # where does the opponent stop?
tools/check_audio.sh                             # is the music actually coming out? (needs a display)
tools/setup_katago.sh [--verify]                 # fetch + checksum the pinned KataGo (binary and models are not in git)
godot --headless --path . --script res://tools/katago_calibrate.gd   # every cast profile: startup, reply time, legality
godot --headless --path . --script res://tools/katago_review_test.gd # the review gate: a whole 9x9 and 19x19, and a wedged engine
godot --headless --path . --script res://tools/katago_strength_probe.gd -- --concurrent=8 --tag=after
                                                # STRENGTH, not latency: whole 9x9 games per beginner profile against a
                                                # reference ladder; --cells=beginners,temperature,anchors,floor,
                                                # thirteen,smoke; --board=13 for the back table.
                                                # ONE GIGABYTE PER CONCURRENT GAME -- it once took the machine down at
                                                # 24 engines. It refuses to start a game under --mem-floor-gb (6).
                                                # Eight at once, nothing else running: ~20 min per hundred games.
                                                # GNU Go anchors it: nix-shell -p gnugo once, then tools/gnugo-gtp.sh
python3 tools/gen_maps.py                        # rebuild the maps from their generators
python3 tools/gen_content.py                     # rebuild NpcData / OpponentProfile / quests
python3 tools/gen_props.py                       # art/props/ — the tram, the "..." bubble
python3 tools/make_test_save.py invited          # a save in a hard-to-reach state
python3 tools/make_test_save.py invited 2 Ada 42 # ...in slot 2, as Ada, at 42 minutes
                                                # also: league_ready thirteen_ready cup_ready
                                                # cup_day playing_up outgrown open_ready open_day
                                                # exam_ready exam_day exam_round2 exam_passed
                                                # exam_failed exam_missed exam_final
                                                # beat_kesh lost_to_kesh
                                                # quay_review quay_review_19 quay_empty
                                                # thirteen_ketel (thirteen_ready, but in The Kettle where Kesh is)
```

Autopilot scripts in `tools/autopilot/`: `opening`, `prologue`, `institute`,
`nigiri`, `win_path`, `feel`, `resign`, `city`, `joos`, `banter`, `desk`, `handicap`,
`endgame`, `board`, `saves`, `lessons`, `taught`, `thirteen`, `cup` / `cup_round` /
`cup_outgrown` / `cup_playing_up` / `cup_enter_open` / `cup_open`, `exam` /
`exam_round` / `exam_play` / `exam_result` / `exam_missed` / `exam_final`, `wassalon` /
`wassalon_game`, `katago_trial` / `katago_style_steady` / `katago_style_balanced` /
`katago_style_fighting` (the engine at the board, no world), `rev01_wren` (deliberate two-liberty abandonment against Wren’s shipped engine) /
`review_e2e` / `review_13x13`
/ `review_graph` (REV-04: the same whole game, then the graph card, walking, opening
a card, Compare C and closing) / `review_win` (a whole game to the count, then the cards; the last one against the
weakest heuristic so the player wins -- the autoplay brain cannot beat even Abel's engine), `review_world_wren_loss` / `review_world_wren` /
`review_world_13` (the same through the town: Wren at The Kettle, Kesh's thirteen, then the
post-match talk), `review_leave` (walk away from the loading card, read it later on the
quay), `review_unavailable` (a wedged engine must still let you out), `quay_review` /
`quay_review_19` (the noticeboard from a save).

Production acceptance: `rendered_doors` (all 22 connections plus GPU/input checks),
`rendered_match` (current Wren rematch/count/review flow), `rendered_tram` (boarding interrupts
a passing tram and holds its position), `rendered_coastal` (White City facades and Jaffa-inspired
harbor approaches), `rendered_polish_motion` (actual walk/run frame sequences),
`rendered_interior` (attic exposure benchmark). Regenerate doors with `tools/build_rendered_routes.py`.

Art routes: `art_signs` (shop lettering and all three entrances), `art_stop` (platform directions, cancel, bounds, home approach and both rides),
`stop_gates` (both refusals before the novice card), `art_ficus` (grounded ficus, clear façades/title roofs and arrivals), `art_tram` (white articulated tram passing and boarding both destinations), `art_tour` (all twelve maps, washer frames, park and novice aisle),
`art_materials` (quay variants), `art_people` (working pose, far-seat sorting, conversation),
`portrait_sprites` (ART-06's six preview people, running, conversation and activity return),
`art_arrivals` (both tram illustrations and federation furniture), and `art_cleanup`
(title composition and cleaned The Arcade masonry).

Screenshots land in `/tmp/ninepoint-shots` (override with `OUT=`). **`run_game.sh` needs a
script argument** — it runs on a hidden display. `DISPLAY_NUM=0` runs it on the real display
instead. A script **declares its own** starting state with a top-level `{"save": "<preset>"}`
entry; `{"save": {}}` means no slots at all, which is what a script that starts from New Game
wants. `run_game.sh` takes an exclusive `flock`: two sessions must never drive the game at
once, because `user://save_*.json` and the screenshot folder are shared.

**Three rules for writing autopilot scripts:**

1. **`advance: N` must carry `stop_at_choice` if a choice can occur inside it.** A blind
   advance selects the highlighted option; `slice_full` once accepted a rematch that way and
   every later shot was of a second game, at exit 0.
2. **A script declares the save it needs, and never inherits one.** Scripts that end by saving
   overwrite slot 1 with wherever the player finished.
3. **A green run is not evidence.** Only the images are, and only if somebody opens them. The
   first M37 run of `slice_full` wrote thirty confident frames of which the last twelve were a
   rematch nobody asked for, because `choose: 2` on a two-option card wraps to the first.
   The tram stop is `walk_to [1,10]`, `face [1,9]`, `tap interact`, `choose`.

---

**While somebody plays:** use a separate checkout and an absolute `XDG_DATA_HOME`
under `/home/user` for test and fixture runs. The save suite temporarily writes all three
slots, so backup/restore is not safe beside a live game using those same slots.
`tools/run_rendered.sh` supplies disposable user data; use distinct `OUT` and `LOG` paths
and run game/engine acceptance routes serially. `tools/check_user_data.gd` verifies the
Python fixture tools and Godot resolve the same data directory.

## Environment (NixOS — read this before running anything)

- Godot 4.7.2 lives at `~/.local/opt/godot`, wrapped by `~/.local/bin/godot`, which is
  `exec steam-run …`. A downloaded Godot binary **will not start** here without `steam-run`.
- `steam-run` sandboxes the filesystem: it cannot `chdir` into `/tmp/Codex-*` scratchpad
  paths. Keep working files under `/home/user`.
- Headless work (tests, `--editor --quit`) runs fine through the wrapper. To *see* the game
  under automation, `Xvfb :99` plus `DISPLAY=:99` — `run_game.sh` handles this.
  `play.sh` uses the real display and gets hardware acceleration.
- **Global `class_name` scripts only register after an editor pass.** Run
  `godot --headless --path . --editor --quit` before `--script res://tests/…`, or every
  class name is "not declared in the current scope". `test.sh` does this for you.
- Screenshots come from inside the game (`get_viewport().get_texture().get_image()`), not
  from X. They land in `~/.local/share/godot/app_userdata/Ninepoint/shots`.

---

## Architecture

Dependencies point one way. `src/go/` has **zero** inbound arrows.

```
src/go/        pure rules: board, game, scoring, ranks, the rank ladder, nigiri/handicap,
               lessons, puzzles, SGF, table talk (what just happened, as tags)
src/go_ai/     GoOpponent interface, GoEndgame (which ground is finished), the heuristic AI
               (style as well as strength), EnginePipe (one child process, read a line at a
               time off the scene thread), GtpOpponent (KataGo at the board), KataGoAnalysis
               (KataGo's analysis mode over a whole game) + MatchAnalysis (the review, pure),
               ReviewFacts / ReviewContinuation / ReviewNarrator / ReviewEnrichment (pure evidence and payloads)
src/go_ui/     board view, match scene, puzzle scene, lesson runner, nigiri ceremony
src/rpg/       world, player, NPCs, maps, components (Warp, Interactable, CharacterSprite),
               SignDesk (everything you read on a wall or sit down at: the boards, the
               study desk, the tram stop, the bed), TileAnimator, Soundscape, NpcIdle,
               CrowdSpawner/Passer and the Tram
src/academy/   LeagueTable (pure) + LeagueBoard (the panel); Exam + ExamBoard; CupDraw + CupBoard
src/dialogue/  DialogueGraph — JSON graphs, conditions and actions against GameState
src/quest/     QuestData + QuestTracker (autoloaded as `Quests`)
src/ui/        title, opening, dialogue box, HUD, pause menu, save slots, UiKit
src/autoload/  EventBus, GameState, SaveSystem, SceneRouter, MatchBridge, KataGoService
               (engine leases warmed while the player walks to the board),
               MatchReviewService (the one review that may be running), Audio,
               GameInput, Autopilot  (all registered in project.godot)
```

**Key seams:**
- `MatchBridge` is the *only* connection between the world and the Go layer. The world hands
  over a `MatchRequest`; it gets back a `MatchResult`. Also routes puzzles and lessons.
- `GameState.record_match()` appends the result, steps the rank (`GoRankLadder.step`), and
  sets `last_result` for the conversation that follows.
- `GoOpponent.choose_move()` may `await`, so a subprocess engine fits the same interface as
  the shipped AI. Every ordinary full-Go cast profile is `engine = "gtp"`: KataGo's Human-SL model at the
  character's rank and temperament, with the heuristic as the fallback when the engine is
  missing or slow. The binary and models are fetched by `tools/setup_katago.sh`, not in git.
- **The review is one process per game.** `MatchBridge.record_completed_match()` records once before returning to the world.
  After the reaction, `request_review(record_index)` starts `MatchReviewService`, which runs
  `KataGoAnalysis` on the SGF: an eight-visit query over every position, then up to nine
  actual/best (200 visits) and pass (50 visits) comparisons on the same process (REV-01 Step 1).
  Both phases stream progress; detail failures preserve the existing score-based cards. The world-owned review panel shows progress and can be left with [Esc]; the review
  finishes on its own and waits on the quay noticeboard. Nothing in it changes the result.
- `GoMatchSetup` decides colours: nigiri for even games, automatic Black at 0.5 komi for
  handicap games, derived from the two ranks.
- Systems talk through `EventBus` signals or `GameState` flags — never by reaching across
  the scene tree.
- **Pure half / panel half.** `LeagueTable`/`LeagueBoard`, `CupDraw`/`CupBoard`,
  `Exam`/`ExamBoard`. A `CanvasLayer` that reads an autoload does not compile in a
  `--script` run, so anything a test needs goes on the pure half. Nothing detects it.

---

## Assets and content are GENERATED — do not hand-edit the outputs

| Edit this | To change this |
|---|---|
| `tools/ps1/` + `tools/build_world_art.py` | `art/rendered/` — production maps/depth masks, people/busts, Go set, title and travel; Blender/Pillow via Python |
| `tools/gen_maps.py` + `tools/coastal_layouts.py` | `data/maps/*.json` — the maps, including walls, spawns, warps, signs, the tram stop, who stands where |
| `tools/gen_content.py` | `data/npcs/*.tres`, `data/opponents/*.tres`, `data/quests/*.tres` |
| `tools/characters.py` | shared identity for production models in `tools/ps1/people.py`; `art_people.py`, `portrait_sprite_people.py` / `portrait_sprite_heads.py` and `gen_characters.py` retain the grid fallback |
| `tools/gen_tiles.py` + `tools/coastal_tiles.py` | `art/tiles/town_tileset.png` + its manifest **and** `town_tileset.tres` (via `gen_tileset_resource.py`, which `build_assets.py` runs — a tile outside the resource draws as nothing, silently) |
| `tools/font5x7.py` | the bitmap font glyphs |
| `tools/gen_audio.py` + `tools/coastal_audio.py` + `wav.py` | `audio/*.wav` — synthesised from oscillators, no samples. A track named `<t>_in` is a one-shot intro sting for `<t>` |
| `tools/gen_props.py` | the articulated tram (160×36) and the "..." bubble |
| `tools/art_furniture.py`, `art_architecture.py`, `art_materials.py`, `coastal_architecture.py` | venue props, structures and tile material recipes |
| `tools/art_specs.py` | shared prop dimensions, footprints and animation holds |
| `tools/art_scene_details.py` | static floor/wall dressing, rebuilt with map geometry |

Hand-authored (edit directly): `data/dialogue/*.json` (and `VOICES.md`), `data/lessons/*.json`,
`data/puzzles/*.json`, `data/banter/*.json`, everything in `src/`.

`tools/gen_maps.py` has a `validate()` that fails the build if a spawn, an NPC or a warp
lands on a solid tile, if a sign lands on a walkable one, or if a sign has nowhere to stand
and read it. Trust it.

---

## Conventions

- Static typing everywhere; `class_name` on anything that is a type; snake_case files.
- No script over ~300 lines — if it grows, it wants to be a component.
- Signals past tense (`match_finished`), methods imperative (`start_match`).
- **The bitmap font's native size is 9 and its line height is 11.** Only integer multiples
  of the size are allowed, and the theme sets `Label/constants/line_spacing = 0`: Godot's
  default of 3 made every row 14 px, so every "four rows" in the game was three and a
  fourth on the frame, and nothing that measured text could see it.
- Text panels are measured against their contents with `UiKit.text_height` /
  `UiKit.fit_card` / `UiKit.paginate`. Nothing may run off the bottom of a card.
- Comments explain *why*, not what. Several record a bug that was actually hit — leave them.

---

## Verification discipline (learned the hard way)

1. **Run the game. Look at the screenshot.** `GoBoardView` carried a type-inference parse
   error for several milestones: the project launched, all tests passed, and the match screen
   was silently blank, because no unit test loads that file.
2. **`tools/test.sh` compiles and then *loads* every file.** The old gate grepped the import
   log for parse errors and reported "all scripts compile" while ten functions were missing
   from `go_match.gd`. `tests/check_load.gd` loads all 98 scripts, scenes and resources.
3. **Never trust a Go position you wrote by eye.** `tools/check_lessons.py` replays every
   taught position against the rules and has caught: three capture lessons where the target
   group had two liberties instead of one, and an openings lesson whose walls enclosed
   nothing at all. It also checks that a claimed enclosure is *regional* — with one colour on
   the board, whole-board scoring says that colour owns everything, which is true and useless.
4. A node must not `await` a call that destroys it (scene changes) — fire and forget instead.
5. **A green gate does not mean you can hear it.** Music and ambience were silent for the life
   of the project. `play_music()` set `loop_mode = LOOP_FORWARD` on the stream; these import as
   QOA, and a loop mode on a QOA `AudioStreamWAV` stops playback within milliseconds — so
   `_loop_music()` restarted it on `finished`, forever, and the track relaunched every few
   milliseconds with `playing == true` and the master bus at **-97 dB**. No error, no warning,
   no failing test, and a comment in the file ("loop flags do not survive every import path")
   that recorded the symptom as if it were the cause. **Never set `loop_mode` in code; loop by
   replaying on `finished`.** `tools/check_audio.sh` now measures
   `AudioServer.get_bus_peak_volume_left_db()` for every track and fails under -45 dB. It
   cannot run in `tools/test.sh`: `--headless` forces the Dummy driver, which reports silence
   for everything, which is the other half of why this went unnoticed.

---

## Before you call it done — sweep the documents

A task is not finished when the code works. **Every time**, before committing, walk the
documents and ask what each of them now says that is no longer true. This is the same
discipline as "pull `main` first" and it fails the same way: nothing errors, nothing warns,
and the file quietly becomes a liar that the next session reads as fact.

| file | what goes stale |
|---|---|
| `WORKBOARD.md` | ticket status, owner/branch, dependencies, acceptance evidence, and newly discovered work |
| `ROADMAP.md` | the product rationale or trade-off behind a ticket that changed direction |
| `MILESTONES.md` | the new `## M<n>` entry: what was built, **`Done when:` with the check count and its predecessor**, the deliberate-breaks table, and what you actually looked at |
| `AGENTS.md` | the command block, the autopilot script list, "Current state", the known-gaps list |
| `README.md` | controls, the vertical slice, the layout tree — it is the only document written for somebody who wants to *play* it |
| `ARCHITECTURE.md` | module boundaries, the seams, and any format it prints verbatim |
| `GAME_DESIGN.md` | only when a pillar, the cast or the teaching order moved |

Two habits that catch most of it: **grep for the numbers** (`grep -rn "<old check count>" --include=*.md .`),
and **read the paragraph you are about to leave alone** rather than the one you changed --
M31 found `ARCHITECTURE.md` §8 still printing a save schema with a `relationships` field in
it, from a system that was removed several milestones earlier, and `README.md` pointing at a
`src/save/` that has never existed.

## Work selection

`WORKBOARD.md` is the soft Jira-like source of truth. Before any non-trivial implementation:

1. Sync and prove `HEAD` matches `origin/main` as above.
2. Open `WORKBOARD.md`; take one `READY` ticket only. Do not start `NEEDS DECISION` or
   `BLOCKED` work as though it were ready.
3. Mark it `DOING` with your owner/branch, then implement against its scope and acceptance
   criteria. If the work changes the product direction, update `ROADMAP.md` too.
4. When it is verified, record the evidence and mark it `SHIPPED`. Add a milestone entry only
   for a release-sized piece of work; milestone numbers are history, not issue IDs.

Tiny fixes and documentation-only changes do not need a ticket, but they must reconcile any
ticket they affect. A new feature, debt item, or defect gets a board ID before implementation.

`MILESTONES.md` is deliberately historical: a `[done]` entry means that work shipped then; it
does not mean its system still exists after a later cut. `ROADMAP.md` explains the work; it
does not declare its live status.

## Current state

ART-08 converts the normal game to fixed-angle rendered 2.5D presentation. Use `tools/play.sh`.
ART-09 adds connected gait poses, daylight, visible entrances, continued surroundings,
varied White City facades and a Jaffa-inspired harbor.
All twelve maps, the cast/passers and Go assets use `art/rendered/`; logical coordinates,
saves and Go rules are unchanged. `tools/run_rendered.sh <route>` provides isolated play
verification. Blender/Pillow build commands and the depth-mask format are in
`docs/ps1/world/README.md`. Earlier art-freeze statements below describe historical work;
ART-08 supersedes them for production art. The ART-07 opt-in room remains session-only.

Playable start to finish: cold open → name → the attic → Market Lane → capture demonstration and optional practice with Pip →
Wren’s short rules and finishing lessons → optional opening comparison → supported unrated
full game → reaction/review → Kesh’s novice card (optional handicap practice) → tram north →
Hana’s welcome and first class → enrol → league board → novice fixtures → the Cup ending → optional Academy League/exam. Twelve maps, twenty characters, each on
exactly one map. Capture Go uses 7×7; town games use 9×9 and 13×13, with 19×19 available
in development play. Four quests. Three save slots.

REV-01/M51 adds coordinate-grounded review facts, ownership comparisons and Lesson L.
Pure facts/narration run without engine or game files. Capture examples are explicitly
labelled possible lines and legally replayed on load; they never establish forced death.
Steps 1–4 are complete. REV-02 implements optional Step 5 teaching; independent beginner
acceptance remains pending. LLM narration remains deferred. Reproduce the
inspected Black/White cards with `rev01_fixture_keyboard` / `rev01_fixture` and the saved
engine payloads in `docs/review/PLAYTEST.md`.

**M37 was the cut.** The owner played it and found it unplayable in six ways, and none of the
verification this project had done — 7,081 checks and thirty autopilot scripts — had asked
whether it made sense at the keyboard. What went:

| cut | why |
|---|---|
| the review (15 detectors, an evaluator, eight voice files, ~1,500 lines) | rules without judgement; needs an engine |
| the hooks ladder | two progressions that disagree is the confusion |
| the borrowed book | an inventory quest in a game with no inventory screen |
| the performance rating | three losses from 22 kyu were a promotion, and it toasted "Rank up" |
| the calendar: hours, days, weekdays, weather, sleep, schedules, occasions | complexity that decided nothing; a quest step could hide behind an hour |

And what was fixed: every after-game line branches on the game just played (`won_last`),
where every graph had branched on the lifetime record; the tram is a stop you press [Space]
at and the tram you see is the tram you board; text fits its panels and the box moves out of
the way of the people talking; and all sixteen graphs were rewritten against a voice sheet.

**Rank is a step ladder** (`GoRankLadder`): beat somebody at or above your rank and it goes
up one, lose to somebody at or below it and it goes down one, nothing else moves it, and
handicap is priced at `GoRank.ranks_per_stone()` — three ranks a stone on 9×9, two on 13×13.
Kesh issues provisional 30 kyu before optional unrated practice; the ladder floor is 30k. Park and arch games are `unrated`.

**Two board sizes.** 13×13 opens on three rated wins (`rated_wins_at_least`), at Tomás's
back table, where Kesh will also play you on it. The Cup's open section is on thirteen lines.

**The Cup has two sections.** Beginners' — fifteen kyu and weaker, rank-based handicap — and open —
no ceiling, thirteen lines, handicap by the gap, against Kesh, Ilse, Tomás, Sunny and Orla. A
player under the ceiling with three rated wins may play up. Joos cannot be entered. Both
start when you tell Marguerite you are ready and run round after round.

**The opponents are people at the board.** `GoTableTalk` tags what just happened and
`data/banter/*.json` gives each character something to say about it. Weak players blunder
plausibly, from a ranked shortlist. `GoEndgame` decides when the opponent stops.

**A game that counts has music.** `MatchMusic.theme_for()`: a free game keeps `theme_match`,
a rated one gets `theme_battle`, five people carry their own, the two occasions outrank them.

**The engine is in (M38–M41).** KataGo uses Human-SL rank profiles for the original cast; the
review is the engine's score swings, offered by the person you played, bounded only by
progress you can walk away from. Rank is `humanSLProfile` and temperament is
`chosenMoveTemperature` in a generated config. M41 measured the cast in whole games
against a realistic ladder: on 9×9 the model cannot tell 20k from 15k, the cast sits in
that band, and the dial's normal range moves nothing. The model's floor is a realistic
online 20 kyu, so the two 20k configs (Abel, Wren) apply temperature 1.5 to every move,
the one setting that measured below it. The games before any rank exists give no stones
(ENG-08). Dead stones at the
count are still the heuristic's proposal with a player override: `final_status_list` hung
on the bundled Human-SL build.

**Known gaps, in priority order:** see `ROADMAP.md`. The short version: independent beginner
learning/motivation testing for CAP-01 and DESIGN-01; Wren/novice strength and stopping
(CONTENT-05, PROG-01, ENG-09); engine dead-stone
adjudication; teaching and town access for 19×19 (development play already has overview/zoom); `world.gd` and `go_match.gd` are over the line-count convention; independent audio listening remains separate from M49’s measured real-driver audibility check.

## The longer documents

- `GAME_DESIGN.md` — pillars, the three-act structure, the cast, the teaching order
- `ARCHITECTURE.md` — module boundaries, the world↔Go seam, the opponent interface
- `ART_DIRECTION.md` — palette, tiles, the font, the nigiri ceremony's layout
- `MILESTONES.md` — what is built, what was verified how, and the full debt list
- `ROADMAP.md` — what is **not** built, in priority order, and the one open decision
- `README.md` — controls and how to play
- `data/dialogue/VOICES.md` — how each character talks

## M43 presentation and play verification

M43 gave the original eleven maps generated furniture and deliberate activity spaces. Four-direction
optional action sheets preserve the walking-sheet contract. Presence states can declare
ordered exchanges, played once per visit and suspended during modal UI. Named NPCs remain
available. Return positions fall back to a named safe spawn when invalid or occupied.

Match requests carry presentation-only `practice` and `venue_id`; `unrated` remains the rank
authority. First handicap introductions are controlled by the player and saved through
`handicap_intro_seen`; H reopens the explanation. `MatchPresentation` owns factual wording.
Unknown ranks never generate a handicap. Pip’s demonstration is prepared; his optional practice and Wren’s first full game are empty.

Historical M43 routes: `overhaul_fresh`, `overhaul_shortcuts`,
`overhaul_white`, `overhaul_joos`, `overhaul_art`, `overhaul_returns`, `overhaul_activities`,
`overhaul_cup`, `overhaul_cup_open`, `overhaul_exam_pass`, `overhaul_exam_fail`,
`overhaul_hana_passed`, `overhaul_hana_failed`, `overhaul_arcs_3`, `overhaul_arcs_6`, `overhaul_review_return`,
`overhaul_review_failure`, and the M42 `nineteen` regression. Play evidence and its limits
are in `docs/overhaul/PLAYTEST.md`. Use a separate XDG_DATA_HOME for play and another for tests.

The test runner loads suites after autoload readiness; script errors fail the shell gate.
Green checks remain supporting evidence, not a substitute for reading scenes in play.


## Board mouse controls (UI-02)

Board hover is occupancy-only: never call legality or engine analysis for a preview.
Illegal clicks keep their existing messages and must still reach the ko/self-capture
lesson handler. Mouse selection does not move the nineteen-line view anchor. Keyboard
selection still follows the cursor; explicit buttons pan the close view.

Mouse routes: `mouse_capture`, `mouse_nigiri`, `mouse_nineteen`, `mouse_count`,
`mouse_lessons`, `mouse_puzzle`, `mouse_review`, `mouse_colours`; `thirteen` now dismisses both handicap
pages before asserting a played move. `board_input` can send actual motion, click visible
buttons, resize the window, and assert a stable view/unchanged game while hovering.
Use isolated XDG data and run these serially with the existing runner lock.

## PROG-01 novice progression verification

Use `tools/autopilot/kesh_skip.json` for New Game through novice arrival and
`novice_losses.json` for five losses, the handicap Cup ending, and a fresh attempt.
`novice_academy.json` covers optional registration, six fixtures with byes, a disk reload,
a losing retry and archive browsing from the `novice_graduate` fixture.
Both declare isolated fixture requirements; set XDG_DATA_HOME, OUT and LOG outside real
player data. The full journey needs TIMEOUT=3600. `novice_ready` is the new registration
preset; existing league/Cup/exam presets deliberately remain legacy compatibility cases.

`godot --headless --path . --script res://tools/katago_strength_probe.gd -- --cells=novices
--games=8 --concurrent=2 --tag=novice-initial` records complete colour-alternating games,
exact configurations and rejected truncations. This establishes relative engine behaviour,
not human beginner plausibility. Release remains gated in WORKBOARD.md.

Save fields: `league_attempts` contains division/attempt numbers, entry rosters, schedules,
NPC winners and player-history indices; `active_league` identifies the active attempt.
Optional match division/attempt/fixture identifiers count scheduled games once.
`LeagueProgress` is the shared registration/migration/qualification seam; `LeagueAttempt`
is pure. Old Cup registrations retain their `nigiri` policy; new ones store `by_rank`.

Additional PROG-01 routes: `novice_cup` replays four complete games with frozen Cup entry
rank; `novice_legacy` loads old league/Cup/exam fixtures through the title UI. New Cup
registrations save `cup_entry_rank` alongside their colour policy, so changes to the live
card cannot rewrite earlier pairings. The existing Cup rematch fallback is preserved.

`novice_rank_card` checks the card before any game, declining and returning after reload.
`kesh_practice` plays the optional handicap game from `novice_first_rank`; `kesh_skip`
plays New Game through the novice-room arrival without facing Kesh. `novice_losses` covers subsequent league/Cup completion; `slice_full` is retired (TEST-01). PROG-02 supersedes the old
required even-game opening; old saved results remain unchanged.


## Early-game revision contracts

The accepted score returns to the opponent’s reaction before `PostMatchReview`; Cup/exam
announcements precede it too. Rematch offers belong to the next interaction. Analysis uses
the existing record index, never another call to `GameState.record_match`. `session_ended`
cancels old analysis before New Game or load replaces progress. Saved pending reviews are
marked interrupted; no result, rank step or fixture is replayed by requesting a review.

Lesson fields are additive: `action`, `reply`, `proofs`, `dead`, `prisoners`, `komi` and
`expected_score`. `GoLessonActions` owns pure action/proof state; `LessonLayout` and
`LessonDemonstration` present it. Older single-move files still work. Validate every scripted
action, refusal and exact count with `tools/check_lessons.py` and the focused tests.

Supplemental routes: `early_lessons`, `early_skips`, `early_counting`, `early_kesh`,
`early_quay`, `early_review_failure`, `early_exam_pass`, `early_exam_fail`; review routes use the
world-owned offer. Main manual walkthrough evidence and limitations live in
`docs/early-game/PLAYTEST.md`. Automated answers, direct visits and bot games establish
coverage only. Independent human beginner testing remains open. No audio was subjectively assessed.

## Sela environment and save contracts

Use `coastal_palette.py`, `coastal_tiles.py`, `coastal_architecture.py`,
`coastal_layouts.py`, `coastal_views.py`, `coastal_signage.py` and `coastal_audio.py` for the coastal setting.
Edit generators, never generated maps/images. All 73 character PNGs are protected by
`tests/sela_characters.sha256.json`; shared character palettes must not change.
Street trees use the boulevard ficus silhouette; keep trees off roofs, façades and arches.
Small pots use low foliage, with a visible supporting floor or ledge.

Saves carry `world_layout_revision`. Missing/older values clear only exact return coordinates
on load, retaining the internal map and named spawn plus all progress. New saves preserve
positions normally. The old navigation hash freeze is superseded by the approved loop's
reachability contracts. `sela_loop` walks all six directed connections and reloads the save.
`sela_legacy` loads an old coordinate inside the new bench, walks from the safe arrival,
then loads and saves/reloads a current stored position through the title/menu UI.
Use `art_tour`, `art_arrivals`, `art_people`, current early-game and novice routes with
isolated XDG directories; `slice_full` is retired. See `docs/sela/PLAYTEST.md` for evidence.

## CAP-01 capture practice contracts

`capture_practice` plays the fresh demonstration, neutral pass ending, resignation, retry,
capture, saved replay and onward access. `capture_skip` leaves the demonstration and
reaches Wren without playing practice. Use isolated XDG data. The headless
`tools/capture_scene_probe.gd` launches the actual board with installed/missing GTP paths
and verifies the variant bypasses both engine preparation and heuristic fallback.

`MatchResult.capture_goal` identifies the rules even after resignation; `practice_ended`
is neutral, never a win/loss counter or rank step. `capture_review` stores the exact board
before the final capture. Old records are unchanged. Ordinary territory analysis rejects
all Capture Go outcomes, including legacy `pip_capture` records without the new fields.
Pip’s neutral post-match branch is the deliberate extension to the two-result convention;
win and loss branches still describe the actual result. Independent beginner testing remains open.

## DESIGN-01 club baseline verification

The displayed Institute is now the community centre’s Sela Go Club rooms; internal
`academy_*`, invitation/class flags, opponents, ranks and fixtures remain compatible.
`club_journey` meets Noor before the welcome class and registration. `beginner_full_games`
adds complete automated Wren/Noor/Ivo games; these do not establish human beginner
strength. `club_everyday` covers ordinary exchanges and `club_payoff` covers the return
after a completed Cup. All play uses declared isolated saves.


## REV-02 live teaching (REV-01 Step 5)

Wren's first unrated 9×9 and Kesh's resolved handicap practice offer With teaching /
Play normally. The choice is per game; Help can turn teaching off. A separate match-owned
analysis process uses 30 visits and a shared profile deadline for actual/best branches.
Missing/stale/late results are silent; rank profiles and post-match review budgets stay fixed.
Only factual questions beside a demonstrated board may discuss a prospective mistake.
Ordinary table talk stays outcome-only. Undo restores history as well as stones; an undone
move never reaches GTP or the saved SGF. Help replays the last explanation on its own board.

`tools/teaching_benchmark.gd` measures the real worker. `tools/teaching_worker_test.gd`
and `tools/teaching_scene_test.gd` use labelled synthetic protocol/turn fixtures and run in
`tools/test.sh`. Rendered routes: `teaching_wren`, `teaching_kesh`, their `_keep` variants,
and their `_normal` variants. `teaching_note` explicitly scripts the real-analysis PV reply
to inspect the note and its Help replay. They use declared isolated saves and prepared positions;
they are interface/engine evidence, not independently played full games or human learning.
See `docs/review/TEACHING.md`; keep human acceptance separate from technical delivery.

## REV-04 graph-first review POC

`MatchAnalysis.curve` adds a per-move `curve` to the review payload from the pass-one
turns; pending and failed reviews carry none, and legacy saves without one render the old
tally card. `ReviewGraph` is a drawing-only Control; `ReviewCards` shows it as card one when
a curve and a replayable SGF exist, opens on the praised move, walks moves with Left/Right,
jumps marks with Up/Down, opens a marked card with Space and closes with Escape. The graph
caption rounds the pass-one loss; the cards quote the second pass, so the two can differ by
a few points on the same move. Route: `review_graph` (real engine, isolated XDG data).
