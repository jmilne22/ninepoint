#!/usr/bin/env bash
# Headless checks: everything must *compile* first -- a parse error in a script
# the unit tests never touch will otherwise only show up as a blank screen --
# and then the suites run.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"

echo "== compiling all scripts and importing assets =="
IMPORT_LOG=$(mktemp)
timeout 300 "$GODOT" --headless --path . --editor --quit > "$IMPORT_LOG" 2>&1
if grep -qE "Parse Error|Compile Error" "$IMPORT_LOG"; then
  echo "COMPILE FAILURES:"
  grep -E -A1 "Parse Error|Compile Error" "$IMPORT_LOG" | head -40
  rm -f "$IMPORT_LOG"
  exit 1
fi
rm -f "$IMPORT_LOG"
echo "   import pass produced no parse errors"

"$GODOT" --headless --path . --script res://tools/check_user_data.gd || exit 2

# The import log is not enough on its own: a bad patch has produced a clean log
# and a broken scene. Load every file and see.
LOAD=$(timeout 240 "$GODOT" --headless --path . --script res://tests/check_load.gd 2>&1)
echo "$LOAD" | grep -E "load check|FAILED|  res://" | head -30
if echo "$LOAD" | grep -q "FAILED"; then
  exit 1
fi

echo "== test suites =="
timeout 300 "$GODOT" --headless --path . --script res://tests/test_runner.gd 2>&1 \
  | grep -E "checks|passed,|FAIL"

echo "== KataGo Linux integration gates =="
timeout 90 "$GODOT" --headless --path . --script res://tools/katago_smoke.gd
timeout 120 "$GODOT" --headless --path . --script res://tools/katago_service_test.gd
timeout 600 "$GODOT" --headless --path . --script res://tools/katago_review_test.gd
