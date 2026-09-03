"""Minimal RGBA PNG writer and a tiny pixel canvas.

No PIL in this environment, and that turns out to be a feature: every pixel in
Ninepoint is placed by code, so the art is deterministic and regenerable.
"""
import zlib
import struct


class Img:
    def __init__(self, w, h, fill=(0, 0, 0, 0)):
        self.w = w
        self.h = h
        self.buf = bytearray(w * h * 4)
        if fill[3] != 0 or fill[:3] != (0, 0, 0):
            for i in range(w * h):
                self.buf[i * 4:i * 4 + 4] = bytes(fill)

    # --- pixels ---------------------------------------------------------
    def set(self, x, y, c):
        if c is None or x < 0 or y < 0 or x >= self.w or y >= self.h:
            return
        if len(c) == 3:
            c = (c[0], c[1], c[2], 255)
        if c[3] == 0:      # a fully transparent colour erases
            i = (y * self.w + x) * 4
            self.buf[i:i + 4] = b"\x00\x00\x00\x00"
            return
        i = (y * self.w + x) * 4
        if c[3] == 255:
            self.buf[i:i + 4] = bytes(c)
        else:  # simple source-over
            a = c[3] / 255.0
            for k in range(3):
                self.buf[i + k] = int(c[k] * a + self.buf[i + k] * (1 - a))
            self.buf[i + 3] = max(self.buf[i + 3], c[3])

    def get(self, x, y):
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return (0, 0, 0, 0)
        i = (y * self.w + x) * 4
        return tuple(self.buf[i:i + 4])

    # --- shapes ---------------------------------------------------------
    def rect(self, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, c)

    def frame(self, x, y, w, h, c):
        for xx in range(x, x + w):
            self.set(xx, y, c)
            self.set(xx, y + h - 1, c)
        for yy in range(y, y + h):
            self.set(x, yy, c)
            self.set(x + w - 1, yy, c)

    def hline(self, x, y, w, c):
        for xx in range(x, x + w):
            self.set(xx, y, c)

    def vline(self, x, y, h, c):
        for yy in range(y, y + h):
            self.set(x, yy, c)

    def disc(self, cx, cy, r, c):
        """Filled circle with pixel-art rounding (cx, cy may be halves)."""
        r2 = r * r
        for yy in range(int(cy - r - 1), int(cy + r + 2)):
            for xx in range(int(cx - r - 1), int(cx + r + 2)):
                dx = xx - cx + 0.5 if isinstance(cx, float) else xx - cx
                dy = yy - cy + 0.5 if isinstance(cy, float) else yy - cy
                if dx * dx + dy * dy <= r2:
                    self.set(xx, yy, c)

    def blit(self, other, x, y):
        for yy in range(other.h):
            for xx in range(other.w):
                p = other.get(xx, yy)
                if p[3]:
                    self.set(x + xx, y + yy, p)

    def sub(self, x, y, w, h):
        out = Img(w, h)
        for yy in range(h):
            for xx in range(w):
                out.set(xx, yy, self.get(x + xx, y + yy))
        return out

    def scaled(self, n):
        out = Img(self.w * n, self.h * n)
        for y in range(self.h):
            for x in range(self.w):
                p = self.get(x, y)
                if p[3]:
                    out.rect(x * n, y * n, n, n, p)
        return out

    # --- io -------------------------------------------------------------
    def save(self, path):
        raw = bytearray()
        stride = self.w * 4
        for y in range(self.h):
            raw.append(0)  # filter: none
            raw += self.buf[y * stride:(y + 1) * stride]
        data = zlib.compress(bytes(raw), 9)

        def chunk(tag, payload):
            out = struct.pack(">I", len(payload)) + tag + payload
            return out + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

        png = b"\x89PNG\r\n\x1a\n"
        png += chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
        png += chunk(b"IDAT", data)
        png += chunk(b"IEND", b"")
        with open(path, "wb") as f:
            f.write(png)
        return path


class Rand:
    """Deterministic xorshift32 so art never changes between runs.

    (An LCG was tried first and its low bits correlated badly enough to draw
    visible rows of "random" stars across the title art.)
    """

    def __init__(self, seed):
        self.s = (seed * 2654435761 + 1) & 0xFFFFFFFF or 0x9E3779B9

    def next(self):
        x = self.s
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        self.s = x & 0xFFFFFFFF
        return self.s >> 1

    def chance(self, n):
        return self.next() % n == 0

    def pick(self, seq):
        return seq[self.next() % len(seq)]

    def rng(self, a, b):
        return a + self.next() % (b - a + 1)
