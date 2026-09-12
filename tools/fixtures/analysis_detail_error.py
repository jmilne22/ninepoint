#!/usr/bin/env python3
"""Real pipe fixture: complete pass one, reject pass two without losing its scores."""
import json
import sys
for line in sys.stdin:
    query = json.loads(line)
    if query["id"] != "review":
        print(json.dumps({"id": query["id"], "error": "detail unavailable"}), flush=True)
        continue
    for turn in query["analyzeTurns"]:
        print(json.dumps({"id": "review", "turnNumber": turn,
            "rootInfo": {"scoreLead": -3.0 * turn},
            "moveInfos": [{"move": "F4", "scoreLead": -3.0 * turn}]}), flush=True)
