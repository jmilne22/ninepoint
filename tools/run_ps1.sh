#!/usr/bin/env bash
# Reuse the game's locked screenshot harness with disposable, verified user data.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p "$HOME/.cache/ninepoint-ps1"
export XDG_DATA_HOME
XDG_DATA_HOME=$(mktemp -d "$HOME/.cache/ninepoint-ps1/run-XXXXXX")
export ENTRY_SCENE="res://src/prototype/ketel/room.tscn"
export OUT="${OUT:-$PWD/docs/ps1/screenshots}"
trap 'rm -rf "$XDG_DATA_HOME"' EXIT
bash tools/run_game.sh "${1:-tools/autopilot/ps1_composition.json}"
