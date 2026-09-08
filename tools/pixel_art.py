"""Integer pixel drawing helpers. Additive API: portrait canvas semantics stay fixed."""
import zlib
from png import Img, Rand
from palette import rgb


def seed(asset: str, detail: str = '') -> int:
    """Names, not registry positions or Python's process-randomized hash."""
    return zlib.crc32((asset + '/' + detail).encode('utf8'))


def colour(value):
    return rgb(value) if isinstance(value, str) else value


def polygon(im: Img, points, fill) -> None:
    """Even/odd scan conversion, sampled at pixel centres; no antialiasing."""
    c = colour(fill)
    for y in range(max(0, min(p[1] for p in points)), min(im.h, max(p[1] for p in points))):
        crossings = []
        for a, b in zip(points, points[1:] + points[:1]):
            if min(a[1], b[1]) <= y + .5 < max(a[1], b[1]):
                crossings.append(a[0] + (y + .5-a[1])*(b[0]-a[0])/(b[1]-a[1]))
        crossings.sort()
        for left, right in zip(crossings[::2], crossings[1::2]):
            for x in range(max(0, int(left)), min(im.w, int(right)+1)):
                if left <= x + .5 < right:
                    im.set(x, y, c)


def ellipse(im: Img, x: int, y: int, w: int, h: int, fill) -> None:
    if w <= 0 or h <= 0:
        return
    c = colour(fill)
    for yy in range(max(0, y), min(im.h, y+h)):
        for xx in range(max(0, x), min(im.w, x+w)):
            if ((2*(xx-x)+1-w)/w)**2 + ((2*(yy-y)+1-h)/h)**2 <= 1:
                im.set(xx, yy, c)


def stamp(im: Img, x: int, y: int, rows, colours) -> None:
    for yy, row in enumerate(rows):
        for xx, ch in enumerate(row):
            if ch in colours:
                im.set(x+xx, y+yy, colour(colours[ch]))


def mask(im: Img, allowed=None) -> Img:
    out = Img(im.w, im.h)
    colors = None if allowed is None else {colour(c) for c in allowed}
    for y in range(im.h):
        for x in range(im.w):
            p = im.get(x, y)
            if p[3] and (colors is None or p in colors):
                out.set(x, y, (255, 255, 255, 255))
    return out


def clipped(im: Img, paint: Img, clip: Img) -> None:
    for y in range(min(im.h, paint.h, clip.h)):
        for x in range(min(im.w, paint.w, clip.w)):
            if clip.get(x, y)[3] and paint.get(x, y)[3]:
                im.set(x, y, paint.get(x, y))


def remap(im: Img, mapping) -> Img:
    lookup = {colour(a): colour(b) for a, b in mapping.items()}
    out = Img(im.w, im.h)
    # Direct assignment preserves straight-alpha source pixels exactly.
    for y in range(im.h):
        for x in range(im.w):
            p = im.get(x, y)
            i = (y*im.w+x)*4
            out.buf[i:i+4] = bytes(lookup.get(p, p))
    return out


def grain(im: Img, clip: Img, asset: str, dark='wood1', light='wood3', count=8) -> None:
    marks = Img(im.w, im.h)
    r = Rand(seed(asset, 'grain'))
    for _ in range(count):
        x, y = r.rng(0, max(0, im.w-4)), r.rng(0, im.h-1)
        length = r.rng(3, max(3, im.w//3))
        marks.hline(x, y, length, colour(dark))
        if r.chance(3):
            marks.hline(x+2, y+1, max(1, length-3), colour(light))
    clipped(im, marks, clip)


def panel(im: Img, x: int, y: int, w: int, h: int,
          base='wood1', light='wood3', dark='wood0') -> None:
    im.rect(x, y, w, h, colour(base))
    im.hline(x, y, w, colour(light))
    im.vline(x, y, h-1, colour(light))
    im.hline(x, y+h-1, w, colour(dark))
    im.vline(x+w-1, y+1, h-1, colour(dark))
