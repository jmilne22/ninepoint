"""The title illustration: 384x216, an evening board on a Steenbeek rooftop."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from png import Img, Rand
from palette import rgb, mix

W, H = 384, 216


def build(out_dir):
    im = Img(W, H)
    r = Rand(20260903)

    # --- sky: dusk, many narrow bands with a dithered seam between each
    ramp = ["ink1", "plum0", "plum0", "plum1", "plum1", "rust0", "rust0",
            "rust1", "rust1", "rust2", "gold0", "gold1", "gold2"]
    top, bottom = 0, 140
    step = (bottom - top) / float(len(ramp))
    for i, col in enumerate(ramp):
        y0 = int(top + i * step)
        y1 = int(top + (i + 1) * step)
        im.rect(0, y0, W, y1 - y0, rgb(col))
    for i in range(1, len(ramp)):
        y = int(top + i * step)
        prev = rgb(ramp[i - 1])
        for x in range(W):
            if (x // 2 + y) % 2 == 0:
                im.set(x, y, prev)
                im.set(x, y + 1, prev)
        for x in range(0, W, 3):
            im.set(x, y - 1, rgb(ramp[i]))

    # stars, only where the sky is still dark
    for _ in range(60):
        x, y = r.rng(0, W - 1), r.rng(2, 50)
        im.set(x, y, rgb("paper1") if r.chance(3) else rgb("ink3"))

    # --- town silhouette, two depths
    def skyline(y_base, colour, seed, min_h, max_h):
        rr = Rand(seed)
        x = -4
        while x < W:
            w = rr.rng(14, 34)
            h = rr.rng(min_h, max_h)
            im.rect(x, y_base - h, w, h + 40, colour)
            for k in range(6):
                im.rect(x - 2 + k, y_base - h - 6 + k, w + 4 - 2 * k, 1, colour)
            if rr.chance(2):
                im.rect(x + w // 2, y_base - h - 12, 4, 8, colour)
            x += w + rr.rng(0, 3)

    skyline(150, rgb("plum0"), 7, 12, 34)
    skyline(166, rgb("ink1"), 11, 8, 26)

    for _ in range(50):
        x, y = r.rng(4, W - 8), r.rng(134, 172)
        if im.get(x, y)[:3] == rgb("ink1")[:3]:
            im.rect(x, y, 3, 2, rgb("gold2") if r.chance(2) else rgb("gold1"))

    # --- foreground terrace
    im.rect(0, 172, W, H - 172, rgb("ink1"))
    im.rect(0, 172, W, 2, rgb("ink2"))
    for x in range(0, W, 26):
        im.vline(x, 174, H - 174, rgb("ink0"))

    # --- the board, in true perspective: a trapezoid receding from the viewer.
    # It deliberately sits on the right half: title_screen.gd reserves the
    # left third for the poster card, rather than laying lettering on skyline
    # noise and asking a player to read through it.
    cx = 260
    rows_y, rows_hw = [], []
    y, gap = 116.0, 5.0
    for i in range(9):
        rows_y.append(int(y))
        rows_hw.append(52 + i * 7)
        y += gap
        gap += 1.35

    # the wooden slab, one pixel wider than the grid all round
    for i in range(len(rows_y) - 1):
        y0, y1 = rows_y[i], rows_y[i + 1]
        for yy in range(y0, y1):
            t = (yy - rows_y[0]) / float(rows_y[-1] - rows_y[0])
            hw = rows_hw[0] + (rows_hw[-1] - rows_hw[0]) * t
            im.rect(int(cx - hw - 7), yy, int(2 * hw + 14), 1, rgb("board1"))
    im.rect(int(cx - rows_hw[0] - 7), rows_y[0] - 6, int(2 * rows_hw[0] + 14), 6, rgb("board2"))
    for yy in range(rows_y[-1], rows_y[-1] + 12):
        t = 1.0 + (yy - rows_y[-1]) / 40.0
        hw = rows_hw[-1] * t
        im.rect(int(cx - hw - 7), yy, int(2 * hw + 14), 1, rgb("board0"))

    def grid_point(col, row):
        hw = rows_hw[row]
        return int(cx - hw + (col / 8.0) * 2 * hw), rows_y[row]

    for row in range(9):
        x0, yy = grid_point(0, row)
        x1, _ = grid_point(8, row)
        im.hline(x0, yy, x1 - x0 + 1, rgb("line"))
    for col in range(9):
        for row in range(8):
            xa, ya = grid_point(col, row)
            xb, yb = grid_point(col, row + 1)
            for yy in range(ya, yb + 1):
                t = (yy - ya) / float(max(1, yb - ya))
                im.set(int(xa + (xb - xa) * t), yy, rgb("line"))

    def stone(col, row, black):
        xx, yy = grid_point(col, row)
        rad = 3.0 + row * 0.42
        if black:
            im.disc(xx, yy, rad, rgb("stoneB0"))
            im.disc(xx - rad * 0.35, yy - rad * 0.4, rad * 0.42, rgb("stoneB1"))
        else:
            im.disc(xx, yy, rad, rgb("stoneW0"))
            im.disc(xx - rad * 0.25, yy - rad * 0.3, rad * 0.62, rgb("stoneW1"))

    for c, ro, b in ((2, 1, True), (5, 1, False), (3, 3, True), (6, 3, False),
                     (2, 4, True), (4, 5, False), (6, 5, True), (3, 6, False),
                     (5, 7, True), (1, 6, False), (7, 7, False)):
        stone(c, ro, b)

    # a lamp at the right, throwing the warm light
    im.rect(330, 96, 4, 74, rgb("ink0"))
    im.rect(322, 84, 20, 12, rgb("ink0"))
    im.rect(324, 86, 16, 8, rgb("gold2"))
    im.rect(326, 88, 12, 4, rgb("gold3"))
    for i in range(30):
        a = 60 - i * 2
        im.rect(316 - i, 96 + i, 48 + i * 2, 1, (rgb("gold3")[0], rgb("gold3")[1], rgb("gold3")[2], max(0, a // 6)))

    # two cups on the terrace, because someone is about to sit down
    for cxx, cyy, body, lip in ((28, 188, "paper1", "paper0"), (46, 196, "paper2", "paper1")):
        im.rect(cxx, cyy, 11, 9, rgb(body))
        im.rect(cxx, cyy, 11, 2, rgb(lip))
        im.rect(cxx + 11, cyy + 2, 3, 4, rgb(body))
        im.hline(cxx, cyy + 9, 11, rgb("ink0"))
        im.rect(cxx + 2, cyy - 3, 2, 3, (rgb("paper0")[0], rgb("paper0")[1], rgb("paper0")[2], 70))

    # vignette
    for x in range(W):
        for y in range(H):
            d = max(abs(x - W / 2) / (W / 2), abs(y - H / 2) / (H / 2))
            if d > 0.86:
                a = int((d - 0.86) * 300)
                im.set(x, y, (20, 18, 26, min(150, a)))

    os.makedirs(out_dir, exist_ok=True)
    im.save(os.path.join(out_dir, "title.png"))
    return W, H


if __name__ == "__main__":
    print(build(os.path.join(os.path.dirname(__file__), "..", "art", "title")))
