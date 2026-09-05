#!/usr/bin/env sh
# A KataGo that never answers. The review's watchdog must fail it honestly and
# the match must still return to the world.
while read -r _line; do :; done
sleep 3600
