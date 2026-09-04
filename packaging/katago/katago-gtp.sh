#!/usr/bin/env bash
# Linux x64 launcher. The v1.15 CPU release needs these bundled compatibility
# libraries; NixOS additionally needs steam-run for the generic ELF loader.
set -euo pipefail
KATAGO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export LD_LIBRARY_PATH="$KATAGO_ROOT/lib:$KATAGO_ROOT/lib/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
if command -v steam-run >/dev/null 2>&1; then
  exec steam-run "$KATAGO_ROOT/bin/katago" "$@"
fi
exec "$KATAGO_ROOT/bin/katago" "$@"
