#!/usr/bin/env bash
# Deliberately reject every command using GTP error framing.
while IFS= read -r line; do
  printf '? rejected by fixture\n\n'
done
