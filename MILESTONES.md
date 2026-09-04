# NINEPOINT — Milestones

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
