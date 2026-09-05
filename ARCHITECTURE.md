# NINEPOINT — Architecture

Godot 4.7 · GDScript · 2D · `gl_compatibility` renderer.

## 1. The one rule

**`src/go/` may not know that a game exists around it.**

The Go rules module is pure `RefCounted` GDScript: no `Node`, no scene tree, no signals into
the world, no `res://` loads except its own. It can be run and tested by a `SceneTree` script
with the rest of the project deleted. Everything else in this document exists to keep that true.

Dependencies point one way:

```
                ┌────────────────────────────────────────────┐
                │                   ui/                      │  title, menus, HUD, dialogue box
                └───────────────┬────────────────────────────┘
                                │
   ┌─────────────┬──────────────┼───────────────┬──────────────┐
   │   rpg/      │  dialogue/   │   quest/      │   go_ui/     │  presentation + world
   └──────┬──────┴───────┬──────┴───────┬───────┴──────┬───────┘
          │              │              │              │
          └──────────────┴──────┬───────┴──────────────┘
                                │
                    ┌───────────▼────────────┐
                    │   autoload/ (state)    │  GameState, SaveSystem, SceneRouter, EventBus
                    └───────────┬────────────┘
                                │  (reads data only)
                    ┌───────────▼────────────┐
                    │        data/           │  Resources + JSON: NPCs, dialogue, quests, opponents
                    └────────────────────────┘

              go_ui/ ──uses──► go_ai/ ──uses──► go/          (never the reverse)
```

`go/` has **zero** inbound arrows. `go_ai/` depends only on `go/`. `go_ui/` is the only place
where a stone becomes a sprite.

## 2. Directory layout

```
project.godot
GAME_DESIGN.md ARCHITECTURE.md ART_DIRECTION.md MILESTONES.md

src/
  go/                 PURE RULES — no Node, no scene tree, unit-tested headlessly
    go_types.gd         enums, Move, Vec helpers, rank utilities
    go_board.gd         position: stones, groups, liberties, capture, legality
    go_game.gd          game: move history, ko, passes, captures, komi, handicap, result
    go_scoring.gd       Japanese (territory) + Chinese (area) scoring, dead-stone heuristic
    go_zobrist.gd       position hashing (ko / superko / repetition)
    go_sgf.gd           SGF export (the record of a game)
    go_rank.gd          the kyu/dan scale, handicap between two ranks, ranks per stone
    go_rank_ladder.gd   how a rank moves: one step, in the direction the result says
    go_table_talk.gd    what just happened at the board, as tags a person could react to

  go_ai/              OPPONENTS — depend on go/ only
    go_opponent.gd      abstract interface: choose_move(game) -> Move  (async-capable)
    random_opponent.gd  legal-move picker, eye-avoiding (floor of the ladder)
    heuristic_opponent.gd  the shipped AI: capture/escape/atari/extend/influence, tunable by rank
    engine_pipe.gd      one child process on a pipe, read a line at a time off the scene thread
    gtp_opponent.gd     GTP adapter: KataGo's Human-SL model at the character's rank, at the board
    katago_analysis.gd  KataGo's analysis mode over a whole finished game, one turn at a time
    match_analysis.gd   the review, pure: what a move cost, which three positions, the payload
    opponent_factory.gd  OpponentProfile resource -> live opponent instance

  go_ui/              PRESENTATION of a Go game
    go_board_view.*     draws a board+stones from a GoGame, emits point_activated
    go_board_geometry.gd pure visible-region, pixel-spacing and hit-test transform
    go_board_ink.gd      stone, coordinate and crop-boundary drawing
    board_navigation.gd shared overview/zoom caption and input; presentation only
    board_controls.gd   once-per-session 19×19 controls card
    go_match.*          the match scene: board, HUD, turn loop, pass/resign, scoring phase
    go_puzzle.*         puzzle scene reusing GoBoardView
    go_lesson.*         the tutorial runner, also reusing GoBoardView
    nigiri_ceremony.*   choosing colours, as a set piece
    table_talk_voice.gd which character says a table-talk tag, and in what words

  rpg/                THE WORLD
    player/             player character body, input, interaction ray
    npc/                NPC body, idle behaviour, passers-by
    maps/               city exteriors, interiors, spawn points, doors
    components/         reusable: Interactable, Warp, Facing, CharacterSprite
    props/tram.gd       the tram: passes on its own, and pulls in when you board it
    sign_desk.gd        everything you READ on a wall or SIT DOWN at -- the league,
                        Cup and exam boards, the study desk, the tram stop, the bed.
                        Split out of world.gd in M30 along the one seam that
                        actually divides it: reading versus starting a match

  academy/            THE INSTITUUT'S PROGRESSION -- and the federation's events
    league_table.gd     pure: standings from the record, round robin, league
                        fixtures only. The exam, the Cup and a rematch at De
                        Ketel are all played against league members and none
                        of them is a fixture
    league_board.gd     the panel on the hall wall
    exam.gd             pure: the qualifying exam, three rounds, top two through
    cup_draw.gd         pure: the Cup. The two sections live here rather than on
                        the panel -- which board, which field, which title, and
                        the summary line the wall and Marguerite share. Pure is
                        not a preference: cup_board.gd reads autoloads, so in a
                        `--script` run it does not compile and its statics all
                        return null, silently
    cup_board.gd        the draw pinned up at the Bondszaal

  dialogue/           dialogue graph runner + typewriter box (data-driven from JSON)
  quest/              quest definitions, tracker, objective evaluation
  ui/                 title screen, opening, dialogue box, HUD, pause, save slots
  autoload/           GameState, SaveSystem, SceneRouter, EventBus, MatchBridge, KataGoService,
                      MatchReviewService, Audio, GameInput, Autopilot

data/
  npcs/*.tres         NPCData resources (identity, rank, portrait, dialogue file)
  opponents/*.tres    OpponentProfile resources (engine, strength knobs, board, komi, handicap)
  dialogue/*.json     dialogue graphs
  quests/*.tres       QuestData resources
  puzzles/*.json      puzzle definitions

art/                  generated pixel art (see ART_DIRECTION.md)
audio/                generated sound and music (see tools/gen_audio.py)
tools/                python art generators + run/screenshot harness
tests/                headless test runner + suites
```

## 3. Autoloads (the only globals)

| Autoload | Owns | Never does |
|---|---|---|
| `EventBus` | Global signals (`dialogue_started`, `match_finished`, `quest_advanced`, …) | Hold state |
| `GameState` | Flags, player rank, quest progress, inventory, the match record, spawn target | Touch the scene tree, know about UI |
| `SaveSystem` | Serialise/deserialise `GameState` to `user://save_N.json`, slot metadata | Own gameplay state |
| `SceneRouter` | Scene changes, fade transitions, "return here afterwards" stack | Know what a Go match is |
| `MatchBridge` | The single seam between world and Go: takes a `MatchRequest`, pushes the match, puzzle or lesson scene, returns a `MatchResult` | Contain Go rules |
| `Audio` | Buses, a pool of SFX voices, one music track; listens on `EventBus` for the sounds that belong to events rather than to callers | Decide when gameplay happens |
| `KataGoService` | Short-lived engine leases, warmed while the player is still walking to the board and handed to exactly one match or killed | Outlive a scene by accident |
| `MatchReviewService` | The one review that may be running: starts `KataGoAnalysis` on a recorded game, reports progress, stores the payload in `GameState.match_analysis`; a new match cancels it | Resume after a quit — an interrupted review is marked failed on load |

Rule of thumb: if two systems need to talk, they do it through `EventBus` or through
`GameState` flags — never by reaching across the scene tree with `get_node("../../..")`.

## 4. The world↔Go seam

```gdscript
# rpg side (an NPC's dialogue action):
var req := MatchRequest.new()
# The filename carries the board: <id>_9x9, <id>_13x13, or <id>_<variant> for a
# game arranged rather than sized (_exam, _first, _teaching, _capture). Nothing
# builds that string inline -- OpponentProfile.path_for(id, board, variant) is
# where the convention lives, because a MatchRequest carries no size of its own
# and the profile is the only place a board is chosen.
req.profile          = load(OpponentProfile.path_for("kesh", 9))
req.context_id       = "kesh_first_match"
MatchBridge.start_match(req)          # suspends the world, routes to the match scene

# ...later, anywhere:
EventBus.match_finished.connect(func(result: MatchResult): ...)
```

`MatchResult` carries: `context_id`, `npc_id`, `winner`, `player_won`, `margin`,
`by_resignation`, `board_size`, `handicap`, `handicap_taken`, `komi`, `move_count`,
`unrated`, `opponent_strength` and `sgf`. `GameState.record_match()` appends it to
`match_records`, steps the rank through `GoRankLadder`, and sets `last_result` so the
conversation that follows can branch on `won_last` / `lost_last` — the game just played,
not the lifetime record, which is what `beat` / `lost_to` answer.

Consequences: the Go board can be launched standalone from the editor for testing; the RPG
can be developed against a fake result; and swapping the AI or the board renderer touches
nothing else.

**Coming back from a lesson or a match, the world re-enters the graph at a fixed node**, and
in both directions the failure is silent rather than loud: `DialogueGraph.resolve()` returns
`""` for a node that does not exist, and `DialogueBox.run` then emits `end` without ever
showing a box. So a missing node is a beat that stops happening, with no error and no
failing test.

| Coming back from | World enters | If it is missing |
|---|---|---|
| a match | `post_match` | the opponent says nothing about the game |
| a lesson | `taught_<lesson>`, falling back to `taught` | the teacher says nothing about what they just taught |

`taught_<lesson>` exists because one teacher may give several lessons that want different
closing words — Wren teaches the rulebook and, much later, ko, and a single `taught` node
closing both sent anyone finishing ko back through a speech about a game they had already
played. A teacher with one thing to say still says it from `taught`.

`tests/test_data.gd` enforces both rows: a graph with a `start_match` exit must have a
`post_match`, and every lesson's `teacher` must have one of its two nodes. Both rules exist
because the shape had already cost silent bugs — see MILESTONES M24 and M27.

## 5. Opponent interface (KataGo behind it since M38)

```gdscript
class_name GoOpponent extends RefCounted
func setup(profile: OpponentProfile, game: GoGame) -> void
func choose_move(game: GoGame) -> Dictionary   # {type: MOVE|PASS|RESIGN, x, y}  (may await)
func should_accept_dead_marks(marks) -> bool
func shutdown() -> void
```

`choose_move` is allowed to await, so a subprocess engine can take as long as it wants without
the shipped AI paying for an async architecture. `GtpOpponent` implements the same interface
over `EnginePipe` (one child process, lines read on a worker and polled from the coroutine,
so a wedged engine can never freeze the scene) and speaks `boardsize/clear_board/komi/play/
genmove`, sending handicap and setup stones once and then only unseen moves. Every cast
profile is `engine = "gtp"` with a generated `human_<rank>_<style>.cfg`; a missing binary, a
timeout, a rejected command or an illegal reply falls back to the heuristic for the rest of
the game and says so on the profile (`unavailable_reason`). In those configs the rank is
`humanSLProfile` and the temperament is `chosenMoveTemperature`, and temperature is a
strength knob as well as a mood: below 1.0 the engine plays the majority vote of that rank
rather than one player of it, and skips the blunders. `tools/katago_strength_probe.gd`
measures what a config actually plays at, in whole games against the same model at
temperature 1.0; the temperaments were set from its numbers (M41), not by feel.

The review uses the same pipe against `katago analysis`: `KataGoAnalysis.run(record)` writes
one JSON query for the whole game (`analyzeTurns` = every position, handicap as
`initialStones`, the game's komi, Japanese rules to match `GoScoring`) and reads one line per
position as it arrives. `MatchAnalysis` is pure: it parses those lines, charges each of the
player's moves the difference between the position before and after from their side,
tallies how many matched the engine's move or gave nothing away, and picks at most three
positions. Cost is about one core-second per position on the Eigen build, so the
service streams progress and the caller may leave; a watchdog fails a silent engine.

Strength knobs on `OpponentProfile` (all honest, none of them "the AI plays badly on purpose
because you levelled up"): `engine`, `rank_label`, `board_size`, `komi`, `handicap`,
`mistake_rate`, `reading_depth`, `aggression`, `territory_bias`, `resign_threshold`.

## 6. Data-driven content

**NPCs** (`NPCData.tres`): id, display name, rank label, portrait, sprite palette id,
dialogue graph path, opponent profile. Where somebody stands is the *map's* business:
`data/maps/*.json` lists each map's people, and every person stands on exactly one map, all
the time. There is no schedule; there was one from M26 to M36 and it was cut in M37.

**Presence states** (optional `presence_states` in a map JSON) give a location a small set
of persistent, story-driven versions. `WorldPresence` selects the first state whose `when`
flags match, then may replace local NPC placements/routes and add decor tiles or non-blocking
overheard lines. This is environmental memory, not a calendar: no state depends on the hour,
and a map's services remain available on every visit. States end in an unconditional
`routine` fallback and are checked by `WorldAmbienceTests` for valid tiles, placements and
conversation partners.

**Dialogue** (JSON graph):
```json
{ "id": "wren", "nodes": {
    "start": { "goto": "offer" },
    "offer": { "text": ["Shall we play a practice game?"], "choices": [
        {"text": "Let's play.", "exit": {"type": "start_match", "profile": "wren_9x9",
            "context": "wren", "unrated": true, "practice": true}}
    ]},
    "post_match": { "branches": [
        {"if": [["won_last"]], "goto": "wren_lost"}, {"goto": "wren_won"}
    ]},
    "wren_lost": { "text": ["You won! Well played."] },
    "wren_won": { "text": ["Oh, I won! Thank you for playing."] }
} }
```
Node keys are `text`, `choices`, `branches`, `actions`, `exit` and `goto`. Conditions and
actions read or write GameState. A match exit can set `practice` (default false) and the
world supplies `venue_id`; both are presentation fields. `unrated` alone controls rank
consequences. `GoMatchSetup` resolves size, colours, handicap and komi; `MatchPresentation`
formats those resolved facts, never numerical claims copied from dialogue. `HandicapHelp`
owns modal input and starting-stone highlights. Opponent replies wait until it closes.

The writing rules are in `data/dialogue/VOICES.md`, and the ones a machine can check are
enforced by `tests/test_data.gd`: two lines a node, 110 characters a line, every line fits
four rows beside a portrait, no calendar words, and none of the tics that made fifteen
people sound like one. `tools/check_dialogue.py` prints a graph as a script a person can
read. There is no item *registry* — `GameState.inventory` is a bare `Array[String]` — so an
id exists only because two files spell it the same way, and `tests/test_data.gd` requires
every `take` and every `has_item` to name something some `give` actually hands over.

**Quests** (`QuestData.tres`): ordered steps, each with a completion condition (flag set,
match finished with context, puzzle solved, lesson finished, somebody talked to, location
entered) and a journal line. `QuestTracker` listens on `EventBus` and advances steps; NPC
dialogue branches on quest step. The opening quest additionally reconciles durable teaching
flags and match records on load and after progression events. Completed progress remains
complete; knowing the rules or skipping optional opening advice cannot strand the objective.

`art_props` names generated images and pixel positions; physical footprints are baked into
map collision by the generator. `VenueProps` renders them. `presence_exchanges` is an ordered
list of exchanges, each containing speaker/text lines. Legacy individual lines remain
standalone exchanges. `AmbientBanter` plays each exchange once per visit, leaves silence
between them and suspends during conversation, menus and transitions. Activity variations
use existing flags and head-to-head records, with no clock or relationship state.

## 7. Scenes and reuse

Composition over inheritance, small scenes with one job:
`Interactable` (area + prompt + signal, and `PRIORITY_SIGN` < `PRIORITY_PERSON` — the probe
routinely holds two of these at once, and a person must outrank the furniture behind them),
`Warp` (area → target map + spawn point),
`Facing` (which way a character is turned), `DialogueBox` (typewriter, portrait, choices),
`GoBoardView` (renders a GoGame and holds cursor/zoom presentation state). There is no `GridMover` and no
`ScheduleComponent`; movement lives on `Player`/`Npc`, and there is no schedule.

The tram stop is a sign whose text begins `__TRAM__` followed by JSON naming its routes;
`SignDesk.tram_stop()` offers them as choices, refuses in the box when a route's flag is not
set, asks the `Tram` prop to pull in, and only then changes scene.

Maps are `TileMapLayer`-based with a `YSort` entity layer; every map exposes named
`SpawnPoint` nodes so warps and save/load can place the player deterministically.

For 19×19, `GoBoardGeometry` owns the visible rectangle in global board coordinates.
Both drawing and mouse picking recompute it before use, so input immediately after a
view change cannot use yesterday's pixel transform. Zoom never crops the rules board,
changes a move index, or persists into a save. `go_zoom` (V) is handled only by the active
match/counting view or review card; confirmations and the introductory controls card
consume input before board interaction. Review arrows navigate cards in overview and
inspect intersections in zoom. Long finding text is paginated with `UiKit.paginate`,
reserving the move legend on every page; arrows finish those pages before changing
positions. Page state is presentation-only too.

## 8. Save format

`user://save_1.json` .. `user://save_3.json` — plain JSON, versioned, human-readable for
debugging. These are the real keys, which is `GameState.to_dict()` and nothing else:

```json
{ "version": 1, "saved_at": "2026-09-04T12:00:00", "playtime": 640.0,
  "player_name": "Ro", "rank_strength": 8,
  "flags": {...}, "quests": {"first_stones": {"step": 2, "done": false}},
  "inventory": ["old_goban"],
  "match_records": [ {"npc_id": "kesh", "opponent_name": "Kesh Idowu", "player_won": false,
                      "margin": 8.5, "sgf": "(;GM[1]...)", "review_requested": true, ...} ],
  "match_analysis": { "0": {"availability": "available", "engine_version": "KataGo v1.15.0",
                            "findings": [ {"kind": "mistake", "move_number": 12, ...} ], ...} },
  "current_map": "de_ketel", "spawn_point": "from_street",
  "return_position": [12, 8], "has_return_position": true }
```

`SaveSystem.SAVE_VERSION` remains 1. Legacy calendar keys are ignored. Missing review data
means no saved review; unfinished analysis is marked interrupted on load. The optional
`flags.handicap_intro_seen` is saved after completing or explicitly skipping the first
introduction. Older saves receive the explanation at their next handicap encounter.

Saving is `GameState.to_dict()`; loading is `GameState.from_dict()` then `SceneRouter` opens
the map at the spawn point, or drops the player back on `return_position` when a match
interrupted them there. Blocked or out-of-bounds return positions fall back to a named safe
spawn after layout changes. No node paths are serialised. `current_map` is a map **id**, not a
scene path — every map is data, and `MapData` resolves it.

Which of the three slots a run belongs to is `GameState.active_slot`, and it is deliberately
**not** in the file: the path is the slot's identity, and a number written inside would
disagree with it the first time somebody copied one. `SaveSlots` (`src/ui/save_slots.gd`) is
the one panel that lists them, shared by the title screen and the pause menu.

## 9. Testing

`tests/test_runner.gd extends SceneTree` runs headlessly. It defers suite loading until
autoloads have initialised, so UI-adjacent suites cannot silently fail to compile:

```
godot --headless --path . --script res://tests/test_runner.gd
```

Suites cover the Go module exhaustively (captures, suicide, ko, superko, scoring, handicap,
komi, game end) and the data layer (every dialogue graph parses, every goto resolves, every
NPC resource loads, every puzzle has a legal solution). RPG behaviour is verified by the
**autopilot harness** (`tools/run_game.sh`), which drives the real game under Xvfb with
scripted input and captures PNG screenshots at named beats. The engine has three gates of
its own in `tools/test.sh`, all against the real binary: `katago_smoke.gd` (one legal reply,
and the fallbacks), `katago_service_test.gd` (lease lifecycle, handicap and setup sync,
the malformed and rejecting fixtures) and `katago_review_test.gd` (a whole 9×9 and a whole
19×19 game analysed position by position, and a wedged engine failed by the watchdog).

The save suite, manual development trial and autopilot can be isolated with an absolute
`XDG_DATA_HOME`. `check_user_data.gd` verifies Godot and the Python fixture writer resolve
the same directory before fixtures touch slots. `run_game.sh` acquires its lock before
writing those slots and propagates game failures. Keep engine checks serial.

## 10. Conventions

- `snake_case` files and members, `PascalCase` classes, `SCREAMING_SNAKE` constants.
- Every script that is a type declares `class_name`.
- Static typing everywhere; `Variant` only at data boundaries.
- Signals are past tense (`match_finished`), methods are imperative (`start_match`).
- No script over ~300 lines; if it grows, it wants to be a component.
- `assert()` for programmer errors, `push_error()` for data errors, never silent failure.
- Godot 4.7: `TileMapLayer` (not `TileMap`), typed arrays, `@onready`, `await`.

## 11. Known architectural risks

- **Dead-stone marking** at game end is heuristic + player override. The bundled Human-SL
  engine hung on `final_status_list dead`; ENG-05 investigates analysis ownership instead.
- **Dialogue JSON is untyped.** Mitigated by a validation test over every graph, not by types.
- **Autopilot input** simulates events rather than a human; it can miss timing-dependent bugs.
