"""Checks every lesson and puzzle position against the actual rules.

Positions are the easiest thing in this project to get quietly wrong -- a group
that looks surrounded but has two liberties makes a lesson teach the opposite of
what it says. This mirrors src/go/go_board.gd closely enough to catch that.
"""
import glob
import json
import os
import sys

EMPTY, BLACK, WHITE = 0, 1, 2


LEGAL_CHARS = set("XO.")


def parse(rows):
    g = []
    for r in rows:
        g.append([BLACK if c == "X" else WHITE if c == "O" else EMPTY for c in r])
    return g


def stray_chars(rows):
    """Characters that are neither a stone nor an empty point.

    parse() silently reads anything it does not recognise as an empty point, so a
    typo in a board row -- a stray keystroke at the start of a line -- produced a
    valid, wrong position that every other check then passed.
    """
    bad = set()
    for r in rows:
        bad |= set(r) - LEGAL_CHARS
    return sorted(bad)


def neighbours(g, x, y):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= ny < len(g) and 0 <= nx < len(g[ny]):
            yield nx, ny


def chain(g, x, y):
    colour = g[y][x]
    seen, stack, libs = set(), [(x, y)], set()
    while stack:
        cx, cy = stack.pop()
        if (cx, cy) in seen:
            continue
        seen.add((cx, cy))
        for nx, ny in neighbours(g, cx, cy):
            if g[ny][nx] == EMPTY:
                libs.add((nx, ny))
            elif g[ny][nx] == colour:
                stack.append((nx, ny))
    return seen, libs


def play(g, x, y, colour):
    """Returns (legal, captured_count, new_grid)."""
    if g[y][x] != EMPTY:
        return False, 0, g
    ng = [row[:] for row in g]
    ng[y][x] = colour
    enemy = WHITE if colour == BLACK else BLACK
    captured = 0
    for nx, ny in neighbours(ng, x, y):
        if ng[ny][nx] == enemy:
            stones, libs = chain(ng, nx, ny)
            if not libs:
                for sx, sy in stones:
                    ng[sy][sx] = EMPTY
                captured += len(stones)
    _, own_libs = chain(ng, x, y)
    if not own_libs and captured == 0:
        return False, 0, g
    return True, captured, ng


def pocket_after(g, move, colour, at):
    """Size of the enclosed empty region containing `at`, after `move` is played,
    or -1 if that region is not sealed by `colour` alone.

    Deliberately regional rather than global: on a board with only one colour on
    it, whole-board scoring says that colour owns everything, which is true and
    useless for teaching that a corner is cheaper than the centre.
    """
    legal, _, ng = play(g, move[0], move[1], colour)
    if not legal:
        return -1
    ax, ay = at
    if ng[ay][ax] != EMPTY:
        return -1
    region, borders, stack = set(), set(), [(ax, ay)]
    while stack:
        cx, cy = stack.pop()
        if (cx, cy) in region:
            continue
        region.add((cx, cy))
        for nx, ny in neighbours(ng, cx, cy):
            if ng[ny][nx] == EMPTY:
                stack.append((nx, ny))
            else:
                borders.add(ng[ny][nx])
    if borders != {colour}:
        return -1
    return len(region)


def eyes_of(g, x, y):
    """Eye-like empty points belonging to the chain containing (x, y).

    An eye-like point here is an empty point whose orthogonal neighbours are all
    that colour. Good enough to prove a taught two-eye shape really has two, and
    deliberately not a life-and-death solver.
    """
    colour = g[y][x]
    stones, _ = chain(g, x, y)
    eyes = set()
    for sx, sy in stones:
        for nx, ny in neighbours(g, sx, sy):
            if g[ny][nx] != EMPTY:
                continue
            if all(g[by][bx] == colour for bx, by in neighbours(g, nx, ny)):
                eyes.add((nx, ny))
    return eyes


def after(g, move, colour):
    """The grid after `move`, or None if the move is illegal."""
    legal, _, ng = play(g, move[0], move[1], colour)
    return ng if legal else None


def check_lessons():
    problems = []
    for path in sorted(glob.glob("data/lessons/*.json")):
        d = json.load(open(path))
        size = d["size"]
        for i, step in enumerate(d["steps"]):
            where = "%s step %d" % (os.path.basename(path), i + 1)
            bad = stray_chars(step["board"])
            if bad:
                problems.append("%s: board contains %s, which is not a stone or a point"
                                % (where, "".join(repr(c) for c in bad)))
                continue
            g = parse(step["board"])
            if len(g) != size or any(len(r) != size for r in g):
                problems.append("%s: board is not %dx%d" % (where, size, size))
                continue
            colour = BLACK if step.get("to_move", "black") == "black" else WHITE
            accept = step.get("accept", "any_legal")
            pts = [tuple(p) for p in step.get("points", [])]

            # A step may open with the opponent's move -- that is how ko is
            # taught, since ko is a fact about history and not about a position.
            ko_point = None
            if "pre" in step:
                px, py = step["pre"]
                other = WHITE if colour == BLACK else BLACK
                before = [r[:] for r in g]
                legal, taken, g = play(g, px, py, other)
                if not legal:
                    problems.append("%s: pre-move %s is illegal" % (where, (px, py)))
                    continue
                # Simple ko: a one-stone capture by a stone left on one liberty.
                # Without this the checker has no ko rule at all and would call a
                # forbidden retake perfectly legal, which is the one thing a ko
                # lesson exists to demonstrate.
                if taken == 1:
                    _, libs = chain(g, px, py)
                    stones, _ = chain(g, px, py)
                    if len(stones) == 1 and len(libs) == 1:
                        for y2 in range(len(before)):
                            for x2 in range(len(before[y2])):
                                if before[y2][x2] != EMPTY and g[y2][x2] == EMPTY:
                                    ko_point = (x2, y2)

            if accept == "points":
                if not pts:
                    problems.append("%s: accept=points but no points listed" % where)
                for x, y in pts:
                    legal, cap, _ = play(g, x, y, colour)
                    if not legal:
                        problems.append("%s: accepted point %s is illegal" % (where, (x, y)))
                        continue
                    # A step that claims to enclose N points must actually do it.
                    # The first draft of the openings class claimed nine points
                    # from walls that enclosed nothing at all.
                    if "encloses" in step:
                        anchor = step.get("region_at")
                        if anchor is None:
                            problems.append("%s: encloses given without region_at" % where)
                            continue
                        got = pocket_after(g, (x, y), colour, tuple(anchor))
                        want = int(step["encloses"])
                        if got != want:
                            problems.append(
                                "%s: %s seals a pocket of %d points, not the %d claimed"
                                % (where, (x, y), got, want))

                    # A group told to run for its life must actually get out.
                    if "liberties_after" in step:
                        ng = after(g, (x, y), colour)
                        want = int(step["liberties_after"])
                        # Usually the chain you just played, but a ladder step is
                        # a claim about the stone being chased, not the chaser.
                        ax, ay = step.get("liberties_at", [x, y])
                        if ng is None:
                            problems.append("%s: %s is illegal" % (where, (x, y)))
                        elif ng[ay][ax] == EMPTY:
                            problems.append("%s: liberties_at %s is an empty point"
                                            % (where, (ax, ay)))
                        else:
                            _, libs = chain(ng, ax, ay)
                            if len(libs) != want:
                                problems.append(
                                    "%s: after %s the chain has %d liberties, not the %d claimed"
                                    % (where, (x, y), len(libs), want))

                    # A group told it is alive must actually have the eyes.
                    if "eyes_after" in step:
                        ng = after(g, (x, y), colour)
                        want = int(step["eyes_after"])
                        anchor = step.get("eyes_at", [x, y])
                        if ng is None:
                            problems.append("%s: %s is illegal" % (where, (x, y)))
                        elif ng[anchor[1]][anchor[0]] != colour:
                            problems.append("%s: eyes_at %s is not a %s stone"
                                            % (where, tuple(anchor), "black" if colour == BLACK else "white"))
                        else:
                            got = len(eyes_of(ng, anchor[0], anchor[1]))
                            if got != want:
                                problems.append(
                                    "%s: after %s that group has %d eyes, not the %d claimed"
                                    % (where, (x, y), got, want))

                    # A move told to connect two groups must leave them as one.
                    if "connects" in step:
                        ng = after(g, (x, y), colour)
                        ax, ay = step["connects"][0]
                        bx, by = step["connects"][1]
                        if ng is None:
                            problems.append("%s: %s is illegal" % (where, (x, y)))
                        elif ng[ay][ax] != colour or ng[by][bx] != colour:
                            problems.append("%s: connects endpoints are not both %s"
                                            % (where, "black" if colour == BLACK else "white"))
                        else:
                            stones, _ = chain(ng, ax, ay)
                            if (bx, by) not in stones:
                                problems.append(
                                    "%s: after %s those two groups are still separate"
                                    % (where, (x, y)))
            elif accept == "capture":
                capturing = [(x, y) for y in range(size) for x in range(size)
                             if play(g, x, y, colour)[1] > 0]
                if not capturing:
                    problems.append("%s: accept=capture but no move captures anything" % where)
                for tx, ty in [tuple(p) for p in step.get("target", [])]:
                    if g[ty][tx] == EMPTY:
                        problems.append("%s: target %s is an empty point" % (where, (tx, ty)))
                        continue
                    _, libs = chain(g, tx, ty)
                    if len(libs) != 1:
                        problems.append("%s: target group at %s has %d liberties, not 1"
                                        % (where, (tx, ty), len(libs)))
            elif accept == "illegal_attempt":
                for x, y in pts:
                    legal, _, _ = play(g, x, y, colour)
                    if ko_point == (x, y):
                        legal = False          # forbidden by ko, not by suicide
                    if legal:
                        problems.append("%s: %s is supposed to be illegal but is legal"
                                        % (where, (x, y)))
            else:
                any_legal = any(play(g, x, y, colour)[0]
                                for y in range(size) for x in range(size))
                if not any_legal:
                    problems.append("%s: no legal move exists" % where)
    return problems


def check_puzzles():
    problems = []
    for path in sorted(glob.glob("data/puzzles/*.json")):
        d = json.load(open(path))
        bad = stray_chars(d["board"])
        if bad:
            problems.append("%s: board contains %s, which is not a stone or a point"
                            % (path, "".join(repr(c) for c in bad)))
            continue
        g = parse(d["board"])
        colour = BLACK if d.get("to_move", "black") == "black" else WHITE
        # What the puzzle claims its answer achieves. Capture is the default and
        # was for a long time the only kind; a puzzle about living or running has
        # a correct answer that takes nothing at all, and saying so is what stops
        # this check either rejecting it or waving it through unverified.
        kind = d.get("kind", "capture")
        for x, y in [tuple(p) for p in d["solutions"]]:
            legal, cap, ng = play(g, x, y, colour)
            if not legal:
                problems.append("%s: solution %s illegal" % (path, (x, y)))
                continue
            if kind == "capture":
                if cap == 0:
                    problems.append("%s: solution %s captures nothing" % (path, (x, y)))
            elif kind == "live":
                anchor = d.get("alive_at", [x, y])
                if ng[anchor[1]][anchor[0]] != colour:
                    problems.append("%s: alive_at %s is not the solver's stone"
                                    % (path, tuple(anchor)))
                else:
                    eyes = len(eyes_of(ng, anchor[0], anchor[1]))
                    if eyes < 2:
                        problems.append("%s: after %s that group has %d eyes, not two"
                                        % (path, (x, y), eyes))
            elif kind == "escape":
                anchor = d.get("escape_at", [x, y])
                want = int(d.get("liberties", 3))
                _, libs = chain(ng, anchor[0], anchor[1])
                if len(libs) < want:
                    problems.append("%s: after %s the group has %d liberties, fewer than the %d claimed"
                                    % (path, (x, y), len(libs), want))
            else:
                problems.append("%s: unknown puzzle kind '%s'" % (path, kind))
    return problems


if __name__ == "__main__":
    found = check_lessons() + check_puzzles()
    for p in found:
        print("PROBLEM:", p)
    print("%d problems" % len(found))
    sys.exit(1 if found else 0)
