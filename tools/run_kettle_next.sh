#!/usr/bin/env bash
# Existing serial runner, isolated saves, optional normal-speed movie.
set -euo pipefail
cd "$(dirname "$0")/.."
export NINEPOINT_PRESENTATION=kettle_next
if [ "${1:-}" = "--baseline" ]; then unset NINEPOINT_PRESENTATION; shift; fi
export OUT="${OUT:-$PWD/docs/kettle_next/screenshots}"
export LOG="${LOG:-$HOME/.cache/ninepoint-kettle-next-run.log}"
export TIMEOUT="${TIMEOUT:-1200}"
exec tools/run_rendered.sh "${1:-tools/autopilot/kettle_next.json}"
