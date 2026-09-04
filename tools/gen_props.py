"""Props that are not tiles and not people: things that cross the frame.

Same idiom as gen_tiles.py -- deterministic pixels through tools/png.py, one
light direction (top-left), palette only. These are standalone images rather
than atlas cells because a tram is six tiles long and would burn three atlas
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
    """A Verhaven tram, side on, 96x36, facing right.

    Six tiles long and two people tall. It was 48x18 -- smaller than the
    16 px character standing next to it -- and read as a toy. Rust red and
    cream, drawn facing right and flipped in code for the other direction.
    """
    w, h = 96, 36
    im = Img(w, h)

    # the pantograph to the overhead line, which is most of what says "tram"
    im.rect(44, 0, 10, 2, rgb("ink2"))
    im.vline(48, 2, 6, rgb("ink2"))
    im.vline(49, 2, 6, rgb("ink3"))

    im.rect(2, 8, w - 4, 22, rgb("rust1"))          # body
    im.frame(2, 8, w - 4, 22, rgb("ink0"))          # outline
    im.hline(3, 9, w - 6, rgb("rust2"))             # lit top edge, light top-left
    im.hline(3, 10, w - 6, rgb("rust2"))
    im.hline(3, 28, w - 6, rgb("rust0"))            # shaded bottom
    im.hline(3, 27, w - 6, rgb("rust0"))
    im.hline(3, 20, w - 6, rgb("paper1"))           # the cream waist band
    im.hline(3, 21, w - 6, rgb("paper0"))

    # window band. The gaps are the pillars between them.
    for x in range(8, w - 16, 12):
        im.rect(x, 12, 8, 7, rgb("blue1"))
        im.hline(x, 12, 8, rgb("blue2"))
        im.hline(x, 18, 8, rgb("blue0"))
        im.vline(x, 12, 7, rgb("blue2"))

    # the door, two thirds of the way along
    im.rect(66, 12, 7, 16, rgb("rust0"))
    im.vline(69, 12, 16, rgb("ink1"))
    im.rect(67, 13, 5, 6, rgb("blue1"))

    # the front: a destination blind and a lamp
    im.rect(w - 14, 12, 9, 5, rgb("paper1"))
    im.hline(w - 14, 12, 9, rgb("paper0"))
    im.rect(w - 6, 23, 2, 2, rgb("gold3"))
    im.set(w - 7, 24, rgb("gold2"))

    im.hline(3, 29, w - 6, rgb("ink1"))             # skirt
    im.rect(2, 30, w - 4, 2, rgb("ink1"))
    for wx in (12, 24, 62, 74):                     # wheels, two bogies
        im.rect(wx, 31, 6, 5, rgb("ink0"))
        im.rect(wx + 1, 32, 4, 3, rgb("ink2"))
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
