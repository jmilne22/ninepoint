# Expressive Ninepoint — campaign rollout

The approved Kettle refinement now supplies the full campaign's visual direction:
original painted-face characters, natural resting poses, continuous motion, warm timber,
cream plaster and green details. All twelve campaign areas use live 3D geometry.
The 21 named identities and five kinds of passer share the full-body model pipeline.

**Correction:** the initial rollout had high-refresh locomotion resets and an inward-facing
mirrored tram cab. [ART-13R fixes, footage and launcher](motion-fix/README.md).

## Play

```bash
/home/user/Code/ninepoint-style-rollout/tools/play_expressive_world.sh
```

This is the complete campaign, starting at the title screen. Its preview saves persist
under `~/.local/share/ninepoint-style-preview`, separate from existing campaign saves.
New Game, Continue, the three slots, lessons, Capture Go, rated games, both leagues,
the Cup, exam and match reviews retain their existing behaviour.

WASD/arrows walk, Shift runs, Space/Enter interacts, Tab opens the menu and Esc cancels.
Board controls are displayed beside the board; mouse and keyboard remain supported.
`tools/play.sh` also uses the new presentation, with the normal campaign save directory.

## Review

- [One-minute in-engine review film](showcase.mp4) — normal speed, with recorded game audio.
- [Six selected screenshots](six-screenshots.jpg).
- [All twelve areas](rooms-overview.jpg) and [the complete cast](cast-overview.jpg).
- [Uncut 90.6-second campaign tour](full-tour.mp4).
- [Verification, fixes and limits](verification.md).

## Interface

DejaVu Sans outline text replaces the bitmap face. MSDF glyphs and vector panels render
at window resolution through Godot's `canvas_items` stretch mode. The world and portrait
viewports retain the approved 768×432 visual density; layouts remain in their established
384×216 world/teaching and 768×432 match coordinates. Rounded paper/green panels, restrained
borders and shared button/focus styling cover menus, dialogue, teaching, counting and review.
The title, Hana introduction and tram arrivals use live campaign/table geometry.
Teaching, puzzles and review use matching kaya grain and smooth slate/shell stone art,
while retaining their top-down board layout and input geometry.

The font is bundled with its [license](../../art/fonts/LICENSE.txt).
[Godot's resolution guidance](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
explains why Canvas Items keeps interface outlines sharp independently of 3D viewports.

## Architecture and builds

`World`, `Player`, `Npc`, map data and the bridge still own simulation. `ProjectedWorld`
now renders a live 3D view of the same coordinates: 16 logical pixels correspond to .8
model units. `ExpressivePerson` only follows the existing character's position, facing
and activity; it owns no collision, interaction, rank, flags or save data. `ExpressiveTramVisual`
follows the existing tram arrival tween. Real geometry supplies occlusion and shadows.
`ExpressivePortrait` uses the same full-body mesh in the dialogue close-up.

Python coordinates Blender/Pillow sources in `tools/expressive_world/`, reusing the
approved full-body rig and the campaign's existing architectural vocabulary. Static meshes
are grouped by material to keep live draw calls modest. `art/expressive_world/` holds
separate generated outputs; the original trial and its media remain available.

```bash
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_expressive_world.py'
# Selective rebuilds:
python3 tools/build_expressive_world.py --people
python3 tools/build_expressive_world.py --maps de_ketel quay
# Also included in the complete asset coordinator:
python3 tools/build_assets.py --groups expressive_world
XDG_DATA_HOME=/home/user/.cache/ninepoint-world-gate tools/test.sh
```

## Verification

The full gate passes 19,407 / 0 checks and loads 380 resources. The asset gate includes
134 live-world checks; the full-body build passes 4,160 deformed-pose assertions.
Serial rendered checks cover all 22 connections, mouse/keyboard board input, lessons,
counting, real Wren play/review, save slots, tram and competition panels.
See [the inspected evidence](verification.md) for the exact routes and boundaries.
Human review remains the judge of the art direction; automated checks protect gameplay
and layout contracts. The logical maps, source Go rules, engine profiles, dialogue content,
progression and save schema are unchanged by this rollout.


To serve the review files locally with video seeking:

```bash
python3 tools/expressive_world/serve.py
# http://127.0.0.1:8770/showcase.mp4
```

Record the actual campaign with disposable data; `MOVIE` is optional for other routes:

```bash
DISPLAY_NUM=0 RESOLUTION=1536x864 TIMEOUT=480 \
  MOVIE=/home/user/.cache/ninepoint-world-showcase.avi \
  OUT=/home/user/.cache/ninepoint-world-film \
  tools/run_rendered.sh tools/autopilot/expressive_showcase.json
```

`tools/expressive_world/media.py` documents the inspected capture's frame cuts and encoding.
All cuts retain 30 fps and ordinary game animation time; no motion is sped up.
