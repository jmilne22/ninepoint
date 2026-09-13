# The Kettle — expressive area POC

A single walkable area that carries the approved match characters into the room and
conversation portraits. Ro, Wren, Kesh and Tomás share the match cast's silhouettes,
clothes, colours, painted faces and continuous gestures. The furnished room uses the
same warm wood, cream and green palette. Other areas retain their current presentation.

## Try it

```bash
/home/user/Code/ninepoint-kettle-refinement/tools/play_expressive_kettle.sh
```

WASD/arrows walk, Shift runs, Space talks, Tab opens the player card, V offers the
last game's review, and Esc opens the exit confirmation. Talk to Wren for the existing
practice game. Talk to Kesh after that game for the novice card. Tomás is at the counter.

This launcher opens a 1536×864 window over a 768×432 canvas, with normal-speed
30-fps animation. It uses a disposable data directory and never writes campaign saves.
The visit starts with the basic rules already acknowledged so Wren can offer a game.

## Latest review pass

[ART-12R refinement](refinement/README.md) is the current version: balanced body
proportions, corrected joint roll, relaxed individual stances, grounded strides,
full-body conversation close-ups, textured surfaces, cast shadows and leafy ficus.
The user clarified Hikaru no Go 3 on GameCube as the presentation reference.
The earlier footage below remains available as the before version.

## First POC footage

[43-second viewing cut](showcase.mp4) · [Full 110.8-second recorded route](full-tour.mp4)

The cut removes engine startup and verification pauses; every retained segment plays
at its original 30 fps with in-engine sound. It shows walking, Wren's conversation,
a real match, returning to the room, Tomás and Kesh. This is footage from Godot,
not an asset mock-up. [Screenshots](screenshots/01_arrival.png).

[Inspected acceptance record](verification.md): 28 rendered checks, full regression gate and media metadata.

## Rebuild and verify

```bash
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_expressive_kettle.py'
DISPLAY_NUM=0 LOG=/home/user/.cache/kettle-route.log tools/run_expressive_kettle.sh --tour
# Optional movie capture; output is Godot's actual MovieWriter AVI.
DISPLAY_NUM=0 MOVIE=/home/user/.cache/kettle.avi tools/run_expressive_kettle.sh --tour
XDG_DATA_HOME=/home/user/.cache/ninepoint-kettle-gate tools/test.sh
```

Sources live in `tools/expressive_kettle/`; outputs stay in `art/expressive_kettle/`.
The full-body generator extends the approved match source meshes with skinned legs,
shoes and locomotion clips. It does not alter the approved match exports.

The room and its conversation adapter live in `src/experiments/expressive_kettle/`.
The existing DialogueGraph, MatchBridge, engine profiles, rules, scoring, result records,
novice card and review service remain the authority. SceneRouter's session-only return
route restores the player's position. This is an isolated presentation seam, not a
replacement for the campaign world controller.

Limits: this is one fixed-camera room. The front edge is a room boundary; travel to other
areas is not part of this prototype. Lessons, puzzles and review cards retain their
existing presentation, at the appropriate canvas size. Full-world adoption follows
visual review of this area.
