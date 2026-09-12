# Wren table scene — revised trial

This branch is a second, isolated match experiment. The owner rejected the first
prototype's models, pose swapping and stretched board. This version replaces those
three presentation systems. It has not been adopted for the campaign.

## Play

From this checkout:

```sh
tools/play_table_scene.sh
```

It opens a 768×432 match, displayed at 2×, against Wren Calloway (20k). Ro plays Black;
Wren's shipped engine profile, komi and stopping policy are preserved. The player is
unranked and this is a casual match. Every launch has disposable user data; closing,
resigning or completing the game writes no campaign record.

Use the mouse or arrow keys to choose an intersection, click or Space to place,
P to pass, R to resign, and H for counting help. Esc cancels a modal; closing the
window ends the trial. The result card exits instead of entering the walking world.

## What changed

- A real 3D wooden board, lens-shaped stones and turned bowls share a lit tabletop.
  Camera projection and ray-to-board intersection give display and picking the same geometry.
- Original Ro and Wren identities are rebuilt as skinned meshes. Seven continuous
  animation clips replace four-frame pose atlases. Faces use painted UV expressions,
  including blink frames; facial features have no projecting geometry.
- The lower-corner characters have separate transparent 3D viewports and inward-facing
  cameras. Their composition keeps all 81 intersections visible.
- Placement, capture and result reactions use the match's observable events. They do
  not request an engine evaluation. Wren's idle/thinking state follows the turn.
- The existing GoMatch controller still owns legality, keyboard input, modal guards,
  captures, scoring and the result. A hidden GoBoardView receives explicitly mapped
  viewport input. The trial draws the shared game state with 3D meshes.

The camera is fixed. This is a composed match view, not a new walking-world camera or
an adoption decision for the other opponents. Hands have authored gestures, not
physical interaction with arbitrary board intersections.

## Reproduce the assets and evidence

```sh
# NixOS dependencies; Blender and Pillow generate every experimental art export.
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'tools/table_scene/build.sh'
python3 tools/table_scene/check_assets.py
LOG=/home/user/.cache/table-input.log tools/run_table_scene.sh --verify-table_scene
LOG=/home/user/.cache/table-live.log tools/run_table_scene.sh --live-check
MOVIE=/home/user/.cache/table-scene.avi tools/run_table_scene.sh --showcase
```

Run game/engine routes serially. The rendered runner takes the normal global game
acceptance lock, uses a hidden display and creates disposable user data. It stages
768×432 project settings before Godot starts, so MovieWriter records the true trial
resolution. The ordinary `project.godot` remains at the campaign's resolution.

The showcase is explicitly a **prepared, legally replayed game**, not a recording of
Wren choosing scripted moves. Its 16 moves include one capture by each side, two
passes, counting and the result. The live check separately requires actual engine
replies with no fallback. All animation and movie timing use normal speed.

See [verification.md](verification.md) for inspected evidence and technical results.
