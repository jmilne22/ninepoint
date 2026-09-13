# Kettle: model, movement and atmosphere prototype

An opt-in prototype on `codex/kettle-next`, based on freshly verified `main` at
`2c0ca2d`. Ro, Wren, Kesh and Tomás use rebuilt bodies and garments, articulated
hands and authored motion. Their approved head/hair designs remain; every
neutral-gaze facial expression preserves the original painted pixels exactly.

## Play

```bash
/home/user/Code/ninepoint-kettle-next/tools/play_kettle_next.sh
```

Starts inside the actual campaign Kettle with a disposable preview save. Walk with
WASD/arrows, hold Shift to jog, Space/Enter to talk; Tab opens the menu. Wren offers
a normal game. The original engine, teaching, result, reaction and review remain.
Closing discards this preview's progress. Existing campaign saves are separate.

Use `tools/play_kettle_next.sh --baseline` for the same starting save with the
current main presentation. The normal launcher retains main's art unless
`NINEPOINT_PRESENTATION=kettle_next` is explicitly set for that process.

## Changes

- Four bodies with separate silhouettes, continuous shoulders, tailored garments,
  cuffs, hems, shaped shoes, and articulated finger/thumb joints. Tomás has a bar apron.
- A relaxed jogging cycle with curved arm paths and neutral wrists, opposing torso
  and hip rotation, foot roll and phase-preserving transitions. Character movement
  still comes from the original physics actor; animation follows distance travelled.
- Shared world/portrait/match models; gaze variants move only the irises. Reactions
  play once, then settle. Scene-owned timers reject stale capture gestures.
- Long oak planks, rebuilt Go tables, ceramics and napkins, green bar cabinetry,
  espresso equipment, back shelves and continuous plaster walls. Existing collision
  footprints, walkways, map IDs and interaction positions remain authoritative.
- Room-specific light and grounding, animated window foliage and cup steam; a cloth
  follows Tomás's working hand and disappears when work is interrupted.
- The prototype world renders at 1536×864; portrait rendering doubles independently
  of UI layout. Match board picking and its logical coordinates are unchanged.

## Build and verify

```bash
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_kettle_next.py'
# Selective builds:
python3 tools/build_kettle_next.py --people player
python3 tools/build_kettle_next.py --room
python3 tools/build_assets.py --groups kettle_next
XDG_DATA_HOME=/home/user/.cache/ninepoint-next-gate tools/test.sh
DISPLAY_NUM=0 tools/run_kettle_next.sh
```

Sources live in `tools/kettle_next/`; generated output lives in `art/kettle_next/`.
The optional asset group is excluded from default production builds. The runtime
profile and acting controller are in `src/rpg/kettle_next/`. No Go rules, difficulty
profiles, dialogue text, progression or save schema change.

`kettle_next.json` plays the full conversation/game/review return and explicitly
rejects engine fallback, incomplete review and duplicate match recording.
`kettle_next_showcase.json` is a short film route ending by resignation; it is not
the full-game acceptance evidence. All acceptance runs use isolated user data and
run serially. Engine binaries/models/libraries are local dependencies, not git assets.

See [verification](verification.md) for results and review media. This prototype
is for visual review; whole-campaign rollout remains a separate decision.

## Repeat the visual review

```bash
python3 tools/kettle_next/capture.py --kind cast
python3 tools/kettle_next/capture.py --kind motion
python3 tools/kettle_next/capture.py --kind performance
python3 tools/kettle_next/serve.py             # http://127.0.0.1:8781
```

Capture commands share the game runner's exclusive lock and discard their save data.
Raw 30-fps AVI movies go to `~/.cache/ninepoint-kettle-next/`; `media.py --movie`
converts them without changing playback speed. The isolated movement film omits the
passing tram so it cannot obscure Ro's feet. The actual 30/60/144-fps movement gate
retains the normal environment.
