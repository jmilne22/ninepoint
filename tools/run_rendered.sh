#!/usr/bin/env bash
# Production presentation, normal launch, disposable user data.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p "$HOME/.cache/ninepoint-rendered"
export XDG_DATA_HOME
XDG_DATA_HOME=$(mktemp -d "$HOME/.cache/ninepoint-rendered/run-XXXXXX")
export OUT="${OUT:-$PWD/docs/ps1/world/screenshots}"
trap 'rm -rf "$XDG_DATA_HOME"' EXIT
bash tools/run_game.sh "${1:-tools/autopilot/art_tour.json}"
