#!/usr/bin/env bash
# Deliberately valid GTP framing with an invalid move vertex.
while IFS= read -r line; do
  case "$line" in
    genmove*) printf '= definitely-not-a-vertex\n\n' ;;
    *) printf '=\n\n' ;;
  esac
done
