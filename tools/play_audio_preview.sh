#!/usr/bin/env bash
# Latest campaign graphics with the default production audio and disposable progress.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "${1:-}" = "--baseline" ]; then echo 'The superseded audio has been removed.' >&2; exit 2; fi
export NINEPOINT_PRESENTATION=campaign_next
GODOT="${GODOT:-$HOME/.local/bin/godot}"
mkdir -p "$HOME/.cache/ninepoint-audio-preview"
export XDG_DATA_HOME
XDG_DATA_HOME=$(mktemp -d "$HOME/.cache/ninepoint-audio-preview/play-XXXXXX")
trap 'rm -rf "$XDG_DATA_HOME"' EXIT
"$GODOT" --headless --path . --editor --quit > "$XDG_DATA_HOME/import.log" 2>&1
if rg -q 'Parse Error|Compile Error' "$XDG_DATA_HOME/import.log"; then cat "$XDG_DATA_HOME/import.log"; exit 1; fi
python3 tools/make_test_save.py lost_to_kesh >/dev/null
"$GODOT" --path . --resolution 1536x864 res://tools/kettle_next/start.tscn -- "$@"
