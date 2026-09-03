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
# SAVE=<preset> regenerates save slot 1 before launching, so a script declares
# the state it needs instead of inheriting whatever was left lying around.
#
# This is not a convenience. Every script that ends by saving through the pause
# menu -- slice_full, joos, win_path -- overwrites the slot with wherever the
# player finished, so running two in a row silently tests the first one's
# leftovers. That produced three wrong diagnoses in one evening, twice by one
# session and once by another checking the first's work: the screenshots were
# all fine and the starting state was not.
SAVE="${SAVE:-}"
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

if [ -n "$SAVE" ]; then
  echo "regenerating save slot 1 as '$SAVE'"
  python3 tools/make_test_save.py "$SAVE" >/dev/null || {
    echo "no such preset '$SAVE' -- see tools/make_test_save.py STATES" >&2; exit 2; }
fi

if ! xdpyinfo -display ":$DISPLAY_NUM" >/dev/null 2>&1; then
  echo "starting Xvfb on :$DISPLAY_NUM"
  Xvfb ":$DISPLAY_NUM" -screen 0 1280x720x24 >/tmp/xvfb.log 2>&1 &
  sleep 2
fi

# Only one run at a time. The screenshot directory and user://save_*.json are
# shared by every copy of the game on this machine, and `rm -rf "$SHOTS"` below
# will happily delete another run's frames out from under it -- which is how a
# run ends up with two shots numbered 11 and eight frames missing from OUT, with
# no error anywhere. Two sessions verifying at once cost an entire evening to
# exactly this; refuse instead.
exec 9>"/tmp/ninepoint-run.lock"
if ! flock -n 9; then
  echo "another run_game.sh is using the game (save slots and shots/ are shared)." >&2
  echo "wait for it to finish, or kill it -- do not run two at once." >&2
  exit 3
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
# Not silenced: a copy that fails must say so. `2>/dev/null` here turned a
# failure into an absence, which is the same trick the old _talk_to warning
# played -- and an absent screenshot looks exactly like a beat that was skipped.
if [ -d "$SHOTS" ]; then
  cp "$SHOTS"/*.png "$OUT"/ || echo "WARNING: could not copy all screenshots" >&2
  ls -1 "$OUT"
fi
