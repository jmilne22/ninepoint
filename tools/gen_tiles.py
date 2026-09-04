"""Generates art/tiles/town_tileset.png -- one coherent 16x16 atlas, 16 per row.

Light comes from the top-left in every tile. Three-value shading, no gradients.
Emits a manifest so the TileSet resource and the map loader agree on indices.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from png import Img, Rand
from palette import rgb

TS = 16
TILES = []


def tile(name):
    def deco(fn):
        TILES.append((name, fn))
        return fn
    return deco


def speckle(im, colors, seed, density=6, area=(0, 0, TS, TS)):
    r = Rand(seed)
    x0, y0, w, h = area
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if r.next() % density == 0:
                im.set(x, y, r.pick(colors))


def _mini_grid(im, x, y, w, h, spacing=3):
    """A legible miniature go board: a few widely spaced lines, not a mesh."""
    for gx in range(x + spacing, x + w - 1, spacing):
        im.vline(gx, y + 2, h - 4, rgb("line"))
    for gy in range(y + spacing, y + h - 1, spacing):
        im.hline(x + 2, gy, w - 4, rgb("line"))


# ---------------------------------------------------------------- row 0: ground
@tile("grass_a")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass1"))
    speckle(im, [rgb("grass2"), rgb("grass0")], s, 5)


@tile("grass_b")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass1"))
    speckle(im, [rgb("grass2"), rgb("grass0")], s + 1, 6)
    for bx, by in ((3, 5), (10, 9), (6, 12)):
        im.vline(bx, by, 3, rgb("grass2"))
        im.set(bx + 1, by, rgb("grass3"))


@tile("grass_c")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass1"))
    speckle(im, [rgb("grass2"), rgb("grass0")], s + 2, 7)
    for px, py in ((4, 4), (11, 6), (7, 11)):
        im.rect(px, py, 2, 2, rgb("path1"))
        im.set(px, py, rgb("path2"))


@tile("grass_flowers")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass1"))
    speckle(im, [rgb("grass2")], s + 3, 5)
    for fx, fy, c in ((3, 4, "gold2"), (9, 7, "paper0"), (12, 12, "rust3"), (5, 11, "gold3")):
        im.set(fx, fy, rgb(c))
        im.set(fx, fy + 1, rgb("grass0"))


def _cobble(im, seed, base="path1"):
    im.rect(0, 0, TS, TS, rgb(base))
    r = Rand(seed)
    for row in range(4):
        y = row * 4
        off = 0 if row % 2 == 0 else 2
        im.hline(0, y, TS, rgb("path0"))
        for x in range(off, TS + 4, 4):
            im.vline(x % TS if x < TS else x - TS, y, 4, rgb("path0"))
        for x in range(TS):
            if r.next() % 5 == 0:
                im.set(x, y + 1 + r.next() % 2, rgb("path2"))


@tile("cobble_a")
def _(im, s):
    _cobble(im, s)


@tile("cobble_b")
def _(im, s):
    _cobble(im, s + 17)
    im.set(4, 6, rgb("path0"))
    im.set(11, 13, rgb("path0"))


@tile("pavement")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    speckle(im, [rgb("path1"), rgb("path3")], s, 6)
    im.hline(0, 8, TS, rgb("path1"))
    im.vline(8, 0, 8, rgb("path1"))
    im.vline(4, 8, 8, rgb("path1"))


@tile("gravel")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path1"))
    speckle(im, [rgb("path0"), rgb("path2"), rgb("path3")], s, 3)


@tile("dirt")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("wood2"))
    speckle(im, [rgb("wood1"), rgb("path1")], s, 5)


@tile("kerb")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    speckle(im, [rgb("path1")], s, 7)
    im.hline(0, 12, TS, rgb("path3"))
    im.rect(0, 13, TS, 3, rgb("path0"))


def _water(im, s, frame=0):
    """Frame 0 is exactly what shipped; later frames slide the highlights.

    TileAnimator cycles these by name, and offsets each cell's phase by (x+y) --
    water where every tile ripples in step reads as a screensaver.
    """
    im.rect(0, 0, TS, TS, rgb("blue1"))
    r = Rand(s)
    for y in range(TS):
        for x in range(TS):
            if r.next() % 9 == 0:
                im.set(x, y, rgb("blue0"))
    for wy in (3, 9, 13):
        im.hline(2 + ((wy % 3) + frame * 2) % 5, wy, 5, rgb("blue2"))


@tile("water")
def _(im, s):
    _water(im, s, 0)


@tile("water_f1")
def _(im, s):
    _water(im, s, 1)


@tile("water_f2")
def _(im, s):
    _water(im, s, 2)


@tile("water_edge")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("blue1"))
    speckle(im, [rgb("blue0")], s, 9)
    im.rect(0, 0, TS,3, rgb("path1"))
    im.hline(0, 3, TS, rgb("path0"))
    im.hline(0, 4, TS, rgb("blue2"))


@tile("plank")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("wood2"))
    for y in (0, 5, 10, 15):
        im.hline(0, y, TS, rgb("wood1"))
    speckle(im, [rgb("wood3"), rgb("wood1")], s, 8)


@tile("step")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    im.rect(0, 0, TS, 6, rgb("path3"))
    im.hline(0, 6, TS, rgb("path0"))
    im.hline(0, 12, TS, rgb("path0"))


@tile("drain")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path1"))
    im.rect(3, 5, 10, 7, rgb("ink2"))
    for x in range(4, 12, 2):
        im.vline(x, 6, 5, rgb("ink0"))
    im.frame(3, 5, 10, 7, rgb("path0"))


@tile("void")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("ink0"))


# ------------------------------------------------------------- row 1: buildings
def _plaster(im, seed, base="paper1", hi="paper0", lo="paper2"):
    im.rect(0, 0, TS, TS, rgb(base))
    speckle(im, [rgb(hi), rgb(lo)], seed, 7)


@tile("wall_plaster")
def _(im, s):
    _plaster(im, s)


@tile("wall_plaster_win")
def _(im, s):
    _plaster(im, s)
    im.rect(3, 3, 10, 9, rgb("wood1"))
    im.rect(4, 4, 8, 7, rgb("blue1"))
    im.rect(4, 4, 4, 3, rgb("blue2"))
    im.vline(8, 4, 7, rgb("wood1"))
    im.hline(4, 7, 8, rgb("wood1"))
    im.hline(3, 12, 10, rgb("wood0"))


def _brick(im, seed, base="brick1", mortar="brick0", hi="brick2"):
    """Wet Verhaven brick. Courses of four, staggered, mortar in shadow."""
    im.rect(0, 0, TS, TS, rgb(base))
    r = Rand(seed)
    for row in range(4):
        y = row * 4
        im.hline(0, y, TS, rgb(mortar))
        off = 0 if row % 2 == 0 else 4
        for x in range(off, TS, 8):
            im.vline(x, y, 4, rgb(mortar))
        for x in range(TS):
            if r.next() % 6 == 0:
                im.set(x, y + 2, rgb(hi))


@tile("wall_brick")
def _(im, s):
    _brick(im, s)


@tile("wall_base")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path0"))
    speckle(im, [rgb("path1"), rgb("ink2")], s, 5)
    im.hline(0, 0, TS, rgb("ink2"))


@tile("door_wood")
def _(im, s):
    _plaster(im, s)
    im.rect(2, 1, 12, 15, rgb("wood0"))
    im.rect(3, 2, 10, 14, rgb("wood1"))
    im.rect(4, 3, 8, 5, rgb("wood2"))
    im.rect(4, 9, 8, 6, rgb("wood2"))
    im.set(11, 9, rgb("gold2"))
    im.set(11, 10, rgb("gold1"))


@tile("door_glass")
def _(im, s):
    _plaster(im, s)
    im.rect(2, 1, 12, 15, rgb("teal0"))
    im.rect(3, 2, 10, 14, rgb("teal1"))
    im.rect(4, 3, 8, 8, rgb("blue2"))
    im.rect(4, 3, 4, 4, rgb("blue3"))
    im.vline(8, 3, 8, rgb("teal0"))
    im.set(11, 10, rgb("gold2"))


@tile("door_club")
def _(im, s):
    _plaster(im, s)
    im.rect(2, 1, 12, 15, rgb("plum0"))
    im.rect(3, 2, 10, 14, rgb("plum1"))
    im.rect(5, 4, 6, 6, rgb("board1"))
    im.frame(5, 4, 6, 6, rgb("line"))
    for i in range(1, 6, 2):        # a tiny go board in the door glass
        im.vline(5 + i, 5, 4, rgb("line"))
        im.hline(6, 4 + i, 4, rgb("line"))
    im.set(11, 10, rgb("gold2"))


@tile("roof_slate")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("ink2"))
    r = Rand(s)
    for row in range(4):
        y = row * 4
        off = 0 if row % 2 == 0 else 3
        im.hline(0, y, TS, rgb("ink1"))
        for x in range(off, TS, 6):
            im.vline(x, y, 4, rgb("ink1"))
        for x in range(TS):
            if r.next() % 7 == 0:
                im.set(x, y + 1, rgb("ink3"))


@tile("roof_rust")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("rust1"))
    r = Rand(s)
    for row in range(4):
        y = row * 4
        im.hline(0, y, TS, rgb("rust0"))
        for x in range(0 if row % 2 else 3, TS, 6):
            im.vline(x, y, 4, rgb("rust0"))
        for x in range(TS):
            if r.next() % 7 == 0:
                im.set(x, y + 1, rgb("rust2"))


@tile("roof_eave")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("ink2"))
    im.hline(0, 0, TS, rgb("ink1"))
    im.rect(0, 10, TS, 3, rgb("ink1"))
    im.hline(0, 13, TS, rgb("ink0"))
    im.rect(0, 14, TS, 2, rgb("wood0"))


@tile("roof_ridge")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("ink2"))
    im.rect(0, 0, TS, 4, rgb("ink3"))
    im.hline(0, 4, TS, rgb("ink1"))
    for x in range(0, TS, 6):
        im.vline(x, 5, 11, rgb("ink1"))


@tile("chimney")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("ink2"))
    im.rect(4, 1, 8, 14, rgb("rust1"))
    im.rect(3, 0, 10, 3, rgb("rust0"))
    im.vline(4, 3, 12, rgb("rust2"))
    im.rect(6, 0, 2, 2, rgb("ink0"))
    im.rect(9, 0, 2, 2, rgb("ink0"))


@tile("awning")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("paper1"))
    for x in range(TS):
        c = "teal1" if (x // 3) % 2 == 0 else "paper0"
        im.vline(x, 2, 9, rgb(c))
    im.hline(0, 1, TS, rgb("teal0"))
    im.hline(0, 11, TS, rgb("teal0"))
    for x in range(1, TS, 3):
        im.set(x, 12, rgb("teal0"))


@tile("sign_hanging")
def _(im, s):
    _plaster(im, s)
    im.rect(1, 0, 14, 2, rgb("ink1"))
    im.rect(2, 2, 12, 9, rgb("wood1"))
    im.frame(2, 2, 12, 9, rgb("wood0"))
    im.rect(4, 4, 8, 5, rgb("gold2"))
    im.hline(4, 5, 8, rgb("gold0"))
    im.hline(4, 7, 6, rgb("gold0"))


@tile("lamp_post")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path1"))
    speckle(im, [rgb("path0")], s, 8)
    im.rect(7, 4, 2, 12, rgb("ink1"))
    im.rect(5, 1, 6, 4, rgb("ink2"))
    im.rect(6, 2, 4, 2, rgb("gold2"))
    im.set(6, 2, rgb("gold3"))
    im.rect(5, 14, 6, 2, rgb("ink1"))


@tile("wall_corner")
def _(im, s):
    _plaster(im, s)
    im.rect(0, 0, 3, TS, rgb("paper2"))
    im.vline(0, 0, TS, rgb("ink2"))


# ------------------------------------------------------------- row 2: props
@tile("fence_h")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass1"))
    speckle(im, [rgb("grass2")], s, 6)
    im.rect(0, 5, TS, 2, rgb("wood2"))
    im.rect(0, 10, TS, 2, rgb("wood2"))
    im.hline(0, 7, TS, rgb("wood1"))
    im.hline(0, 12, TS, rgb("wood1"))


@tile("fence_post")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass1"))
    speckle(im, [rgb("grass2")], s, 6)
    im.rect(0, 5, TS, 2, rgb("wood2"))
    im.rect(0, 10, TS, 2, rgb("wood2"))
    im.rect(6, 2, 4, 13, rgb("wood2"))
    im.vline(6, 2, 13, rgb("wood3"))
    im.vline(9, 2, 13, rgb("wood0"))
    im.hline(6, 2, 4, rgb("wood3"))


@tile("hedge")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass0"))
    r = Rand(s)
    for y in range(TS):
        for x in range(TS):
            n = r.next() % 8
            if n == 0:
                im.set(x, y, rgb("grass2"))
            elif n == 1:
                im.set(x, y, rgb("grass1"))
    im.hline(0, 0, TS, rgb("grass2"))
    im.hline(0, 15, TS, rgb("ink1"))


def _canopy(im, seed, quad):
    im.rect(0, 0, TS, TS, rgb("grass0"))
    r = Rand(seed)
    for y in range(TS):
        for x in range(TS):
            n = r.next() % 7
            if n == 0:
                im.set(x, y, rgb("grass1"))
            elif n == 1:
                im.set(x, y, rgb("grass2"))
    if quad in ("tl", "tr"):
        im.hline(0, 0, TS, rgb("grass1"))
    if quad == "tl":
        im.disc(5, 5, 4, rgb("grass2"))
        im.disc(4, 4, 2, rgb("grass3"))
    if quad in ("bl", "br"):
        im.hline(0, 15, TS, rgb("ink1"))


@tile("tree_tl")
def _(im, s):
    _canopy(im, s, "tl")


@tile("tree_tr")
def _(im, s):
    _canopy(im, s + 5, "tr")


@tile("tree_bl")
def _(im, s):
    _canopy(im, s + 9, "bl")
    im.rect(11, 8, 5, 8, rgb("wood1"))
    im.vline(11, 8, 8, rgb("wood2"))


@tile("tree_br")
def _(im, s):
    _canopy(im, s + 13, "br")
    im.rect(0, 8, 4, 8, rgb("wood1"))
    im.vline(3, 8, 8, rgb("wood0"))


@tile("bush")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass1"))
    speckle(im, [rgb("grass2")], s, 6)
    im.disc(8, 9, 6, rgb("grass0"))
    r = Rand(s + 2)
    for y in range(3, 16):
        for x in range(1, 15):
            if im.get(x, y)[:3] == rgb("grass0")[:3] and r.next() % 5 == 0:
                im.set(x, y, rgb("grass1"))
    im.disc(6, 7, 3, rgb("grass2"))


@tile("bench")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    speckle(im, [rgb("path1")], s, 8)
    im.rect(1, 3, 14, 3, rgb("wood2"))
    im.hline(1, 3, 14, rgb("wood3"))
    im.rect(1, 7, 14, 3, rgb("wood2"))
    im.hline(1, 9, 14, rgb("wood0"))
    im.rect(2, 10, 2, 4, rgb("ink2"))
    im.rect(12, 10, 2, 4, rgb("ink2"))


@tile("planter")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    im.rect(2, 6, 12, 9, rgb("wood1"))
    im.hline(2, 6, 12, rgb("wood2"))
    im.rect(3, 1, 10, 6, rgb("grass0"))
    for fx, fy, c in ((4, 2, "rust2"), (8, 1, "gold2"), (11, 3, "paper0")):
        im.set(fx, fy, rgb(c))
    im.hline(2, 14, 12, rgb("wood0"))


@tile("stone_table")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass1"))
    speckle(im, [rgb("grass2")], s, 7)
    im.rect(1, 2, 14, 10, rgb("path1"))
    im.frame(1, 2, 14, 10, rgb("path0"))
    im.rect(3, 4, 10, 6, rgb("board1"))
    for i in range(1, 6, 2):
        im.vline(3 + i * 2, 4, 6, rgb("line"))
    for i in range(1, 3):
        im.hline(3, 4 + i * 2, 10, rgb("line"))
    im.rect(5, 12, 6, 3, rgb("path0"))


@tile("noticeboard")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    im.rect(1, 1, 14, 11, rgb("wood1"))
    im.frame(1, 1, 14, 11, rgb("wood0"))
    im.rect(3, 3, 4, 4, rgb("paper0"))
    im.rect(9, 3, 4, 3, rgb("paper1"))
    im.rect(4, 8, 5, 3, rgb("gold3"))
    im.rect(3, 12, 2, 4, rgb("wood0"))
    im.rect(11, 12, 2, 4, rgb("wood0"))


@tile("post_box")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    im.rect(4, 3, 8, 12, rgb("rust1"))
    im.vline(4, 3, 12, rgb("rust2"))
    im.vline(11, 3, 12, rgb("rust0"))
    im.rect(4, 2, 8, 2, rgb("rust0"))
    im.rect(6, 6, 4, 2, rgb("ink0"))


@tile("barrel")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    im.rect(3, 2, 10, 13, rgb("wood1"))
    im.vline(3, 2, 13, rgb("wood2"))
    im.vline(12, 2, 13, rgb("wood0"))
    im.hline(3, 5, 10, rgb("ink2"))
    im.hline(3, 11, 10, rgb("ink2"))
    im.rect(4, 1, 8, 2, rgb("wood2"))


@tile("crate")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    im.rect(2, 3, 12, 12, rgb("wood2"))
    im.frame(2, 3, 12, 12, rgb("wood0"))
    im.hline(2, 8, 12, rgb("wood1"))
    im.vline(8, 3, 12, rgb("wood1"))


@tile("flowerbed")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("wood2"))
    speckle(im, [rgb("wood1")], s, 4)
    r = Rand(s + 4)
    for i in range(10):
        x, y = r.rng(1, 14), r.rng(1, 14)
        im.set(x, y, r.pick([rgb("rust2"), rgb("gold2"), rgb("paper0"), rgb("plum2")]))
        im.set(x, y + 1, rgb("grass0"))


# ------------------------------------------------------------- row 3: interior
def _boards(im, seed, base="wood2", line="wood1", hi="wood3"):
    im.rect(0, 0, TS, TS, rgb(base))
    for y in (0, 8):
        im.hline(0, y, TS, rgb(line))
    speckle(im, [rgb(hi), rgb(line)], seed, 9)


@tile("floor_wood_a")
def _(im, s):
    _boards(im, s)


@tile("floor_wood_b")
def _(im, s):
    _boards(im, s + 3)
    im.vline(5, 0, 8, rgb("wood1"))
    im.vline(11, 8, 8, rgb("wood1"))


@tile("floor_mat")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("grass3"))
    for y in range(TS):
        for x in range(TS):
            if (x + y) % 4 == 0:
                im.set(x, y, rgb("grass2"))
    im.frame(0, 0, TS, TS, rgb("grass2"))


@tile("rug")
def _(im, s):
    # Muted: the club floor should sit behind the people, not shout at them.
    im.rect(0, 0, TS, TS, rgb("plum0"))
    speckle(im, [rgb("plum1"), rgb("ink1")], s, 6)
    im.frame(0, 0, TS, TS, rgb("ink1"))
    im.frame(3, 3, 10, 10, rgb("gold0"))
    im.rect(7, 7, 2, 2, rgb("plum1"))


@tile("wall_int")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("paper1"))
    speckle(im, [rgb("paper0"), rgb("paper2")], s, 9)
    im.hline(0, 0, TS, rgb("paper2"))


@tile("wall_int_base")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("paper1"))
    speckle(im, [rgb("paper0")], s, 9)
    im.rect(0, 10, TS, 4, rgb("wood1"))
    im.hline(0, 10, TS, rgb("wood2"))
    im.rect(0, 14, TS, 2, rgb("wood0"))


@tile("wall_int_win")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("paper1"))
    speckle(im, [rgb("paper0")], s, 9)
    im.rect(2, 2, 12, 10, rgb("wood1"))
    im.rect(3, 3, 10, 8, rgb("blue2"))
    im.rect(3, 3, 5, 4, rgb("blue3"))
    im.vline(8, 3, 8, rgb("wood1"))
    im.hline(3, 7, 10, rgb("wood1"))


@tile("shelf_books")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("paper1"))
    im.rect(0, 1, TS, 14, rgb("wood1"))
    im.hline(0, 1, TS, rgb("wood2"))
    r = Rand(s)
    for shelf_y in (2, 9):
        x = 1
        while x < 15:
            w = r.rng(1, 2)
            col = r.pick([rgb("rust1"), rgb("teal1"), rgb("plum1"), rgb("gold1"), rgb("blue1")])
            im.rect(x, shelf_y, w, 6, col)
            im.set(x, shelf_y, rgb("paper0"))
            x += w + 1
        im.hline(0, shelf_y + 6, TS, rgb("wood0"))


@tile("counter")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("wood2"))
    im.rect(0, 0, TS, 3, rgb("wood3"))
    im.hline(0, 3, TS, rgb("wood0"))
    speckle(im, [rgb("wood1")], s, 10, (0, 4, TS, 12))
    im.hline(0, 15, TS, rgb("wood0"))


## Stones in the order they go down. TileAnimator walks the frames slowly, so
## a table in the corner of De Ketel is a game getting longer while you talk --
## which, paired with the stone_place emitter in Soundscape, is the cheapest
## "somebody is playing over there" in the game.
_TABLE_STONES = [
    (6, 5, "B"), (9, 9, "W"),
    (9, 5, "B"), (5, 9, "W"),
    (7, 7, "B"), (11, 7, "W"),
]


def _stones(im, upto):
    for x, y, col in _TABLE_STONES[:upto]:
        dark = col == "B"
        im.disc(x, y, 1.7, rgb("stoneB0" if dark else "stoneW0"))
        im.set(x - 1 if dark else x, y - 1, rgb("stoneB1" if dark else "stoneW1"))


def _go_table(im, s, frame=0):
    im.rect(0, 0, TS, TS, rgb("wood2"))
    im.rect(1, 1, 14, 13, rgb("board1"))
    im.frame(1, 1, 14, 13, rgb("board0"))
    _mini_grid(im, 1, 1, 14, 13)
    _stones(im, 2 + frame * 2)
    im.hline(0, 15, TS, rgb("wood0"))


@tile("go_table")
def _(im, s):
    _go_table(im, s, 0)


@tile("go_table_f1")
def _(im, s):
    _go_table(im, s, 1)


@tile("go_table_f2")
def _(im, s):
    _go_table(im, s, 2)


@tile("go_table_empty")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("wood2"))
    im.rect(1, 1, 14, 13, rgb("board1"))
    im.frame(1, 1, 14, 13, rgb("board0"))
    _mini_grid(im, 1, 1, 14, 13)
    im.hline(0, 15, TS, rgb("wood0"))


@tile("chair")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("wood2"))
    speckle(im, [rgb("wood1")], s, 10)
    im.rect(3, 2, 10, 3, rgb("wood1"))
    im.rect(3, 6, 10, 5, rgb("wood3"))
    im.hline(3, 10, 10, rgb("wood0"))
    im.rect(4, 11, 2, 4, rgb("wood1"))
    im.rect(10, 11, 2, 4, rgb("wood1"))


def _kifu(im, s, frame=0):
    """The demonstration board. Somebody is replaying a game on it."""
    im.rect(0, 0, TS, TS, rgb("paper1"))
    im.rect(1, 1, 14, 12, rgb("board2"))
    im.frame(1, 1, 14, 12, rgb("wood0"))
    _mini_grid(im, 1, 1, 14, 12)
    im.disc(7, 4, 1.7, rgb("stoneB0"))
    im.disc(10, 8, 1.7, rgb("stoneW0"))
    if frame >= 1:
        im.disc(4, 8, 1.7, rgb("stoneB0"))
    if frame >= 2:
        im.disc(10, 4, 1.7, rgb("stoneW0"))


@tile("kifu_board")
def _(im, s):
    _kifu(im, s, 0)


@tile("kifu_board_f1")
def _(im, s):
    _kifu(im, s, 1)


@tile("kifu_board_f2")
def _(im, s):
    _kifu(im, s, 2)


@tile("plant_int")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("wood2"))
    speckle(im, [rgb("wood1")], s, 10)
    im.rect(5, 10, 6, 5, rgb("rust1"))
    im.hline(5, 10, 6, rgb("rust2"))
    im.disc(8, 6, 4, rgb("grass0"))
    im.disc(6, 4, 2, rgb("grass1"))
    im.set(9, 3, rgb("grass2"))


@tile("kettle_table")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("wood2"))
    im.rect(1, 3, 14, 10, rgb("wood3"))
    im.hline(1, 3, 14, rgb("paper1"))
    im.rect(4, 4, 5, 5, rgb("ink3"))
    im.rect(5, 3, 3, 2, rgb("ink2"))
    im.set(9, 6, rgb("ink3"))
    im.rect(10, 7, 3, 3, rgb("paper0"))
    im.hline(1, 13, 14, rgb("wood0"))


@tile("door_int")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("paper1"))
    im.rect(2, 0, 12, 16, rgb("wood0"))
    im.rect(3, 1, 10, 15, rgb("wood1"))
    im.rect(4, 2, 8, 6, rgb("wood2"))
    im.rect(4, 9, 8, 6, rgb("wood2"))
    im.set(11, 9, rgb("gold2"))


# ---------------------------------------------------------------------- build
# ------------------------------------------------------------- row 4: the city
# Verhaven: brick, tram rails, wet asphalt, and one cold neon tube. Same light
# from the top-left, same three values. The board stays the brightest thing.

def _asphalt(im, seed, base="asphalt1"):
    im.rect(0, 0, TS, TS, rgb(base))
    speckle(im, [rgb("asphalt0"), rgb("asphalt2")], seed, 4)


@tile("asphalt")
def _(im, s):
    _asphalt(im, s)


def _puddle(im, s, frame=0):
    _asphalt(im, s)
    im.disc(6, 9, 4, rgb("blue0"))
    im.disc(6, 9, 3, rgb("blue1"))
    # the sky, upside down in the road: the only reason a puddle reads as one
    if frame == 0:
        im.hline(4, 7, 4, rgb("blue2"))
        im.set(9, 11, rgb("blue2"))
    else:
        # something landed in it
        im.hline(5, 8, 3, rgb("blue2"))
        im.set(4, 10, rgb("blue2"))
        im.set(8, 7, rgb("blue2"))


@tile("puddle")
def _(im, s):
    _puddle(im, s, 0)


@tile("puddle_f1")
def _(im, s):
    _puddle(im, s, 1)


def _rails(im, seed, vertical=False):
    _asphalt(im, seed)
    for a in (5, 10):
        if vertical:
            im.vline(a - 1, 0, TS, rgb("asphalt0"))
            im.vline(a, 0, TS, rgb("path3"))
            im.vline(a + 1, 0, TS, rgb("asphalt0"))
        else:
            im.hline(0, a - 1, TS, rgb("asphalt0"))
            im.hline(0, a, TS, rgb("path3"))
            im.hline(0, a + 1, TS, rgb("asphalt0"))


@tile("tram_rail_h")
def _(im, s):
    _rails(im, s)


@tile("tram_rail_v")
def _(im, s):
    _rails(im, s, vertical=True)


@tile("cobble_wet")
def _(im, s):
    # Not _cobble(): that draws its joints and speckle in the path ramp, which
    # is a dry pavement in daylight. Wet cobble is nearly all shadow.
    im.rect(0, 0, TS, TS, rgb("asphalt1"))
    r = Rand(s)
    for row in range(4):
        y = row * 4
        off = 0 if row % 2 == 0 else 2
        im.hline(0, y, TS, rgb("asphalt0"))
        for x in range(off, TS, 4):
            im.vline(x, y, 4, rgb("asphalt0"))
        for x in range(TS):
            if r.next() % 6 == 0:
                im.set(x, y + 2, rgb("asphalt2"))
    # the sheen stands in the joints, which is where the water actually stands
    for y in (3, 7, 11, 15):
        for x in range(0, TS, 4):
            im.set(x + 1, y, rgb("blue1"))


def _canal(im, s, frame=0):
    """The ripple lines march down a pixel per frame, so the canal drifts."""
    im.rect(0, 0, TS, TS, rgb("blue0"))
    r = Rand(s)
    for y0 in range(0, TS, 3):
        y = (y0 + frame) % TS
        im.hline(0, y, TS, rgb("blue1"))
        for x in range(TS):
            if r.next() % 5 == 0:
                im.set(x, y, rgb("blue2"))


@tile("canal")
def _(im, s):
    _canal(im, s, 0)


@tile("canal_f1")
def _(im, s):
    _canal(im, s, 1)


@tile("canal_f2")
def _(im, s):
    _canal(im, s, 2)


@tile("quay_edge")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("blue0"))
    im.rect(0, 0, TS, 9, rgb("path1"))
    speckle(im, [rgb("path0"), rgb("path2")], s, 6, area=(0, 0, TS, 9))
    im.hline(0, 0, TS, rgb("path3"))
    im.rect(0, 9, TS, 2, rgb("ink1"))          # the drop to the water
    im.hline(0, 11, TS, rgb("blue1"))


@tile("bollard")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path1"))
    speckle(im, [rgb("path0"), rgb("path2")], s, 6)
    im.rect(6, 5, 4, 9, rgb("ink1"))
    im.rect(6, 5, 2, 9, rgb("ink2"))
    im.disc(7, 5, 2, rgb("ink2"))
    im.hline(5, 14, 6, rgb("ink0"))


@tile("bike_rack")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    speckle(im, [rgb("path1"), rgb("path3")], s, 7)
    for x0 in (2, 9):
        im.hline(x0, 5, 5, rgb("ink3"))
        im.vline(x0, 5, 8, rgb("ink2"))
        im.vline(x0 + 4, 5, 8, rgb("ink2"))
    im.hline(0, 13, TS, rgb("ink1"))


@tile("tram_pole")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path2"))
    speckle(im, [rgb("path1")], s, 7)
    im.vline(7, 0, TS, rgb("ink1"))
    im.vline(8, 0, TS, rgb("ink2"))
    im.hline(9, 2, 7, rgb("ink1"))             # the bracket that holds the wire
    im.hline(0, 3, 7, rgb("ink2"))
    im.rect(6, 13, 4, 3, rgb("ink0"))


@tile("wall_brick_win")
def _(im, s):
    _brick(im, s)
    im.rect(3, 3, 10, 9, rgb("brick0"))
    im.rect(4, 4, 8, 7, rgb("blue1"))
    im.rect(4, 4, 4, 3, rgb("blue2"))
    im.vline(8, 4, 7, rgb("brick0"))
    im.hline(4, 7, 8, rgb("brick0"))
    im.hline(3, 12, 10, rgb("ink1"))           # the sill, in shadow


@tile("wall_brick_base")
def _(im, s):
    _brick(im, s, base="brick0", mortar="ink0", hi="brick1")
    # the wet course: everything within a hand of the pavement is darker
    im.rect(0, 11, TS, 5, rgb("ink1"))
    speckle(im, [rgb("asphalt1"), rgb("ink0")], s + 5, 4, area=(0, 11, TS, 5))
    im.hline(0, 11, TS, rgb("ink0"))


@tile("graffiti")
def _(im, s):
    _brick(im, s)
    # a tag: three strokes, unreadable, which is what a tag looks like at 16px
    for x, y, h in ((3, 5, 6), (6, 4, 8), (10, 6, 5)):
        im.vline(x, y, h, rgb("neon0"))
        im.set(x + 1, y + h - 1, rgb("neon0"))
    im.hline(3, 9, 8, rgb("neon1"))


@tile("shutter")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("ink2"))
    for y in range(0, TS, 2):
        im.hline(0, y, TS, rgb("ink1"))
    speckle(im, [rgb("ink3")], s, 11)
    im.rect(7, 12, 3, 2, rgb("ink3"))          # the handle nobody has pulled
    im.hline(0, 15, TS, rgb("ink0"))


@tile("shutter_sign")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("wood1"))
    im.frame(1, 3, 14, 9, rgb("wood0"))
    im.rect(2, 4, 12, 7, rgb("paper2"))
    for x in range(3, 13, 2):                  # lettering, faded past reading
        im.set(x, 7, rgb("path0"))
    speckle(im, [rgb("path1"), rgb("wood2")], s, 9, area=(2, 4, 12, 7))
    im.hline(0, 15, TS, rgb("wood0"))


def _arch(im, seed, right=False):
    """Half of a viaduct arch: brick haunch, dark opening under the curve.

    The opening is a quarter of a circle of radius TS centred on the springing
    point at the middle of the two-tile span, so `arch_left` + `arch_right`
    make one semicircular arch. Getting this backwards drew a diagonal wedge.
    """
    _brick(im, seed, base="brick0", mortar="ink0", hi="brick1")
    for y in range(TS):
        dy = TS - y
        for x in range(TS):
            dx = (x + 1) if right else (TS - x)
            d = dx * dx + dy * dy
            if d <= TS * TS:
                im.set(x, y, rgb("ink0"))
            elif d <= (TS + 2) * (TS + 2):
                im.set(x, y, rgb("brick2"))     # the ring course, catching light


@tile("arch_left")
def _(im, s):
    _arch(im, s)


@tile("arch_right")
def _(im, s):
    _arch(im, s, right=True)


@tile("arch_shade")
def _(im, s):
    """Walkable ground under the viaduct: one lamp's worth of light, no more."""
    im.rect(0, 0, TS, TS, rgb("asphalt0"))
    r = Rand(s)
    for row in range(4):
        y = row * 4
        im.hline(0, y, TS, rgb("ink0"))
        for x in range(0 if row % 2 == 0 else 2, TS, 4):
            im.vline(x, y, 4, rgb("ink0"))
        for x in range(TS):
            if r.next() % 7 == 0:
                im.set(x, y + 2, rgb("asphalt1"))
    # No baked-in lamp spill: it tiles, and a gold mark every 16 pixels reads as
    # a pattern rather than as light. The lamp lights itself.


def _neon(im, s, frame=0):
    """Frame 1 is the tube half out. TileAnimator holds frame 0 far longer, so
    this reads as an intermittent fault rather than as a blinking light."""
    im.rect(0, 0, TS, TS, rgb("ink0"))
    speckle(im, [rgb("ink1")], s, 9)
    lit = frame == 0
    im.frame(2, 4, 12, 8, rgb("neon0" if lit else "ink2"))
    im.frame(3, 5, 10, 6, rgb("neon1" if lit else "neon0"))
    im.rect(5, 7, 6, 2, rgb("neon0" if lit else "ink2"))
    # the tube throws a little of itself onto the brick
    if lit:
        im.hline(1, 3, 14, rgb("neon0"))
        im.hline(1, 12, 14, rgb("neon0"))


@tile("neon_sign")
def _(im, s):
    _neon(im, s, 0)


@tile("neon_sign_f1")
def _(im, s):
    _neon(im, s, 1)


@tile("snack_window")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("ink1"))
    im.rect(2, 3, 12, 9, rgb("gold1"))
    im.rect(3, 4, 10, 7, rgb("gold2"))
    im.rect(4, 5, 8, 3, rgb("gold3"))
    im.rect(5, 8, 4, 3, rgb("gold0"))         # whoever is working the hatch
    im.hline(1, 12, 14, rgb("ink0"))
    im.hline(1, 2, 14, rgb("ink0"))


@tile("stairs_down")
def _(im, s):
    """Three steps below the pavement. Walkable: it is De Ketel's doorway."""
    im.rect(0, 0, TS, TS, rgb("path1"))
    for i, y in enumerate((1, 6, 11)):
        im.rect(0, y, TS, 5, rgb("path0") if i % 2 else rgb("path1"))
        im.hline(0, y, TS, rgb("path3"))
        im.hline(0, y + 4, TS, rgb("ink2"))
    im.rect(0, 14, TS, 2, rgb("ink1"))         # it keeps going, out of sight


@tile("concrete")
def _(im, s):
    im.rect(0, 0, TS, TS, rgb("path1"))
    speckle(im, [rgb("path0"), rgb("path2")], s, 8)
    im.hline(0, 0, TS, rgb("path3"))
    im.vline(0, 0, TS, rgb("path2"))
    im.hline(0, 15, TS, rgb("path0"))


@tile("glass_curtain")
def _(im, s):
    """The Instituut's front: mullions and cold glass, and no way to see in."""
    im.rect(0, 0, TS, TS, rgb("blue1"))
    im.rect(1, 1, 6, 6, rgb("blue2"))
    im.rect(9, 1, 6, 6, rgb("blue1"))
    im.rect(1, 9, 6, 6, rgb("blue1"))
    im.rect(9, 9, 6, 6, rgb("blue2"))
    im.rect(1, 1, 3, 3, rgb("blue3"))
    im.rect(9, 9, 3, 3, rgb("blue3"))
    im.vline(8, 0, TS, rgb("ink2"))
    im.hline(0, 8, TS, rgb("ink2"))
    im.vline(0, 0, TS, rgb("ink1"))
    im.hline(0, 0, TS, rgb("ink1"))


def _stove(im, s, frame=0):
    """The coal stove De Ketel is named for, or near enough."""
    im.rect(0, 0, TS, TS, rgb("wood1"))
    im.rect(2, 2, 12, 13, rgb("ink1"))
    im.rect(3, 3, 10, 11, rgb("ink2"))
    im.rect(5, 7, 6, 5, rgb("gold0"))          # the door, and what is behind it
    if frame == 0:
        im.rect(6, 8, 4, 3, rgb("gold2"))
        im.set(7, 9, rgb("gold3"))
    else:
        im.rect(6, 8, 4, 3, rgb("gold1"))
        im.set(8, 9, rgb("gold3"))
        im.set(7, 10, rgb("gold2"))
    im.rect(6, 0, 4, 2, rgb("ink1"))           # the flue
    im.hline(2, 14, 12, rgb("ink0"))


@tile("stove")
def _(im, s):
    _stove(im, s, 0)


@tile("stove_f1")
def _(im, s):
    _stove(im, s, 1)


@tile("hooks")
def _(im, s):
    """A board of brass hooks, one card per regular, strongest at the top."""
    im.rect(0, 0, TS, TS, rgb("wood1"))
    im.frame(0, 0, TS, TS, rgb("wood0"))
    for row, y in enumerate((2, 6, 10)):
        for col in range(3):
            x = 2 + col * 4
            im.set(x + 1, y, rgb("gold1"))     # the hook
            im.rect(x, y + 1, 3, 3, rgb("paper1") if row else rgb("paper0"))
            im.hline(x, y + 2, 3, rgb("path0"))


@tile("floor_concrete")
def _(im, s):
    """The Instituut's floor: poured, ground smooth, with expansion joints."""
    im.rect(0, 0, TS, TS, rgb("path2"))
    speckle(im, [rgb("path1"), rgb("path3")], s, 9)
    im.hline(0, 0, TS, rgb("path1"))
    im.vline(0, 0, TS, rgb("path1"))


def _washer(im, s, frame=0):
    """A front-loader. Enamel, a control panel, and a drum that is going round.

    The only tile in the atlas whose animation exists to say a room is warm:
    the wassalon has no music and no stove, so the machines are the whole of
    its light and its noise.
    """
    im.rect(0, 0, TS, TS, rgb("paper1"))
    im.hline(0, 0, TS, rgb("paper0"))          # light from the top-left, as ever
    im.vline(0, 0, TS, rgb("paper0"))
    im.hline(0, 15, TS, rgb("path0"))
    im.vline(15, 0, TS, rgb("paper2"))

    im.rect(1, 1, 14, 4, rgb("ink2"))          # the control panel
    im.rect(2, 2, 3, 2, rgb("ink1"))           # the little window that counts down
    im.set(3, 3, rgb("gold3") if frame == 0 else rgb("gold1"))
    for dx in (8, 11):                         # two dials, one of them broken
        im.set(dx, 2, rgb("path3"))
        im.set(dx, 3, rgb("path0"))

    im.rect(3, 6, 10, 9, rgb("ink1"))          # the porthole rim
    im.set(3, 6, rgb("paper1"))                # knocked corners read as round
    im.set(12, 6, rgb("paper1"))
    im.set(3, 14, rgb("paper1"))
    im.set(12, 14, rgb("paper1"))
    im.rect(4, 7, 8, 7, rgb("blue0"))          # glass
    im.rect(5, 8, 6, 5, rgb("blue1"))
    im.set(5, 8, rgb("blue3"))                 # the one highlight on the glass
    im.set(6, 8, rgb("blue2"))

    # The load, which is the frame. It is warm in there and cold out here.
    if frame == 0:
        im.rect(6, 10, 4, 3, rgb("paper0"))
        im.set(9, 9, rgb("paper2"))
        im.set(6, 9, rgb("gold3"))
    else:
        im.rect(5, 9, 4, 3, rgb("paper1"))
        im.set(9, 11, rgb("paper0"))
        im.set(10, 9, rgb("gold3"))

    im.set(13, 10, rgb("ink2"))                # the latch


@tile("washer")
def _(im, s):
    _washer(im, s, 0)


@tile("washer_f1")
def _(im, s):
    _washer(im, s, 1)


def build(out_dir):
    cols = 16
    rows = (len(TILES) + cols - 1) // cols
    atlas = Img(cols * TS, rows * TS)
    manifest = {}
    for i, (name, fn) in enumerate(TILES):
        t = Img(TS, TS)
        fn(t, 1000 + i * 37)
        cx, cy = i % cols, i // cols
        atlas.blit(t, cx * TS, cy * TS)
        manifest[name] = [cx, cy]
    os.makedirs(out_dir, exist_ok=True)
    atlas.save(os.path.join(out_dir, "town_tileset.png"))
    with open(os.path.join(out_dir, "tileset_manifest.json"), "w") as f:
        json.dump({"tile_size": TS, "columns": cols, "rows": rows, "tiles": manifest}, f, indent=1)
    return len(TILES), cols, rows


if __name__ == "__main__":
    print(build(os.path.join(os.path.dirname(__file__), "..", "art", "tiles")))
