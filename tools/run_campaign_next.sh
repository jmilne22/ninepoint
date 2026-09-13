#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export NINEPOINT_PRESENTATION=campaign_next
if [ "${1:-}" = "--baseline" ]; then unset NINEPOINT_PRESENTATION; shift; fi
export OUT="${OUT:-$HOME/.cache/ninepoint-campaign-next/shots}"
export LOG="${LOG:-$HOME/.cache/ninepoint-campaign-next/run.log}"
export GODOT="${GODOT:-$HOME/.local/bin/godot}"
export TIMEOUT="${TIMEOUT:-900}"
mkdir -p "$HOME/.cache/ninepoint-campaign-next"
XDG_DATA_HOME="$HOME/.cache/ninepoint-campaign-next/import" "$GODOT" --headless --path . --editor --quit > "$HOME/.cache/ninepoint-campaign-next/import.log" 2>&1
if rg -q 'Parse Error|Compile Error' "$HOME/.cache/ninepoint-campaign-next/import.log"; then cat "$HOME/.cache/ninepoint-campaign-next/import.log"; exit 1; fi
exec tools/run_rendered.sh "${1:-tools/autopilot/campaign_next.json}"
