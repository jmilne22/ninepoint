#!/usr/bin/env bash
# Prove the review's facts work with the rest of the game and engine absent.
set -euo pipefail
cd "$(dirname "$0")/.."
PURE_ROOT=$(mktemp -d /home/user/.cache/ninepoint-review-pure.XXXXXX)
trap 'rm -rf "$PURE_ROOT"' EXIT
mkdir -p "$PURE_ROOT/src/go" "$PURE_ROOT/src/go_ai" "$PURE_ROOT/tests"
cp src/go/*.gd "$PURE_ROOT/src/go/"
cp src/go_ai/review_facts.gd src/go_ai/review_continuation.gd src/go_ai/review_narrator.gd "$PURE_ROOT/src/go_ai/"
cp tests/test_kit.gd tests/test_review_facts.gd tests/test_review_narrator.gd "$PURE_ROOT/tests/"
printf '[application]\nconfig/name="Review pure gate"\n' > "$PURE_ROOT/project.godot"
cat > "$PURE_ROOT/run.gd" <<'SCRIPT'
extends SceneTree
func _initialize() -> void:
    var kit := TestKit.new()
    ReviewFactsTests.run(kit)
    ReviewNarratorTests.run(kit)
    print(kit.report())
    quit(1 if kit.failed > 0 else 0)
SCRIPT
GODOT="${GODOT:-$HOME/.local/bin/godot}"
export XDG_DATA_HOME="$PURE_ROOT/user-data"
"$GODOT" --headless --path "$PURE_ROOT" --editor --quit > "$PURE_ROOT/import.log" 2>&1
"$GODOT" --headless --path "$PURE_ROOT" --script res://run.gd > "$PURE_ROOT/run.log" 2>&1
cat "$PURE_ROOT/run.log"
if rg -q 'SCRIPT ERROR|Parse Error|Compile Error' "$PURE_ROOT/import.log" "$PURE_ROOT/run.log"; then
    cat "$PURE_ROOT/import.log"
    exit 1
fi
