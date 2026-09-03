#!/usr/bin/env bash
# Play Ninepoint on your own screen.
#
# (tools/run_game.sh is the *test* harness -- it forces a virtual display and
#  screenshots into /tmp. This one opens a real window.)
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"
exec "$GODOT" --path . --resolution 1152x648 "$@"
