"""Props that are not tiles and not people: things that cross the frame.

Same idiom as gen_tiles.py -- deterministic pixels through tools/png.py, one
light direction (top-left), explicit colors. These are standalone images rather
than atlas cells because a tram is ten tiles long and would burn several atlas
slots that no map ever places.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from palette import rgb
from png import Img
from pixel_art import polygon

PROPS = []


def prop(name):
    def deco(fn):
        PROPS.append((name, fn))
        return fn
    return deco


@prop("tram")
def _():
    """Sela's articulated light rail: 160x36, with a cab at either end.

    Five short sections read as a long, low vehicle at native resolution. The
    central doorway stays at the sprite centre, where arrive() meets the stop.
    """
    im = Img(160, 36)
    white, edge, shade = map(rgb, ("#edf0e8", "#fafbf4", "#b4bfbd"))
    glass, reflection = map(rgb, ("#182d35", "#425d66"))
    joint, rib = map(rgb, ("#697774", "#a5afaa"))

    # Underfloor machinery and almost-hidden wheels keep the carriage low.
    im.rect(10, 29, 140, 4, rgb("#5a6867"))
    for x in (17, 44, 103, 133):
        im.rect(x, 31, 10, 4, rgb("ink1"))
        im.hline(x+2, 34, 6, rgb("ink2"))
    polygon(im, [(2,30),(2,24),(5,16),(10,10),(17,8),(143,8),
                 (150,10),(155,16),(158,24),(158,30),(154,32),(6,32)], shade)
    polygon(im, [(3,27),(4,21),(7,14),(13,10),(147,10),(153,15),
                 (156,22),(157,28),(153,30),(7,30)], white)
    im.hline(16, 9, 128, edge)
    im.rect(14, 12, 132, 12, glass)
    im.hline(15, 13, 130, reflection)
    im.hline(8, 29, 144, shade)

    # Flexible bellows separate the body shells; avoid outlining every window.
    for x in (34, 64, 94, 124):
        im.rect(x, 10, 4, 21, joint)
        for dx in (0, 2):im.vline(x+dx, 11, 19, rib)
        im.hline(x, 10, 4, shade)
    for x in (21, 48, 76, 107, 133):
        im.rect(x, 12, 8, 18, shade)
        im.rect(x+1, 13, 6, 14, glass)
        im.hline(x+1, 14, 6, reflection)
        im.vline(x+4, 13, 17, joint)
        im.rect(x+1, 27, 6, 3, white)
        im.set(x+6, 25, rgb("#76a790"))

    # Curved dark windscreens, white noses and small lamps at both ends.
    for mirrored in (False, True):
        def x(v):return 159-v if mirrored else v
        polygon(im, [(x(4),23),(x(7),16),(x(12),13),(x(17),13),
                     (x(17),24),(x(5),26)], glass)
        for xx,yy in ((8,16),(9,15),(10,14)):
            im.set(x(xx), yy, reflection)
        im.hline(x(7) if not mirrored else x(10), 27, 4, edge)
        im.set(x(6), 27, rgb("#9daead"))
        im.set(x(16), 26, rgb("#6f9694"))
    # Roof equipment has a clear upper face, without grain on the white shell.
    for x,w in ((20,10),(44,15),(100,17),(130,10)):
        im.rect(x, 6, w, 4, shade)
        im.hline(x+1, 6, w-2, edge)
        for xx in range(x+2,x+w-1,3):im.vline(xx,7,2,joint)
    polygon(im, [(72,8),(78,3),(87,7),(85,8),(78,5),(75,8)], joint)
    im.hline(74, 2, 10, rgb("ink2"))
    im.hline(76, 3, 6, shade)
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
