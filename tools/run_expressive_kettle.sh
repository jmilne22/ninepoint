#!/usr/bin/env bash
# Serial, disposable rendered acceptance and optional in-engine movie capture.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"
export OUT="${OUT:-$PWD/docs/expressive_kettle/screenshots}"
LOG="${LOG:-$HOME/.cache/ninepoint-table_scene-run.log}"
mkdir -p "$HOME/.cache/ninepoint-table_scene" "$OUT"
export XDG_DATA_HOME
XDG_DATA_HOME=$(mktemp -d "$HOME/.cache/ninepoint-table_scene/run-XXXXXX")
trap 'rm -rf "$XDG_DATA_HOME"' EXIT
exec 9>/tmp/ninepoint-run.lock
flock -n 9 || { echo 'Another game acceptance route is running.'; exit 3; }
export DISPLAY=":${DISPLAY_NUM:-99}"
if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  Xvfb "$DISPLAY" -screen 0 1600x900x24 9>&- >"$XDG_DATA_HOME/xvfb.log" 2>&1 &
  sleep 1
fi
# A fresh checkout must import the bitmap font before the theme can load.
if [ ! -f .godot/global_script_class_cache.cfg ]; then
  "$GODOT" --headless --path . --editor --quit > "$XDG_DATA_HOME/first-import.log" 2>&1
fi
"$GODOT" --headless --path . --editor --quit > "$XDG_DATA_HOME/import.log" 2>&1
if rg -q 'Parse Error|Compile Error' "$XDG_DATA_HOME/import.log"; then
  cat "$XDG_DATA_HOME/import.log"; exit 1
fi
python3 tools/table_scene/runtime.py "$XDG_DATA_HOME/project"
args=()
if [ "$#" = 0 ]; then set -- --tour; fi
mode="$1"
if [ -n "${MOVIE:-}" ]; then
  mkdir -p "$(dirname "$MOVIE")"
  args+=(--write-movie "$MOVIE" --fixed-fps 30 --disable-vsync)
fi
scene="res://src/experiments/expressive_kettle/room.tscn"
if [ "$mode" = "--poses" ]; then scene="res://src/experiments/expressive_kettle/poses.tscn"; fi
status=0
timeout 240 "$GODOT" --path "$XDG_DATA_HOME/project" "${args[@]}" "$scene" -- "$@" > "$LOG" 2>&1 || status=$?
cat "$LOG"
if rg -q 'SCRIPT ERROR|Parse Error|ERROR:|[1-9][0-9]* failed' "$LOG"; then exit 1; fi
exit "$status"
