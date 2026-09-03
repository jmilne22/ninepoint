#!/usr/bin/env bash
# Is the music actually coming out?
#
# Not part of tools/test.sh, and it cannot be: --headless forces Godot's Dummy
# audio driver, which reports silence for everything. This needs a display so
# the real driver initialises, so it runs on Xvfb like run_game.sh does.
#
# It exists because music and ambience were silent for the life of the project
# and every other gate stayed green throughout -- see tests/check_audio.gd.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"

if ! pgrep -x Xvfb >/dev/null 2>&1; then
    Xvfb :99 -screen 0 640x360x24 >/dev/null 2>&1 &
    XVFB_PID=$!
    trap 'kill "$XVFB_PID" 2>/dev/null' EXIT
    sleep 2
fi

DISPLAY=:99 timeout 180 "$GODOT" --path . --script res://tests/check_audio.gd 2>&1 \
    | grep -E "driver:|peak|audible|SILENT|check_audio:"
exit "${PIPESTATUS[0]}"
