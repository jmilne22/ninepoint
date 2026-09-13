#!/usr/bin/env bash
# Complete campaign with disposable preview saves. --baseline keeps the same route.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"
mkdir -p "$HOME/.cache/ninepoint-campaign-next"
export XDG_DATA_HOME
XDG_DATA_HOME=$(mktemp -d "$HOME/.cache/ninepoint-campaign-next/play-XXXXXX")
trap 'rm -rf "$XDG_DATA_HOME"' EXIT
export NINEPOINT_PRESENTATION=campaign_next
if [ "${1:-}" = "--baseline" ]; then unset NINEPOINT_PRESENTATION; shift; fi
"$GODOT" --headless --path . --editor --quit > "$XDG_DATA_HOME/import.log" 2>&1
if rg -q 'Parse Error|Compile Error' "$XDG_DATA_HOME/import.log"; then cat "$XDG_DATA_HOME/import.log"; exit 1; fi
python3 tools/make_test_save.py lost_to_kesh > /dev/null
"$GODOT" --path . --resolution 1536x864 -- "$@"

if [ -n "${OUT:-}" ]; then
  mkdir -p "$OUT"
  cp "$XDG_DATA_HOME/godot/app_userdata/Ninepoint/shots/"*.png "$OUT/"
fi
