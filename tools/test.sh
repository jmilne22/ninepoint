#!/usr/bin/env bash
# Headless checks: everything must *compile* first -- a parse error in a script
# the unit tests never touch will otherwise only show up as a blank screen --
# and then the suites run.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"

echo "== deterministic art contracts =="
python3 tests/test_art.py

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
SUITE_LOG=$(mktemp)
if ! timeout 300 "$GODOT" --headless --path . --script res://tests/test_runner.gd > "$SUITE_LOG" 2>&1; then
  cat "$SUITE_LOG"
  rm -f "$SUITE_LOG"
  exit 1
fi
if grep -qE "SCRIPT ERROR|Compile Error|Parse Error" "$SUITE_LOG"; then
  cat "$SUITE_LOG"
  rm -f "$SUITE_LOG"
  exit 1
fi
grep -E "checks|passed,|FAIL" "$SUITE_LOG"
rm -f "$SUITE_LOG"

# Godot can resume a caller after an awaited function hits a script error, then
# exit zero. A gate's own "passed" line is insufficient in that case.
run_integration_gate() {
  local gate_log
  gate_log=$(mktemp)
  if ! timeout "$1" "$GODOT" --headless --path . --script "$2" > "$gate_log" 2>&1; then
    cat "$gate_log"
    rm -f "$gate_log"
    return 1
  fi
  cat "$gate_log"
  if grep -qE "SCRIPT ERROR|Compile Error|Parse Error" "$gate_log"; then
    rm -f "$gate_log"
    return 1
  fi
  rm -f "$gate_log"
}

echo "== capture scene and KataGo Linux integration gates =="
run_integration_gate 30 res://tools/capture_scene_probe.gd
run_integration_gate 90 res://tools/katago_smoke.gd
run_integration_gate 120 res://tools/katago_service_test.gd
run_integration_gate 600 res://tools/katago_review_test.gd
