# Expressive match view

The owner approved the revised Wren footage and selected it as Ninepoint's new
style. The rollout starts with all match screens. Walking characters and dialogue
portraits retain their current presentation until the next pass.

## Play

```sh
tools/play.sh                 # normal campaign, with your existing saves
tools/play_table_scene.sh     # disposable, immediately playable Wren match
tools/play_table_scene.sh --opponent=kesh
tools/play_table_scene.sh --opponent=tomas --board=13
```

Cast encounters automatically open the 768×432 view, shown at 2× in the default
1536×864 window. Names, real ranks, colours,
handicap and engine profiles come from the original match request. All 20 opponents
have generated models, seven continuous animation clips and painted expressions.
Ro/Wren retain the approved designs; other identities retain their skin, hair,
clothing, glasses, scarves and accessories from `tools/characters.py`.

Mouse or arrows choose a crossing; click or Space places. P passes, R resigns and
H opens available help. On 19×19, V opens the nine-line close view, with global
coordinates and pan buttons. Confirmations and teaching panels block board input.
Normal campaign results use the existing record, rank, reaction and review flow.

## Presentation

A real wooden board, lens-shaped stones and turned bowls share a warm table.
The fixed camera and ray/plane picking use one geometry at 7/9/13/19 lines and in
close view. Bowl colours follow the player after nigiri. Waist-up characters remain
clear of every crossing. Their placement, capture and result reactions use observable
events; animation never asks the engine for another evaluation.

Teaching temporarily gives the board the left side and a measured panel the right.
Liberties, teaching targets, attempted moves, counting groups and territory follow
the existing board state. Colour selection uses the same table and new characters.
The view runs at 30 fps, with normal-speed animation, and restores the previous
canvas and frame cap when returning to the world. Hands make authored gestures;
they do not physically reach each arbitrary intersection.

The original GoMatch controller still owns setup, legality, keyboard controls,
modal guards and scoring. `src/go_ui/table_scene/` owns presentation;
`MatchViewRoute` selects it for cast matches. Development profiles without a cast
model keep their existing board harness. The standalone Wren launcher is still
disposable and exits after the result instead of writing a campaign record.

## Reproduce

```sh
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'tools/table_scene/build.sh'
python3 tools/table_scene/check_assets.py
tools/run_table_scene.sh --gallery
tools/run_table_scene.sh --verify-table_scene
tools/run_rendered.sh tools/autopilot/table_adoption.json
tools/run_rendered.sh tools/autopilot/rendered_match.json
tools/run_rendered.sh tools/autopilot/teaching_kesh.json
tools/run_rendered.sh tools/autopilot/teaching_wren.json
tools/run_rendered.sh tools/autopilot/mouse_capture.json
MOVIE=/home/user/.cache/table-scene.avi tools/run_table_scene.sh --showcase
```

Art sources are Python/Blender/Pillow in `tools/table_scene/`; exports remain in
`art/table_scene/`. Run game/engine routes serially with disposable data. The runners
provide isolation. `DISPLAY_NUM=0` uses the graphics card on the real display;
the default hidden display uses software rendering.

The showcase is a prepared, legally replayed game, separate from the live Wren
engine check. The multi-size route also declares prepared positions and a random
legal opponent; ordinary campaign/teaching routes exercise the shipped engines.
[Original approved evidence](verification.md) · [Rollout evidence](adoption/verification.md).


The next scoped step is the [one-area Kettle POC](../expressive_kettle/README.md),
which extends these source models into walking and conversation without altering
the approved match exports.
