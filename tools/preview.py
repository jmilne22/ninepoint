"""Loads PNGs we wrote and composes a scaled contact sheet for visual review."""
import sys, os, zlib, struct
sys.path.insert(0, os.path.dirname(__file__))
from png import Img

def load(path):
    d = open(path, 'rb').read(); pos = 8; w = h = 0; idat = b''
    while pos < len(d):
        ln = struct.unpack('>I', d[pos:pos+4])[0]; tag = d[pos+4:pos+8]
        pay = d[pos+8:pos+8+ln]; pos += 12 + ln
        if tag == b'IHDR': w, h = struct.unpack('>II', pay[:8])
        elif tag == b'IDAT': idat += pay
    raw = zlib.decompress(idat)
    im = Img(w, h)
    stride = w * 4
    prev = bytearray(stride)
    pos = 0
    for y in range(h):
        f = raw[pos]; pos += 1
        line = bytearray(raw[pos:pos + stride]); pos += stride
        # PNG filters: 0 none, 1 sub, 2 up, 3 average, 4 Paeth
        for i in range(stride):
            a = line[i - 4] if i >= 4 else 0
            b = prev[i]
            c = prev[i - 4] if i >= 4 else 0
            if f == 1: line[i] = (line[i] + a) & 0xFF
            elif f == 2: line[i] = (line[i] + b) & 0xFF
            elif f == 3: line[i] = (line[i] + ((a + b) >> 1)) & 0xFF
            elif f == 4:
                p_ = a + b - c
                pa, pb, pc = abs(p_ - a), abs(p_ - b), abs(p_ - c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pred) & 0xFF
        for x in range(w):
            im.set(x, y, tuple(line[x*4:x*4+4]))
        prev = line
    return im
