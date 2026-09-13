# Developing Ninepoint

[Back to the README](../README.md) · [Player guide](PLAYING.md) · [Repository instructions](../AGENTS.md)

Ninepoint uses Godot 4.7 and statically typed GDScript. The Go rules are independent
of the RPG; see [ARCHITECTURE.md](../ARCHITECTURE.md) before changing those boundaries.
Read [AGENTS.md](../AGENTS.md) for the design rules, generated-file ownership and full
verification workflow. Fetch `origin`, start from the current `origin/main`, prove the
hashes match, and work on a branch. Check [WORKBOARD.md](../WORKBOARD.md) for current work.

## Local setup

Open `project.godot` in Godot and finish its import pass, or run from the repository root:

```bash
godot --headless --path . --editor --quit
GODOT="$(command -v godot)" tools/play.sh
```

The shell helpers default to `~/.local/bin/godot`; set `GODOT` to your executable when
using another installation. Direct `godot` commands assume it is on your PATH.
Global `class_name` scripts need the editor pass before a headless `--script` run.
`tools/play.sh` and `tools/test.sh` refresh imports themselves.

### NixOS

The development machine keeps Godot at `~/.local/opt/godot`, with a wrapper at
`~/.local/bin/godot` that launches it through `steam-run`. A bare downloaded binary
will not run here without that runtime. Use the wrapper or put its directory on PATH.
Keep checkouts and scratch work under `/home/user`; the runtime cannot enter
`/tmp/Codex-*` paths. Headless tests use the same wrapper.

`tools/play.sh` uses the real display. `tools/run_game.sh` uses Xvfb for automated
screenshots; `DISPLAY_NUM=0` selects the real display when needed.

## Tests and played verification

The full test gate needs the pinned Linux x86_64 KataGo package and models. Playing
with the fallback opponent does not. Install once, then verify locally:

```bash
tools/setup_katago.sh
tools/setup_katago.sh --verify
tools/test.sh
python3 tools/check_lessons.py
```

`tools/test.sh` compiles and loads scripts, scenes and resources, then runs the unit
suites and engine integration gates. Visual and gameplay work also requires a played
route and inspection of its screenshots. A successful process exit alone is insufficient.

Use a separate checkout and an **absolute `XDG_DATA_HOME` under `/home/user`** while
someone is playing. Save tests write all three slots. For example:

```bash
XDG_DATA_HOME=/home/user/.cache/ninepoint-tests tools/test.sh
TIMEOUT=600 OUT=/home/user/.cache/ninepoint-practice-shots LOG=/home/user/.cache/ninepoint-practice.log tools/run_rendered.sh tools/autopilot/standalone_practice.json
OUT=/home/user/.cache/ninepoint-readme-shots LOG=/home/user/.cache/ninepoint-readme.log tools/run_rendered.sh tools/autopilot/readme_showcase.json
```

`run_rendered.sh` supplies disposable user data. Run game/engine routes serially, use
distinct output and log paths, and open the resulting images. Autopilot scripts declare
their starting save; see [AGENTS.md](../AGENTS.md) for route authoring rules.

Additional focused checks:

```bash
tools/test_review_pure.sh
python3 tools/check_dialogue.py
godot --headless --path . --script res://tools/katago_review_test.gd
tools/check_audio.sh
```

The audio check needs a display and a real audio driver; headless Godot cannot verify audibility.

## Assets and content

Art builds use Python, Blender and Pillow. The checked-in assets are sufficient to play.
Edit source generators, never their exported images, models, maps or resource files.
Dialogue, lessons and puzzles are hand-authored. The ownership table in
[AGENTS.md](../AGENTS.md#assets-and-content-are-generated--do-not-hand-edit-the-outputs)
identifies each generator.

```bash
python3 tools/build_assets.py
python3 tools/gen_maps.py
python3 tools/gen_content.py
python3 tools/gen_practice_profiles.py
python3 tests/test_art.py
```

Pipeline guides: [live campaign](expressive_world/README.md),
[rendered world](ps1/world/README.md), [audio](audio_preview/README.md),
[standalone Practice](practice/README.md).

Optional presentation previews and historical comparisons live in the
[campaign preview](campaign_next/README.md), [Kettle prototype](kettle_next/README.md),
[motion correction](expressive_world/motion-fix/README.md) and
[table showcase](table_scene/README.md) guides. These documents distinguish preview
assets from the default campaign presentation.

## Source map

| Directory | Responsibility |
|---|---|
| `src/go/` | Pure rules, scoring, ranks, handicap, lessons and puzzles |
| `src/go_ai/` | Opponents, KataGo integration and review analysis |
| `src/go_ui/` | Board, match, lesson and puzzle screens |
| `src/practice/` | Standalone settings, learning, history and resumable games |
| `src/rpg/` | World, movement, NPCs, interactions and tram |
| `src/academy/` | Leagues, Cup and exam |
| `src/dialogue/`, `src/quest/` | Conversations and campaign progress |
| `src/ui/`, `src/autoload/` | Shared interface, state, saves and services |
| `data/`, `art/`, `audio/` | Content and game assets |
| `tools/`, `tests/` | Generators, launchers, capture routes and verification |
