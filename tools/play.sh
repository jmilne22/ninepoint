#!/usr/bin/env bash
# Play Ninepoint on your own screen.
#
# (tools/run_game.sh is the *test* harness -- it forces a virtual display and
#  screenshots into /tmp. This one opens a real window.)
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"

# Pulls can add assets and global script classes even when .godot already exists.
# The runtime cannot import them itself; refresh the cache before opening a window.
IMPORT_LOG=$(mktemp)
trap 'rm -f "$IMPORT_LOG"' EXIT
echo "Preparing game assets…"
# A missing theme font can report an error before the editor imports it. Retry
# once with the rebuilt cache, but stop if the project still cannot load cleanly.
for attempt in 1 2; do
  if "$GODOT" --headless --path . --editor --quit > "$IMPORT_LOG" 2>&1 &&
      ! grep -qE 'ERROR:|SCRIPT ERROR|Parse Error|Compile Error' "$IMPORT_LOG"; then
    break
  fi
  if [ "$attempt" -eq 2 ]; then
    cat "$IMPORT_LOG" >&2
    exit 1
  fi
done
rm -f "$IMPORT_LOG"
trap - EXIT
exec "$GODOT" --path . --resolution 1536x864 "$@"
