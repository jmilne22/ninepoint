#!/usr/bin/env bash
# TEST HARNESS -- runs the game on a hidden virtual display and captures the
# screenshots an autopilot script asks for. There is nothing to watch and
# nothing to play here.
#
# To actually play the game, use:  tools/play.sh
#
#   tools/run_game.sh tools/autopilot/slice_full.json
#
# Ctrl-C works: the whole process group is torn down.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"
DISPLAY_NUM="${DISPLAY_NUM:-99}"
SHOTS="$HOME/.local/share/godot/app_userdata/Ninepoint/shots"
OUT="${OUT:-/tmp/ninepoint-shots}"
LOG="${LOG:-/tmp/ninepoint-run.log}"

if [ $# -lt 1 ]; then
  cat >&2 <<'USAGE'
run_game.sh needs an autopilot script -- it runs on a hidden display, so without
one it would sit there invisibly until it timed out.

  To play the game:      tools/play.sh
  To drive the slice:    tools/run_game.sh tools/autopilot/slice_full.json

Available scripts:
USAGE
  ls -1 tools/autopilot/*.json >&2
  exit 2
fi

child=""
cleanup() {
  [ -n "$child" ] && kill -TERM "$child" 2>/dev/null
  sleep 0.5
  [ -n "$child" ] && kill -9 "$child" 2>/dev/null
  exit 130
}
trap cleanup INT TERM

if ! xdpyinfo -display ":$DISPLAY_NUM" >/dev/null 2>&1; then
  echo "starting Xvfb on :$DISPLAY_NUM"
  Xvfb ":$DISPLAY_NUM" -screen 0 1280x720x24 >/tmp/xvfb.log 2>&1 &
  sleep 2
fi

rm -rf "$SHOTS" "$OUT"; mkdir -p "$OUT"
echo "running $1 (log: $LOG) -- Ctrl-C to stop"

DISPLAY=":$DISPLAY_NUM" timeout "${TIMEOUT:-180}" \
  "$GODOT" --path . --resolution 1152x648 -- "--autopilot=res://$1" > "$LOG" 2>&1 &
child=$!
wait "$child"
status=$?
trap - INT TERM

grep -E "AUTOPILOT|SCRIPT ERROR|Parse Error" "$LOG" | tail -40
echo "--- exit $status, $(grep -c 'SCRIPT ERROR' "$LOG") script errors ---"
if [ -d "$SHOTS" ]; then cp "$SHOTS"/*.png "$OUT"/ 2>/dev/null; ls -1 "$OUT"; fi
