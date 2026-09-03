"""Renders the 5x7 pixel font to a PNG page plus a BMFont descriptor.

Godot 4 imports BMFont .fnt files as FontFile, which is the least fiddly way to
get a genuine bitmap font into the engine. Glyphs are white with alpha so the
theme's font_color tints them.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from png import Img
from font5x7 import GLYPHS, CELL_H, BASELINE, advance, trimmed

COLS = 16
CELL_W = 6
WHITE = (255, 255, 255, 255)


def build(out_dir, name="ninepoint_font"):
    os.makedirs(out_dir, exist_ok=True)
    chars = sorted(GLYPHS.keys(), key=lambda c: ord(c))
    rows = (len(chars) + COLS - 1) // COLS
    atlas = Img(COLS * CELL_W, rows * CELL_H)

    records = []
    for i, ch in enumerate(chars):
        cx = (i % COLS) * CELL_W
        cy = (i // COLS) * CELL_H
        art = trimmed(ch)
        w = len(art[0])
        for y, row in enumerate(art):
            for x, c in enumerate(row):
                if c == "#":
                    atlas.set(cx + x, cy + y, WHITE)
        records.append({
            "id": ord(ch), "x": cx, "y": cy, "w": w, "h": CELL_H,
            "xadvance": advance(ch),
        })

    png_path = os.path.join(out_dir, name + ".png")
    atlas.save(png_path)

    lines = [
        'info face="Ninepoint" size=%d bold=0 italic=0 charset="" unicode=1'
        ' stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0' % CELL_H,
        'common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0'
        % (CELL_H + 2, BASELINE, atlas.w, atlas.h),
        'page id=0 file="%s.png"' % name,
        "chars count=%d" % len(records),
    ]
    for r in records:
        lines.append(
            "char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0"
            " xadvance=%d page=0 chnl=15"
            % (r["id"], r["x"], r["y"], r["w"], r["h"], r["xadvance"]))
    fnt_path = os.path.join(out_dir, name + ".fnt")
    open(fnt_path, "w").write("\n".join(lines) + "\n")
    return len(records), atlas.w, atlas.h


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    print(build(os.path.join(here, "..", "art", "ui")))
