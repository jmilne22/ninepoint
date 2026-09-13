#!/usr/bin/env bash
# Keep the correction build separate from a still-running rollout preview.
set -euo pipefail
cd "$(dirname "$0")/.."
export NINEPOINT_STYLE_DATA="${NINEPOINT_STYLE_DATA:-$HOME/.local/share/ninepoint-motion-preview}"
exec tools/play_expressive_world.sh "$@"
