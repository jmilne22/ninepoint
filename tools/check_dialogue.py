#!/usr/bin/env python3
"""Print every dialogue graph as a script a person can read.

    python3 tools/check_dialogue.py            # everyone
    python3 tools/check_dialogue.py kesh wren  # some

Nodes come out in the order a player meets them (breadth first from `start`,
then `post_match`, then the `taught` closes), with each branch's guard in
brackets. The point is to read the conversation rather than the JSON: a line
that makes no sense in the box makes no sense here either, and here you can
see the line before it.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DIALOGUE = os.path.join(HERE, "..", "data", "dialogue")


def targets(node):
    out = []
    if "goto" in node:
        out.append(node["goto"])
    for b in node.get("branches", []):
        if "goto" in b:
            out.append(b["goto"])
    for c in node.get("choices", []):
        if "goto" in c:
            out.append(c["goto"])
    return out


def guard(conds):
    if not conds:
        return "otherwise"
    return " and ".join(" ".join(str(x) for x in c) for c in conds)


def show(gid):
    with open(os.path.join(DIALOGUE, gid + ".json"), encoding="utf-8") as fh:
        nodes = json.load(fh)["nodes"]
    roots = [k for k in ("start", "post_match") if k in nodes]
    roots += sorted(k for k in nodes if k.startswith("taught"))
    seen, order, queue = set(), [], list(roots)
    while queue:
        k = queue.pop(0)
        if k in seen or k not in nodes:
            continue
        seen.add(k)
        order.append(k)
        queue.extend(targets(nodes[k]))
    print("=" * 72)
    print(gid.upper(), "--", len(nodes), "nodes")
    for k in order:
        n = nodes[k]
        head = "[%s]" % k
        if "actions" in n:
            head += "  {" + "; ".join(" ".join(str(x) for x in a) for a in n["actions"]) + "}"
        print()
        print(head)
        for b in n.get("branches", []):
            print("    (%s) -> %s" % (guard(b.get("if", [])), b.get("goto")))
        for line in n.get("text", []):
            print("    " + line)
        for c in n.get("choices", []):
            extra = ""
            if "if" in c:
                extra += "  (%s)" % guard(c["if"])
            if "exit" in c:
                e = c["exit"]
                extra += "  => " + e.get("type", "") + " " + str(e.get("profile", e.get("lesson", e.get("puzzle", ""))))
            elif "goto" in c:
                extra += "  -> " + c["goto"]
            print("    > " + c.get("text", "") + extra)
        if "goto" in n:
            print("    -> " + n["goto"])
    unreached = sorted(set(nodes) - seen)
    if unreached:
        print("\n  UNREACHABLE:", ", ".join(unreached))


def main(argv):
    ids = argv or sorted(f[:-5] for f in os.listdir(DIALOGUE) if f.endswith(".json"))
    for gid in ids:
        show(gid)


if __name__ == "__main__":
    main(sys.argv[1:])
