#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export NINEPOINT_AUDIO_PREVIEW=1
if [ "${1:-}" = "--baseline" ]; then export NINEPOINT_AUDIO_PREVIEW=baseline; shift; fi
export NINEPOINT_PRESENTATION=campaign_next
export OUT="${OUT:-$PWD/docs/audio_preview/screenshots}"
export LOG="${LOG:-$HOME/.cache/ninepoint-audio-preview-run.log}"
export TIMEOUT="${TIMEOUT:-1200}"
mkdir -p "$HOME/.cache/ninepoint-audio-preview"
import_log="$HOME/.cache/ninepoint-audio-preview/import.log"
XDG_DATA_HOME="$HOME/.cache/ninepoint-audio-preview/import-data" "${GODOT:-$HOME/.local/bin/godot}" --headless --path . --editor --quit > "$import_log" 2>&1
if rg -q 'Parse Error|Compile Error' "$import_log"; then cat "$import_log"; exit 1; fi
exec tools/run_rendered.sh "${1:-tools/autopilot/audio_preview.json}"
