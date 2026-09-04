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
    go_sgf.gd           SGF export (debugging, reviews, kifu)
    go_review.gd        picks the three things worth saying about a finished game
    go_review_replay.gd     reading a game's positions back
    go_review_detectors.gd        liberties and capture: what went wrong
    go_review_detectors_good.gd   the four things it is pleased about
    go_review_detectors_shape.gd  what only the whole game can show
    go_evaluator.gd     how the game was going, in points -- the engine seam
    go_progress.gd      the shipped answer: stones plus what you walled off
    go_review_history.gd    what this player keeps doing, across games

  go_ai/              OPPONENTS — depend on go/ only
    go_opponent.gd      abstract interface: choose_move(game) -> Move  (async-capable)
    random_opponent.gd  legal-move picker, eye-avoiding (floor of the ladder)
    heuristic_opponent.gd  the shipped AI: capture/escape/atari/extend/influence, tunable by rank
    gtp_opponent.gd     GTP-over-stdio adapter (KataGo/GNU Go) — stub + protocol, unused in slice
    opponent_factory.gd  OpponentProfile resource -> live opponent instance

  go_ui/              PRESENTATION of a Go game
    go_board_view.*     draws a board+stones from a GoGame, emits point_pressed
    go_match.*          the match scene: board, HUD, turn loop, pass/resign, scoring phase
    go_puzzle.*         puzzle scene reusing GoBoardView
    go_lesson.*         the tutorial runner, also reusing GoBoardView
    go_review.*         the post-game review, ditto: your own game, replayed at you
    go_replay.gd        a cursor over the game, so the board can be stepped through
    go_review_voice.gd  which character says a finding, and in what words

  rpg/                THE WORLD
    player/             player character body, input, interaction ray
    npc/                NPC body, schedule component, interact component
    maps/               city exteriors, interiors, spawn points, doors
    components/         reusable: Interactable, Warp, Facing, GridMover
    sign_desk.gd        everything you READ on a wall or SIT DOWN at -- the league,
                        Cup and exam boards, the study desk, the hooks, the bed.
                        Split out of world.gd in M30 along the one seam that
                        actually divides it: reading versus starting a match.
                        Anything that spends an hour stays in the World

  academy/            THE INSTITUUT'S PROGRESSION -- and the federation's events
    league_table.gd     pure: standings from the record, round robin, rated only.
                        Ignores exam AND Cup contexts: a tournament game is not
                        a fixture in the term, and the open section put four
                        league members in the draw
    league_board.gd     the panel on the hall wall
    exam.gd             pure: the qualifying exam, three rounds, top two through
    cup_draw.gd         pure: the Cup. The two sections live here rather than on
                        the panel -- which board, which field, which title, and
                        the summary line the wall and Marguerite share. Pure is
                        not a preference: cup_board.gd reads autoloads, so in a
                        `--script` run it does not compile and its statics all
                        return null, silently
    cup_board.gd        the draw pinned up at the Bondszaal

  club/               DE KETEL'S PROGRESSION -- the other half of the argument
    hooks_ladder.gd     pure: seven name-cards on brass hooks, ordered by who has
                        beaten who. Counts UNRATED games, which is why it is not a
                        second LeagueTable roster. Only wins move a card and only
                        upwards; a new card goes on the bottom hook, not at your rank
    hooks_board.gd      the panel at the back of the salon

  dialogue/           dialogue graph runner + typewriter box (data-driven from JSON)
  quest/              quest definitions, tracker, objective evaluation
  save/               serialisation of GameState to user:// slots
  ui/                 title screen, pause, rank card, toasts
  autoload/           GameState, SaveSystem, SceneRouter, EventBus, MatchBridge, Audio

data/
  npcs/*.tres         NPCData resources (identity, rank, portrait, schedule, dialogue file)
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
| `GameState` | Flags, player rank, relationship scores, quest progress, inventory, time-of-day, spawn target | Touch the scene tree, know about UI |
| `SaveSystem` | Serialise/deserialise `GameState` to `user://save_N.json`, slot metadata | Own gameplay state |
| `SceneRouter` | Scene changes, fade transitions, "return here afterwards" stack | Know what a Go match is |
| `MatchBridge` | The single seam between world and Go: takes a `MatchRequest`, pushes the match, puzzle, lesson or review scene, returns a `MatchResult` | Contain Go rules |
| `Audio` | Buses, a pool of SFX voices, one music track; listens on `EventBus` for the sounds that belong to events rather than to callers | Decide when gameplay happens |

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
req.opponent_profile = load(OpponentProfile.path_for("kesh", 9))
req.context_id       = "kesh_first_match"
MatchBridge.start_match(req)          # suspends the world, routes to the match scene

# ...later, anywhere:
EventBus.match_finished.connect(func(result: MatchResult): ...)
```

`MatchResult` carries: `context_id`, `winner`, `player_won`, `margin`, `by_resignation`,
`board_size`, `handicap`, `komi`, `move_count`, `sgf`, and `findings` — what `GoReview`
noticed in the game. The findings hold board positions and so are deliberately absent
from `to_dict()`: they are for the screen that runs next, not for the save file.

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

## 5. Opponent interface (built for KataGo later)

```gdscript
class_name GoOpponent extends RefCounted
func setup(profile: OpponentProfile, game: GoGame) -> void
func choose_move(game: GoGame) -> Dictionary   # {type: MOVE|PASS|RESIGN, x, y}  (may await)
func should_accept_dead_marks(marks) -> bool
func shutdown() -> void
```

`choose_move` is allowed to await, so a subprocess engine can take as long as it wants without
the shipped AI paying for an async architecture. `GtpOpponent` implements the same interface
over `OS.execute_with_pipe` and speaks `boardsize/clear_board/play/genmove/final_score`.
The intent is that switching Kesh to KataGo is one field in her `.tres` — `engine = "gtp"`,
`gtp_command = "…/katago"`. **That is the design, not yet the state.** `GtpOpponent` is
unwired and carries three known gaps: handicap stones never reach the engine, `set_position`
positions never reach it at all, and `_command` blocks the main thread. See MILESTONES.md.

Strength knobs on `OpponentProfile` (all honest, none of them "the AI plays badly on purpose
because you levelled up"): `engine`, `rank_label`, `board_size`, `komi`, `handicap`,
`mistake_rate`, `reading_depth`, `aggression`, `territory_bias`, `resign_threshold`.

## 6. Data-driven content

**NPCs** (`NPCData.tres`): id, display name, rank label, portrait, sprite palette id, home
location, schedule (time-block → location + position), dialogue graph path, opponent profile.

**Dialogue** (JSON graph):
```json
{ "id": "kesh", "nodes": {
    "start":   { "cond": [["flag_false","kesh_beaten_once"]], "goto": "first_meeting" },
    "first_meeting": { "portrait":"kesh", "text":["..."],
                       "choices":[{"text":"You're on.","goto":"challenge"}] },
    "challenge": { "action":{"type":"start_match","profile":"kesh_9x9","context":"kesh_first"} }
} }
```
Node kinds: `text`, `choices`, `branch` (conditions), `action` (set flag, bump flag, give an
item, **take one back**, set rank, start a quest, toast), `exit` (start match, start puzzle,
start lesson, a Cup or exam round, the problem paper), `goto`, `end`. Conditions read
`GameState` only — dialogue never queries the world directly. There is no relationship
action; that system was removed, and this line claimed one for several milestones after it.

`take` is the opposite of `give` and arrived with it in M32, because a borrowed thing that
cannot be handed back is not borrowed. There is no item *registry* — `GameState.inventory` is
a bare `Array[String]` — so an id exists only because two files spell it the same way, and
`tests/test_data.gd` is what makes that true: every `take` and every `has_item` in the graphs
must name something some `give` actually hands over.

**Quests** (`QuestData.tres`): ordered steps, each with a completion condition (flag set,
match finished with context, puzzle solved, lesson finished, somebody talked to, location
entered) and a journal line. `QuestTracker` listens on `EventBus` and advances steps; NPC
dialogue branches on quest step. Only the **current** step is ever tested, so the events are
strictly ordered and one fired out of turn is lost. Which quest the journal displays is
`QuestTracker.journal_quest_id()` — the last one started that is still running.

## 7. Scenes and reuse

Composition over inheritance, small scenes with one job:
`Interactable` (area + prompt + signal), `Warp` (area → target map + spawn point),
`GridMover` (8-way movement with collision), `ScheduleComponent` (moves an NPC per time block),
`DialogueBox` (typewriter, portrait, choices), `GoBoardView` (stateless renderer of a GoGame).

Maps are `TileMapLayer`-based with a `YSort` entity layer; every map exposes named
`SpawnPoint` nodes so warps and save/load can place the player deterministically.

## 8. Save format

`user://save_1.json` .. `user://save_3.json` — plain JSON, versioned, human-readable for
debugging. These are the real keys, which is `GameState.to_dict()` and nothing else:

```json
{ "version": 1, "saved_at": "2026-09-04T12:00:00", "playtime": 640.0,
  "player_name": "Ro", "rank_strength": 8,
  "flags": {...}, "quests": {"first_stones": {"step": 2, "done": false}},
  "inventory": ["old_goban"],
  "match_records": [ {"npc_id": "kesh", "player_won": false, "margin": 8.5, ...} ],
  "day": 7, "slots_used": 1, "time_block": "dusk",
  "current_map": "de_ketel", "spawn_point": "from_street",
  "return_position": [12, 8], "has_return_position": true }
```

Saving is `GameState.to_dict()`; loading is `GameState.from_dict()` then `SceneRouter` opens
the map at the spawn point, or drops the player back on `return_position` when a match
interrupted them there. No node paths are serialised. `current_map` is a map **id**, not a
scene path — every map is data, and `MapData` resolves it.

Which of the three slots a run belongs to is `GameState.active_slot`, and it is deliberately
**not** in the file: the path is the slot's identity, and a number written inside would
disagree with it the first time somebody copied one. `SaveSlots` (`src/ui/save_slots.gd`) is
the one panel that lists them, shared by the title screen and the pause menu.

## 9. Testing

`tests/test_runner.gd extends SceneTree` — runs headlessly, no editor, no rendering:

```
godot --headless --path . --script res://tests/test_runner.gd
```

Suites cover the Go module exhaustively (captures, suicide, ko, superko, scoring, handicap,
komi, game end) and the data layer (every dialogue graph parses, every goto resolves, every
NPC resource loads, every puzzle has a legal solution). RPG behaviour is verified by the
**autopilot harness** (`tools/run_game.sh`), which drives the real game under Xvfb with
scripted input and captures PNG screenshots at named beats.

## 10. Conventions

- `snake_case` files and members, `PascalCase` classes, `SCREAMING_SNAKE` constants.
- Every script that is a type declares `class_name`.
- Static typing everywhere; `Variant` only at data boundaries.
- Signals are past tense (`match_finished`), methods are imperative (`start_match`).
- No script over ~300 lines; if it grows, it wants to be a component.
- `assert()` for programmer errors, `push_error()` for data errors, never silent failure.
- Godot 4.7: `TileMapLayer` (not `TileMap`), typed arrays, `@onready`, `await`.

## 11. Known architectural risks

- **Dead-stone marking** at game end is heuristic + player override. A GTP engine would give a
  better answer (`final_status_list dead`); the interface already has the seam for it.
- **Dialogue JSON is untyped.** Mitigated by a validation test over every graph, not by types.
- **Autopilot input** simulates events rather than a human; it can miss timing-dependent bugs.
