"""Props that are not tiles and not people: things that cross the frame.

Same idiom as gen_tiles.py -- deterministic pixels through tools/png.py, one
light direction (top-left), palette only. These are standalone images rather
than atlas cells because a tram is three tiles long and would burn three atlas
slots that no map ever places.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import rgb
from png import Img

PROPS = []


def prop(name):
    def deco(fn):
        PROPS.append((name, fn))
        return fn
    return deco


@prop("tram")
def _():
    """A Verhaven tram, side on, 48x18, facing right.

    Rust red and cream, because the palette's warm accents were already the
    right colours for a city that is wet most of the time. It is drawn facing
    right and flipped in code for the other direction, so the two passes are
    the same vehicle rather than two.
    """
    w, h = 48, 18
    im = Img(w, h)

    # the pole to the overhead line, which is most of what says "tram"
    im.vline(30, 0, 4, rgb("ink2"))
    im.set(31, 1, rgb("ink3"))

    im.rect(1, 4, w - 2, 12, rgb("rust1"))          # body
    im.frame(1, 4, w - 2, 12, rgb("ink0"))          # outline
    im.hline(2, 4, w - 4, rgb("rust2"))             # lit top edge, light top-left
    im.hline(2, 14, w - 4, rgb("rust0"))            # shaded bottom

    # window band. The gaps are the pillars between them.
    for x in range(4, w - 6, 7):
        im.rect(x, 6, 5, 5, rgb("blue1"))
        im.hline(x, 6, 5, rgb("blue2"))
        im.set(x, 10, rgb("blue0"))

    # the front: a destination blind and a lamp
    im.rect(w - 8, 6, 5, 3, rgb("paper1"))
    im.hline(w - 8, 6, 5, rgb("paper0"))
    im.set(w - 3, 12, rgb("gold3"))
    im.set(w - 4, 12, rgb("gold2"))

    im.hline(2, 15, w - 4, rgb("ink1"))             # skirt
    for wx in (7, 14, 33, 40):                      # wheels
        im.rect(wx, 16, 3, 2, rgb("ink0"))
    return im


@prop("bubble")
def _():
    """A "..." over somebody's head: two people at a table are talking, and
    this is the whole of the evidence. 13x11, tail at the bottom left, drawn
    in paper and ink so it reads against brick and against a lit interior."""
    w, h = 13, 11
    im = Img(w, h)
    im.rect(1, 0, w - 2, 8, rgb("paper0"))
    im.rect(0, 1, w, 6, rgb("paper0"))
    im.frame(1, 0, w - 2, 8, rgb("ink1"))
    im.set(0, 0, rgb("paper0"))
    im.set(w - 1, 0, rgb("paper0"))
    # the tail
    im.set(3, 8, rgb("ink1"))
    im.set(2, 9, rgb("ink1"))
    im.set(3, 7, rgb("paper0"))
    for x in (3, 6, 9):
        im.rect(x, 3, 2, 2, rgb("ink2"))
    return im


def build(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    written = []
    for name, fn in PROPS:
        im = fn()
        im.save(os.path.join(out_dir, name + ".png"))
        written.append((name, im.w, im.h))
    return written


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    for row in build(os.path.join(here, "..", "art", "props")):
        print("%-10s %dx%d" % row)
