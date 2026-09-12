# De Ketel: fixed-view 2.5D experiment

The owner approved full-game conversion after this experiment. The normal game now uses
the [ART-08 production pipeline](world/README.md); this guide records the isolated prototype.

An opt-in playable room, separate from the shipped Sela town. Original low-poly character
models supply **both** sprites and bust portraits; no AI-generated portrait is included.
The owner replaced the initial illustrated-portrait proposal with model-rendered portraits.

## Play

After the normal Godot editor import pass:

```sh
tools/play_ps1.sh
```

Move with WASD/arrows, run with Shift, talk with Space/Enter/E. Walk to the seat opposite
somebody to talk across their table. Wren offers her existing supported, unrated 9×9 game.
Lessons, match cancellation, the result reaction, and review return to this same room.
V reopens the last game's review offer after leaving the cards or loading panel. Esc opens
the exit card; Enter leaves the application and Esc resumes. This visit is never saved.

Entering the prototype does not modify production assets or save files. Session mode
refuses save, load and delete calls at the persistence boundary, including calls from a
board or background review. It neither copies nor reads a saved playthrough.

## Build

Blender 5.2.1 LTS and Python with Pillow are development dependencies for both this
experiment and production art. Playing either uses checked-in PNG exports and needs neither.
The normal `build_assets.py` does not regenerate or overwrite this experiment.

On this NixOS machine:

```sh
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_ps1.py --group room'
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_ps1.py --group people'
godot --headless --path . --editor --quit
```

On other systems with those dependencies installed, run the Python commands directly;
`--blender /path/to/blender` or `BLENDER` selects the executable. `--group preview` renders
one standing view per person and the busts for composition review before animation.

`tools/ps1/room.py` builds the set, lighting, camera, furniture groups and physical footprints.
`people.py` builds the four cast models from the existing `tools/characters.py` identity
records. `common.py` holds geometry/material primitives; `render.py` is Blender's entry.
`build_ps1.py` exports full-canvas layered PNGs, the projected layout, six-pose/eight-direction
40×64 sprite atlases and 108×108 portraits. A character is about 48 pixels tall in its cell.
The model pose columns are idle, walk contact/passing/opposite contact, activity A/B.

Editable `.blend` snapshots in `source/` are reproducible outputs, not a second authoring
source. Edit the Python geometry/material/pose definitions and regenerate. `.gdignore`
keeps those sources out of Godot's automatic Blender importer. PNG imports use nearest
filtering; render shadows are baked into the room and actor shadows are drawn at the feet.
The Blender version, Cycles CPU settings and fixed random seed make the process repeatable;
bit-identical renders across different Blender/denoiser versions are not promised.

## Presentation boundary

`RoomPresentation` loads the generated manifest: background, depth-sorted image layers,
collision polygons, foot/seat positions, fixed camera and spawn. Every coordinate comes
from the same orthographic render camera (45° azimuth, 30° elevation). Moving characters
use screen-space `CharacterBody2D` collisions and normalized input. Large bar sections are
separate sort groups. The original `MapData`/`MapBuilder` renderer remains independent.

`SceneRouter.session_world_scene` supplies an in-memory return destination consumed by
`MatchBridge`; `SaveSystem.session_only` guards persistence. The prototype conversation
adapter uses the shipped JSON graphs and match profiles, including post-match branching.
The dialogue subclass inherits the interpreter and keyboard handling, measures prose,
and scrolls long choice lists while following keyboard selection.

## Verification

```sh
tools/run_ps1.sh tools/autopilot/ps1_tour.json
tools/run_ps1.sh tools/autopilot/ps1_match.json
tools/run_ps1.sh tools/autopilot/ps1_walk.json
tools/run_ps1.sh tools/autopilot/ps1_cancel.json
tools/run_ps1.sh tools/autopilot/ps1_branches.json
tools/run_ps1.sh tools/autopilot/ps1_review_leave.json
tools/test.sh
```

The wrapper supplies a disposable `XDG_DATA_HOME` under the user's cache, selects the
prototype scene, and uses `run_game.sh`'s exclusive lock. Screenshot output defaults to
`docs/ps1/screenshots`; use `OUT` to retain different routes. `KetelProbe` plans foot-safe
paths over the actual exported polygons and drives real input; it does not teleport.
Synthetic result-branch regressions are explicitly labelled and are not played-game evidence.

The later full-town conversion was approved and implemented as ART-08. This prototype
remains available as a separate session-only scene; production verification is in the
[world guide](world/verification.md), with [ART-09 polish](polish/verification.md) afterward.

## Verified 2026-09-12

Base `f459336` was fetched and matched HEAD before creating `codex/ps1-ketel-prototype`.
Final gate: **16,975 Godot checks** (previous 16,922; 53 new presentation/isolation
checks), **13 art tests**, **292 loaded files**, and all three KataGo integration gates.
The review engine gate covered complete 9×9 and 19×19 games and the stalled-engine exit.
The final gate output is retained in [verification.log](verification.log).

| Route | Captures | What was inspected |
|---|---:|---|
| `ps1_tour` | 10 | Every NPC approach/bust, Wren practice choices, five-option refresher |
| `ps1_walk` | 10 | Window aisle, behind/front of bar, stove, door/cancel, front table, walking |
| `ps1_match` | 7 | Actual Wren game: 16 player moves, count, loss, reaction, 59-position engine review, return |
| `ps1_cancel` | 1 | Actual preparation cancellation, same seat, zero records, save refusal |
| `ps1_branches` | 3 | Explicit synthetic win/loss records reach different reactions and review offer |
| `ps1_review_leave` | 3 | Synthetic two-move fixture: leave live analysis, walk, reopen completed review with V |
| Existing `art_tour` | 18 | Normal renderer across twelve maps; bar, institute and street captures opened |

All routes exited zero with no script errors. The representative images in `tour/`,
`walk/`, `match/`, `cancel/`, `branches/`, `leave/` and `normal/` were opened. The initial
composition in `screenshots/` predates the full animation and final aisle adjustment;
`tour/` and `walk/` show the final geometry. `preview.png` and `room_3x.png` are nearest-scaled
copies of actual game captures, not mockups. Regenerate them and the model reference sheet
with `python3 tools/ps1/contact_sheet.py` in the Pillow environment.

The first route caught an overly tight chair/corridor approach; actual geometry was widened
and the navigation probe changed to a finer, foot-safe grid. The door interaction moved
inward from the collision boundary. A loading hint now points to V in this room rather than
to the normal world's quay. The screenshot harness's Xvfb child originally inherited its
exclusive lock; closing that descriptor in the child fixes repeated runs.

Limits: the real played result was a loss; the win reaction was tested with an explicit
synthetic result, not claimed as a human or engine-strength playtest. Busts currently have
one expression each. The Go board continues using the shipped portrait strips and UI.
This proves one room's pipeline and loop; it does not approve the full-town art direction.

Both prototype and normal routes report the existing shutdown-only two-object/one-resource
warning. A verbose isolated exit identifies `AudioStreamWAV`/`AudioStreamPlaybackWAV` for
`theme_club.wav`; it is not a live script failure or a new room resource leak.

Document sweep: README, AGENTS, ARCHITECTURE, ART_DIRECTION, ROADMAP and WORKBOARD updated.
GAME_DESIGN and MILESTONES inspected: no gameplay pillar or shipped town revision changes,
and an opt-in experiment receives a workboard record rather than a new release milestone.
