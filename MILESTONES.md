# NINEPOINT — Milestones

This is the append-only history of shipped work and its verification evidence. It is **not**
the current backlog: use `WORKBOARD.md` to select or update active work, and `ROADMAP.md` for
the product rationale behind it. Older entries may describe systems later changed or removed;
the latest relevant milestone and the current design documents win.

Rule for every milestone: **run the real game, interact with it, screenshot it, read the error
log, fix, run again.** A milestone is not done because the project opens.

---

## M0 — Foundation  [done]
Environment (Godot 4.7.2 under `steam-run`, Xvfb render+screenshot loop), design docs,
directory structure, `project.godot`, autoload skeleton, headless test runner.

## M1 — Go rules module  [done]
Pure GDScript, zero engine coupling. Board, groups, liberties, capture, suicide, simple ko,
positional superko, pass, two-pass end, handicap, komi, Japanese + Chinese scoring,
dead-stone heuristic, Zobrist hashing, SGF export.
**Done when:** the headless suite passes, including textbook positions (snapback, ko fight,
handicap placement, territory and area scoring).

## M2 — Opponent interface + shipped AI  [done]
`GoOpponent` interface, `RandomOpponent`, `HeuristicOpponent` tuned by `OpponentProfile`,
`GtpOpponent` skeleton with protocol implementation.
**Done when:** the AI plays full legal 9×9 games to two passes against itself with no illegal
move and no infinite loop, and a fixed seed reproduces a game move for move while a high
mistake rate does not.

## M3 — Art pipeline  [done]
`tools/png.py`, palette, tileset, 9 character sprite sheets + portraits, UI frame, icons,
title illustration. **Done when:** every asset imports into Godot and a test scene shows the
tileset and all portraits without a missing-texture placeholder.

## M4 — World, movement, collision  [done]
Town exterior + Go club interior, `TileMapLayer` maps, collision, player controller, camera,
warps between maps, spawn points. **Done when:** a screenshot shows the player standing in the
club having walked there from the street, and the player cannot leave the map or pass a wall.

## M5 — Dialogue + NPCs  [done]
Dialogue graph runner, typewriter box, portraits, choices, conditions, actions.
Four interactive NPCs with data-driven graphs.
**Done when:** every NPC can be talked to, choices branch, and screenshots show the box.

## M6 — Quest + rank + relationships  [done]
`QuestData`, tracker, journal line, flags, relationship scores, provisional rank award.
**Done when:** "First Stones" advances through all six steps under autopilot.

## M7 — Match integration  [done]
`MatchBridge`, match scene, board view, HUD, turn loop, pass/resign, scoring phase, result
returned to the world; rival dialogue differs on win vs loss.
**Done when:** the autopilot plays a full 9×9 game against Kesh from inside the RPG, the
world returns to the same spot afterwards, and both result branches are seen on screen --
the loss by playing it, the win by loading a save in that state (`tools/make_test_save.py`),
with the branch logic itself covered by the headless suite.

## M8 — Puzzle/tutorial  [done]
Capture/liberty puzzle from Hana, reusing the board view; hint, success explanation, retry.
**Done when:** the puzzle can be failed, retried and solved under autopilot, and the
explanation is shown on success.

## M9 — Title screen + save/load  [done]
Title, New Game / Continue / Quit, save slot, restore map + spawn + flags + quest + rank.
**Done when:** a run is saved, the game is quit, relaunched, continued, and the screenshot
shows the same position and quest state.

## M10 — Vertical slice polish + full playthrough  [done]
End-to-end autopilot run: title → new game → leave home → club → Wren → Kesh → match →
result dialogue → Hana → puzzle → save. Screenshots at every beat, zero errors in the log.

---

## Verification

Every milestone above was checked by running the game, not by reading the code. The habit
paid for itself: `GoBoardView` carried a type-inference parse error for several milestones,
so the Go board silently failed to build and the match screen was blank -- the unit tests
never load that file and could not have caught it. `tools/test.sh` now compiles every script
as its first step, and `tools/run_game.sh <script>` drives the real game under Xvfb and
captures a screenshot at each beat.

---

## M11 — Teaching, ceremony, and game feel  [done]

Added after the slice, on the observation that a game about learning Go never taught Go and
never let you decide who went first.

- **Capture Go** in the rules module (`GoGame.capture_goal`) -- the standard beginner game,
  first capture wins, no scoring. 15 lines, no new class.
- **`GoMatchSetup`**: nigiri for even games, automatic Black for handicap games, and a
  sentence of explanation either way. Colours are derived from the two ranks instead of a
  hard-coded field on the profile.
- **A lesson runner** (`GoLessonData` + `go_lesson.tscn`) and three lessons: liberties,
  capture, self-capture. Reuses `GoBoardView`, so a lesson looks like a real game.
- **A liberty overlay** on the board view -- rings on the liberties of whatever the cursor
  is on, which teaches the central concept faster than any amount of prose.
- **Audio**: `tools/wav.py` and `tools/gen_audio.py` synthesise 17 sounds and two music
  loops from oscillators and noise. No samples, no service, ~1.9 MB, fully regenerable.
- **Animation**: stones land with a scale-and-overshoot, captures shrink and fade.
- **Match state machine**: the `phase` enum plus three loose booleans became explicit states
  with per-state input handling.

**Done when:** the tutorial was played from the title screen and each step screenshotted, the
nigiri ceremony was played and both branches seen, and the original slice still ran with 0
script errors.

---

## M12 — Feedback pass  [done]

- **The tutorial moved out of the menu.** "Learn to play" is gone from the title screen; the
  lessons are reached only by Wren asking whether you have played, which is the point of
  setting a teaching game in a club. Saying "never" runs the whole track in one sitting.
- **Nigiri became a set piece**, structured on HammerLock Wrestling's three-window layout.
  See ART_DIRECTION.md section 4c.
- **A generated 5x7 bitmap font** replaced Godot's vector default: a text patch went from
  157 colours to 2. Native size 9, integer multiples only, and integer window scaling.
- **Text no longer overflows**: `UiKit` measures cards against their contents and paginates
  prose that will not fit; the match panel was relaid from two long lines to four short ones.
- **A real compile gate.** `tests/check_load.gd` loads all 86 scripts, scenes and resources.
  This exists because a bad patch silently deleted ten functions from `go_match.gd` and the
  previous gate -- grepping the import log -- reported "all scripts compile".

---

## M13 — Restructure: prologue, then the Institute  [done]

The game opened with the player already living among Go players and a narration that
implied they knew the rules. Rebuilt into three acts, after Pokemon, Hikaru no Go and
Yu-Gi-Oh! Tag Force. See GAME_DESIGN.md section 0.

- **A cold open** (`src/ui/opening.gd`): Hana addresses the player directly over an empty
  board and asks their name.
- **Act 1 reframed to zero knowledge.** A board is left in the player's room with no
  instructions; Pip sees them carrying it and teaches them Capture Go before anyone
  explains anything. Wren then teaches the rules, Kesh challenges, Hana points east.
- **The Ashfield Institute**: four new maps (hall, study hall, classroom, dormitory), the
  road east out of Stonebrook gated behind Hana's invitation, and three new students --
  Ilse 9k, Sunny 6k, Orla 4k -- filling the ladder between Kesh and Nadia.
- **The league board** (`src/academy/league_table.gd`, `league_board.gd`): standings
  computed only from `GameState.match_records`. The one honest progression system in the
  game; 21 tests cover its counting, ordering and what it refuses to count.
- **A class**: `data/lessons/openings.json` -- corner, side and centre, taught by making
  the player seal the same nine points three times and count the walls: 7 stones, 11, 16.
- **The relationship system removed** entirely, at request. Dialogue that branched on
  affection branches on the record instead.

**Done when:** the cold open, the prologue and the Institute spine were each played under
autopilot with 0 script errors, and the original slice still ran.

---

## M14 — The setting: Stonebrook becomes Verhaven  [done]

A four-phase setting pass. The town was a texture rather than a place: no
landmark, no industry, one overcast hour, everything at street level, and a premise that
admitted the problem ("a town where an unusual number of people play Go" — a coincidence
standing in for a reason). Re-sited into a rainy port city, with the world split into two
opposed Go cultures. See CLAUDE.md "The setting".

**Phase 1 — fiction and names  [done]**
- Every place name **translated** rather than replaced, so nothing in the fiction was lost:
  Stonebrook → Steenbeek, Kettle Row → Ketelsteeg, Mill Park → Molenpark, Ashfield →
  Essenveld, the Go club → De Ketel (a bar's back room, three steps below the pavement),
  the Community Hall → the Bondszaal.
- Map ids renamed with them (`kettle_row` → `ketelsteeg`, `go_club` → `de_ketel`), which
  reached eight places outside `data/maps/`.
- **Joos**, the twelfth cast member: no surname, no papers, and no rank on his card. The
  counterweight to the Instituut — it says a rank is a document, he says a rank is what
  happens at the table. His games are `unrated`, so `LeagueTable` never sees them.
- `OpponentProfile` gained `RANK_WITHHELD` (`"?"`) and `strength_override`, because
  `GoMatchSetup` cannot derive a handicap from a question mark. `tests/test_data.gd` now
  asserts a label is a real rank *or* withheld, and separately that every profile has a real
  strength behind it — rule 3 kept, with its one deliberate exception named.
- The `enrolment` quest was hand-edited under a header claiming `gen_content.py` had written
  it, so rerunning the tool neither updated nor deleted it. Both quests are generated now.

**Phase 2 — palette and tiles  [done]**
- 9 colours added to `tools/palette.py`: `brick0-3`, `asphalt0-2`, `neon0-1`. No sodium ramp
  was needed — a street lamp is exactly the town's existing `gold1`/`gold2`, which is why the
  night reads warm without a new colour. The neon is cold and dimmer than `board1`, because
  nothing may out-saturate the board.
- 26 tiles added (atlas 16×4 → 16×6, 64 → 90): asphalt, tram rails, puddle, wet cobble,
  canal, quay edge, bollard, bike rack, tram pole, brick window and wet base, graffiti,
  shutter and dead sign, the two halves of a viaduct arch and the ground under it, neon,
  snack window, steps down, concrete, glass curtain, the stove and the hooks, poured floor.
- **The trap:** `town_tileset.tres` lists one entry per atlas cell and was not regenerated,
  so every tile in the two new rows drew as nothing, silently — the city's first build had
  black holes where its windows and road should have been. `build_assets.py` now runs
  `gen_tileset_resource.py`. The arch was also drawn inside-out on the first pass and read as
  a diagonal wedge; it is a quarter circle centred on the springing point.

**Phase 3 — the rooms  [done]**
- `ketelsteeg` rebuilt at 34×20: brick, tram rails in wet asphalt, the shuttered stationer's
  with your stairs beside it, De Ketel's steps, the wassalon and its snack window, the
  viaduct closing the east end with an arch you walk into, Molenpark below the road, and the
  railing gap down to the water.
- New maps: `attic` (12×9), `onderbrug` (24×12), `quay` (26×14). **The game now opens in the
  attic**, which is where the narration always said the board was.
- `de_ketel` gained the stove and the hooks; the hooks sit on the wall *base* because on row 1
  the interaction probe cannot see them — the same bug the league board had.
- `academy_hall` is now poured concrete and a glass curtain wall: the two Go cultures should
  not be dressed alike. `validate()` caught concrete-as-floor immediately.
- **Camera fix:** a map smaller than the screen was pinned to the top-left with the void
  showing bottom-right, which read as a broken tileset. Small maps are centred now, and
  `World._build_backdrop()` paints `ink0` behind the tiles so alleys and frames read as shadow.

**Phase 4 — the hours  [done]**
- `src/rpg/ambient.gd`: a `CanvasModulate` for the hour plus one additive glow per self-lit
  tile. Additive is the trick — the modulate multiplies the glow, so a lamp is worth nothing
  at noon and everything at night, with no second canvas to keep in step with the camera. An
  earlier draft used a `CanvasLayer` above the modulate and had to copy the camera transform
  every frame; the additive version deleted that code.
- `MapData.indoors` and `INDOOR_TINTS`: De Ketel at eleven at night was as blue as the street
  above it, which is not what a lit bar looks like from inside.
- Drizzle on its own canvas layer, so rain falls across the screen rather than the map.
- `EventBus.time_block_changed` / `weather_changed` are the seam the day counter emits on.
  Ambient only ever reads `GameState.time_block`.
- Audio: `theme_night` (same key and tempo as `theme_street`, an octave down, more air),
  plus `amb_rain`, `amb_tram`, `amb_gull`. `MapData.music_night` swaps the street's track
  after dark.

**Done when:** all twelve autopilot scripts ran with **0 script errors** — including three new
ones (`city`, `night`, `salon`) — the street was screenshotted at afternoon, dusk, night, and
night in the rain, the arches were shown lit by their three lamps, and the suite went
2532 → 3465 checks with every file loading. Two harness bugs were fixed on the way: `feel`
never got through the cold open at all, and `_walk_to` reported "could not reach" every time a
walk ended by stepping through a door.

---

## M15 — The review  [done]

A game about learning Go learned one bit per match: whether you won. `MatchResult`
carried the result and a summary line, `LeagueTable` counted wins and losses, and that
was the whole of what the world knew about how you had played.

Meanwhile three characters already *talked* as though they had reviewed the game.
`kesh.json` said "you let me cut you in two on move fourteen and then defended the smaller
half" whether you had resigned on move six or lost by half a point on move ninety;
`ilse.json` named move eleven; `hana.json` named moves eleven and twenty. The illusion was
convincing enough to be remembered as analysis, which is the best possible argument for
building the real thing in the same shape.

- **`GoReview`** (`src/go/go_review.gd`) replays a finished game from its move list and
  reports what happened in it. Pure `RefCounted`, no engine, no `Node`: every finding
  comes from the rules, because a group that had one liberty and died is a fact about the
  board rather than an opinion about it. `positions_of()` refuses to review a game it
  cannot reproduce — a position set wholesale by `set_position()` (a puzzle, a lesson)
  replays to the wrong board, and reviewing the wrong board is worse than reviewing none.
- **Nine detectors** (`go_review_detectors.gd`): atari ignored, died-when-savable, own eye
  filled, self-atari, capture missed, first line early, ladder failed — and two that are
  not optional, `good_capture` and `good_save`. P5 says losing is content; a review that
  is only a list of failures makes losing punishment instead, so every review opens with
  something the player did.
- **Rank thresholding.** Each kind carries the strength at which it becomes worth hearing.
  A 22k is told about atari and filled eyes and nothing else; the first line waits for 15k.
  The order is Yasuda's, the same one the lessons already follow.
- **One finding per kind, at most three, told in the order they happened.** Four ignored
  ataris are one mistake made four times, and the same sentence three times teaches less
  than three different ones. The opening compliment keeps its place at the front.
- **`GoReviewVoice`** + `data/reviews/*.json`: each character's file overlays
  `default.json`, so a voice writes only what it says differently. Kesh is furious and
  precise, Hana asks rather than tells, Joos manages four words, and **Wren refuses** —
  she is 20k and says so rather than inventing something, which is the honest form of the
  rule that only somebody stronger than you can review your game.
- **The screen** (`src/go_ui/go_review.gd`) is the lesson runner with the positions coming
  from the game just played. `GoBoardView` gained one optional field, `mark_point`, because
  a single ring cannot say both "this group died" and "here is the move that would have
  saved it" on the same board.

**Two bugs found on the way.** `MatchResult.to_dict()` dropped the `sgf` field, so the game
record written at `go_match.gd:441` was discarded at the exact moment the match was
persisted — the kifu was generated and thrown away, and nothing had ever read it. And two
detectors identified a group by `stones[0]`, which breaks whenever the captured group
contains a stone played *after* the position being asked about — routinely, since the
stone the player just added is usually first in the captured list.

**Done when:** the suite went 3465 → 3596 checks with 131 covering the review, every
fixture *played* as legal moves rather than drawn by eye (`_play()` asserts legality, so a
fixture that drifts fails loudly); twelve simulated beginner-vs-Kesh games produced a
review in twelve of twelve; and the screen was run and screenshotted — the position, the
group ringed, the move that was there marked in teal, and Kesh saying "Move 34. D5. That's
all it needed. I watched you not see it and I did not say anything, because I'm not a
saint." The fabricated move numbers are gone from all three dialogue graphs.

Then end to end for real: `tools/autopilot/review.json` loads a save, walks to Kesh in De
Ketel, plays her, resigns, and is told about it — 0 script errors, and the shot shows the
review sitting between the result card and the town, with Kesh's edited dialogue picking up
from it afterwards instead of contradicting it. `slice_full` was re-run and did not desync:
the review only appears when a game produced findings, and a short resignation produces
none.

---

## M16 — The city is inhabited  [done]

The town was compact but not alive. Ketelsteeg is 34x20 tiles and had **one person on it**;
Pip was the only NPC in the game with `wanders = true`, and every other character early-returned
in `_physics_process` and stood frozen on a single sprite frame. `amb_rain.wav`, `amb_tram.wav`
and `amb_gull.wav` had been generated, imported and loaded into `Audio._streams` — and were
played by nothing. Nothing in the world moved: no animated tiles, no `AnimationPlayer` anywhere
in the repo, no `Tween` in `src/rpg/` at all, one particle system, and glow discs that never
flickered. GAME_DESIGN P4 asks for "compact and alive over large and empty"; only the first half
was true.

**The organising idea, taken from `Ambient`:** every system reads the map's own tiles and decides
from them. `Ambient` already found its lamps that way. So eight of the nine maps needed no data
change at all, and adding a tile to a table lights it up everywhere it already appears.

- **`Soundscape`** (new) picks one looping bed per map from map + hour + weather (rain outdoors,
  a room tone indoors, the canal at the quay) and places positional `AudioStreamPlayer2D`
  emitters from a `SOUND_SOURCES` table shaped exactly like `LIGHT_SOURCES` — the stove, the
  snack window, the go tables, the quay. Emitters gate on the hour (gulls are a daylight sound,
  the fryer an after-dark one) and are **thinned**: the quay has 156 canal tiles, and 156 gulls
  is a seabird attack rather than a port.
- **`TileAnimator`** (new) cycles water, the canal, puddles, the neon, the stove, the go tables
  and the kifu boards by tile *name*. Frame 0 **is** the base tile, so parking an animation is a
  no-op. Native TileSet animation was declined: it needs frames in consecutive atlas cells and
  `gen_tiles.py` packs strictly `i % 16`, so it would have meant rewriting the packer and editing
  the generated `.tres` — the file M3 records as silently fatal to get wrong.
- **`NpcIdle`** (new) gives each NPC a behaviour from one `"idle"` key per *map placement*, so
  Kesh paces in the bar and talks to Orla in the study hall without either being a property of
  Kesh. `NpcData.wanders` was deleted: once behaviour moved to the map it was a live-looking
  field that did nothing. Every NPC also glances up when the player passes — before it you could
  walk the length of Ketelsteeg and nobody registered that you existed.
- **`Passer` / `CrowdSpawner`** (new) put traffic on Ketelsteeg and students in the Instituut's
  hall: no name, no dialogue, not interactable, and they leave. Density falls by time block.
- **`Tram`** (new) runs on the rails, finding its own row from the longest run of `tram_rail_h`.
- **`Ambient`** gained per-lamp hum and a neon fault synchronised to the tube's own hold times,
  plus splash-up particles under the drizzle.
- **`CharacterSprite`** gained a one-pixel idle bob, on an integer offset and a random phase.
  No new art: a fourth sprite column would have meant regenerating all 13 sheets for less effect.

New: `soundscape.gd`, `tile_animator.gd`, `npc_idle.gd`, `passer.gd`, `crowd_spawner.gd`,
`props/tram.gd`, `tools/gen_props.py`, `tests/test_world_ambience.gd`, `tools/autopilot/alive.json`.
101 tiles (was 90), 31 sounds (was 21), 18 character sheets (was 13, and the five extras get no
portrait because nothing ever puts them in a dialogue box).

### Verification

- `tools/test.sh` green: 114 files load, 3735 passed / 0 failed, of which the new **ambience**
  suite is 139 checks. It asserts what fails *silently*: every tile name in every table resolves
  through `TileAtlas.at()`, every sound named has a wav, every animation's holds match its frames
  and its frame 0 is the base tile, every crowd sheet exists, and every `converse:<id>` names
  somebody actually on that map. A wrong name in any of these is silence or a hole, never an error.
- `gen_maps.validate()` gained route checking — the whole segment, not just the ends, because a
  passer walks its route with no pathfinding at all. It immediately **rejected the Onderbrug
  route**: the arches are walled at both ends and there is nowhere for anyone to be coming from,
  which is the correct answer for a dead end under a viaduct. Onderbrug has no crowd.
- `tools/autopilot/alive.json` (new), then the screenshots measured rather than eyeballed —
  region diffs between frames with the camera clamp held identical:

  | check | result |
  |---|---|
  | canal band, 2.5s apart | 61.7% of pixels changed — water moves, and not in lockstep |
  | bare wall, 24s apart, camera fixed | **0.0%** — the control that makes the rest trustworthy |
  | go tables, same 24s | 12.1% and 7.0% — two stones added, and the two tables out of phase |
  | the stove, same 24s | 100% — tile *and* its additive glow |
  | Wren's 16x24 box, player west vs east | 25.0% against a 2.2% control — she turns to look |

### The bug this pass actually hit

Passers-by started on collision layer 1 with the cast, and the first autopilot run through a
populated Ketelsteeg **could not reach De Ketel at all**. The crowd routes run along the
pavements, which is also the way the player walks, so somebody was always in the doorway. They
now sit on their own layer that the player's mask ignores: half a second of overlap when you walk
through an extra is much cheaper than not being able to get through a door. `Passer.LAYER`
carries the note.

---

## M17 — The soundtrack  [done]

`world.gd` was the **only** caller of `Audio.play_music()` in the project. Three consequences,
all of them audible: the title screen and the opening were silent; a Go match had no music of
its own, so whatever the street happened to be playing simply carried on underneath the game;
and all four Instituut rooms played `theme_club` — the same track as the bar three steps below
the pavement in Steenbeek — which flattened the single opposition the setting is built on.

Five tracks, in the register of Tag Force's academy, Hikaru no Go's patience, and Pokemon's
willingness to have a hook. All synthesised in `gen_audio.py` like everything else; no samples.

| track | where | what it is |
|---|---|---|
| `theme_institute` | the four Instituut rooms | A major pentatonic, 84bpm, with a quaver tick underneath that is frankly the timetable. Nothing in it thinks anything is wrong |
| `theme_match` | the board, during a game | E minor pentatonic, 52bpm, six notes in thirty-seven seconds and a low pulse closer to a clock than a part. It must not compete with reading the position |
| `theme_quay` | the quay, which shipped silent | D minor, slower than anything else in the game; the phrase falls every time, ends on the fifth in the wrong octave, and never resolves |
| `theme_arches` | Onderbrug, at every hour | A walking bass on every beat — the only steady pulse in the soundtrack — with the melody landing late. The money table is the one place in Verhaven enjoying itself |
| `theme_title` | the title screen | Climbs to the ninth and holds there, which is as close as a bitmap-font game gets to explaining its own name out loud |

Supporting changes: melodies are now `(start_beat, "A4", length_beats)` lists fed through a
shared `_voice()`, with `n("F#5")` for the frequency — the old tracks used raw floats, which
cannot be read as music. De Ketel keeps `theme_club`; the arches dropped their `music_night`
because it is never really daylight under a viaduct.

**The latent bug this pass promoted to a real one.** `play_music()` had the same two-live-tweens
race that `play_ambience()` was fixed for in M16, and it was harmless only because a single
caller could not stop and start a track in the same frame. The title screen and the match board
both play music now, so it was fixed rather than documented: `Audio._fade()` is the one helper
both voices use, and it kills the pending tween before starting another.

### Revision after listening (the part a spectral check cannot do)

Played, and two things were wrong that no gate could have told me:

- **The whole soundtrack was depressing.** Every track was minor and slow, including the two
  inherited ones. The brief named Tag Force and Pokemon alongside Hikaru no Go and I had taken
  only the third: `theme_title`, `theme_street`, `theme_night`, `theme_club` and `theme_match`
  were rewritten into major keys. The title is D major and now sounds like arriving somewhere;
  the street is G major, because a working street on a wet afternoon was scored like a funeral
  and it is the track the player hears more than any other; De Ketel is F major, because a bar
  you like being in is not a sad place; and the match theme leans on C and ends on G rather
  than falling to the root, so it reads as *focused* rather than bereaved. `theme_quay` was
  left exactly as it was: it is where you go after losing, and it has earned the right.
- **A tap was running in every interior.** `amb_room` was broadband noise lowpassed at 420 Hz
  and normalised to 0.16 — about 11 dB under the music, which does not read as "a room", it
  reads as water in the next room. Two fixes: filtered far lower and dropped to a third of the
  level, and, more importantly, a room tone now only plays on interiors with **no music**
  (the attic and the dormitory). It exists to fill silence; running it under a scored room put
  a hiss beneath De Ketel and all three Instituut rooms. `amb_rain` and `amb_canal` came down
  with it — a bed sits under the music, not beside it.

### Verification

- `tools/test.sh` green: 3746 passed / 0 failed, the **ambience** suite now 150 checks. It
  asserts every track named by a map exists as a wav (an unknown name makes `play_music()`
  return quietly, so a typo is a silent map), that the two scenes with no map to declare them —
  title and match — have theirs, and that De Ketel and the Instituut do not share a theme.
- **The bug this pass uncovered: the game has never had audible music.** Wiring the title
  screen and the match board meant actually measuring the output, and
  `AudioServer.get_bus_peak_volume_left_db()` read **-97 dB** while `_music.playing` was true
  and `volume_db` had faded correctly to 0. `play_music()` set `loop_mode = LOOP_FORWARD` on
  the stream; these import as QOA, and a loop mode on a QOA `AudioStreamWAV` stops playback
  within milliseconds, so `_loop_music()` relaunched it on `finished` forever. Isolated by
  measuring the master peak across five variants of one stream:

  | | master peak | still playing |
  |---|---|---|
  | untouched | -8.3 dB | yes |
  | `LOOP_FORWARD` + `loop_end = 0` (shipped) | -13.3 dB | no |
  | `LOOP_FORWARD`, `loop_end` left alone | -90.3 dB | no |
  | untouched, on the Music bus | -14.1 dB | yes |

  The fix is a deletion: never set `loop_mode` in code, loop by replaying on `finished`. The
  file's old comment — "loop flags do not survive every import path; restart by hand" — had
  recorded the symptom as though it were the cause, and the manual restart hid it completely.
  `tools/check_audio.sh` + `tests/check_audio.gd` are new and now assert every track exceeds
  -45 dB at the master bus. They cannot join `tools/test.sh`, because `--headless` forces the
  Dummy audio driver and it reports silence for everything: a green headless gate is
  structurally incapable of catching this.
- Nobody can hear this, so each track was checked against its own score instead: a Goertzel
  probe over half-second windows recovers the dominant pitch from the rendered wav, and all
  five return their written melody in order, with no clipping and peaks of 0.32-0.46. It
  catches a wrong octave, a note in the wrong place, or two notes landing on each other. It
  cannot tell anyone whether the music is good.

---

## M18 — Rank follows results  [done]

Rank was awarded once, hardcoded, and never moved again: `["rank", "22k"]` in `kesh.json` was
the only rank action in the project. Everything downstream was inert because of it.

- `src/go/go_rating.gd` — a performance rating over a rolling window of rated games: the
  average strength of the opposition, adjusted by the score against it, with handicap stones
  folded in so beating a 1 dan on nine stones reads as a 10 kyu performance. Pure, stored
  nowhere, recomputed from `match_records` by `GameState.record_match()`. No hidden score
  (Rule 5) and no statistic on the character (Pillar 1).
- `MatchResult` now carries `opponent_strength` and `handicap_taken`, because a game's worth
  cannot be reconstructed afterwards from a cast list that may since have been edited.
- Every profile is `by_rank`; `GoMatchSetup` falls back to nigiri once the gap is under a
  stone, so the ceremony became something climbed to rather than the default. `kesh_first.tres`
  keeps `nigiri` for the scripted first game, whose dialogue explains komi.
- **Handicap is scaled to the board.** One stone per rank is a 19x19 convention and does not
  travel; the league was producing H9 on a 9x9, which is a board with no room left on it.
  `GoRank.ranks_per_stone()` is three ranks per stone on 9x9, and `max_handicap()` caps a
  board at its own star points — five on 9x9. The same matchup now plays H4.
- **The league is a league.** `LeagueTable` plays out the term's fixtures between the students
  from their ranks, deterministically, with upsets on close pairings pinned to a hash of the
  two names. Before this, only the player's own games existed, so one win topped the table.
  Rows on nought games now sort last: that is an absence, not a standing, and the footer
  already said so.
- `rank_at_least` / `rank_at_most` / `on_map` dialogue conditions. The Cup's "fifteen kyu and
  below" is a *ceiling*: it is a thing the player can be too strong for, and eventually is.

## M19 — The calendar and the Cup  [done]

The fiction had been promising a deadline since the first screen — "a tournament in six weeks"
in the quest summary, the noticeboard, Wren, Tomas, and Marguerite's "entries close on the
Friday" — against a `time_block` that nothing ever wrote.

- A day holds `SLOTS_PER_DAY` hours. A rated game or a class costs one; lessons, puzzles and
  unrated games are free, which turns a real distinction in Go culture into the economy and
  turns Tomas's "one game a day, and he means it" from a brush-off into a mechanic.
- Spending an hour moves `time_block` through morning, afternoon, dusk and night. The whole
  M14/M16 atmosphere layer had only ever been seen at "afternoon" in play.
- Sleeping is the only thing that advances the day, so nobody is punished for thinking about
  a position. Beds are `__BED__`-sentinel signs, following the board sentinels, so the map
  generator still owns the prose.
- **The Bondszaal** — the last unbuilt location in GAME_DESIGN §4. Reached by the southbound
  tram, because trams run both ways and the federation hall is not the Institute.
- **The Beginner Cup**: `src/academy/cup_draw.gd`, pure and tested like `LeagueTable`. Four
  rounds, one a day, McMahon-ish pairing on score. Nothing is stored — the crosstable is a
  function of the field and the games the player has actually played, so a save and a reload
  is the same tournament. Greedy pairing can strand the bottom of the table once everyone
  left has met everyone left; a forced rematch is the answer, because a tournament you
  entered must never hand you a bye.
- Three new entrants (Abel Roos 21k, Dov Halevi 19k, Moss Lindqvist 16k). Only Wren and Pip
  are weak enough for a 15k-and-below section, and a city tournament should bring in people
  the player has never met.
- Verified by playing it: the draw board, the pairing, and a round that opens on nigiri —
  because inside a capped section the ranks are close enough that `by_rank` gives an even
  game, which is exactly what Marguerite says the ceiling is for.

---

## M20 — Table talk  [done]

The opponent had two lines. `taunt_ahead` and `taunt_behind`, fired on
`move_number() % 7 == 0` and chosen by a crude whole-board count, so the same two
sentences cycled all game and nothing anybody said had any relationship to what had
just happened on the board. Pillar 3 says every opponent is a person first, and at
the board they were all the same person saying one of two things.

- `src/go/go_table_talk.gd` — pure. Classifies the last move into tags a person
  could react to: captures (graded by size), ko, atari, the first line played early.
  Tagged from the speaker's side, so `i_captured` and `you_captured` are the same
  move read from opposite chairs.
- `data/banter/*.json` — sixteen voices. A character with no line for a tag falls
  through to `default`, and a character who should not have one simply does not get
  a line: Hana answers a capture with a question rather than a boast, and Joos
  manages "Mm." That is characterisation as data, with no special cases in code.
- `src/go_ui/table_talk_voice.gd` — picks a line, with a cooldown and a ban on the
  same remark twice running. Silence is the common case and is the point: somebody
  who comments on every move is a tutorial, not an opponent.

**The boundary with the review, which is the design decision here.** Banter reacts
to *outcomes* — a capture landed, a group died, a ko started, the score swung. The
review reacts to *decisions* — the move you did not see. If Kesh says "you missed
that atari" live on move fourteen, the review saying it on the result screen has
nothing left to reveal, and the review's whole value is telling the player something
they did not already know. The one deliberate exception is announcing your own
atari, which is characterisation rather than analysis: it discloses nothing the
board is not already showing, and whether a character does it says a lot about them.
Pip shouts it. Hana never would.

`taunt_ahead` / `taunt_behind` are deleted from `OpponentProfile` and the `CAST`
table rather than left as dead exports; `on_resign` stays, and is still read.

---

## M21 — The curriculum  [done]

The game taught liberties, capture and self-capture, then handed the player a full
scored game using territory rules it had never explained. Wren's own lesson outro
promised the missing half and pointed at Hana, who never delivered it.

Seven new lessons, and the teachers they belong to:

| lesson | teacher | where |
|---|---|---|
| `ko` | Wren | De Ketel, once the rulebook has settled |
| `escape` | Kesh | after she has beaten you with a cut |
| `connection` | Kesh | after `escape` |
| `two_eyes` | Hana | the Institute class board |
| `life_and_death` | Hana | the class board |
| `ladders` | Bertie | Molenpark |
| `counting` | Tomas | De Ketel |

- **`GoLessonData` gained a pre-move.** Ko is a fact about history, not about a
  position, so a board handed to `set_position` has no ko on it and the engine
  happily allows the retake. A step may now open with the opponent's move, which
  means the ko lesson is refused by the same rule that refuses it in a real game.
- **The openings class finally counts.** It is built on "I am not going to tell you
  why. You are going to count," and its `encloses` / `region_at` keys were read only
  by the validator. The runner now highlights the pocket and states its size and
  cost, so the argument is made by the board.
- **The class board walks a track** instead of the dead branch that returned
  `openings` twice under the comment "the only class built so far".
- **The study desk exists.** GAME_DESIGN promised the board in your room replays
  problems; it was a sign you could read. Eight puzzles now, in teaching order --
  and `capture_2`, written long ago and referenced by nothing, is reachable.
- **Two teachers were in the wrong place.** Bertie's own first line is "four kyu,
  forty years, one park bench" and he was under a viaduct; he is in Molenpark now.
  **Tomas was on no map at all** -- he owns the bar, he is named on its sign, he had
  a sprite, a portrait, dialogue and an 8 kyu profile, and he stood nowhere. He is
  behind his counter, he teaches the endgame, and his "one game a day, and I mean
  it" is now a game you can actually play.

**What the validator learned**, because every one of these is a position written by
hand and CLAUDE.md's rule is never to trust one:

- `liberties_after` / `liberties_at` -- a group told to run must actually get out.
- `eyes_after` / `eyes_at` -- a group told it is alive must have the eyes.
- `connects` -- a move told to join two groups must leave them as one.
- the ko rule, so a forbidden retake is not waved through as legal.
- puzzle `kind`: capture, live or escape, since a puzzle about living has a correct
  answer that takes nothing off the board.
- **stray characters.** `parse()` read anything it did not recognise as an empty
  point, so a typo at the start of a board row produced a valid, wrong position that
  every other check then passed. It caught a real one within a minute of existing.

The ladder was not written by hand at all. Four attempts at deriving one by eye were
wrong -- white gains three liberties on each extension unless the chasing stones are
placed exactly -- so `tools/` searched for a genuine sustained ladder using the rules
code and the lesson was emitted from the result.

---

## M22 — Twelve opponents instead of one  [done]

`reading_depth` was documented as 0/1/2 and the code only ever tested `>= 1`, so
Hana at 5 dan ran the same policy as Ilse at 9 kyu. The single real strength dial
was `mistake_rate`, and it replaced the best move with a *uniformly random legal
one* -- Wren at 0.45 played a random point on the board nearly every other move.
Pillar 3 asks that every opponent be a person first; at the board they were all the
same person, differing only in how often they threw a move away.

- **Mistakes are plausible now.** Candidates are ranked, and a blunder picks from a
  shortlist whose width comes from `mistake_rate` (`MISTAKE_BREADTH`). A 20 kyu does
  not play a random point; they play the fourth-best move, confidently. Measured:
  200 openings from a 0.9-blunder profile put **74 stones on the first line** under
  the old code and **none** under the new, and `tests/test_go_ai.gd` asserts the
  zero. Weakness now reads as misjudgement, which is the only kind of weakness a
  player can learn from.
- **`reading_depth = 2` does something.** `_worst_reply()` looks at what the
  opponent could capture immediately, over the liberties of chains the move
  actually touches -- a full reply search per candidate is not affordable and would
  not have found anything this AI could use.
- **Style flags, from the blurbs.** `ladder_happy` (Pip: "attempts ladders, the
  ladders do not work" -- nothing at the board made him do it), `cut_bias` (Kesh
  cuts, which the dialogue had always claimed and the board never showed),
  `book_moves` (Ilse opens on the corner star points by rote and is on her own the
  moment the book runs out). Off by default, so nobody acquires a habit by accident.

The style test is worth reading before changing it. Asserting "a ladder-happy
player chases" passed at 40/40 for *both* profiles, because atari on a nearby stone
is already the top-scoring move and everybody chases. The test now zeroes
`aggression` on both sides so the ordinary pull toward contact is out of the way and
the chase is the only thing that can produce the move: 0 for the calm profile, and
the habit for the other.

**Arcs, gated on the record.** A new `played_at_least` dialogue condition, and three
of them written -- Ilse, Sunny and Orla, who are the people a student actually plays
over and over. Each advances on games played, not on affection (Rule 4 intact), and
each says something the character could only say after that many games: Ilse decides
the books were never the problem, Sunny complains that she has stopped being able to
read four moves ahead of you, Orla admits that top of the lower league is nerve
rather than talent.

**Not done here, and deliberately:** review voices for the rest of the cast. Ten of
fifteen characters still fall back to `data/reviews/default.json`. That directory is
being restructured with new detector kinds, and writing voices against a schema
about to change would be wasted work.

---

## Known debt and known bugs

Nothing here blocks the slice; all of it will bite later.

**Debt**
- **Rank follows results (M18).** `GoRating.performance()` is a pure function of
  `GameState.match_records` — a performance rating over a rolling window of rated games:
  the average strength of the opposition, adjusted by the score against it, with handicap
  stones folded in so that beating a 1 dan on nine stones reads as a 10 kyu performance
  rather than a dan one. Nothing is stored, so there is no hidden score (Rule 5) and no
  statistic on the player (Pillar 1); delete the save and the rank goes with the games that
  earned it. `record_match()` recomputes it; below `PROVISIONAL_GAMES` it declines to say,
  which is what lets Kesh's provisional 22k stand for the first couple of games.

  What that unlocked, and what is still open:
  1. **Handicap moves.** Every profile is `by_rank` now, so the stones shrink as the record
     improves, and `GoMatchSetup` falls back to nigiri once the gap is under a stone — the
     ceremony became something you climb to rather than the default. Kesh's scripted first
     game keeps its own `kesh_first.tres` at `nigiri`, because her dialogue explains komi
     and an unranked player would otherwise be handed stones and hear none of it.
  2. **Handicap is scaled to the board.** One stone per rank is a 19x19 convention and does
     not travel: `GoRank.ranks_per_stone()` makes it three ranks per stone on 9x9, and
     `max_handicap()` caps a board at its own star points — five on 9x9. The league used to
     produce H9 on a 9x9, which is a board with no room left on it rather than a game.
  3. **`rank_at_least` exists** as a dialogue condition, taking a label ("15k") so a graph
     reads like the Cup's entry form. Marguerite's Cup gate uses it.
  4. **Still open: league position is read by nothing.** `player_position()` feeds only the
     footer string. The exam is what will want it.

- **Dead-stone estimation is a heuristic** (`GoScoring.estimate_dead`). It is right on the
  positions a beginner reaches and the player can override every call, but it will mis-judge
  seki and complicated life-and-death. A GTP engine answers this properly with
  `final_status_list dead`; the seam exists.
- **The exam does not exist.** The league board and Marguerite both state that entry is by
  league position at the end of term, and nothing happens. The machinery it needs is now
  built and running -- a calendar, a term that ends, a pure draw module and a results board
  (`CupDraw` / `CupBoard`) -- so the exam is a content job rather than a systems one.
  `LeagueTable.player_position()` is still read by nothing, and that is what it will gate on.
- **The calendar has nothing to spend itself on.** Six weeks of term against one class, six
  league opponents and three lessons. "Sleep until the Cup" exists at the bed precisely
  because the middle of the term is empty, and it is a plaster over a content gap rather
  than a feature. The extra classes, the puzzle library and the opponent arcs are the fix.
- **The lessons stop where judgement starts.** Eleven of them now, through counting and
  life and death, which is enough to play a whole game and know why it was lost. What is
  not taught is whole-board judgement -- which group is worth abandoning, whether a move
  is worth eight points or two -- because the rules cannot answer it and the heuristic
  cannot either. That is the wall Act 3 runs into, not a missing lesson.
- **~~The tutorial stops at lesson 4~~ -- closed by M21**, which built the other seven and
  gave each of them a teacher, so a beginner is no longer handed a scored game with scoring
  unexplained. What the teaching path still gets wrong -- `self_capture` reachable from one
  dialogue choice, `knows_the_rules` meaning "has had any lesson", four lessons that end
  with their teacher saying nothing, and an autopilot script still driving a menu item
  deleted in M12 -- is **ROADMAP §6**.
- **Music is two short loops** and repeats quickly. It is pleasant enough under thinking but
  it is not a soundtrack.
- **The shipped AI stops playing once only first-line points remain.** That is honest Go
  judgement, but combined with a human who passes early it produces enormous margins
  (an autopilot game that passed throughout lost by 83.5). It needs a resign/mercy rule
  and a stronger midgame before it is a satisfying opponent above ~15 kyu.
- **A real Go engine was considered and declined (3 September 2026).** The question was
  whether to put KataGo or GNU Go behind the stronger half of the cast. Measured cost:
  KataGo's CPU/Eigen Linux build is ~40 MB (v1.18.1 — v1.18.2 ships CUDA-only), a strong
  network is ~100 MB, and the human-imitation net `b18c384nbt-humanv0.bin.gz` is 94.5 MB
  and is needed *in addition* to the strong net, not instead of it. That is ~235 MB against
  a 7.6 MB game. nixpkgs has `katago` (1.16.5, defaulting to OpenCL/CUDA rather than Eigen)
  and `gnugo`; neither bundles weights.
  Against that, the gain is small *for this game*: dan-strength opponents nobody has
  outgrown, point-value judgement no beginner can act on, and better dead-stone marking —
  the only real one, and beginner positions rarely need it. Turning an engine's visits down
  does not produce a kyu player either; it produces a dan player with worse precision, whose
  moves stay structurally sound. The heuristic's legibility is a teaching feature, and a
  ladder that does not work is content Pip is built out of.
  **What would change the answer:** a ladder that runs past ~8 kyu, i.e. Act 3. At that
  point `humanSLProfile` (`rank_9k` and so on) is the correct tool and is worth its size.
- **`GtpOpponent` is unwired, and three bugs stand between it and an engine.** Handicap
  stones are placed straight onto the board in `go_game.gd:46-48` and never enter
  `game.moves`, while `choose_move` issues `clear_board` every turn (line 43) and replays
  only `moves` — so the engine would analyse a board with no handicap stones on it, on the
  game's primary difficulty axis. `set_position` (puzzles, lessons) never reaches GTP at
  all. And `_command` blocks on `get_line()` (line 81), which would freeze the main thread
  for the length of a real search, despite the interface being built to `await`.
- **Two test hooks live in shipping code**: `Autopilot` is an autoload (inert without the
  command-line flag) and `GoMatch.THINK_DELAY_FAST` shortens the opponent's pause under it.
- **The UI is still positioned by hand.** A project-wide Theme now carries the font, and
  `UiKit` centralises label and panel construction, but the coordinates are still literals
  rather than containers. Good enough that text fits; not yet the container layout
  `godot-ui-control` describes.
- **`GtpOpponent` replays the whole game on every move.** Correct, but it must track an
  index before a real engine is attached.
- **Dialogue JSON is untyped.** Guarded by validation tests over every graph, not by types.
- **The heuristic AI recomputes empty regions every move.** Fine on 9x9; will need caching
  at 19x19.
- ~~**NPC schedules are groundwork only.**~~ Wired in M26: an NPC entry takes `"blocks"`, `build_npcs()` filters on the hour and `World._repopulate()` rebuilds when it turns.
- 7 of the 12 characters are placed on Steenbeek maps; only the Bondszaal is still unbuilt.

**Known bugs**
- ~~On a map narrower than the viewport the camera shows blank space at the edges.~~ Fixed in
  M14 phase 3: small maps are centred and a backdrop sits behind the tiles.
- Tree canopies do not occlude the player; entities Y-sort among themselves but not against
  tile props.
- The title screen's save summary was moved and given a shadow, but still sits over busy
  title art.
- The crowd window in the ceremony is a static strip; the onlookers do not react.
- Portrait expressions (neutral / happy / annoyed) exist for every character but most
  dialogue nodes do not choose one, so the neutral face is used more than it should be.

---

## M23 — The review, properly  [done]

M15 built a review that was correct and not yet useful. Played as the person it is written
for -- four days into Go, 22k, losing to Kesh by thirty-four points -- it had six problems,
and the first one was the worst.

- **The opening compliment was not guaranteed.** GAME_DESIGN and this file both state it as
  a rule; `select()` honoured it `if not good.is_empty()`, and `good_capture` needed three
  stones in one move while `good_save` required the rescued group to survive to the end of
  the game. So the losing games -- the ones P5 was written for -- were the likeliest to open
  on a criticism. `tools/review_distribution.gd` measured it at **44 of 60**. Fixed by
  lowering both thresholds, adding `atari_answered`, and adding `best_moment` as a floor:
  every game contains a move after which the player was better off, so there is always
  something true to open with. Now 60 of 60, across three player models and three strengths.
- **The gate withheld the two most actionable findings from the people who needed them.**
  `capture_missed` waited until 18k and `died_savable` until 20k -- above the band where
  most of the game is played. The order was the lesson order, which is ordered by what
  builds on what; a review has to be ordered by what you can act on tomorrow. Both are now
  ungated, and ranked by cost instead.
- **Severity was not comparable across kinds.** `stones + 3` here, a flat `5.0` there. A new
  `GoEvaluator` seam prices every finding in points; `GoProgress` implements it by counting
  what a person counts -- stones plus the regions only one colour has walled off -- after
  every move. Ranking is cost first, severity as the tiebreak, so the review leads with the
  worst thing that actually happened.
- **It said what happened and never what to do.** Findings now carry a `takeaway` (the rule,
  not the voice, so it lives only in `default.json`) and the id of the lesson that covers
  them, and `GoPuzzleData.from_finding()` hands the position back as a problem to solve.
- **You could not look at the board.** `positions_of()` already walked every position to
  find the findings and threw them all away; `GoReplay` puts a cursor on them and the arrows
  step through the game.
- **Nothing was remembered between games.** `MatchResult.review_summary` is small enough to
  keep in the save, and `GoReviewHistory` reads it back: which habits recur, how many games
  running, what to study.

**Five bugs found on the way, three of them by the tests and tools this milestone added.**

`positions_of()` fed a curve that was nonsense at the start of every game: on an empty board
the single region has no border, and after Black's first stone the *entire* rest of the board
is bordered by Black alone, so a 9x9 read +80 on move one and back to zero on move two.
`worst_swing()` then found an 81-point collapse in every game ever played -- a review
inventing a mistake, the one thing this module exists not to do. Territory has to be
regional to mean anything, which is the same trap `tools/check_lessons.py` was written to
catch in the openings lesson.

`dead_group_fed` keyed a group by its stones, and the chain grows by one every time it is
fed, so four wasted stones became four findings of one stone each and the count never
accumulated -- the same family as the two `stones[0]` bugs M15 found. It keys on the capture
now: everything taken in one move died together.

`best_moment` and the fallback compliment both fired on a three-move resignation, which
would have put a review screen in front of somebody who sat down and immediately quit.
`MatchBridge` skips the review when nothing was found, and that is the mechanism; both now
require `GoReview.ENOUGH_GAME`.

`_show_cells()` builds its board with `set_position()`, which leaves the move list empty --
so `GoBoardView`, which draws its last-move marker from `game.last_move()`, silently drew
nothing. A replay with no indication of what was just played is worse than no replay, and it
fails exactly the way the blank board view of M8 did: no error, no failing test.

And `tools/autopilot/review.json` was stale against M21's content. Kesh now opens with
`offer_escape` ("Show me." / "Not now.") rather than going straight to `rematch_offer`, so
the script chose "Show me.", drove itself into the escape lesson, and reported **0 script
errors** while screenshotting the wrong screen entirely. A green autopilot run proves the
game did not crash and nothing else.

**Done when:** the suite went 5118 -> 5480 checks with 281 covering the review and the
curve; every fixture *played* rather than drawn, so three that had drifted failed loudly
instead of testing positions nobody meant; `tools/review_distribution.gd` reported 60 of 60
games opening with praise at strengths 8, 11 and 15 across three player models, with no kind
above 40% of all findings. That harness carries a warning it is worth repeating: the
heuristic opponent is no longer a beginner. Since M22 it picks from a ranked shortlist rather
than playing randomly, and with `SELF_ATARI_PENALTY` on top it will essentially never
self-atari, fill its own eye or wander onto the first line -- a much better opponent and a
much worse *subject*. Every number that harness prints is a lower bound on what a person
triggers, not an estimate of it.

**The harness was hardened, because three of the four things that went wrong this milestone
were the harness lying rather than the code being wrong.** `tools/run_game.sh` gained
`SAVE=<preset>`, which regenerates save slot 1 before launching so a script declares the state
it needs instead of inheriting whatever the last run left behind — every script that ends by
saving through the pause menu had been poisoning the slot for the next one, and that produced
three wrong diagnoses in one evening. It also takes an exclusive `flock` and refuses to start
a second run: two runs share `user://save_*.json` and the screenshot folder, and the second
one's `rm -rf "$SHOTS"` deletes the first one's frames mid-flight, which surfaces as duplicate
shot indices and files silently missing from `OUT`. And the screenshot copy no longer ends in
`2>/dev/null`, which had been turning a failed copy into an absent file — the same trick
`_talk_to`'s warning played, and indistinguishable from a beat that never ran.

**One detector was deleted rather than fixed.** `first_line_early` fired on the outermost
ring within twenty moves; M20's `GoTableTalk` emits `you_edge_early` on the identical
condition, same window, same constant. Said at the table on move eight it is a nudge you can
still act on; repeated on the result screen it is a lecture about a game that is over. The
banter owns it now, which also disposed of an awkward 15k threshold on a mistake beginners
make constantly, and freed one of the three slots for something the player does not already
know.

---

## M24 — The exam  [done]

Act 2 had no ending. Marguerite said entry was by league position twice, the
league board printed it under every standing, and `LeagueTable.player_position()`
was read by exactly one thing in the project: the footer string underneath it.

- **`src/academy/exam.gd`** — four players, three rounds, top two pass. Pure and
  stores nothing, like `CupDraw` and `LeagueTable`: the crosstable is a function
  of the field and the games the player has actually played, so a save and a
  reload is the same exam. Where the Cup is McMahon this is a round robin, which
  deletes the pairing search entirely — with four people over three rounds
  everybody meets everybody once and a bye is arithmetically impossible.
- **The field is earned rather than declared.** `CupBoard.FIELD` is a constant;
  the exam's field is the top four of the lower league less Marguerite, who runs
  it. Before the exam starts the list on the wall is a live preview of the
  standings — look at it in week two and it tells you who would sit it if the
  term ended now. The first time it is asked for *after* the exam starts it is
  written down and read back from then on, which is what entries closing means
  and what stops the list changing under a player who wins a league game between
  rounds.
- **Marguerite's problem paper**, sat before round one — two positions from
  `data/puzzles/`, no hints, and sitting them is what counts. It pays off a line
  she has had since M13: "I run the register, the league board, and the part of
  the exam nobody thanks me for."
- **Both endings are written.** Passing gives a certificate and nothing else, and
  she says so ("It does not make you stronger"). Failing is an ending too — P5 —
  and Hana has the closing word on either, because she asked the player's name in
  the cold open and should be the one to say what the term came to.
- **Four unreachable opponents wired**, closing ROADMAP §2: Wren at De Ketel
  (so a beginner's first rated game is no longer against a 12 kyu), Bertie's
  unrated bench game, Hana's `hana_teaching` and `hana_9x9`, and Marguerite's own
  league fixture. `hana_teaching` had been orphaned since the day it was written.

**The five bugs this pass found, none of which a green gate would have shown, and
three of them older than the exam.**

1. **A tournament could not tell you it had ended.** `SceneRouter.go_to()` uses
   `change_scene_to_file()`, so the World is *freed* for the length of a match --
   and `World` was listening for `EventBus.match_finished` to notice that a Cup
   or an exam had played its last round. There is no World in the tree when
   `finish_match()` emits, so that handler had **never run, not once**. The Cup
   limped anyway since M19, because `_start_cup_round()` also sets `cup_finished`
   when you come back and ask for a round that is not there, so the flag arrived
   a conversation late and only if you asked. The exam made it visible: the
   standings on the wall said "you finished 3 of 4" while the journal still said
   "play your three rounds". The check runs in `_after_load()` now, where the
   world already collects `MatchBridge.last_result`, and one move fixes both
   events. Every part of this looked correct in isolation -- the emit is in the
   right place, the handler is on the right signal, and `change_scene_to_file`
   quietly deletes the listener.
2. **The journal never noticed a quest finishing.** `Hud` refreshed on
   `quest_advanced` and not on `quest_completed`, and `QuestTracker` emits the
   latter for the last step -- so a completed quest kept displaying its final
   objective until a rank, a day or an hour happened to change. Every quest in
   the game had ended that way since M6. One line.
3. **The league table could be ground.** It counted *every* rated game the player
   had played while the students played a round robin of five, against a sort
   that leads on wins — so twenty games and eight wins finished above a student
   who went 5-0. That is grinding past a stronger player and Pillar 1 forbids it;
   nobody had noticed because nothing read the position. It now counts the
   player's first game against each person, which is what a league is. Rematches
   still move rank through `GoRating`, which is where volume belongs.
4. **Two graphs offered a game and had no `post_match` node** — `tomas.json`
   since M21, `pip.json` since the prologue. `resolve()` returns `""`, the box
   never opens, and the after-game beat is skipped in silence. `tests/test_data.gd`
   now refuses the combination, and found the second one within a minute of
   existing.
5. **A player not in the exam field was told they finished fourth of four.**
   Nothing stops the simulation when the player has no game in it, so it ran to
   the end and `placing()` fell through to the bottom of the table. Found by
   looking at a screenshot, which is three for three this year for that rule.

**The shape all five share, and the thing worth carrying forward:** every one was
a failure that had been converted into an absence. A probe warning that printed
and carried on. A signal emitted into an empty scene tree. A quest completion
nobody was listening for. A `cp` with its errors sent to `/dev/null`. None of
them ever failed anything; they stopped happening quietly, and the run stayed
green.

**What the validator learned.** `tests/test_data.gd` never looked at an `exit` at
all, only at `goto`, so a wrong profile, lesson or puzzle id passed every check
in the project and failed silently at run time. It now validates every exit
target, requires a `post_match` node beside every `start_match`, and asserts the
reverse direction: a profile named by no dialogue must appear on a written
allow-list of the ones an event draws by string interpolation. `check_load.gd`
had been loading `hana_teaching.tres` faithfully every run since it was written.

**And the harness bug underneath all of it.** `slice_full` had not been playing
its match in three runs out of five since M16, and nothing had noticed because it
still wrote all nineteen screenshots and exited 0. M16 gave every NPC an idle
behaviour; several wander on a leash of about a tile and a half.
`Autopilot._talk_to` took the tile beside the NPC once, before walking, pressed
[Space] at where they had been, found nothing on the probe, printed a warning and
carried on — so the rest of the script ran against a world in which the
conversation had never happened. Measured on pristine HEAD at 3/5; `_talk_to` now
retries from where the person actually is and tests whether the dialogue box
opened rather than what the probe overlaps. 0/5 after. A flaky harness also fakes
a clean bisect: four single-sample runs pointed convincingly at three different
files before the rate was measured.

**Done when:** `tools/test.sh` green at 5481 / 0 with the new `exam` suite at 64
checks; `check_lessons.py` 0 problems; and six autopilot runs screenshotted with
0 script errors — the list of four, entering, the paper opening on `live_2`, a
round two that opens on nigiri because the exam is even, and both verdicts, plus
the refusal shown to somebody who finished sixth.

---

## After the slice

Most of this table is now done. What is left has moved to **`ROADMAP.md`**, which is
the authoritative list of unbuilt work; this is kept only to show what was outstanding
at the end of the slice and what became of it.

| Next | State |
|---|---|
| The attic, Onderbrug, the quay, the Bondszaal | **Built** (M14, M19) |
| Beginner Cup tournament | **Built** (M19) |
| Lesson/puzzle library | **Built** (M21) — eleven lessons, eight puzzles, a study desk |
| Audio | **Built** (M11, M16, M17) |
| NPC schedules | **Built** (M26). `"blocks"` on a map's NPC entry; Hana and Kesh cross between the Instituut and De Ketel, Pip and Bertie between the park and the arches |
| 13×13 + the club ladder | Still open, and now the natural next board size — the rank system it was meant to exercise exists |
| KataGo/GTP integration | Still declined; the condition has not changed (see the debt list) |
| The exam | Still open, and the most valuable single item left. Act 2 has no ending |

## M25 — Music for a game that counts  [done]

`theme_match` was the only thing that ever played under a game of Go, and the comment
in `tools/gen_audio.py` explaining why it is written to be ignored — 58 bpm, eight
notes in half a minute, anything busier competes with reading the position — is right
about a lesson, a puzzle and a game in the park. It was wrong about the rival who keeps
score, the man under the arches with no papers, and the exam that ends Act 2. Those
sounded like a lesson.

Resolved the way Pokemon resolves it, by tiering rather than by choosing: seven new
loops and four intro stings, and one pure function deciding between them.

**What was built**

- `MatchMusic.theme_for()` (`src/go_ui/match_music.gd`), static and pure so every
  branch is testable with no scene and no audio server. Occasion beats person beats
  tier: an exam or Cup round sounds like itself whoever the draw produced, then a
  profile's own `theme`, then `theme_battle` for a rated game and `theme_match` for a
  free one. The line between rated and free is `MatchRequest.unrated`, which the day
  economy already drew — this reuses a distinction rather than inventing a parallel one.
- `OpponentProfile.theme`, generated by `tools/gen_content.py` like everything else in
  `data/opponents/`. On the profile rather than in a table keyed by character because
  that is what distinguishes `hana_teaching` (no theme — a nine-stone teaching game
  scored like a title match would be lying to the player) from `hana_9x9`.
- Percussion in `gen_audio.py`, which had none: `_kick` (a pitch sweep, not a low note),
  `_snare`, `_hat`, and `_drums()` taking sixteen-character bar patterns — `"x...x..."`
  reads as a rhythm and a list of beat offsets does not, which is the same argument the
  file already made for note names over frequencies. Each hit is synthesised once per
  track and mixed in repeatedly; rebuilding a hat 128 times is the difference between a
  seven-second build and a very long one.
- Intro stings by convention: `Audio.play_music()` looks for `<track>_in`, plays it once
  at `INTRO_FADE` rather than the 0.9 s music fade (a sting is supposed to hit), and
  `_loop_music()` swaps the loop in when it ends. `_music_name` is the *loop* throughout,
  so the repeat-call guard and `stop_music()`'s clear-before-fade both still hold — the
  QOA rule is untouched and nothing sets `loop_mode`.
- `Audio.has_track()`, because `play_music()` returns quietly on a name it does not have
  and leaves the previous track running: a safe guard and a useless diagnosis.

**Two bugs found on the way**

- **The Bondszaal has been silent for its whole life.** It declared `"music": "institute"`
  where the file is `theme_institute.wav`, so the hall the Cup and the exam are held in
  played whatever the previous map had been playing. It escaped `test_world_ambience.gd`
  because `MAPS` omitted `bondszaal` — the list that proves every map's track exists did
  not contain every map. Fixed in `gen_maps.py`, and `bondszaal` added to that list with
  a comment saying what its absence hid.
- **`play_music`'s fade race was fixed in M17 and documented as outstanding ever since.**
  `CLAUDE.md` and `ROADMAP.md` both still warned about it; `_music_fade` and `_fade()`
  have killed the pending tween for both voices since M17, as M17's own entry records.
  Two separate sessions were steered away from a bug that did not exist. Both bullets
  retired.

**Verification, including what it does not cover**

`tools/check_melody.py` is new, and the first version of it was a fake gate: it compared
the rendered wav against the same note list that produced it, so changing a note moved
both sides and it reported ok. That was only discovered by deliberately breaking a track
and watching it pass. It now tests four things, each confirmed by breaking a track on
purpose and watching it fail — a harmonic swamping its fundamental, a filter removing a
note, a tempo that does not match the beat grid, and a note landing past the bar count
(`Sound.mix()` extends the buffer rather than refusing, so that one reads as a longer
track and never as an error). Its docstring now says outright that it cannot check the
note list is the tune anybody meant, because nothing mechanical can.

244 notes verified across the seven themes. `tests/test_match_music.gd` — 20 checks,
confirmed to fail on inverted precedence, which is the mistake that would put Joos on the
lesson bed. Full gate 5525/0. `tools/check_audio.sh` extended with the seven loops; the
four stings are deliberately **not** listed separately, since each is about two seconds
against a `LISTEN` of 2.5 and alone would read as a track that stopped — listening to the
loop covers the sting and the handover to it, which is the part that could break.

Still not covered, and unchanged from M17: whether any of it is any good. That needs a
person and a pair of headphones.

---

## M26 — The term gets a shape  [done]

Two problems that were the same problem. The term ran forty-two days and held about four
days of content, and the clock that measured it changed the light, the sound, the crowd
and the music while every person in the city stood on the same tile at midnight as at nine
in the morning.

**The term is a fortnight.** `CUP_DAY` 42 -> 14, `EXAM_DAY` 38 -> 10, which is roughly what
the content supports: nine open days, the exam's three rounds, a clear day, the Cup. Every
day count in the game is derived from those two constants, so the code side was two lines.
"Six weeks" was written in three places and not the four ROADMAP §0 claimed — Wren, Hana
and the `first_stones` quest summary. The Ketelsteeg noticeboard, named as the fourth,
carries no duration at all and never did.

The two "Sleep until..." options stay. They were a plaster over a term four times longer
than its content; against nine open days they are an ordinary convenience, which is the
difference between covering a gap and closing one.

**People have somewhere to be.** An NPC entry may now carry `"blocks": ["dusk", "night"]`.
It is deliberately not a new concept: `TileAnimator` and `Soundscape` have both read a
`blocks` array for milestones, with absent-or-empty meaning always, so `build_npcs()` reads
it the same way and every map that predates schedules works untouched. Fourteen lines of
engine; the rest is content in `gen_maps.py`.

What it buys is the setting saying out loud what it was built on. Hana and Kesh were on two
maps each *because* the city has two Go cultures, and until now that was two permanent
copies of each. Now Hana teaches at the Instituut in daylight and is at De Ketel after
dark. Pip and Bertie are in Molenpark by day and under the arches at night — which finally
populates a map that can never have a crowd route (walled at both ends, so `validate()`
correctly rejects every one). The bar is shut in the morning, so De Ketel's back room is
Wren alone. The study hall empties as the day goes on and Ilse is still there at midnight,
out of a book.

**The four things that could have gone wrong quietly, and what was done about each.**

1. **A schedule can hide a quest step.** The default is "present at every hour" and
   `tests/test_data.gd` enforces it, with a written allow-list of the five who are
   deliberately absent at some hours and why — the same shape as `REACHED_BY_EVENT`, and
   for the same reason: an absence should be a decision somebody made. It also asserts that
   De Ketel and the study hall are staffed at *every* hour, because a room that empties is
   an hour the player cannot spend, and no way to spend an hour is no way to reach the hour
   when the person they want is back. That is the one way a schedule can deadlock the game
   rather than merely inconvenience. Both guards were confirmed by deliberately scheduling
   Wren out of the morning and watching two checks fail.
2. **A misspelt hour deletes a person from the whole game.** `GameState.BLOCKS` is
   morning/afternoon/dusk/night, and GAME_DESIGN §4 said "Morning / Afternoon / Evening" —
   so "evening" is the word the next person reaches for, and it would match no hour at any
   time and remove them silently. `gen_maps.validate()` now rejects unknown block names,
   confirmed by feeding it one. The design doc's line is fixed too.
3. **The rebuild could have paired somebody with a corpse.** `queue_free()` lands at the end
   of the frame and `Npc.find_peer()` searches the "npc" group, so an incoming Kesh would
   have found the *outgoing* Orla and held a reference to a node already going — "converse"
   standing there facing nobody, with no error. The outgoing NPCs leave the tree before the
   new ones are built. Measured for leaks afterwards rather than assumed: ten hour-toggles
   in a four-person room leak the same two ObjectDB instances as a run that never changes
   the hour at all.
4. **The save presets carried literal days.** Seven of them — 42, 41, 40, 39, 38, 36 —
   against a term that just moved. None would have errored: `exam_ready` at day 36 against
   `EXAM_DAY = 10` is a save twenty-six days past the exam, and a screenshot of the wrong
   starting state looks exactly as confident as one of the right state. `make_test_save.py`
   reads the constants out of `game_state.gd` now.

**And one the audit caught rather than a person.** Scheduling Joos to the hours he actually
exists broke two autopilot scripts that visit him in the afternoon, and neither would have
said so — `city.json` would have photographed an empty viaduct and `joos.json` would have
walked to a tile with nobody on it. Found by checking every script's `talk_to` targets
against the new schedules mechanically instead of by eye; only those two of twenty-two were
affected, which is also what confirmed that keeping Kesh and Hana on the afternoon in both
places was the right call — Act 1 meets them at De Ketel on day one at that hour, and a
schedule may not break the opening.

**Done when:** `tools/test.sh` green at 5525 / 0 (the schedule suite is 18 of them);
`check_lessons.py` 0 problems; `gen_maps.validate()` clean; and four autopilot runs
screenshotted and *looked at*. The new `schedule` script is the evidence: De Ketel at
morning is one person and at night is four, from the same tile with no scene change in
between, and Onderbrug goes from three people under the lamps to an empty row of crates.
The first cut of that script shot the spawn tile and captioned it "Molenpark" — it was
exactly as convincing as the correct frame, which is the third time this year that rule has
earned its place.


---

## M27 — The teaching path  [done]

This is a game about being taught Go, and the part that does the teaching was the part
nobody had revisited since there were three lessons in it. M21 grew the curriculum to
eleven and left the machinery at three. ROADMAP §6 listed seven faults; all seven are
closed, and three of them changed what a player was actually taught rather than merely
how it was worded.

**The one worth naming, because it is a pattern and not an accident.**
`knows_the_rules` was set by `finish_lesson` whenever *any* lesson completed with an empty
queue. So Bertie's ladders, or Tomas's counting, or a class at the Instituut, all declared
the rulebook taught. It gated five things — the study desk, Joos, Bertie, Tomas and Wren's
ko lesson — and it was never wrong, because it was never really right: it measured
something far broader than its own name. Two other sessions hit that identical shape in
this tree on the same day: a melody checker comparing a wav against the note list that
generated it, and a data test that walked every map's NPCs with no concept of hours. Three
in one day is a pattern worth writing down. **A check or a flag whose name is narrower
than what it measures passes for years and tells you nothing.**

It was also worse than ROADMAP §6 recorded, which is the argument for verifying documented
debt rather than repeating it. `kesh.json`'s `offer_escape` is not gated on the flag, so a
single lesson from Kesh retroactively unlocked four of those five at once — and a
player who told Wren outright "I know how the stones move" was refused by every one of them
until that happened, because that answer set only `wren_knows_you_can_play`, which had zero
readers and was set by the `cup` node on every path through it regardless of what the
player had said. Now split: `said_knows_the_rules` for what you said, the three
`lesson_<id>_done` flags for what you were taught, and `knows_the_rules` as the or of them.

**A lesson ends on `taught_<lesson>`, falling back to `taught`.** `World._post_lesson`
opened `taught` and nothing else, and only Wren and Hana had one — so Kesh's escape and
connection, Bertie's ladders and Tomas's counting ended in silence, four of eleven. Not a
crash: `resolve()` returns `""`, `DialogueBox.run` emits `end` without showing a box, and
the teacher simply says nothing. The one general seam fixes both halves of the problem,
because the other half was Wren having *one* `taught` node closing *two* lessons — it ended
`"goto": "cup"`, and ko is only ever offered after the Kesh game, so finishing ko sent the
player back through "That's Kesh over there, by the window. Twelve kyu." about somebody
they had already played.

**Two of the four silent lessons were not missing their writing.** Bertie and Tomas both
had the paragraph, in nodes called `after_lesson`, reachable from `start` — so it played
one conversation late, and read as a greeting instead of a close. Bertie's "Read it to the
end. That's it. That's the whole of what I know that Pip doesn't" is good and had never
once played at the moment it was written for. One line each.

**And the rulebook can be asked for twice.** `wren_asked_experience` closed
`ask_experience` for the life of the save, so a beginner who forgot what a liberty was had
nowhere to go. Wren offers it again from `repeat` and from both game offers. Deliberately
on her rather than at the study desk: GAME_DESIGN says there is no menu item because being
taught by somebody is the point, and the desk keeps handing out problems.

**Four guards, each confirmed by breaking the thing on purpose and watching it go red.**
A test that has never failed is not yet a test — this project shipped `check_melody.py`
once in a state where it compared a wav to the note list that produced it and passed.

| Guard | Broken on purpose | Result |
|---|---|---|
| every lesson's teacher has a close | deleted Bertie's `taught` | 1 failed |
| tracks name real files | typo'd `capture_3` in `PUZZLE_TRACK` | 1 failed |
| every dialogue node is reachable | added an orphan to `joos.json` | 1 failed |
| ... and the allow-list is load-bearing | dropped `pip.json` from `KNOWN_ORPHANS` | 1 failed |
| lessons are reachable both ways | dropped `self_capture` from the track list | 1 failed |
| the rulebook is taught whole | removed `track` from Wren's capture choice | 1 failed |

The last one is the general form of the `self_capture` bug rather than the specific one:
*any* `start_lesson` exit naming a lesson in `TUTORIAL_TRACK` must carry `track`, because
entering the rulebook part-way and not finishing it is the fault, not that one node being
wrong. The tracks are read off the script with `get_script_constant_map()` rather than
named directly, because `MatchBridge` is an autoload and an autoload is not resolvable as a
plain identifier in a `--script` run — the same reason `dialogue_graph.gd` looks its own up
by path.

**`tools/autopilot/tutorial.json` is deleted, and its replacement had the same disease.**
The old script drove a title-screen item removed in M12, so it pressed Continue and wrote
twelve screenshots of the overworld named `lesson_intro` and `step1_liberties`.
`lessons.json` replaced it — and `lessons.json` moved the board cursor three squares left
and **never moved it vertically at all**, so it could not reach the answer to step 1 of the
ko lesson. It sat on step 1 for the life of the file while writing shots called `ko_taken`,
`step_two_intro` and `refused`, exiting 0 with no script errors. The whole §6 fix was
verified against those images before anybody opened them; opening them is what found it.
Both scripts now navigate by clamping into the corner and counting out, which cannot drift
no matter where the cursor starts.

That is the third time this year the same rule has earned its place, and it now has a
sharper form than "look at the screenshots": **a screenshot is evidence of the frame it
contains and of nothing else.** A file named `f_refused` is a claim, not a result.

**Done when:** `tools/test.sh` green at **5824 / 0** (up from 5525; 150 files load),
`check_lessons.py` 0 problems, `gen_maps.py` regenerates every map byte-identical, and two
autopilot runs screenshotted and *looked at* — Wren closing ko on "That is genuinely the
whole rule. It has a long name and a short meaning, like most of this", and Bertie closing
ladders on "Corner, side, centre, and read your ladders. Forty years and I could have had
it on a postcard." Both are beats that, before this milestone, the player never saw.

**Left undone, deliberately.** `pip.json`'s orphaned `capture_go` node is now detected and
allow-listed rather than fixed: the intended entry condition is not obvious from the file
and it wants whoever wrote the prologue rather than a guess. And the audit turned up one
new gap, recorded in ROADMAP §8 — `check_load.gd`'s `EXTS` is `gd/tscn/tres/fnt`, so the
load gate walks `res://data` and opens none of the JSON in it.


---

## M28 — Thirteen by thirteen  [done]

The title refers to the nine star points of a 19×19 -- *the shape you grow into* -- and for
twenty-seven milestones there was nothing to grow into. Every board was 9×9 except Pip's
7×7. `intro.json` describes the board the last tenant left as "nineteen one way, nineteen
the other", so the player has owned a 19×19 since minute one and never played on one, and
Hana closes Act 2 by naming the board the game does not have. GAME_DESIGN §9 puts chapter 2
at 13×13 on a gate of three rated games won. The intent had been written for four
milestones. This is the work.

**The bug underneath it, which is the part worth keeping.** `GoRating._effective_strength()`
priced a handicap stone at **one rank**. `GoRank.ranks_per_stone()` deals them out at
**three a stone on 9×9**, two on 13×13, and one only at 19×19 -- the size the convention was
written for and the one board this game does not have. So the rating read the stones back in
a currency they were never paid in: a 22 kyu who beat Orla on the five stones the game
itself handed them was credited with having beaten a 9 kyu, five ranks and a rank class out.
Pillar 5 is that the table is honest, and it had not been since handicap games existed.

ROADMAP §5 had this written down as a hazard *waiting* at a new board size -- "the first
record at a new size mis-rates the player". It was wrong about the tense, and being wrong
about the tense is what kept it in a list of future work for four milestones instead of on
the bug pile. **Verify documented debt rather than repeating it**, which is the second time
in two milestones that has paid: M27 found `knows_the_rules` was worse than this file said.

Every new rating assertion was watched go red against the old arithmetic before the fix:
`five stones from a 4 kyu on 9x9 is a 15 kyu performance, not a 5 kyu one  (got 25, want 15)`.

**What was built:**

- `GoRating` scales stones by `GoRank.ranks_per_stone(record.board_size)`. Records have
  always carried `board_size`; it was simply never consulted. It defaults to 9 rather than
  19 for a record without one, because 9×9 is the only board this game has ever recorded a
  rated result on and the 19×19 default would reinstate the bug on exactly the old saves the
  fix exists for.
- `OpponentProfile.path_for(id, board, variant)`. Three places interpolated
  `"%s_9x9.tres"` inline -- the Cup round, the exam and its fallback, and `go_match`'s debug
  path. Fine while nine was the only board, a silent lie the moment it was not. Stated once
  now, and mirrored once in `gen_content.py`, which writes the files.
- `tomas_13x13` and `kesh_13x13`, generated. **Two people and not the cast**: a profile
  nothing can reach fails `test_data.gd`'s reachability check, and the honest answer to that
  is fewer profiles rather than a longer allow-list. The guard was seen to fail on both
  before they were wired into dialogue.
- `resign_threshold` scales with the board's area in `gen_content.py`. It is an absolute
  point count tuned at 81 of them: Kesh giving up forty points behind is decisive on a 9×9
  and a bad afternoon on a 13×13. Every zero stays zero, so `pip_capture` and everyone who
  never resigns are byte-identical.
- `rated_wins_at_least`, a dialogue condition counted off `match_records` every time it is
  asked. A condition and not a flag: Rule 5 forbids the stored score, and M27's lesson is
  that a flag whose name is narrower than what it measures passes for years and tells you
  nothing.
- Tomás offers the back table and Kesh the study-hall board, each with the `post_match`
  node Rule 6 requires -- `tomas.json` is the graph that shipped a `start_match` without one
  and lost the whole after-game beat in silence. Kesh's 13×13 is a **third choice on the
  same menu as the nine**, deliberately: picking the size is the decision, and putting it
  behind its own gate would take the league game away from anybody who said no once.
- `thirteen_ready` in `make_test_save.py`, and `build()` now honours a preset's own
  `time_block` -- schedules decide who is standing in the room, so the hour is part of the
  state a preset declares rather than a constant.

**The screen, which was the one real rendering defect.** Row numbers were drawn left-aligned
from a fixed inset inside a margin of `_cell * 0.72`, and `_cell` shrinks as the board grows
while "13" does not. At 13×13 the margin is 9 px and the label is 12, so it started at the
left edge of the wood and finished on top of the first column of stones. Never seen at 9×9
because those labels are one digit. The margin now has a floor of the widest row number plus
air, and the numbers are right-aligned to the grid. **The 9×9 board is pixel-for-pixel where
it was** -- cell 20, origin 16, margin 14.4 -- because the re-fit only fires when the label
is what forces the margin, which at nine lines it never is. The single-digit labels sit
4 px further right, which is the whole of the visible change.

**The numbers, reported rather than asserted.** `tools/review_distribution.gd` takes a board
size now (`-- 13`) and its own caveat still stands: three player models, every figure a
lower bound on what a person triggers.

| | 9×9 | 13×13 |
|---|---|---|
| games reviewed | 60/60 | 60/60 |
| opened with something the player did | 60/60 | 60/60 |
| two or more findings | 60/60 | 60/60 |
| `best_moment` (random model, 22k) | 25 | 12 |
| AI mean move time (kesh profile) | 0.58 ms | 1.17 ms |
| AI worst move time | 1.26 ms | 2.31 ms |
| self-play game length (kesh) | 139 moves | 477 moves |

The review holds: it still opens with something the player did in every game, which is the
floor it is not allowed to miss. Move time is not a problem at either size. **The self-play
length is**, and it is the AI's known weak endgame showing up larger rather than anything
new -- 1.7 moves a point at 9×9 against 2.8 at 13×13. It is not player-facing in the same
way, because the AI passes back once the opponent has passed and nothing scores above
`PASS_THRESHOLD`; it is still the argument for the mercy rule ROADMAP §8 asks for.

**Done when:** `tools/test.sh` green at **5864 / 0** (up from 5824), `check_lessons.py`
0 problems, `gen_maps.py` byte-identical, `gen_content.py` adding two files and changing
none. Two autopilot runs screenshotted and *looked at*: `thirteen` for the new board and
`handicap` to confirm the 9×9 did not move.

**And the new script caught itself doing exactly what this document keeps warning about.**
The first cut of `thirteen.json` exited 0 with seven screenshots and no script errors,
having played a **9×9**. `advance: 8` happened to end its tap budget one line short of the
choice, so `choose: 1` found no list to move in, and a later `tap: interact` selected
option 0 -- the league game. Every frame looked confident. It was found by opening
`05_e_thirteen_with_handicap_stones.png` and reading "9x9 Komi 0.5 H2" in the panel of a
file with `thirteen` in its name. The script now runs to the choice with
`advance: 30, stop_at_choice`, and places its one stone by clamping into a corner and
counting out, because `move_cursor` clamps and a count from a wall cannot drift. A file name
is a claim; the panel is the result.

---

## M29 — The endgame  [done]

Three documents said the same sentence -- ROADMAP §5, ROADMAP §8 and CLAUDE.md's known
gaps -- and none of them said it precisely: *the AI's endgame is weak, it stops playing
once only first-line points remain, so a human who passes wins by a margin that means
nothing.* Half of that was true and the more expensive half was missing.

**What was actually wrong.** `choose_move()` passed only when the opponent had *just*
passed **and** its best move scored under a threshold. So against anybody who kept
playing it never stopped at all: it filled the dame, then its own territory, then played
single stones into settled enemy areas where they died, one after another, until no legal
non-eye move remained. `_candidates()` refused its own settled regions up to
`maxi(8, cells / 4)` points and never refused the opponent's, which is that invasion loop
in one line. And `_line_value()` -- third line +4, first line −4 -- is an opening
heuristic that was being applied to move 150 exactly as to move 1, which is the half the
documents did record.

**Measured before anything was changed**, with `tools/ai_endgame.gd`, which is new
because M28 measured these numbers by hand and left nothing to re-run them with. 24
self-play games a pairing. "Wasted" is a stone played onto a point that
`GoScoring.territory_map()` already gave to somebody -- deliberately *not* the opponent's
own idea of settled, because a policy that grades its own homework stops playing pointless
moves at the moment it redefines pointless.

| 9×9 | moves | worst | per point | wasted | ended in passes | worst move |
|---|---|---|---|---|---|---|
| kesh vs kesh | 96.3 → **79.8** | 145 → **99** | 1.19 → **0.99** | 10.7 → **3.9** | 24/24 → 24/24 | 1.72 → 1.87 ms |
| wren vs kesh | 138.2 → **76.8** | 486 → **92** | 1.71 → **0.95** | 42.7 → **4.8** | 21/24 → **24/24** | 1.48 → 2.00 ms |
| random vs kesh | 98.6 → **93.7** | 122 → **126** | 1.22 → **1.16** | 14.3 → **12.8** | 24/24 → 24/24 | 1.51 → 2.14 ms |

| 13×13 | moves | worst | per point | wasted | ended in passes | worst move |
|---|---|---|---|---|---|---|
| kesh vs kesh | 297.9 → **156.2** | 1014 → **177** | 1.76 → **0.92** | 87.3 → **3.6** | 21/24 → **24/24** | 4.00 → 3.98 ms |
| wren vs kesh | 334.2 → **159.2** | 1014 → **189** | 1.98 → **0.94** | 124.0 → **4.3** | 20/24 → **24/24** | 4.12 → 4.41 ms |
| random vs kesh | 193.9 → **188.9** | 262 → **224** | 1.15 → **1.12** | 22.6 → **24.4** | 24/24 → 24/24 | 7.50 → 5.56 ms |

The 1014s are the guard, not a game: three 13×13 pairings in twenty-four never ended.
The random pairing barely moves and should not -- half of that waste is the random player's
own, and it is in the table as the control that says so.

**What was built:**

- **`GoEndgame`** (`src/go_ai/go_endgame.gd`), pure and static: which empty points belong
  to somebody and are finished with. A region qualifies when it is enclosed by exactly one
  colour, is small enough for that to mean something, and has walls that are neither in
  atari nor already judged dead by `GoScoring.estimate_dead()`. It is in `src/go_ai/` and
  not `src/go/` because "small enough to be sure of" is an opinion a two-ply reader holds,
  and `src/go/` may only contain things that are true.
- **Two caps, and they are different on purpose.** Their ground stops being settled past
  `maxi(8, cells / 4)`, because being wrong there only means declining to invade and an
  invasion is exactly the judgement this reader does not have. Your own stops at `cells / 2`
  -- not a judgement about points, since filling your own territory is wrong at any size,
  but the bound that stops "enclosed by one colour" from meaning "the open board, and only
  I have a stone near it".
- **The pass rule is now the absence of a candidate.** `choose_move()` already passed when
  `_candidates()` came back empty; with settled ground filtered out of it on both sides,
  "nothing contested is left" *is* a pass, and it needs nobody's permission. That single
  change is what ends the 477-move game.
- **The mercy rule** replaces the old score threshold. When the opponent has passed and
  `_area_lead()` says the game is decided by more than `MERCY_SHARE` (0.18) of the board,
  it counts rather than plays on. When the game is *close* it plays on, because those
  points are real and passing them back was the whole of "a margin that means nothing".
- **The positional term fades** with the share of the board still in dispute, so the first
  line stops being a mistake once there is no board left to divide.
- **A pass is an event.** `GoTableTalk.events()` returned early on any move with no point,
  so the one thing that happens at the board and produces no tag was passing. It emits
  `i_pass` / `you_pass` now, nine banter files have lines for them, and the match scene
  reacts to the player's pass as well as the opponent's -- which is the only warning a
  beginner gets that passing does not end a game on its own. A pass that *does* end the
  game holds for `PASS_BEAT` before the counting screen writes over what they said.

**Done when:** `tools/test.sh` green at **5961 / 0** (from 5864), `check_lessons.py` clean,
`gen_content.py` and `gen_maps.py` byte-identical -- this was a policy change and no
generated file moved. `review_distribution.gd` re-run at both sizes: 60/60 reviewed, 60/60
opened with something the player did, 60/60 with two or more findings, nothing above 40%.

**Ten deliberate breaks, and four of them exposed the tests rather than the code.** Each
guard was reverted on purpose and the suite re-run:

| broken | result |
|---|---|
| no cap on your own territory | 2 failed |
| settled points not filtered from candidates | 1 failed (the self-play length) |
| atari clause out of the wall test | 1 failed |
| dead clause out of the wall test | 4 failed |
| no cap on an enemy enclosure | 12 failed |
| mercy rule removed / firing always | 1 failed each way |
| nothing ever settled | 11 failed |
| the positional term never fades | 1 failed |
| a pass produces no tag | 4 failed |

The first pass of that table had **four rows reading "0 failed"**, and they are the part
worth keeping:

- The test named *"a region whose wall is in atari is not settled"* was passing because the
  wall was also **outnumbered**, so the dead clause was answering and the atari clause was
  never asked. Deleting the clause the test was named after broke nothing.
- The test named *"a dead wall encloses nothing"* asserted the settled set was **empty**,
  when the position also contained a sixty-five point region that legitimately belonged to
  White. It failed for a real reason the first time it ran -- and the real reason was a
  **bug**: the opponent called a wide-open board its own territory whenever the other
  player's last stones were walled in, and passed with sixty-five points empty. That is
  what `territory_cap` is for, and it exists because a test was written badly enough to
  find it.
- The *"no cap on your own territory"* test passed under the break because the dead group
  in its corner always left White something else to play. It needed a Black group that was
  **alive**, so that the open board is the only thing left to refuse.
- The guard against reading the opening as territory (`both colours have a stone on the
  board`) turned out to be **dead code** -- `territory_cap` already refuses a region that
  large -- so it was deleted rather than kept as a clause that is never wrong and never
  right either. Its two tests stay, guarding the cap.

**Looked at, not reasoned about.** `tools/autopilot/endgame.json` (new): start a league
game, play one stone, then pass and keep passing. Frame 3 is Ilse answering the pass --
"Already?" -- at move 5, with the game still going and her reply already on the board.
Frame 10 is move 33 and she is still playing. Frame 11 is **move 37: "Nothing left I want.
I'll pass."** -- the mercy rule, in her own words, with the right-hand column and the bottom
rows of the board still empty, in a game that was sixty-eight points decided. She stopped
because it was over, not because the board was full. The count that follows is a real count.

**And the script's own first cut lied in exactly the way this file keeps warning about.**
Three frames named `e_counting`, `f_result` and `g_review` were the same result card,
because the burst of passes ran eight passes past the end of the game and `go_pass` accepts
the count. The shots are named after the pass they follow now, which is a fact rather than
a prediction.

## M30 — The hooks  [done]

ROADMAP §3 has said "fill the term" for four milestones and the first reading of it was
wrong. The term is a fortnight, three slots a day, forty-two hours; the slot-costing content
that exists is twenty-eight. That looks like a shortfall of fourteen hours until you open the
graphs: `ilse`, `orla`, `sunny` and `nadia` all reach `offer` from `start` on *every* visit,
with `<name>_stage_2` and `_stage_3` nodes that vary on the head-to-head, and `bertie`,
`joos`, `kesh`, `pip`, `tomas` and `wren` all carry rematch nodes. **Rated play was already
unbounded.** What the term lacked was not hours to spend but days that differ from one
another: between day 3 and day 8 nothing changed except a head-to-head counter.

So this milestone added a second thing that moves.

**The hooks.** `src/club/hooks_ladder.gd`, pure and static, the shape of
`LeagueTable.standings()` and disagreeing with it on purpose about everything else. Seven
name-cards on the brass hooks at the back of De Ketel; the order is derived from
`GameState.match_records` and stored nowhere (Rule 5). Three rules, each a design decision:

- **Only wins move a card, and only upwards.** Beat somebody hanging above you and you take
  their hook; they and everybody you passed move down one. Losing does nothing, because a
  ladder you can fall down is a ladder nobody challenges up — and it cannot be ground, since
  the only legal move is to beat somebody currently better placed than you (Pillar 1).
- **Unrated games count.** This is the entire reason it is a module rather than a second
  `LeagueTable` roster, which must go on refusing them. Bertie's bench and Joos's crate had
  been playable and consequence-free since M22.
- **A new card goes on the bottom hook**, not at your rank. The card says your rank; the
  hook says where you sit; the room does not care what the card says until you have beaten
  somebody in it. Tested with a 1 dan's card, so that the two can actually disagree.

The setting had already written this and nothing read it. Tomás says "it goes on the hooks"
on two existing match offers and "I keep the cards, I notice" on a third; `__HOOKS__` has
been a sign sentinel since M14 and drew a rank tutorial. He writes your card the first time
you speak to him with a rank, and starts `the_hooks` (four steps: read them, take one, reach
the top three, take the top hook).

**The two things hanging on that wall are now kept apart**, and the distinction is the whole
setting in one function. The *card* is a document: rated games only, `GoRating`, the
Instituut's kind of truth. The *hook* is where you sit in the room, and counts every game
played in it — the park, the arches and the back table included. The old text said "Only
rated games. The park and the arches are for playing, not for counting", which was true of
the card and became false of the wall the moment the wall meant something.

**`SignDesk`** (`src/rpg/sign_desk.gd`). ROADMAP §8 said `world.gd` was 700 lines; it was
**745**, which is the ordinary way a number in a document goes stale. Everything you *read*
or *sit at* — the three boards, the study desk, the hooks, the bed — moved to a component,
and `world.gd` is **577**. The seam is reading versus starting a match, which is where the
two halves actually fall: the Cup round, the exam round and the problem paper stay in the
World because they route through MatchBridge and spend an hour, and the class board is
reached from the desk through an injected callable for the same reason. The desk keeps **no**
"a box is open" flag of its own — it is handed `set_talking` and the World's `_talking` stays
the only copy, because two flags meaning the same thing is exactly how `knows_the_rules` went
wrong in M27.

**Content, and why these particular pieces.** Classes 3 → 5 and puzzles 8 → 12:

| new | why this one |
|---|---|
| `capture_race` (class) | the semeai, taught as arithmetic: your liberties, their liberties, whose move it is |
| `false_eyes` (class) | completes `two_eyes`; the way "two eyes is life" actually goes wrong |
| `capture_5` | one point that is the last liberty of *two* chains |
| `escape_3` | the group with one liberty whose escape point is a wall — the answer is to capture instead |
| `live_3` | two groups with one eye each are two dead groups |
| `connect_1` | a new *kind* of problem, not a twelfth of the same one |

Both classes are deliberately things the **rules** can settle. `tools/check_lessons.py` can
only guard a claim it can decide, and its `eyes_of` counts orthogonal neighbours — so it
would call a false eye an eye. A `false_eyes` lesson whose claims were "this point is not
really an eye" would therefore have shipped unverified, which is the one thing this project
has a rule about. It is taught through what the checker *can* decide instead: White captures
the stone that was making the eye; Black connects it instead; the same shape with the stone
attached refuses the same move as illegal. `connect_1` needed a new puzzle kind, so
`GoPuzzleData.KINDS` now exists and `test_data.gd` reads it rather than keeping a second
copy of the list — the copy in the test being the one that would have gone on passing.

**The quay has somebody on it.** 364 tiles, two signs and nobody: the map GAME_DESIGN says
you come to after losing, with no one there to have lost to. Orla walks home that way at
dusk, is a different person off the premises (`on_map` branch, the idiom Marguerite's two
desks already use), and will play one on the bench that goes on no board and no card. She
was already on the schedule allow-list and still is — a third hour, not a fourth.

**Done when:** `tools/test.sh` **6114 / 0** (from 5961), `check_lessons.py` clean,
`gen_content.py` and `gen_maps.py` regenerated (one new quest, one new NPC entry; everything
else byte-identical), `gen_maps.validate()` green.

**Seven deliberate breaks, each reverted and the suite re-run:**

| broken | result |
|---|---|
| `HooksLadder` skips unrated games | 3 failed |
| losing drops your card | 1 failed |
| a class dropped from the reachability allow-list | 1 failed |
| Orla's `post_match` deleted | 4 failed |
| Orla scheduled onto the quay at every hour | 1 failed |
| each new puzzle's solution moved off the answer | 4 problems (`check_lessons.py`) |
| each new lesson's liberty/eye/connect claim falsified | 4 problems |

**Looked at, not reasoned about.** `tools/autopilot/hooks.json`, from a new `hooks_ready`
preset — ranked, in De Ketel at night, two hooks already taken and one of them unrated.
Frame 8 is the wall: Hana 5d, Joos `-- no card --`, Bertie, Tomás, Kesh, then **Ro at 22k in
sixth**, above Pip at 18k and Wren at 20k, both marked `taken`. A 22 kyu standing above an
18 kyu is the design on screen: the hooks are not rank order and never were. Frame 5's HUD
carries the journal line the quest had just started, and frame 9's carries the next one, so
the chain from Tomás through the board to the second step is a fact rather than an argument.

**And the script's first cut lied in the way this file keeps writing down.** It counted
`advance` in *lines of JSON*, and the dialogue box paginates — a three-line node is not three
presses. Every shot after the second was named for a beat that had not happened yet: frame 9,
called `i_the_wall`, was Tomás still talking. Exit 0, 0 script errors, eleven confident PNGs.
It advances generously with `stop_at_choice` now, and the names were checked against the
images rather than against the intent.

## M31 — Three saves, and the way in and out of them  [done]

`SaveSystem` has taken a slot since M9. `SLOT_COUNT := 3`, `path_for(slot)`, `save_game(slot)`,
`load_game(slot)`, `slot_summary(slot)`, and a `delete_save(slot)` with **no caller anywhere in
the project**. Then the two places the game actually used any of it collapsed all three back
onto one: `pause_menu.gd` wrote the literal `save_game(1)`, and the title screen read
`newest_slot()`. So the player had one save, a second playthrough destroyed the first without
saying so, and nothing could be thrown away. A constant that said three where the player had
one, for twenty-two milestones.

**The panel is one component, not two lists.** `SaveSlots` (`src/ui/save_slots.gd`, 270 lines)
is raised by the title screen and by the pause menu, in three modes -- LOAD, SAVE, NEW -- and
it is one component because the title and the pause menu ask the same question of the same
three files, and a second copy of that question is a second copy to keep in step. It lists
what is actually in each slot: name, rank, minutes, and underneath, the day, the hour and the
place, read from the map's own `"name"` so there is no second table of place names to drift.
`SaveSystem.slot_info()` is the one parser; `slot_summary()` is now written on top of it
rather than beside it.

Three decisions in it, each of which could have gone the other way:

- **New Game does not ask when it does not have to.** It takes the first empty slot and goes
  straight into Hana's cold open, exactly as before. Only with all three taken does it open
  the panel. The opening is the one place the game is allowed to be a cold open, and a menu
  in front of it every time is a tax on the common case to cover the rare one.
- **Deleting answers only to [Del], never to the accept key.** It is the resign guard's shape
  (`go_match.gd:609`) for the resign guard's reason: while the card is up, every other key is
  swallowed, so an arrow cannot move a cursor behind it and a mistyped Space cannot throw a
  playthrough away. `delete_save` is a named input action rather than a raw keycode check
  because the autopilot sends `InputEventAction` -- a raw check would make the delete flow
  undriveable, and an undriveable flow is an unverified one.
- **Saving over the slot the run already lives in is not an overwrite.** Asking every time
  would train the player to dismiss the card, and a card that is always dismissed is not a
  guard. `SAVE` on the active slot goes straight through; every other occupied slot asks.

**`active_slot` is not in the save file.** The path is the slot's identity; a number written
inside would disagree with it the first time somebody copied one. `reset()` therefore leaves
it alone, and needs a comment saying so, because `from_dict()` calls `reset()` first and would
otherwise wipe the slot the loader had just chosen.

**The menus grew, and the harness navigates them by counting.** `autopilot.gd` can only send
named actions, so every script drives a menu as N × `move_down` then `interact`. New Game and
Continue stay at title indices 0 and 1; "Save game" stays at pause index 1 **and stays a save
with no further prompt**, because `slice_full`, `joos`, `win_path` and `exam_final` all end on
one `move_down` and an `interact` and expect a file afterwards. Everything new went on the end.

**Done when:** `tools/test.sh` **6193 / 0** (from 6114), `check_lessons.py` clean, and the
fourteen frames below opened one at a time.

**Six deliberate breaks, each reverted and the suite re-run:**

| broken | result |
|---|---|
| `delete_save` returns true without removing | 10 failed |
| every `save_game` writes slot 1 | 27 failed |
| a corrupt file reads back as `ok` | 2 failed |
| the `return_position` size guard removed | 2 failed |
| `from_dict` drops `match_records` | 2 failed |
| `first_empty_slot` always says 1 | 3 failed |

The fourth of those is the one worth keeping, because it reported **nought failed** twice
before it reported two, and the first explanation of why was wrong.

An out-of-bounds array read in GDScript does not return a wrong answer. It abandons the
function it is in -- here `from_dict`, at the `return_position` line -- and hands the caller a
null, so `load_game` still returned true and `return_position` still held the `Vector2.ZERO`
that `reset()` had put there four lines earlier. Every field the test looked at was written
*before* the bad line, so the guarded and unguarded versions were identical to it. The test
now puts `has_return_position` and `playtime` in the malformed file, which `from_dict` reads
**after** the position, and asserts them: with the guard they arrive, without it the function
never gets that far. The guard was doing something the whole time; the test was looking in the
place where it made no difference.

The first attempt at a fix -- calling `load_game` from its own frame so a crash costs one
assertion rather than every assertion after it -- was aimed at the wrong mechanism, and is
kept anyway: a test whose only failure mode is not running is not a test, and that stays true
whichever function the error abandons.

**A bare autoload name in a test file typed the singleton as `Node` for the entire run.** The
new suite passed 64/0 on its own and failed under `test_runner.gd`, with
`save_system.gd:50`'s `GameState.to_dict()` -- untouched production code that works in the
game -- reporting *"Nonexistent function 'to_dict' in base 'Node'"*. The cause was one line in
a different file: `test_data.gd` said `GameState.BLOCKS`, which the analyser resolves before
the autoload's script is in the global cache, so it settled on plain `Node` and kept that
answer for everything compiled afterwards. It had been killing `_test_dialogue_branches`
outright since that test was written -- thirteen assertions that had never once executed,
under a green report -- which is why fixing it moved `content data` from 4471 to 4484 checks.
Fetch the autoload into an **untyped** local; `: Node` is the same bug written by hand, and is
why `ExamBoard.summary()` at `test_exam.gd:135` is still dead. It is in `ROADMAP.md` §8.

**Looked at, not reasoned about.** `tools/autopilot/saves.json`, from a three-slot fixture:
Ada at 8k on day 8 in the Bondszaal, Bo at 18k in the Study Hall, Cass at 22k in De Ketel at
night. Frame 2 is New Game refusing to guess with all three taken. Frame 3 is the list, cursor
on slot 3 because it is the newest. Frame 6 is the pause menu after loading slot 2 and it says
**Bo 18K** -- the proof that a *chosen* slot loaded rather than the newest. Frame 8 asks
before writing over Cass; frame 11 asks before deleting; **frame 12 is frame 11 again**,
because between them the script presses the accept key and nothing happens, which is the whole
point of the guard. Frame 13 has slot 3 reading `empty`, and frame 14 has the title's summary
line following the delete to Bo rather than describing a file that is gone.

**And the first cut of that script lied, in the way this file keeps writing down.** All three
fixture files were written inside the same second, so `newest_slot()` had a tie and broke it
arbitrarily at slot 1 -- and it feeds both Continue and where the list opens its cursor, so
every `move_down` afterwards landed on a row the script had not meant. The run was exit 0, 0
script errors, fourteen confident PNGs of the wrong rows: frame 6 said Cass where the note
said Bo, and only opening it caught that. The fixture stamps the slots a minute apart in slot
order now. The same fault has a second face: `slice_full` declares no save and starts from New
Game, which now takes the first *empty* slot -- so it silently began saving into slot 2
because the previous run had left slot 1 occupied. It carries `{"save": {}}` now, the empty
declaration, which clears all three.

## M32 — Page Forty  [done]

The last unstruck bullet of `ROADMAP.md` §3 was *fetch-with-meaning*, and `GAME_DESIGN.md`
§7 ended on the same sentence. Five quests shipped and all five were some form of *play
games and win*; the shape the game did not have was an object you are handed and have to
give back.

**The writing had been there since M21 in two files that were never connected.**
`ilse.json`, after she beats you: *"Read the first forty pages. Then come back and beat me
with something that is not in them."* `nadia.json`: *"I always have the book with me."* and
*"The book will still be here. So, unfortunately, will page forty."* Ilse sends everybody;
Nadia is the only person who has page forty. Nobody had ever been able to go and get it.

So: `page_forty`, four steps. Borrow it from Nadia in the classroom, read it at the desk in
the attic, beat Ilse with something that is not in it, hand it back.

**The point of it is that the book does not work**, and that is Pillar 1 argued by two
characters rather than asserted in a design document. Ilse has read four books on the opening
and two on the endgame and is nine kyu and says so unprompted; when you beat her carrying
four hundred pages of correct play she says she has just watched it done with the book shut,
in the bag, on the floor. Nadia asks which page it was, and then tells you not to answer,
because it was not a page, it never is, and she has six books and eleven years of knowing
that and still asks. Nothing in the quest is a modifier. It is a narrative key in exactly the
sense GAME_DESIGN §2 allows and nothing more.

**It also crosses the canal**, which is what makes it this game's fetch rather than a fetch.
It is an Essenveld object carried down into Steenbeek: Wren gets one look at it and cannot
read it and is delighted that it exists, and Joos -- who has no card and no papers and a
withheld 3 dan -- turns it over, recognises the spine, and says do not bring it down here
thinking it is a rank. Both are once-only branches on `has_item`.

**One primitive, and it was missing.** `GameState.give_item` shipped in M6 with no opposite:
no `take_item`, no `item_lost`, no dialogue action. "Return the book" would have played the
thank-you with the book still in the bag and Nadia's next `has_item` branch would have gone
on asking for it. `take_item` and `["take", "<id>"]` are the whole of the new code besides
the desk branch.

**And the journal was choosing which quest to display by filename.** `Hud.refresh` read
`Quests.active_quest_ids()[0]`, and `active_quest_ids` walked `QuestTracker.quests` -- the
order `DirAccess` handed the `.tres` files back in. So the objective line showed whichever
active quest sorted first alphabetically, and a quest taken on later than an unfinished one
was invisible for as long as the older one ran. `page_forty` starts days after `enrolment`
and would never once have appeared. Nothing errored. It was found by opening the third
screenshot of the first run and reading the bottom-right corner, which is how all of these
are found. It walks `GameState.quests` now -- insertion-ordered, saved and reloaded in that
order, so "last started" survives a save where the tracker's own dictionary never could --
and the decision lives in `QuestTracker.journal_quest_id()` rather than in the Hud, because
the Hud has no test suite and the tracker does.

**Done when:** `tools/test.sh` **6306 / 0** (from 6193), `check_lessons.py` clean, and the
frames below opened one at a time.

**Seven deliberate breaks, each reverted and the suite re-run:**

| broken | result |
|---|---|
| `take_item` emits but never erases | 2 failed |
| a typo in Nadia's `take` id | 1 failed |
| a quest waits on a match context nothing starts | 1 failed |
| a quest step advances on an event nothing emits | 1 failed |
| `first_stones` points at a puzzle that does not exist | 1 failed |
| `active_quest_ids` ordered by filename again | 1 failed |
| the Hud reading the first active quest again | **0 failed** — see below |

**The sixth and seventh are the two worth keeping.**

The sixth passed first time round. The guard asserted that starting `enrolment` and then
`page_forty` put `page_forty` last -- which the *broken* version also does, because those two
happen to sort alphabetically into the order they are started in. A test that agrees with the
bug it is written against is not a test. It now asserts the same pair started **both** ways,
and the filename version fails the second half.

The seventh could not be made to fail at all, because the decision was in `hud.gd` and the
Hud has no suite. Rather than write one for a UI file, the decision moved into
`QuestTracker.journal_quest_id()` and the Hud's line became a single call, which is the
smaller change and the one that leaves something a test can hold.

**One more thing the new guards found on their way in.** `test_runner.gd` works from
`_initialize()`, which runs **before any autoload's `_ready()`** -- so `Quests.quests` is
empty for the whole suite and every quest id looks unknown. The journal test loads the
registry itself and says why. Worth knowing before writing any other test that expects an
autoload to have done something in `_ready`.

**Looked at, not reasoned about.** Three scripts, three presets, twenty-four frames.
`book.json` from `book_ready`: Nadia's lend, with the toast already reading *"Read page
forty. There is a desk in the attic"* over her head, and the journal line under it agreeing
-- that second one is the frame the ordering bug was found in, before it agreed. Then Ilse in
the study hall: *"You have got her book. Page forty, presumably."* `book_read.json` from
`book_held`, at night in the attic: the desk with three options where there are normally two,
page forty itself, and then Joos under the arch with *"What's that under your arm."*
`book_back.json` from `book_won`: the hand-back, *"No -- do not answer. It was not a page,"*
`Quest complete: Page Forty`, and then **talking to Nadia a second time**, which is the only
visible proof `take_item` did anything -- there is no inventory screen, so the evidence is
that she says the book is back on the shelf instead of asking for it again.

**The first cut of `book_read.json` chose an option that was not on screen yet.** The desk
paginates its prose before it shows its choices, so `choose: 1` landed on a page of narration
and did nothing; the run was exit 0 with no script errors and a confident screenshot of the
first page of the desk description, twice. It carries an `advance` with `stop_at_choice`
before the choice now. Same disease as `lessons.json` in M27 and the same cure: open the PNGs.

**A bullet written in the wrong tense, and corrected before the commit was a day old.** The
first draft of M32's debt said "a quest step *now* depends on a scheduled NPC, and nothing
checks that", crediting this milestone with introducing the pattern. It did not.
`first_stones` step 3 wants Hana **at De Ketel** and she is not there in the morning -- Act 1,
mandatory, and true since schedules landed in M26. `page_forty` is the second instance and the
milder one. `ROADMAP.md` section 5 already records this file being "confident and wrong about
which tense the bug was in"; this is the same mistake, caught only because somebody asked
whether the debt was really ours. Checking took one script over the quest resources and the
map data. Writing it down took no time at all and was wrong.

**One live bug found on the way out, fixed on the same branch.** Checking whether the debt
bullet above was really M32's meant reading `_start_class`, which is gated on `can_act()` --
hours left in the day -- and not on the teacher being in the room. Hana teaches in the
classroom in the morning and the afternoon and is at De Ketel after that, so at dusk the
demonstration board started a class in an empty room: it cost an hour, ran the lesson, and
`_post_lesson` then looked for the teacher, found nobody and returned without a word. Present
since schedules landed in M26.

Reproduced before it was touched (`tools/autopilot/class_dusk.json`, frame 3: *Corner, Side,
Centre* opening at dusk with nobody at the front) and again after (the same frame, now the
refusal). `institute.json` re-run to prove the afternoon class still starts, because a fix
that closes the wrong hours is worse than the bug. The refusal string is the joke of it:
*"Hana has gone home"* was already written and already correct, and had been attached to
whether the day had hours left rather than to whether she was standing there.

`world.gd` has no test suite, so the evidence here is the two frames and not an assertion --
stated plainly rather than glossed, the way the Hud's half of the journal bug was.

**Deliberately not done.** Page forty is prose in the margins, not a position on a board.
`tools/check_lessons.py` can only guard a claim the rules can decide and a joseki is
whole-board judgement, so a taught position here would have shipped unverified -- and the
page is not supposed to help anyway, which needs no diagram.


## M33 — The open section  [done]

`ROADMAP.md` §5 listed the Cup's missing 13×13 section under "still open, and deliberately",
and said the plumbing was ready. It was: `OpponentProfile.path_for(id, board, variant)` has
taken a board argument since M28, and `src/rpg/world.gd` carried a comment written in advance
of this milestone — *"when it exists, the section decides this argument and nothing else in
the round has to change."* That turned out to be exactly true, and it is the least
interesting half of what was here.

**The other half is that improving locked you out of Act 2's ending.** `marguerite.json`'s
`cup_outgrown`, shipping since M24: *"You are past fifteen kyu, which means you are too
strong for the Beginner Cup and I can no longer enter you in it."* And then nothing. There
was no other section to be entered in, so the reward for getting better was less game — P5
upside down, in the one document the player actually reads, which is the dialogue.

So: **two sections, and the difference between them is the argument.** The beginners' section
has a ceiling — fifteen kyu and below — and therefore no handicap, because the entry
requirement does that job. The open section has no ceiling and hands out stones instead.
Those are the two ways Go deals with a gap in strength, and the Cup now runs one of each.
Nine lines below the ceiling, thirteen above it.

**The open field is the two Go cultures at one table**: Kesh, Ilse, Tomás, Sunny, Orla —
the Instituut and De Ketel in one column, which happens at the Bondszaal and nowhere else,
because the federation is neutral ground and the club is not. Joos is not in it and cannot
be: no card, no papers, and the federation needs a rank written down. That is asserted in
`test_cup.gd` rather than left as an omission somebody could later read as an oversight.

**Playing up is a choice and it carries a warning.** A player still under the ceiling with
three rated wins — the same `rated_wins_at_least` gate that opened the club's 13×13 in
M28 — may enter the open section instead. Marguerite enters them, and says first that it is
not brave and not a mistake, that it is four games against people who will beat you, and
that some players learn more from that fortnight than from the year around it and some just
lose four games. The game does not decide which; it is the only place both sections are
offered at once.

**Done when:** `tools/test.sh` **6397 / 0** (from 6306), `check_lessons.py` clean, and the
frames below opened one at a time.

**What it dragged into the light, and the first one is the milestone's real find.**

**A `CanvasLayer` that reads an autoload cannot be tested at all.** The section vocabulary
went onto `CupBoard` first, which is the obvious place — it is the Cup's panel. The suite
runs as `--script`, where autoloads do not exist, so `cup_board.gd` fails to compile,
`CupBoard` resolves to a bare `GDScript`, and **every static on it returns null while
erroring into a log nobody greps.** The two new cup tests aborted at their first
`CupBoard.` call: the suite reported **80** checks where it now reports 115, and passed. A
test that does not run is worse than no test, because it is a claim.

It surfaced only because the same commit's `test_data.gd` guard failed *loudly* for what
looked like an unrelated reason — eleven profiles suddenly unreachable — and the
investigation went one layer down instead of adding names to an allow-list, which would
have "fixed" it and left the twenty dead assertions in place.

Fixed by obeying a boundary that already existed rather than inventing one: the sections,
`PLAYER_ID` and `summary()` moved to `CupDraw`, which is pure, exactly as `LeagueTable` is
pure beside `LeagueBoard` and `HooksLadder` beside `HooksBoard`. `cup_board.gd` keeps one
function that reads a flag. The cup suite went 72 → 115.

This is the **third** costume of the same bug — `ExamBoard.summary()` at `test_exam.gd:135`
is still dead for it, and the `GameState`-typed-as-`Node` bug from M31 is it again. Written
up in `ROADMAP.md` §8 with the rule that would have caught it: **if a test names a class,
check the class compiles without autoloads.**

**`LeagueTable` excluded exam contexts and not Cup ones.** `league_table.gd` has skipped
`Exam.CONTEXT_PREFIX` since M24 with a comment saying why — *"sitting round one against Ilse
would rewrite the very standings that decided you were entitled to sit it."* The identical
argument applies to a Cup round and there was no guard. It was safe only because no Cup
entrant had ever been on the league roster, which is not the same thing as being guarded,
and the open section puts four of them in the draw. One symmetric line, and a test that was
watched to go red.

**`HooksLadder` needed no such fix, and that is the interesting half.** Its docstring already
says the hooks count everything that happened at a table — "a league fixture, an exam round,
it makes no difference to a hook". A Cup win over Tomás moves a brass card, and should: the
two progressions are supposed to disagree. Asserted in `test_hooks.gd` so that nobody
"fixes" it later out of symmetry with the league.

**The allow-list of profiles reached by an event is now derived.** `REACHED_BY_EVENT` in
`test_data.gd` was a hand-typed list with `# CupBoard.FIELD` written beside it. ROADMAP §8
already records what that shape costs — `LESSONS_REACHED_BY_TRACK` is a hand-kept copy of
the track it guards, so adding a class means remembering two places and the copy in the test
is the one that goes on passing. Five new entrants on a bigger board is exactly that trap.
It reads `CupDraw.FIELDS` and `LeagueTable.ROSTER` now.

**Two labels the second section made wrong.** `which_desk` offered "The Beginner Cup." when
the desk now runs two of them, and the finished-Cup toast in `world.gd` hard-coded "You won
the Steenbeek Beginner Cup" — it calls `CupDraw.summary()` now, which is the sentence the
wall already uses, so there is one copy of it rather than two.

**Six deliberate breaks, each reverted and the suite re-run:**

| broken | result |
|---|---|
| the `CupDraw` exclusion dropped from `LeagueTable` | 6 failed |
| a typo'd id in `FIELD_OPEN` | 1 failed |
| `board_for` always returns 9 | 4 failed |
| `ilse` dropped from `THIRTEEN_FIELD` and regenerated | 1 failed |
| nothing writes `cup_section` for the open section | 1 failed |

The third is worth reading. Making `board_for` lie produced four failures and **three of
them were in a different suite**: `ilse_13x13`, `orla_13x13` and `sunny_13x13` became
unreachable profiles, because the derived allow-list asks the section which board it plays
on. A hand-written list would have reported one failure and hidden three.

**A guard for the thing no other guard could see.** `_test_every_section_is_enterable` walks
every dialogue graph for `["set_flag", "cup_section", …]` and requires each section CupDraw
knows to be written by one, and requires nothing to write a section it does not know. A
section nothing enters you in is a board size, a title, a field and five generated profiles
that load, pass every other check in the project, and never once happen.

**Looked at, not reasoned about.** Four scripts, four presets, twenty frames.

`cup_outgrown.json` from the new `outgrown` preset, in the Instituut hall: the sentence that
used to be the whole of it, and then *"It is not. It is the open section, which has no
ceiling and is played on thirteen lines, and which you are now the weakest person eligible
for."* `cup_playing_up.json` from `playing_up` — eighteen kyu, four rated wins — for the
three-way choice that exists nowhere else. `cup_enter_open.json` from `open_ready` for the
entry itself and the toast. `cup_open.json` from `open_day`: the draw on the wall reading
**STEENBEEK CUP — OPEN SECTION** over Orla 4k, Sunny 6k, Tomás 8k, Ilse 9k, Kesh 12k and
`> Ro` at 13k, and then a round played out to a board with **thirteen** lines on it, A–N,
*"Round 1. Board 1. 13x13."*

`cup.json` and `cup_round.json` were re-run unchanged afterwards, because a fix that closes
the old section is worse than the dead end it opened. A 22 kyu still gets the beginners'
section, the beginners' field, and nine lines.

**Three things the frames caught that the suite could not.**

`cup_open.json`'s first cut advanced into `which_desk` and pressed choice 0, which is *the
exam*. The run was exit 0 with no script errors and a confident screenshot of Marguerite
explaining the qualifying exam, filed under the name `d_round_one_board`. This is the M27
and M32 disease for the third time and the cure was the same: open the PNGs. It carries the
choice index and a note saying which one is the exam now.

The presets that make the open section reachable are all `enrolled`, and an enrolled player
at the Bondszaal gets the two-desk choice that `cup_day` never sees — so every existing Cup
script had been exercising a path the new ones do not take.

And a screenshot taken 1.4 s after a line begins is a screenshot of the typewriter still
typing, which reads *exactly* like a card clipping its own text. Two frames were diagnosed
as a layout bug before the wait was lengthened and the sentence finished itself. The
pagination was fine; the ▼ was there all along.

**Deliberately not done.** No 13×13 Cup for the *beginners'* section, and no second draw
structure: `CupDraw` was not touched beyond gaining the vocabulary, because it already took
a field and stored nothing, which is why a second section cost one argument. 19×19 is still
screen space rather than plumbing. And the tournament routing is still in `world.gd`, which
is **591** lines — three more than it was. ROADMAP §8 says so rather than this milestone
pretending it shrank.

## M34 — The week has a shape  [done; ROADMAP §3 stays open]

`ROADMAP.md` §3's second bullet was the only item in the section still marked *half done*, and
the highest-ranked open item in the file. Its own diagnosis was the ticket: *"What the term
lacked was not hours to spend but **days that differ from each other** — nothing changed between
day 3 and day 8 except a head-to-head counter."*

**The reason none did was structural, and nobody had gone looking for it.** `GameState.day` was
read in exactly four places — `EXAM_DAY`, `CUP_DAY`, the HUD line, and the study desk's
`PUZZLE_TRACK[day % size]`. That last one was the *only* mechanic in the game where one day
differed from another. Schedules keyed on `time_block` and nothing else. **M26 built half a
calendar and the half it built was the clock:** the hour decided who was in the room, and the
day decided nothing at all.

So the schedule gained a day axis, and it is spent on one thing worth planning around.

**`"days"` beside `"blocks"`, and both must pass.** A map's NPC entry may carry
`"days": ["wednesday"]`, with the same absent-or-empty-means-always reading that `blocks`,
`TileAnimator` and `Soundscape` all share, so every entry written before either axis existed
keeps working untouched. Club night is the evening hours *and* Wednesday — not a third kind of
rule. `GameState.WEEKDAYS` mirrors `BLOCKS`, `weekday()` is derived from `day` and stored
nowhere, and a fortnight is exactly two weeks, so the period needed no constant to justify it.

**The rule went on the pure half on purpose.** `MapData.is_present(spec, block, weekday)` is a
static on the autoload-free class. Written on `MapBuilder` — the obvious place, since that is
what filters the NPCs — it would have been unreachable from every test in the project, silently,
because `MapBuilder` reads `GameState` and the suite runs as `--script`. That is ROADMAP §8's
list, and this is the first milestone to consult it *before* paying for it rather than after.

**Club night at De Ketel, Wednesdays.** Nadia and Orla come down from the Instituut. They were
chosen by looking rather than by taste: they are the only two people in the game who are
**nowhere at all at night**, so the night costs nobody their own place and puts nobody on two
maps at one hour. Six in the room instead of four. Both have a club-night voice and an unrated
game, so the night moves brass cards and never the league — the distinction the two progressions
exist to draw. Orla's is the second place she is a different person off the premises, which the
quay already established. Sunny is nowhere at night too and is deliberately not there: she is
nine.

The player can see it coming, or a schedule they cannot read is indistinguishable from
randomness: the Ketelsteeg noticeboard carries it beside the Cup entry, Tomás has pinned it to
his own counter, and the HUD says `Day 3, Wed night   club night`. The weekday is abbreviated
because the label is 200 px and the longest line this can produce is **181** — measured against
the font's own advances rather than estimated.

**Done when:** `tools/test.sh` **6515 / 0** (from 6397), `check_lessons.py` clean, and the
frames below opened one at a time.

**What it dragged into the light, and the first one is the milestone's real find.**

**`World` never listened for the day.** `_repopulate()` was connected to `time_block_changed`
and to nothing else. Sleeping normally resets night → morning, so the hour turn rebuilt the room
by luck — but sleeping while it is *already* morning (`slots_used == 0`) makes
`_sync_time_block()` see an unchanged block and return without emitting, so the day advanced and
the world was never rebuilt. Harmless for eight milestones because nothing about who was in a
room depended on the day. It would have stopped being harmless in the very next commit, and the
symptom would have been yesterday's people standing in today's room with no error and no failing
test.

**And no test in this project could have caught it.** `world.gd` reads autoloads, so it does not
compile in a `--script` run — §8's disease in a fourth costume. It was found by reading the
wiring before depending on it, and confirmed by opening screenshots. What *is* guarded is the
half a test can reach: `sleep()` must still emit `day_changed` in the one case where the hour
stays put, so the obvious tidy-up ("nothing changed, why emit?") breaks the room from the other
end instead. The test says plainly which half it covers.

**A day-restricted entry may never satisfy a safety guarantee.** `_test_schedules` asserts every
character is findable at every hour and that De Ketel and the study hall are always staffed. A
`"days"` entry is true one day in seven, so it must not count towards either — the checks are
built from the entries carrying *no* `days` key, which is exactly what they meant before the axis
existed and keeps them meaning it. Day-restricted entries only ever add, and are checked
separately. Day-restricting Wren proves it: four failures, including De Ketel's staffing.

**Six deliberate breaks, each watched to go red and reverted:**

| broken | result |
|---|---|
| a weekday misspelt `"weds"` in the generator | `validate()` refused to build |
| the two schedule filters ORed instead of ANDed | 2 failed |
| Wren given a `"days"` key — the anchor loses her guarantee | 4 failed |
| Nadia put in Onderbrug at night as well | 2 failed |
| Orla dropped from club night | 1 failed |
| `sleep()`'s `day_changed` made conditional | 1 failed |

The third is the one worth reading: day-restricting the room's anchor failed both *"wren can be
found at every hour"* and *"de_ketel has somebody in it at morning, every day of the week"*,
which is the deadlock guard doing its job across the new axis rather than beside it.

**Looked at, not reasoned about.** `tools/autopilot/club_night.json`, six frames, opened one at
a time.

The noticeboard, reading the Cup entry with the club night pinned beside it, *"curling at one
corner"*. De Ketel on **Day 2, Tue night** — Wren, Tomás, Kesh, Hana, four people. The same room
at the same hour on **Day 3, Wed night** with the World still standing — Nadia at the far table,
Orla by the near one, six people, and the HUD line reading `club night`. Nadia's own words for
why she is there, because otherwise she would deliver her classroom lines in a bar. And **Day 4,
Thu night**, back to four: it has to end as well as begin, or `"days"` is a permanent addition
with a calendar painted on it.

**The frame that nearly lied.** The first cut walked to (15, 6) to stand beside Nadia. That is a
chair and it is solid, so the run printed `no path to (15, 6)`, carried on, and wrote a confident
screenshot of the middle of the room under the caption *"an Essenveld student on a De Ketel
stool"*. Exit 0, no script errors. This is the M16/M27/M32/M33 disease and the cure was the same
one every time: open the PNGs. The script now walks to (16, 6) and the note records why.

**Deliberately not done, and §3 stays open because of it.** The day axis has exactly one user:
`"days"` is general and club night is the only thing spending it. That is the right size for one
milestone, and it is also why the term is not yet full — one recurring night is a shape, not a
week.

**This milestone does not close `ROADMAP.md` §3.** The first draft of this entry said it did, and
recorded the leftover in **§8** as though it were debt M34 created. That was wrong twice over: the
bullet is about *content*, so one day in seven does not finish it; and a leftover filed under
technical debt is a leftover hidden from whoever next opens `ROADMAP.md` to choose what to build.
It is back in §3, which reads **half done** — the hours (M30), then the mechanism and one instance
(M34) — and what remains is occasions: a second recurring day that is a different *kind* of day,
not a second club night.

19×19 and `MISTAKE_BREADTH` are both still open in §5 and neither was touched.

---

## M35 — Rain, and a week with a shape  [done; ROADMAP §3 closed]

`ROADMAP.md` §3's last open row asked for *"more days that differ. One recurring night is a
shape, not a week."* It is closed. The term now has an hour axis (M26), a day axis (M34), a
**weather axis**, and three recurring things that differ in kind rather than in degree: rain
every day, club night one evening a week, market day one morning a week.

**The arithmetic nobody had done.** Day 1 is a Monday, so club night — Wednesday since M34 —
fell on day 3 and day 10, and `EXAM_DAY` is **10**. The fortnight held exactly two club nights
and the second one was the exam, with Nadia and Orla scheduled into De Ketel on the night both
of them sat in the exam field. `Hud._day_line()` even suppresses the club-night suffix once
`exam_entered` is set, so the game would not have mentioned the collision. Nothing errored and
no test failed. Club night is **Tuesday** now: days 2 and 9, and the second is the eve of the
exam rather than the exam.

**A whole atmosphere system that had never run.** `raining` had three readers — `Ambient`,
`Soundscape`, `TileAnimator` — and exactly one writer: `Autopilot`, the screenshot hook. A
player had never seen rain in the history of the project, while `CLAUDE.md` listed weather
among the shipped features. The sky is derived from the day now, the way `weekday()` is, and
stored nowhere.

**Five is not seven, and that is the whole design.** `WET_CYCLE` is 5. At seven — the obvious
length, mirroring `WEEKDAYS` — the weather stops being a second axis and becomes the weekday
wearing a hat: Saturday would be dry for the life of every save and market day would never once
be rained on. At five the two drift, so the fortnight gets a dry market (day 6) and a wet one
(day 13), a wet club night (2) and a dry one (9), without any of it being written down. There
is a test that the two cycles share no factor.

**Day 1 must be dry, and that is load-bearing.** Pip teaches Capture Go at the stone tables in
Molenpark and it is the first game in the game; the park is open ground, so on a wet morning he
is under the arches instead. A wet day 1 moves Act 1's opening beat to a map the prologue never
mentions — and he stays *findable*, so every schedule test passes either way. Caught while
writing the content, not by a failure. `_test_weather()` holds it in place.

**The guard change is the part worth copying.** `_test_schedules` built its tables from the
entries carrying no `"days"` key, on the sound reasoning that one day in seven can never satisfy
a guarantee. The cost nobody had priced: *any* conditional entry was discounted, so a schedule
that **removes** somebody failed the findability check by construction, no matter what other
entry put them elsewhere. The day axis could only ever add, and ROADMAP §3 recorded that as a
limit of the mechanism rather than of its test. It is an **exhaustive cover** now — all
4 × 7 × 2 combinations of hour, weekday and sky — which subsumes the old check and lets a *pair*
of entries keep a guarantee. Pip and Bertie's dry-park/wet-arches pair is the first schedule in
the game that moves somebody rather than adding them.

**The graphs can see the calendar.** `DialogueGraph` had eighteen conditions and the only
environmental one was `on_map`, so club night's own dialogue was gated on being in De Ketel and
nothing else — it read correctly only because the map schedule was the one thing putting those
two women in the room. Added: `weekday_is`, `block_is`, `weather_is`, `day_at_least`, and the
zero-argument `club_night` / `market_day`. **Zero-argument on purpose**: a graph saying
`["weekday_is", "tuesday"]` would hold its own copy of which night it is and go on passing after
the night moved, which is the `CLUB_NIGHT_GUESTS` mistake §8 already records. No dialogue file
names a weekday.

**Market day, and why Tomás.** His mornings were already free and nobody had noticed: De Ketel
is shut until the afternoon and Wren is the anchor who keeps it staffed, so the man who owns the
bar had three hours a week doing nothing and a week's supplies to buy. Pure addition — he is
already on the off-hours list and stands on no other map at that hour — so no guarantee moves.
He has a dry-market voice and a wet one. `abel`, `dov` and `moss` look like free population and
are not: all three are written for Cup day at the Bondszaal, and Abel's only line is *"came
across on the ferry this morning for this"*.

**Two M34 defects, found in the audit.** Nadia's `club_night` branch sat at index 4 behind four
book branches, one of which (`returned_the_book`) is permanent — so once `page_forty` finished
she never spoke a club-night line again, and while it was live she delivered book lines in a
bar. And neither guest had a club-night `post_match`, so winning a club-night game got
league-flavoured lines in a room whose whole point is that the league is not watching.

**Done when:** `tools/test.sh` **6725 / 0** (from 6515), `check_lessons.py` clean, and the
seventeen frames below opened one at a time.

**Six deliberate breaks, each watched to go red and reverted:**

| broken | result |
|---|---|
| a weather value misspelt `"dryish"` in the generator | `validate()` refused to build |
| the three schedule filters ORed instead of ANDed | 6 failed |
| Pip's wet-day entry deleted — the pair stops covering | 1 failed, *"pip can be found at every hour"* |
| `CLUB_NIGHT` moved in `GameState` and not in the map | 3 failed |
| `WET_DAYS` shifted so day 1 is wet | 2 failed, incl. *"day 1 is dry, so Pip is in the park"* |
| a dialogue condition typo'd to `weather_iss` | 1 failed |

The third is the one worth reading: it is the assertion the old guard **could not have made**,
because it discounted the very entry whose deletion breaks the cover.

**Looked at, not reasoned about — and this is where the milestone earned its time.**
`tools/autopilot/weather.json` (9 frames) and a retimed `club_night.json` (7), opened one at a
time. **Three frames were wrong and all three looked confident.**

- `weather.json` frames 7 and 8 were captioned *"the wet market"* and showed the **dry**
  conversation still open: one `interact` had not closed the box, the run logged *"dialogue did
  not close after 1 taps"* and carried on, and the day then changed behind an open card. Exit 0,
  0 script errors, two confident captions, and `market_wet` had never played.
- `club_night.json`'s final frame has had the same fault **since M34**. It changed the day with
  Nadia's box open, and `World._repopulate()` guards on `_talking` — so the room was never
  rebuilt and the frame showed a stale six-person room under the caption *"back to four"*. The
  fix needed three goes: `stop_at_choice` correctly halts *at* her choice, and the first repair
  tapped `move_down` while the box was still on its text page, where `_awaiting_choice` is false
  and the key does nothing. Both scripts now shoot an explicit *box closed* frame before the day
  turns, and the final room shot walks back to the vantage the other two were taken from, so the
  three are actually comparable: four people Monday, six Tuesday, four Wednesday.

That is the M16/M27/M32/M33/M34 disease in its sixth costume and the cure was the same one every
time: open the PNGs. A green run is not evidence; it was not evidence this time either.

**One seam this milestone created and then closed.** `World` connects `time_block_changed` and
`day_changed` and did **not** connect `weather_changed`. In normal play that is harmless — the
sky is derived from `day`, so it cannot change without `day_changed` firing first and rebuilding
the room. But M35 made weather a *schedule* axis, and the other writer is Autopilot's `rain`
step: a script could change the sky, the sound and the puddles while leaving yesterday's roster
standing, and photograph it. That is this file's own M34 bug wearing the next costume along, and
the frame would have looked exactly as confident as a correct one. Connected, with a frame that
proves it — `a2_rain_only_no_day_turn` holds the day and the hour still, forces the sky, and the
park empties. The redundant rebuild on sleep costs one extra pass over four NPCs behind a toast;
a rebuild too many is the cheap failure here and a rebuild too few has cost this project a
milestone twice.

**Corrected on the way, because this file has produced it twice before.** The audit that opened
this milestone said no map used the `when_wet` tile key. Wrong — Ketelsteeg and Onderbrug have
five puddle tiles between them and have had since M16. The animation had simply never run,
because nothing ever made it rain. The quay, which is the map you come to after losing in a port
that drizzles, had none; it has two now.

**Deliberately not done.** Market day has no stalls, because a map's decor is a static baked
layer and nothing can vary it by day — and the obvious workaround, solid stall tiles along the
pavement, lands on the crowd routes at y=10 and y=14 that `gen_maps.validate()` checks are
clear. A decor layer with a schedule on it is a different milestone; the market is people,
sound and crowd density. Nadia's and Orla's club-night games still set no flag and advance no
quest, which was M34's choice and is unchanged.

## M36 — The wassalon  [done; ROADMAP §4 closed]

**The door was never missing.** `gen_maps.py` has set `door_glass` at (22,8) on Ketelsteeg
since the setting pass, and then put the sign describing the room **on the same tile**.
`validate()` requires a sign to be solid and a warp to be walkable, so those two could never
have been one tile — the sign was the reason the door could not be a door. Moving it one tile
left is the whole of the fix, and ROADMAP §4 had called it "a facade with a door, a sign, neon
and no warp" for six milestones without anyone noticing that the door and the sign were the
same problem.

**And the room behind it was not new content so much as three people who were already
standing somewhere with nowhere to stand.** Abel Roos (21k), Dov Halevi (19k) and Moss
Lindqvist (16k) shipped complete in M24 — `NpcData`, `OpponentProfile`, a banter file, a
sprite and portrait record in `tools/characters.py`, and a `data/dialogue/<id>.json` holding
exactly one `start` node of self-introduction. Nothing reached them but
`CupDraw.FIELD_BEGINNERS` interpolating their ids into a profile path. So the Beginner Cup,
which is the ending of Act 2, drew a five-person field of which **three were names the player
had never seen**, in a game whose whole argument is that an opponent is a person.

All fifteen characters now stand on a map. Abel at 21k is also the first opponent at or below
a starting player's own strength: the weakest person in the game was Wren at 20k.

**The register.** The city is built on one opposition — the Instituut above ground where you
are recorded, De Ketel below it where nobody asks but the hooks remember — and the wassalon is
neither half of it. Street level, no board on the wall, no card, no table: the ordinary city,
where Go is a thing some people do while their washing goes round. The sign has said so since
M14 and nobody could get in to check.

**Two of the three games are unrated and one is not, and that is the room.** Abel and Dov play
for nothing — free, no hour, nothing kept but the head-to-head. `HooksLadder.ROSTER` does not
contain any of the three, so no hook moves either. Moss plays one that counts, because he is
the one person in a room that records nothing who wants it recorded: sixteen kyu, three years
under the section ceiling, and not proud of it.

The unrated part is a rule and not a flavour note. `rated_wins_at_least` counts every rated
record in the save, so a rated 21 kyu on a doorstep is three farmed wins from opening 13×13
and the Cup play-up — improving your record by beating somebody weaker, which is the M24
league bug and which Pillar 1 forbids. `_test_the_wassalon` asserts it rather than leaving it
to a comment, because "why is this game unrated?" is exactly the tidy-up a later session makes
with every test green.

**The schedule spends the weather axis, not the weekday one.** Abel is there every daylight
hour, having nowhere else to be; Dov comes at dusk, when the machines are free; Moss comes in
out of the rain, and says so in his first line. The weekday already carries club night and
market day and a third weekly occasion would dilute both, whereas rain driving people into the
warmest room on the street is the M35 axis doing something new — and it is the first use of
`"weather"` on an **interior**, where the sky cannot be seen but the people who walked in out
of it can.

**And the room is empty at night, deliberately, with the machines still running.** Nothing
anywhere in this project had ever asserted that a room *empties* — every guard in
`test_data.gd` asserts somebody is somewhere — so `_test_the_wassalon` walks all fourteen
weekday-and-sky combinations of `night` and requires nobody in any of them. It is one careless
`"night"` away from being deleted with the suite green, which is how it is written down.

### Four things it found, all the same shape: a check that passes because it is looking at the wrong thing

**A sign only had to be solid.** `validate()` refused a sign on a walkable tile and never
asked whether a player could stand anywhere to read it. The interaction probe is a 14×14 box
thrown `PROBE_REACH` 12 px from the player's feet, so it reaches exactly one tile: a sign with
no walkable orthogonal neighbour builds an `Interactable` the probe can never overlap. No
prompt, no error, nothing to fail. Written into `gen_maps.validate()` and — separately —
`_test_maps`, because the generator only ever protects the next map and this file protects the
ten already here. It found one on the first run: **the attic dormer sign, unreadable since the
attic was built in M14**, sitting on the upper wall course with the wall base below it and the
floor below that. It has come down a row.

**A notice outranked a person.** `MapBuilder` gave every sign `interact_priority = 1`; `Npc`
left its own at the default `0`. So wherever the probe held a readable object and a human
being — which is routine, the probe is 14 px and a tile is 16 — [Space] read the object.
Standing in front of somebody and being handed a paragraph about the table behind them, with
the dialogue box opening exactly as it should. The two numbers were bare literals in two
files, which is how they came to be the wrong way round; they are
`Interactable.PRIORITY_SIGN` and `PRIORITY_PERSON` now and their ordering is asserted. The
before-and-after is on screen: the prompt over the same tile changed from `Read` to
`Talk to Abel Roos`.

**`Autopilot._talk_to` accepted any open box as proof it had talked to somebody.** M30 replaced
the old interaction-probe test with "did the dialogue box open?", which was the right move and
is still not sufficient, because a sign runs the same box. `talk_to abel` walked up, pressed
[Space], got the folding table, and returned success; the script then advanced through a
paragraph about furniture under a screenshot captioned with his name — the M16 `slice_full`
bug wearing the fix for the M16 `slice_full` bug, at exit 0 with 0 script errors and nine
confident PNGs. It reads the speaker plate now, which a narrated sign does not have. (First
version compared the plate for equality and rejected the right person, because the plate is
`Abel Roos   21k`; a false alarm in a check added to catch a silent failure reads in the log
exactly like the thing it was added to catch.)

**`SOLID` in `gen_maps.py` was read by nothing.** Found by breaking it on purpose: adding the
new `washer` character to it and taking it out again changed no generated map and failed no
check. `solid_mask()` consults only `WALKABLE_OVERRIDE` — a tile is walkable iff its legend
character is on that whitelist and everything else is solid by default. One definition, no
references, in the file whose job is classifying tiles, so it read as the source of truth
while deciding nothing. Deleted, with a comment saying which list decides and not to
reintroduce the other.

### Built

- **`wassalon`**, 16×10, `indoors`, the eleventh map. Five machines, a counter, a folding
  table with a board on it, a second board propped against the wall, a bench, the small ads,
  and two windows onto the street. `music: ""`, which is what makes `Soundscape._choose_bed()`
  return `amb_room` — the attic's precedent, and the only *inhabited* interior in the game
  with no score, so the machines are its whole voice.
- **A `washer` tile**, two frames, in `tools/gen_tiles.py`; a `washer` entry in
  `TileAnimator.ANIMATIONS` with no `blocks` gate, because "open till two" means the drums
  turn at every hour; a `washer` sound in `gen_audio.py` (a motor on one note and the load
  coming round twice, unevenly, for the reason `stove_crackle` uses uneven ticks); a
  `Soundscape.SOUND_SOURCES` entry thinned to two emitters from five machines; and an
  `Ambient.LIGHT_SOURCES` porthole, which is what makes the night frame.
- **The Ketelsteeg door**, two tiles wide for the reason the salon steps are, the WASSALON
  sign one tile left of it, and **a sign for the snack window** — art, a `fryer` emitter and a
  glow since M14, on the one stretch of the largest map in the game that led nowhere.
- **Three dialogue graphs** grown from one node each. Every offer is gated on
  `knows_the_rules`, and that is Abel's own written line used as a condition rather than a
  rail bolted on: *"I have never played anybody I did not already know."* Moss's is gated on
  `ranked` as well, and he has a `rank_at_most` branch for a player who outgrows his section,
  which is Marguerite's `cup_outgrown` seen from the other side.
- **`WorldAmbienceTests.MAPS` derived** from `res://data/maps` instead of retyped.

**Done when:** `tools/test.sh` **7081 / 0** (from 6725), `check_lessons.py` clean,
`check_melody.py` clean, `gen_maps.py` / `gen_content.py` / `build_assets.py` regenerated and
`validate()` green on all eleven maps.

### Deliberate breaks, each reverted and re-run

| broken | result |
|---|---|
| the wassalon door left out of `extra_walkable` | build refused: *warp to wassalon at 22,8 is solid* |
| the WASSALON sign put back on the door tile | build refused: *sign at 22,8 is on a walkable tile* |
| the snack-window sign put on the hatch itself | build refused: *sign at 25,7 has nowhere to stand and read it* |
| the attic dormer sign put back where it was | build refused — **the M14 bug, reproduced on demand** |
| Abel's hours misspelt `"mornin"` | build refused: *unknown block* |
| Dov given a `"night"` hour | 14 failed — one per weekday and sky |
| `abel` dropped from `OFF_AT_SOME_HOUR` | 1 failed |
| Moss's `post_match` deleted | 2 failed (the exit rule, and the orphaned node) |
| Moss's game made unrated | 1 failed |
| Abel's game made rated | 1 failed |
| `from_wassalon` dropped from Ketelsteeg's spawns | 1 failed |
| `k` dropped from `SOLID` | **0 failed, and no map changed** — which is how `SOLID` was found to be dead |
| the ambience map list retyped by hand without the new map | **0 failed**, 7077 green against 7080 — three checks silently not run, which is the entire argument for deriving it |

### Looked at, not reasoned about

`tools/autopilot/wassalon.json` (nine frames) and `wassalon_game.json` (seven), both declaring
`{"save": "invited"}`.

- The WASSALON sign readable from the pavement beside the glass door, and the snack-window
  sign readable under the hatch — the two signs the new rule moved.
- Frame 3, the room: five machines drawn and turning. If any of them were a hole the TileSet
  resource had not been rebuilt, and **nothing in the project detects that** — the per-tile
  assertion in `_test_maps` reads the manifest, not the `.tres`.
- Frame 5, `e_box_closed`: an explicit box-closed frame before any hour or sky is touched,
  because `World._repopulate()` guards on `_talking` and M34 shipped a stale roster behind an
  open card. It is also the frame that shows the priority fix — the prompt reads
  `Talk to Abel Roos` where it read `Read` an hour earlier.
- Frames 6 and 7: the same day and the same hour with the sky forced, and **two** people in
  the room instead of one; then dusk, and Abel replaced by Dov with Moss still there.
- Frame 8: night, nobody, and the portholes lit. The frame the room was built for.
- `wassalon_game`: the offer card with its two choices, `H2` and two black stones on the star
  points against 16 kyu, the resignation, and Moss's `post_match` — the only visible proof
  the graph re-enters.

**Three script faults on the way, all of them the documented ones.** A blind `advance` past a
choice accepted the rematch and turned every later frame into a second game. A fixed `advance`
budget that lands *on* the choice card spends its last tap selecting the highlighted option,
which is why the generous `advance: 20` + `stop_at_choice` form exists. And `_walk_to` has no
pathfinding, so a diagonal walk across a room with two people standing in it walks into one of
them and stops — every leg has to be a straight line through empty floor.

### Left behind

- The `go_table` at (11,5) will never make a sound: `Soundscape` gates `stone_place` on
  `people >= 2` and the room holds one person most of the time. Correct, and worth knowing
  before somebody "fixes" it.
- `washer` is a positional emitter, so like `fryer` and `stove_crackle` it reaches no
  audibility check at all — `tools/check_audio.sh` walks `MUSIC` and `BEDS`.
- Four NPCs elsewhere still stand next to signs (Marguerite at two desks, Pip and Bertie under
  the arches). With the priority fix that is no longer a bug and no assertion was added, since
  a person at a crate with the crate's own sign above them is the intended picture.

## M37 — The cut  [done]

The owner played it and said so: the dialogue did not make sense half the time, the tram
did not work, the ranking was broken, text covered the people talking, the calendar and
the schedules were complexity for nobody, and after a game the person you had just beaten
talked as though they had won. Thirty-six milestones of verification — 7,081 checks and
thirty autopilot scripts — had never asked whether any of it made sense at the keyboard.
Every one of the six was real, and four of them were the same bug: a check that passed
because it was looking at the wrong thing.

**Direction, from the owner:** cut systems aggressively, keep the loop Pokémon TCG and
Tag Force run on. Walk around, talk to people, play Go, climb a table, enter a tournament.

### What went

| cut | lines | why |
|---|---|---|
| the review: fifteen detectors, `GoEvaluator`, `GoProgress`, `GoReviewHistory`, the review scene, eight voice files | ~1,700 | rules without judgement. It could say a group had one liberty; it could never say what a move was worth. A review that is any good needs an engine, which is now ROADMAP §1 |
| the hooks ladder: `HooksLadder`, `HooksBoard`, quest `the_hooks`, its dialogue | ~450 | two progressions that disagree on purpose was the confusion, not the argument. The league board is the progression |
| the borrowed book: quest `page_forty`, the desk's reading, Ilse's and Nadia's book nodes | ~150 | an inventory quest in a game with no inventory screen, and the source of Ilse thanking you for a win after a loss |
| `GoRating` | ~100 | it averaged the opponents' strength over a window, and from the provisional 22 kyu every opponent in the game is stronger, so a 0–3 record *raised* the rank and toasted "Rank up". Nothing moved for two games, then game three could jump eight stones |
| the calendar: `time_block`, `day`, weekday, weather, `sleep()`, slots, `can_act()`, club night, market day, `Ambient`, rain, night music, crowd density, NPC `blocks`/`days`/`weather`, `MapData.is_present`, `World._repopulate`, the bed, the HUD calendar, nine tests, five autopilot scripts | ~1,400 | it decided nothing a player could act on, a quest step could hide behind an hour, and the tests needed a 56-combination cover just to prove nobody had been scheduled out of the game. `ExamBoard`, `CupBoard`, `CupDraw`, `Exam` and `LeagueTable` never read the day; only the "when may it start" wrappers did, and dialogue sets those flags now |

Everyone stands on exactly one map. Hana could not be both at De Ketel for Act 1 and in
the classroom for Act 2, so **Kesh hands out the first rank and the tram invitation**, and
Hana meets you at the Instituut. `first_stones` is three steps; `enrolment` is seven.

### What was fixed

- **After a game, the reaction is to that game.** `dialogue_graph.gd`'s `beat` means "ever
  beaten", and all twelve `post_match` nodes read it as "just beat", so after one win the
  "you got me" line played after every later game the person won. Nadia had no loss node
  at all (a loss played her introduction); Orla's quay node claimed she lost regardless;
  Pip's was result-blind; Moss's `rank_at_most` was inverted, so he told a 22 kyu they had
  outgrown the section. `record_match()` sets `last_result`; graphs read `won_last` /
  `lost_last`; `_test_post_match_reacts_to_the_result` runs every graph both ways and
  requires two different non-empty answers.
- **The dialogue was rewritten, all sixteen graphs and the intro**, against
  `data/dialogue/VOICES.md`. What was wrong with the writing, specifically: one arch voice
  for fifteen people ("that's the whole of it" in six mouths, "it is not an insult, it is a
  starting position" verbatim from Kesh and then Marguerite, the same wait line from three
  people); nobody said a plain sentence; the timeline contradicted itself (intro: Tuesday,
  four days, job on Monday; Hana: "I only drink here on Tuesdays"; HUD: Day 1, Monday);
  people referenced places the player had not seen; rules were taught in speech and
  narration sat inside NPC nodes; lines averaged 95 characters in a box that holds four
  rows. Now: 246 nodes, two lines a node, 110 characters a line, every line measured
  against the box, no calendar words, the shared tics banned — all in
  `_test_writing_rules` — and `tools/check_dialogue.py` prints a graph as a script so it
  can be read as one.
- **Rank is a step ladder** (`GoRankLadder`, pure): beat somebody at or above your rank and
  it goes up one; lose to somebody at or below it and it goes down one; nothing else moves
  it. Handicap priced at `ranks_per_stone`. A loss never raises, a win never lowers, and
  `test_rating.gd` says so. The league board's footer states the rule. `LeagueTable` counts
  `league_*` fixtures only, so Kesh's rematch at De Ketel no longer appears on the
  Instituut's board.
- **The tram is a stop you press [Space] at.** It was two walk-on `Warp`s at the far west
  edge of the map with a `prompt` field nothing displayed, Hana's repeat directions said
  "the road east", and a decorative tram crossed every forty seconds for the player to wait
  for. The stop is a `__TRAM__` sign at the pole with the destinations as choices, the
  refusal spoken in the box, and the tram that passes is the tram you board:
  `SignDesk.tram_stop()` awaits `Tram.arrive()` and then changes scene. Redrawn at 96×36
  from 48×18, which was smaller than the 16 px player.
- **Text fits.** `dialogue_box.gd` never used `UiKit`; its text rect was exactly four rows
  and eight lines needed five, with the "▼" inside the rect. It pages a long line by
  sentence now, keeps the arrow on the frame, wraps choices, and **moves to the top of the
  screen when the people talking stand in the bottom half** — the standard RPG rule, and
  the literal "text covering the avatars". The toast is sized to its text (the southbound
  refusal was 439 px on a 384 px screen); the journal is capped at two lines; the match
  panel's rows no longer overlap.
- **`Label`'s default `line_spacing` of 3 made every row 14 px against a font whose line
  height is 11.** Found by measuring a screenshot's text rows. Every "four rows" in the
  game was three rows and a fourth drawn on the frame, in every panel, for the life of the
  project, and `UiKit.text_height` could not see it because it measures the font and not
  the Label. It is zero in `ninepoint_theme.tres` now.
- The opening's five lines shortened; "the whole of the rules" was in the first thing the
  game says.

**Done when:** `tools/test.sh` **11583 / 0** (from 7081; the writing rules add about
four thousand assertions and the cuts remove about seven hundred), `check_lessons.py`
clean, `gen_maps.py` / `gen_content.py` / `gen_props.py` regenerated and `validate()` green
on all eleven maps.

### Deliberate breaks, each reverted and re-run

| broken | result |
|---|---|
| a `post_match` pointed both branches at the same node | 2 failed: *a win and a loss are different conversations*, and the orphaned node |
| a third line added to a node | 1 failed: *says at most two things* |
| a line of 118 characters | 1 failed: *line fits the box* |
| "fortnight" put back into Wren's Cup line | 1 failed |
| `GoRankLadder.step` made to go up on any result | 22 failed: *a loss never raises* |
| the wassalon's `moss` entry moved to `de_ketel` | 2 failed: *stands in the wassalon and nowhere else* |

### Looked at, not reasoned about

`slice_full` (New Game to the league board, thirty frames), `institute`, `cup`,
`wassalon_game`, `win_path` and `joos`, all declaring their own saves.

- The dialogue box at the **top** of the screen with Pip and the player standing in the
  park below it, and at the bottom in De Ketel with the speakers above it.
- Pip after the capture game ("Got you!") after a resignation, and Kesh's `first_rating`
  after the first game, with the journal changing under it to "Take tram 4 north".
- The tram stop's sentence, its three choices, the tram pulling up with the player at the
  stop, and the hall on the other side.
- Hana's problem, the register, and the league board with the ladder rule in its footer.
- The Bondszaal desk: the entry offer, the draw, and "Ready." starting the Cup with no
  night in between. The script's last frame still shows Marguerite's "your board is ready"
  card rather than round one; the round itself is `cup_round.json`'s job.
- Moss's `post_match` after a resignation: "Still sixteen kyu."

**Two script faults on the way, both the documented ones.** `choose: 2` on a card that
had filtered its middle option down to two choices wrapped to the first and accepted a
rematch, and every later frame was a second game at exit 0. And `advance: 1` at the tram
stop left the box on its sentence, so the `choose` step's own tap advanced to the card
instead of picking from it, and the tram in the frame was the scheduled crossing. Both
found by opening the PNGs.

### Left behind

- The quay has nobody on it and Onderbrug is Joos alone — ROADMAP §2.
- `GtpOpponent` is still unwired. The review is gone until it is not — ROADMAP §1.
- `world.gd` is over the line-count convention; the tram stop went into `SignDesk`.
- Save files are version 2; a version 1 file loads and its calendar keys are ignored.

---

## M38 — The engine at the board

- Decided ENG-01: a bundled KataGo for Linux x64, pinned by `packaging/katago-linux-x64.json`
  (binary, the normal and Human-SL models, checksums, licences, launch arguments) and fetched
  by `tools/setup_katago.sh`; the binary and models are not in git.
- Rebuilt `GtpOpponent` as a stateful boundary (ENG-02): handicap and setup stones are sent
  once, then only unseen moves; a timeout, a rejected command, an illegal reply or a process
  that will not start falls back to the heuristic for the rest of the game and says so.
  `KataGoService` warms a lease while the player is still walking to the board.
- Put every cast profile on `engine = "gtp"` (ENG-03) with a `human_<rank>.cfg` at the
  character's rank. The development fixture `katago_trial` plays the engine with no world
  around it; `tools/katago_smoke.gd` and `tools/katago_service_test.gd` joined `tools/test.sh`.
- `tests/check_load.gd` now parses every `.json` under `data/`, so a malformed dialogue,
  banter, lesson, puzzle or map file fails the gate instead of the player (TECH-01).

**Verification:** `tools/test.sh` — **12341 passed, 0 failed**; `python3 tools/check_lessons.py`
— **0 problems**; the KataGo UI trial: four inspected screens, two legal engine replies, no
fallback, a result with SGF, shutdown and the return to the world. Shipped as PR #16.

---

## M39 — KataGo calibration and cast release

- Replaced the KataGo UI fixture's numeric phase check with `GoMatch.is_player_turn_ready()`.
  The fixture now waits for actual player input availability rather than mistaking the
  preparation/intro phase for a playable turn.
- Inspected the player-black UI trial through preparation, two KataGo replies, resignation
  result and return to the world. It recorded engine startup, two legal replies, result/SGF
  data, shutdown and no fallback.
- Completed the Linux x64 Eigen-AVX2 calibration. Its persistent report is
  `user://katago-calibration.json` (28/28 profiles passed): sampled normal replies peaked at
  649 ms on 7x7, 1042 ms on 9x9 and 1518 ms on 13x13; no sampled profile made a pass move,
  resigned or fell back. Startup (maximum 7105 ms) is preparation-only and is not measured against the
  two-second reply gate.
- Promoted the cast in release order: beginner (Abel, Wren, Dov, Pip, Moss, Kesh), club
  (Ilse, Tomas, Sunny, Bertie, Orla), then advanced (Nadia, Marguerite, Joos, Hana). All
  retain the 8-visit Human-SL configuration because every profile met the legal-reply,
  no-fallback and sub-two-second conditions.

**Verification:** UI trial — **4 inspected screens, 0 script errors**; `tools/test.sh` —
**12341 passed, 0 failed**; `python3 tools/check_lessons.py` — **0 problems**;
`katago_calibrate.gd` — **28/28 passed**. Shipped as PR #16; the temperaments (PR #17)
were merged into that branch after it had already reached `main`, and landed with M40.

**Correction (M41):** "calibration" here means startup, reply latency, legality and
fallbacks. It never measured strength: no profile was played a whole game against anything,
and nothing checked that a "20 kyu" plays like one. The 28/28 above is a latency gate. The
first strength measurement is M41, and it found every beginner profile several ranks above
its label.

---

## M40 — The review, on the engine

The owner's report: play Wren, lose, ask for a review, see "Hana is reading the game", and
nothing happens. The handoff had rewritten the flow three times and proved it with a
three-move resignation. What was actually wrong was arithmetic. One KataGo evaluation of
one position costs about a core-second on the bundled CPU build, at one visit or eight; the
review ran **two** GTP searches per player move, re-synced the whole history before each,
and gave itself eighteen seconds. A finished 9×9 game is fifty to eighty positions. Every
real game timed out, the overlay closed, and the player was dropped back into the world with
nothing said. The three-move fixture passed because it had three positions.

- **One process, one query, every position.** `KataGoAnalysis` (`src/go_ai/`) runs
  `katago analysis` over the whole SGF — handicap as `initialStones`, the game's komi,
  Japanese rules to match `GoScoring` — and reads one JSON line per position as it arrives,
  on as many analysis threads as the machine has cores (capped at eight). `MatchAnalysis`
  is pure: it charges each of the player's moves the swing between the position before and
  after, from their side of the board, and picks at most three — the biggest loss, a second
  loss about a different idea, and one moment the engine agreed with the player when the
  alternative was worse. Under three quarters of a point is noise; a game with nothing to
  say is one honest "steady" card; a failed engine is one honest "no review" card.
- **Progress you can walk away from.** The loading card is "Wren Calloway is going over the
  game. Move 40 of 78." and [Esc] leaves it; `MatchReviewService` (an autoload, ~80 lines)
  owns the one running analysis, a new match cancels it, and a review that lands while the
  player is in the world toasts and waits on the quay noticeboard (WORLD-01's decision). A
  quit mid-review marks it `failed: interrupted` on load; nothing resumes. A silent engine
  is failed by a watchdog, never waited on. Any board from 7 to 19 lines is eligible.
- **What went right comes first, on the board, with a reason.** The owner's note on the
  first cut: "if you make a good move it should tell you and tell you why, because the
  game is to learn go." The first position card is now the player's best move — the
  engine's own choice when there was one, otherwise a move within noise of it — and
  `MoveExplainer` (`src/go_ai/`) says what it did from the stones: took the corner,
  joined your stones, took stones in atari, leaned on a group. Praise without a reason is
  rejected by the payload check, and a first-line stone is never praised. A tally card
  opens the review (how many moves matched the best, which, how many gave nothing away).
  The runner-up requirement went: more visits do not make it visible more often (23 of
  31 positions at 8, 12 and 16 visits), so a review could go a whole game without praise.
- **The advice reads as advice.** The owner's third note, with a card that said "D7 was
  better. It would have leaned on a nearby group of theirs" about a first-line stone:
  "some of it makes no sense." An audit of every sentence over three whole games found the
  rest: "would have took", the endgame's first-line moves scolded as first-line mistakes
  when the better move was on the first line too, and "Yours leaned on C5. D5 would have
  leaned on C5" when both moves did the same job. Now every sentence names its stones, a
  card says what your move did and its flaw ("Yours extended from H4, which already had 3
  liberties"), what the better move would have done, and the habit comes from your flaw
  when you had one. Same-job pairs are told apart by side or direction; a first-line stone
  is only a flaw when the better move is not on the first line.
- **The person you played offers it.** "Go over the game with Wren Calloway?" — never Hana
  in Act 1 (rule 8), and the engine is never named on a card. Filled = your move, ring =
  the better move, and the legend says so on every card.
- **`EnginePipe`** is the one child-process-on-a-pipe both `GtpOpponent` and the analysis
  share: lines read on a worker, polled from the coroutine, closed before the join. Extracting
  it found the bug that broke the first attempt at sharing: the dictionary
  `execute_with_pipe` returns also holds the child's stderr, and dropping it kills KataGo
  with SIGPIPE on its first log line.
- Removed: the GTP `kata-search_analyze` path, `GtpOpponent.dead_stones()` (never called,
  because `final_status_list` hung on this build — ENG-05 records the route that is left),
  the background resume machinery, and the three-move fixture.
- Found on the way: the `thirteen` fixture's save stood the player in the study hall and
  talked to Kesh, who has lived at De Ketel since M37, so it had walked up to nobody and
  photographed it confidently. `thirteen_ketel` stands where she is; both fixtures use it.
- Also lands the temperaments commit (steady / balanced / fighting Human-SL configurations
  per character) that PR #17 had merged into `feat/katago-cast-release` after that branch
  was already on `main`, so it never reached `main`.

**Done when:** `tools/test.sh` — **12505 passed, 0 failed** (M39: 12341) with the three
engine gates green; `tools/katago_review_test.gd` analyses a whole 9×9 and a whole 19×19
game, every position, and fails the wedged fixture through the watchdog; and the fixtures
below were played and their frames opened.

| fixture | what it proves |
|---|---|
| `review_e2e` / `review_13x13` / `review_win` | a whole game to the count, the offer, progress, the cards, the world; the last one a win, against the weakest heuristic profile |
| `review_world_wren_loss` / `review_world_wren` / `review_world_13` | the same through the town: Wren at De Ketel, Kesh's thirteen with handicap stones, then the post-match talk |
| `review_leave` | [Esc] on the loading card, the toast, the cards from the quay noticeboard |
| `review_unavailable` | a wedged engine: one "no review" card and the world, no overlay left |
| `quay_review` / `quay_review_19` | the noticeboard from a save, at nine and nineteen lines |

**What it costs, measured on this machine (32 cores, 8 analysis threads, Eigen AVX2):**

| game | positions | from "yes" to the cards |
|---|---|---|
| gate, 9×9, two heuristics | 79 | 14.4 s (0.18 s per position) |
| gate, 19×19, two heuristics | 241 | 60.0 s (0.25 s per position) |
| `review_e2e`, Wren | 58 | 11.9 s |
| `review_win`, against a random mover | 100 | 19.7 s |
| `review_world_13`, Kesh with handicap stones | 113 | 23.8 s |
| `review_unavailable`, wedged engine | 0 of 60 | 12.1 s to the "no review" card (4 s watchdog in the fixture; 30 s shipped) |

On one thread every position costs about a second, so a four-core laptop should expect
roughly four times these numbers; that is what the progress line and [Esc] are for. Every
fixture's frames were opened. The `2 ObjectDB instances were leaked at exit` warning in
some logs predates this work: `resign.json`, untouched, prints it too. Not done: the same
Wren loss on the real display — `:0` was not reachable from the session that built this,
so every game above ran under Xvfb. The owner's own play is the remaining check.

**Also found, not fixed (ENG-06):** the autoplay brain — the shipped heuristic with
`mistake_rate` 0 and `reading_depth` 2, labelled 1 dan — loses to Abel's *21 kyu* engine
profile by 43 points, and its 12-kyu setting loses to Wren's 20 kyu by 86. Either the
Human-SL profiles play far above their labels at eight visits or the heuristic is far below
its own; M39 calibrated latency and legality, never strength. A beginner's loop depends on
which it is.

**Deliberate breaks:** save version 2 → 3 (`match_analysis`, `opponent_name` and
`review_requested` on a record; a version 2 file loads with no reviews);
`GtpOpponent._parse_vertex` → `GoBoard.from_label`; `tools/autopilot/pip_review_e2e.json`
deleted; the `quay_review` preset's payload reshaped to what the cards can open.

---

## M41 — The cast's strength, measured and retuned

The owner's report after M40: crushed in every game, including by Abel (21 kyu) and Wren
(20 kyu). Rule 3 says those labels are real ranks, and nobody had checked. M39's
"calibration" measured startup, reply latency and legality; it never played a game out.

**The probe.** `tools/katago_strength_probe.gd` plays whole 9×9 games (komi 5.5, colours
alternating, resignation allowed, `final_score` from the engine that played every move) and
puts each subject on a ladder: the same Human-SL model at temperature 1.0, which KataGo's own
notes call a realistic individual of that rank, at 20, 15 and 10 kyu (5 kyu in the first
run). A subject's effective rank is where its win rate crosses fifty percent. GNU Go 3.8
(`tools/gnugo-gtp.sh`, from `nix-shell -p gnugo`) anchors the ladder from outside KataGo.
One process plays both sides (`kata-set-param` switches profile and temperature before each
move) because a KataGo process is about a gigabyte, and the first version of the probe ran
twenty-four of them next to another agent's sixteen and powered the machine off. It now
takes `--concurrent` and refuses to start a game under `--mem-floor-gb`.

**Before, shipped configs, ten games a cell** (wins, mean margin from the subject's side):

| profile | label | temperament | vs 20k | vs 15k | vs 10k | vs 5k | reads as |
|---|---|---|---|---|---|---|---|
| Abel | 21k | balanced | 6/10 (+7) | 1/10 (−12) | 0/10 (−20) | 0/10 (−33) | ~19k |
| Wren | 20k | steady | 6/10 (+10) | 6/10 (+1) | 1/10 (−22) | 2/10 (−11) | ~14k |
| Dov | 19k | steady | 7/10 (+10) | 5/10 (0) | 1/10 (−28) | 0/10 (−37) | ~15k |
| Pip | 18k | fighting | 6/10 (+26) | 5/10 (−2) | 4/10 (−9) | 1/10 (−10) | ~14k |
| Moss | 16k | fighting | 8/10 (+7) | 4/10 (−8) | 3/10 (−12) | 0/10 (−30) | ~16k |
| Kesh | 12k | fighting | 8/10 (+21) | 7/10 (−3) | 2/10 (−19) | 2/10 (−11) | ~13k |

**The dial, eight games a cell.** The 20 kyu profile at four temperatures against the
realistic 20k and 15k: 0.65/0.45 (the shipped "steady") 5/8 and 4/8; 0.85/0.70 (the base,
KataGo's example, the shipped "balanced") 3/8 and 3/8; 1.0 5/8 and 4/8; 1.2 3/8 and 3/8.
Pooled with the beginner cells, steady reads about four ranks above its label and balanced
on it. Above 1.0 nothing moves, because `chosenMoveTemperatureOnlyBelowProb = 0.01` applies
the temperature only to moves under one percent; the floor of the model is a realistic 20 kyu.

**The ladder holds, and it is not measuring itself.** 10k beat 15k 8/8; 15k against 20k
was 4/8 by sixteen points a game, so one rung is real but coarse at eight games. GNU Go
level 10 went 7/8, 7/8, 2/8 up the rungs: it reads 12 kyu, not the "8 kyu" ROADMAP §1 used
to claim. The shipped heuristic lost 8/8 to the realistic 20k at its "1 dan" setting (by 58
points a game) and 8/8 at its 20-kyu setting (by 72): its labels are the fiction M40
suspected, and that is ENG-07, not this ticket.

**What the numbers actually say.** Read together, the 505 games are simpler than a
temperament bug. The model cannot tell 20k from 15k on a 9×9 board: the realistic 15k
split 4/8 with the realistic 20k. Every beginner profile lands in that band and loses
clearly to the 10k, so on the model's own ladder the cast is within about three ranks of
its labels, at the edge of the owner's tolerance and inside the ladder's own resolution.
What crushes a beginner is not a mislabel of three ranks; it is that the model's weakest
profile is a realistic *online* 20 kyu, and a first-week player is nowhere near one. The
game's own hand-written "20k" loses to it by 72 points a game.

**The retune, in two parts.** (1) The steady temperament moves from 0.65/0.45 to
0.80/0.65, a shade under the base rather than well under it; measured, Wren went from
14k to 17k and Dov did not move, which is what a small dial and eight games a cell look
like. (2) The floor: the two 20k configs, Abel's and Wren's, apply temperature 1.5 to
*every* move (`chosenMoveTemperatureOnlyBelowProb = 1.0`), the one setting that measured
below the model's weakest profile — 2/8 against the realistic 20k, losing by fifteen
points a game, where 2.0 lost 0/8 by thirty-one. That is the owner's decision at the start
of the ticket: temperature above 1.0 for Abel and Wren rather than stopping at 1.0.
Balanced and fighting at other ranks were on their labels and are untouched; so are
`maxVisits`, the resign settings and every label. All of it lives in
`tools/gen_content.py`; fifteen generated configs changed, temperature lines only.

**After (steady retune only), eight games a cell, two engines at a time** — the owner's
cap after the machine powered off twice under the probe:

| profile | label | vs 20k | vs 15k | vs 10k | reads as | before |
|---|---|---|---|---|---|---|
| Abel (control, unchanged) | 21k | 5/8 (+5) | 0/8 (−18) | 0/8 (−20) | ~19k | ~19k |
| Wren (steady) | 20k | 6/8 (+14) | 3/8 (+4) | 0/8 (−21) | ~17k | ~14k |
| Dov (steady) | 19k | 6/8 (+5) | 6/8 (+8) | 1/8 (−19) | ~13k | ~15k |
| 20k at 1.5 on every move | — | 2/8 (−15) | | | under 20k | |
| 20k at 2.0 on every move | — | 0/8 (−31) | | | well under | |

**After the floor, Abel and Wren as shipped, eight games a cell:**

| profile | label | vs 20k | vs 15k | reads as |
|---|---|---|---|---|
| Abel | 21k | 0/8 (−31) | 2/8 (−14) | under 20k |
| Wren | 20k | 1/8 (−38) | 2/8 (−10) | under 20k |

Both now lose to the realistic 20k by thirty points a game, where before the ticket they
beat it. Dov (19k) and Pip (18k) are not floored and still read 13–17k on a ladder that
cannot tell 20k from 15k; whether the floor should reach them is ENG-08's question, and
the owner's games answer it.

**Done when:** Abel and Wren read at or under their labels on the ladder and every other
beginner within the ladder's own resolution of theirs; `katago_calibrate.gd` —
**28/28 passed**, slowest reply 1670 ms, no fallbacks (the floor configs cost nothing);
`tools/test.sh` — **12505 passed, 0 failed** (M40: 12505; no test was added, the probe
is a tool, not a suite) with the three engine gates green; the fixtures below were
played and their frames opened.

| fixture | what it proves |
|---|---|
| `review_world_wren_loss` / `review_world_wren` | Wren at De Ketel on the floor config, a whole game to the count, the offer, the cards, "I won. Sorry. Sorry. I WON.", the world. Both are losses (by 76 and 25) because the autopilot's brain is the heuristic |

**Thirteen lines, sanity only.** The configs are shared across board sizes, so the steady
change reaches Tomás and Ilse at the back table. Each against the realistic player of its
own rank on 13×13, eight games (`--cells=thirteen --board=13`): Tomás (8k) 3/8, −4 a game;
Ilse (9k) 5/8, −4 a game. Both on their labels. No 13×13 opponent is 20k, so the floor does
not reach that board; 19×19 has no opponents to measure (UI-01).

**What it cannot prove.** The autopilot's brain is the heuristic, which loses every game to
a realistic 20 kyu, so no fixture can show a beginner winning. Once Kesh hands out 22 kyu
the ladder gives stones as the gap opens, but the games with Pip (18k, not floored) and
Kesh's first (12k) come before any rank exists and are even. That is ENG-08, an owner
decision. The owner playing Abel and Wren is the remaining check.

**What it cost.** Two power-offs. One KataGo process is about a gigabyte and a core; the
first probe ran twelve games of two engines next to another agent's eight, and the second
ran twelve games plus the latency gate. The probe now plays both sides in one process,
takes `--concurrent`, refuses to start a game under `--mem-floor-gb`, and the last runs
were pinned to two or four cores with `taskset` and `nice`. Read `CLAUDE.md`'s command
block before running it.

**Deliberate breaks:** `human_<rank>_steady.cfg` temperatures 0.65/0.45 → 0.80/0.65;
`human_20k_<style>.cfg` temperature 1.5 on every move (`chosenMoveTemperatureOnlyBelowProb`
0.01 → 1.0); `tools/katago_strength_probe.gd` and `tools/gnugo-gtp.sh` added (development
only, not shipped); `README.md` states what an engine costs at runtime.


## M42 — Nineteen lines, readable at the board (UI-01)

Development-only 19×19 play, with the town still offering its existing smaller boards.
The match begins with the whole board and a dismissible controls card. V opens a nine-line
view around the cursor; arrows follow real intersections, with coordinates and continuation
ticks distinguishing a cropped view from a true edge. The footer always names the selected
point. The opponent's last coordinate says when it is outside the view. V returns to the
whole board while preserving the point under consideration. Counting uses both views.

Review cards share the transform and navigation: V begins inspection at the played move
(or the recommended move for a pass), arrows inspect, and V/Esc returns to overview.
Long explanations now have pages, retaining their marker legend instead of overflowing the
card. Overview Left/Right finishes the current explanation before changing positions.

`GoBoardGeometry` is autoload-free; drawing and picking share its current transform.
`GoBoardInk`, `BoardNavigation` and `BoardControls` separate drawing, viewing controls and
the first-session card from the match. The board remains global; rules, ranks, result
formats and save schema have not changed. The manual trial accepts a profile path, with
nineteen-line, handicap and missing-engine fixtures under `tools/fixtures/`.

**Done when:** `tools/test.sh` reported **14269 passed, 0 failed** (M41: **12505**;
**1764** added geometry/input assertions), **229 files all load**, and all three serial
KataGo gates passed. The review gate analysed 79/79 nine-line positions in 14.8 s and
241/241 nineteen-line positions in 61.6 s; its stalled-engine watchdog failed the silent
engine in 6.1 s. `tools/check_lessons.py`: **0 problems**. The game routes below were
played through input events and their listed frames opened; these observations, rather
than the reported assertion count, are the UI acceptance evidence.

The suite still carries the known TECH-06 autoload/CanvasLayer testing debt. The old
ambience/exam script-run errors are not newly repaired by these checks. Shutdown resource
warnings also remain in played routes; they are not a claim of a clean lifetime audit.

### Played and inspected

Captures and logs from this session are under `/home/user/ui01-shots/` and
`/home/user/ui01-*.log`. All runs used
`XDG_DATA_HOME=/home/user/.local/share/ninepoint-ui-01`, whose resolved Godot directory was
checked before fixture writes. `run_game.sh` acquires its lock before writing saves and
uses the same directory as the Python fixture tool. Original playtest checkout and saves
were kept separate. Native 384×216 frames and nearest-neighbour 3× copies were opened;
input events ran against the normal 1152×648 viewport.

| route / capture folder | observed evidence |
|---|---|
| `nineteen` / `regression-nineteen` | controls card; physical V binding; mouse blocked by controls/resignation cards; mouse placement in overview and zoom; D16 retained while locating an opponent reply elsewhere; corners; resignation cancellation/confirmation; visible attic return |
| `nineteen_game` / `full`, then `final-game` | two engine-backed games to counting, result, review and world; 105 and 161 legal engine replies respectively, without fallback; final run had 326/326 review positions analysed in 84.3 s |
| `nineteen_game` / `final-game`, frames 01–09 | positions at moves 81, 161, 241 and 321, captures, crowded counting, a black group toggled with Space and restored with the mouse, score changed and restored; White won the replay by 339.5 |
| `nineteen_game` / `final-game`, frames 10–20 | review offer/loading, tally, dense strength position T16, zoom, distant T1 inspection, both pages of both costly positions, world return; the last frame is during the fade, so the short route supplies the clear world frame |
| `nineteen_review` / `review` | saved nineteen-line review; every page inspected; actual B2 and recommended E13 located through arrows in zoom; Esc restores overview |
| `nineteen_handicap`, `nineteen_missing`, `nineteen_count` | nine handicap stones, real engine reply, unavailable engine with legal fallback play, actual counting with keyboard/mouse group changes and result |
| `prologue`, `handicap`, `thirteen` / corresponding `regression-*` folders | Pip's 7×7, a move and reply, V leaves its layout alone; Ilse's 9×9 handicap stones and occupied-point feedback; Kesh's 13×13 at B12 with reply |
| `lessons` / `regression-lessons`, frames 03–09 | ko's liberties, keyboard-selected capture, forbidden immediate recapture, explanation, and Wren's post-lesson line |
| `quay_review` / `regression-quay_review` | every page of the smaller review, unchanged board layout, V ignored, return to the quay |
| `review_leave` / `regression-review_leave` | Esc leaves loading; the 81-position analysis finishes in the world; its tally and strength card can then be read at the quay |
| `review_unavailable` / `regression-review_unavailable` | stalled review returns a readable "No review today" card after 12.1 s; Space returns to the attic |

### Learner-facing judgement and revisions

The controls card makes V discoverable without a development instruction. "Whole board"
and "Close view", exact coordinates, and the continuation ticks make the current view
readable. Overview shows the distribution of activity; zoom is where a learner can select
and inspect an intersection without counting tiny lines. A distant opponent reply remains
named while the cursor stays put. The D16 → overview → D16 replay demonstrated finding
the reply without losing the player's selected point.

Nine visible lines remain the starting value, borrowed from the existing small board.
Opened crowded match/count/review frames separated stones, territory squares, dead crosses,
and review marks sufficiently at native and 3× scale, so the view was not reduced further.
At the count, marking a group was visibly reversible. The interface does not make the
heuristic's proposed dead groups authoritative or teach the player how to adjudicate them.

The first full game exposed a long review explanation running its legend into the frame;
pagination and a repeated legend fixed it, and the full replay's four explanatory pages
were opened to verify the repair. The long thinking label was also clipped; the nineteen-line
panel now says "Thinking...". A saved review fixture had nine-line prose coordinates on a
nineteen-line board; these now derive from its size and agree with the markers.

Rejected test evidence matters too: the first mouse probe used unscaled screen positions
and failed to place; it now uses the actual viewport transform. The old handicap script
photographed engine preparation instead of stones; it now waits for the player's turn.
The old `lessons` save never satisfied Wren's ko offer and photographed a normal match;
`ko_ready` supplies the missing completed-game flag, and capture/refusal were replayed.
Prologue and unavailable-review routes explicitly clear inherited saves. Another
unavailable-review attempt ended by normal engine resignation; the autoplay used to
wait indefinitely for counting in that case. It now recognises an already shown result
as a finished game, while the nineteen-line counting fixture still explicitly requires
the counting phase.

The development fixture's original two-second reply deadline fell back on nineteen lines.
Five seconds is a development starting deadline, unchanged in production profiles. Across
the two full games, GTP's second-resolution timestamps showed replies spanning 2–4 seconds;
this proves playable latency in these runs, not a strength calibration for a nineteen-line
cast. The player brain is still the heuristic; its heavy losses do not model a human's
learning or prove that the game teaches well.

**Still unbuilt:** CONTENT-04 owns the teaching transition, Hana's offer and its gate.
The current local lessons do not explain when to leave a fight or why a distant move is
larger. A generic review habit even called the nineteen-line position "a small board";
CONTENT-01 records that context problem. The owner's experience remains the stronger test
of teaching. UI-01 delivers access to the board for development, not that introduction.

### Deliberate changes

| before | after / boundary |
|---|---|
| full-board-only drawing and independently cached mouse layout | shared geometry evaluated before drawing and picking, preserving global indices |
| no viewing action | named `go_zoom` on V, active only for nineteen-line board/review viewing |
| one fixed-height review explanation | measured pages with the same board and repeated legend; no review payload change |
| trial asserts nine lines | requested size must match result and SGF `SZ` |
| runner lock after fixture writes; default-only Python save path | lock and Godot path verification before writes; shared XDG override |
| nineteen-line teaching still absent | remains absent, explicitly tracked as CONTENT-04 |
