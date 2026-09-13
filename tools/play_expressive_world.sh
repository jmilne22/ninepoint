#!/usr/bin/env bash
# Full campaign with the approved style and its own persistent preview saves.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"
export XDG_DATA_HOME="${NINEPOINT_STYLE_DATA:-$HOME/.local/share/ninepoint-style-preview}"
mkdir -p "$XDG_DATA_HOME"
"$GODOT" --headless --path . --editor --quit > "$XDG_DATA_HOME/import.log" 2>&1
if rg -q 'Parse Error|Compile Error' "$XDG_DATA_HOME/import.log"; then
    cat "$XDG_DATA_HOME/import.log"; exit 1
fi
exec "$GODOT" --path . --resolution 1536x864 "$@"
