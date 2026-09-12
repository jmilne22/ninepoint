#!/usr/bin/env bash
# A standalone art experiment; no saves are read, written or deleted.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"
exec "$GODOT" --path . --resolution 1152x648 res://src/prototype/ketel/room.tscn "$@"
