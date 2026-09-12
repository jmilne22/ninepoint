#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 tools/table_scene/paint.py
blender -b -t 6 --python tools/table_scene/export.py
python3 tools/table_scene/check_assets.py
