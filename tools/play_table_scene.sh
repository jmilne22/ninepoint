#!/usr/bin/env bash
# An isolated match experiment. Closing or finishing never touches player saves.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"
mkdir -p "$HOME/.cache/ninepoint-table_scene"
export XDG_DATA_HOME
XDG_DATA_HOME=$(mktemp -d "$HOME/.cache/ninepoint-table_scene/play-XXXXXX")
trap 'rm -rf "$XDG_DATA_HOME"' EXIT
# A fresh checkout must import the bitmap font before the theme can load.
if [ ! -f .godot/global_script_class_cache.cfg ]; then
  "$GODOT" --headless --path . --editor --quit > "$XDG_DATA_HOME/first-import.log" 2>&1
fi
"$GODOT" --path . --editor --headless --quit > "$XDG_DATA_HOME/import.log" 2>&1
if rg -q 'Parse Error|Compile Error' "$XDG_DATA_HOME/import.log"; then
  cat "$XDG_DATA_HOME/import.log"
  exit 1
fi
python3 tools/table_scene/runtime.py "$XDG_DATA_HOME/project"
"$GODOT" --path "$XDG_DATA_HOME/project" res://src/experiments/table_scene/trial.tscn -- "$@"
