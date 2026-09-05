#!/usr/bin/env bash
# GNU Go 3.8 as a GTP reference for tools/katago_strength_probe.gd. Development
# only: it is not shipped, and nothing in the game reaches it. It exists because
# the probe needs one opponent that is not KataGo, or the Human-SL ladder would
# only ever be measured against itself.
#
# On this NixOS machine `nix-shell -p gnugo` fetches it into the store; Godot's
# child processes run under steam-run, whose sandbox cannot run nix-shell but can
# execute a store path directly. Pass `--level N` (0..10) to set strength.
set -euo pipefail
if command -v gnugo >/dev/null 2>&1; then
  exec gnugo --mode gtp "$@"
fi
for candidate in /nix/store/*-gnugo-3.8/bin/gnugo; do
  if [ -x "$candidate" ]; then
    exec "$candidate" --mode gtp "$@"
  fi
done
echo "gnugo is not installed; run: nix-shell -p gnugo --run 'gnugo --version'" >&2
exit 127
