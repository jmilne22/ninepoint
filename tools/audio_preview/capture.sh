#!/usr/bin/env bash
# Prepared production-audio replay; the live engine route is tools/run_audio_preview.sh.
set -euo pipefail
cd "$(dirname "$0")/../.."
mode="${1:-preview}"
if [[ "$mode" != preview ]]; then echo 'Use preview; the superseded audio has been removed.'; exit 2; fi
export NINEPOINT_PRESENTATION=campaign_next
mkdir -p "$HOME/.cache/ninepoint-audio-capture" "docs/audio_preview/$mode"
export XDG_DATA_HOME
XDG_DATA_HOME=$(mktemp -d "$HOME/.cache/ninepoint-audio-capture/run-XXXXXX")
trap 'rm -rf "$XDG_DATA_HOME"' EXIT
export OUT="$PWD/docs/audio_preview/$mode"
export DISPLAY=":${DISPLAY_NUM:-99}"
exec 9>/tmp/ninepoint-run.lock
flock -n 9 || { echo 'Another acceptance route is running'; exit 3; }
if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    Xvfb "$DISPLAY" -screen 0 1600x900x24 9>&- >"$XDG_DATA_HOME/xvfb.log" 2>&1 &
    sleep 1
fi
python3 tools/audio_preview/runtime.py "$XDG_DATA_HOME/project"
"${GODOT:-$HOME/.local/bin/godot}" --headless --path . --editor --quit >"$XDG_DATA_HOME/import.log" 2>&1
if rg -q 'Parse Error|Compile Error' "$XDG_DATA_HOME/import.log"; then cat "$XDG_DATA_HOME/import.log"; exit 1; fi
timeout 300 "${GODOT:-$HOME/.local/bin/godot}" --path "$XDG_DATA_HOME/project" \
    --write-movie "$HOME/.cache/ninepoint-audio-capture/$mode.avi" --fixed-fps 30 --disable-vsync \
    res://tools/audio_preview/showcase.tscn -- --showcase >"docs/audio_preview/$mode.log" 2>&1
if rg -q 'SCRIPT ERROR|Parse Error|ERROR:' "docs/audio_preview/$mode.log"; then cat "docs/audio_preview/$mode.log"; exit 1; fi
