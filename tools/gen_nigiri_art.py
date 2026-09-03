"""Art for the nigiri ceremony.

HammerLock Wrestling's trick was showing the crowd, the ring and a close-up of
the action in three horizontal windows at once, with cartoony animation. The
ceremony borrows that layout, so it needs three things the game did not have: a
stone bowl, a hand that opens and closes, and a row of onlookers.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from png import Img, Rand
from palette import rgb, skin
from characters import CHARACTERS, BY_ID

HAND_W, HAND_H = 26, 26
TONES = ["skinA", "skinB", "skinC", "skinD"]
POSES = ["open", "fist", "spill"]


def bowl():
    """A go bowl, three-quarter view, with stones heaped in it."""
    im = Img(44, 30)
    # body
    im.disc(22, 16, 15, rgb("wood0"))
    im.disc(22, 15, 14, rgb("wood1"))
    im.disc(19, 13, 10, rgb("wood2"))
    # cut the top off to make a rim
    im.rect(0, 0, 44, 8, (0, 0, 0, 0))
    # the rim ellipse
    for x in range(4, 40):
        t = (x - 22) / 18.0
        h = int(4.0 * (1.0 - t * t) ** 0.5)
        for y in range(8 - h, 8 + h + 1):
            im.set(x, y, rgb("wood2") if y < 8 else rgb("wood1"))
    for x in range(4, 40):
        t = (x - 22) / 18.0
        h = int(4.0 * (1.0 - t * t) ** 0.5)
        im.set(x, 8 - h, rgb("wood3"))
        im.set(x, 8 + h, rgb("wood0"))
    # stones heaped inside
    r = Rand(4242)
    for i in range(16):
        sx = r.rng(8, 35)
        sy = r.rng(5, 10)
        white = r.chance(2)
        im.disc(sx, sy, 2.4, rgb("stoneW0") if white else rgb("stoneB0"))
        im.set(sx - 1, sy - 1, rgb("stoneW1") if white else rgb("stoneB1"))
    im.hline(4, 28, 36, rgb("ink0"))
    return im


# Hands drawn as explicit pixel art rather than stacked discs: at this size a
# silhouette either reads or it does not, and a pile of circles did not.
#   o outline   d shadow   m mid   l light   . empty
HAND_ART = {
    "fist": [
        "....................",
        "......oooooo........",
        "....oollllllooo.....",
        "...ollllllllllmo....",
        "..ollllmmmmmmmmmo...",
        "..olmomlomlomlommo..",
        "..ommmmmmmmmmmmmmo..",
        "..ommmmmmmmmmmmmmo..",
        ".oommmmmmmmmmmmmdo..",
        ".ommmmmmmmmmmmmmdo..",
        ".ommmmmmmmmmmmmddo..",
        "..ommmmmmmmmmmddo...",
        "..oommmmmmmmmddo....",
        "....ooddddddddo.....",
        ".....odddddddo......",
        ".....oddddddo.......",
        "......oooooo........",
        "....................",
        "....................",
        "....................",
    ],
    "open": [
        "....................",
        "...oo...oo..oo......",
        "..olmo.olmo.olmo....",
        "..olmo.olmo.olmo.oo.",
        "..olmo.olmo.olmoolmo",
        "..olmo.olmo.olmoolmo",
        "..olmoolmooolmoolmo.",
        "..olmmlmmlmmlmmlmmo.",
        ".oollllllllllllllmo.",
        ".ollllllllllllllmmo.",
        ".olllllllmmmmmmmmmo.",
        ".ommmmmmmmmmmmmmmo..",
        "..ommmmmmmmmmmmmdo..",
        "..ommmmmmmmmmmmddo..",
        "...oommmmmmmmmddo...",
        ".....odddddddddo....",
        "......odddddddo.....",
        "......oooooooo......",
        "....................",
        "....................",
    ],
    "spill": [
        "....................",
        "..oooo..............",
        ".ollllo.............",
        ".ollllllooo.........",
        ".olllllllllooo......",
        ".ollllmmmmmmmloo....",
        "..ommmmmmmmmmmmmo...",
        "..ommmmmmmmmmmmmmo..",
        "..oommmmmmmmmmmmmo..",
        "...odmmmmmmmmmmmdo..",
        "...odmmoommoommmdo..",
        "...oddmo.omo.ommdo..",
        "....oddo.omo.omdo...",
        "....oodo.oo..oodo...",
        ".....oo..........o..",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
    ],
}

HAND_ART_W = 20
HAND_ART_H = 20


def hand(tone, pose):
    """A cupped hand, at 20x20. Drawn at 2x in the ceremony."""
    im = Img(HAND_W, HAND_H)
    d, m, l = skin(tone)
    ink = rgb("ink0")
    lookup = {"o": ink, "d": d, "m": m, "l": l}
    ox = (HAND_W - HAND_ART_W) // 2
    oy = (HAND_H - HAND_ART_H) // 2
    for y, row in enumerate(HAND_ART[pose]):
        for x, ch in enumerate(row):
            col = lookup.get(ch)
            if col is not None:
                im.set(ox + x, oy + y, col)
    return im


def crowd():
    """A row of onlookers, seen from behind, leaning over the top window."""
    im = Img(384, 34)
    im.rect(0, 0, 384, 34, rgb("plum0"))
    for x in range(384):
        im.set(x, 0, rgb("plum1"))
    # a warm glow behind them
    for y in range(34):
        for x in range(0, 384, 3):
            if (x // 3 + y) % 7 == 0:
                im.set(x, y, rgb("plum1"))

    # heads, drawn from the cast so the crowd is people you know
    order = ["wren", "pip", "nadia", "tomas", "bertie", "marguerite", "hana", "wren", "pip"]
    x = 6
    for i, cid in enumerate(order):
        c = BY_ID[cid]
        hair = rgb(c["hair_col"][0])
        hair_l = rgb(c["hair_col"][1])
        sk = skin(c["skin"])[1]
        bob = (i % 3) * 3
        cy = 16 + bob
        # shoulders
        im.disc(x + 12, cy + 20, 13, rgb(c["top"][0]))
        # head, back of
        im.disc(x + 12, cy, 9, sk)
        im.disc(x + 12, cy - 1, 9, hair)
        im.disc(x + 9, cy - 3, 5, hair_l)
        im.rect(x + 3, cy + 4, 18, 6, sk)
        x += 42
    return im


def build(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    bowl().save(os.path.join(out_dir, "bowl.png"))
    sheet = Img(HAND_W * len(POSES), HAND_H * len(TONES))
    for ty, tone in enumerate(TONES):
        for px, pose in enumerate(POSES):
            sheet.blit(hand(tone, pose), px * HAND_W, ty * HAND_H)
    sheet.save(os.path.join(out_dir, "hands.png"))
    crowd().save(os.path.join(out_dir, "crowd.png"))
    return {"bowl": (44, 30), "hands": (sheet.w, sheet.h), "crowd": (384, 34),
            "tones": TONES, "poses": POSES}


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    print(build(os.path.join(here, "..", "art", "ui")))
