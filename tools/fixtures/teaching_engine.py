#!/usr/bin/env python3
"""Synthetic protocol responses for failure/scene tests, never gameplay evidence."""
import json
import os
import sys
import threading

mode = os.environ.get("TEACHING_FAKE_MODE", "valid")
count = 0
lock = threading.Lock()


def send(value):
    with lock:
        print(json.dumps(value), flush=True)


for text in sys.stdin:
    query = json.loads(text)
    if "action" in query:
        send(query)
        continue
    count += 1
    if mode == "startup_hang":
        continue
    branch = count in (3, 4)
    if branch and mode == "exit":
        sys.exit(0)
    if branch and mode == "malformed":
        print("broken json", flush=True)
        continue
    if branch and mode == "hang":
        continue
    actual = bool(query["moves"]) and query["moves"][-1][1] == "H8"
    ownership = [0.0] * 81
    for point in (47, 56):  # C4, C3
        ownership[point] = -0.8 if actual else 0.8
    value = {
        "id": query["id"], "turnNumber": len(query["moves"]),
        "isDuringSearch": False, "rootInfo": {"scoreLead": -8.0 if actual else 1.0},
        "ownership": ownership,
        "moveInfos": [{"move": "D3", "scoreLead": 1.0,
                       "pv": ["D3", "C4", "D4"] if actual else ["D3", "H7", "E3"]}],
    }
    if branch and mode == "partial":
        value["isDuringSearch"] = True
    if branch and mode == "stale":
        threading.Timer(0.2, send, args=(value,)).start()
    else:
        send(value)
