"""Minimal WAV writer and a small synthesiser.

The sibling of tools/png.py. There is no audio middleware and no sample library
on this machine, and none is wanted: every sound in Ninepoint is synthesised
here from oscillators and noise, so the whole soundtrack is regenerable,
diffable, and about forty kilobytes.
"""
import math
import random
import struct

RATE = 22050


class Sound:
    """A mono buffer of floats in -1..1."""

    def __init__(self, seconds=0.0, rate=RATE):
        self.rate = rate
        self.s = [0.0] * int(seconds * rate)

    # --- construction ---------------------------------------------------
    @classmethod
    def silence(cls, seconds, rate=RATE):
        return cls(seconds, rate)

    @classmethod
    def tone(cls, freq, seconds, wave="sine", amp=1.0, rate=RATE, phase=0.0, detune=0.0):
        out = cls(seconds, rate)
        n = len(out.s)
        for i in range(n):
            t = i / rate
            f = freq + detune * (i / max(1, n))
            p = phase + 2.0 * math.pi * f * t
            if wave == "sine":
                v = math.sin(p)
            elif wave == "square":
                v = 1.0 if math.sin(p) >= 0 else -1.0
            elif wave == "tri":
                v = 2.0 / math.pi * math.asin(max(-1.0, min(1.0, math.sin(p))))
            elif wave == "saw":
                v = 2.0 * ((f * t) % 1.0) - 1.0
            else:
                raise ValueError(wave)
            out.s[i] = v * amp
        return out

    @classmethod
    def noise(cls, seconds, amp=1.0, rate=RATE, seed=1):
        out = cls(seconds, rate)
        rng = random.Random(seed)
        for i in range(len(out.s)):
            out.s[i] = (rng.random() * 2.0 - 1.0) * amp
        return out

    # --- shaping --------------------------------------------------------
    def env(self, attack=0.002, decay=0.0, sustain=1.0, release=0.05):
        """Standard ADSR over the whole buffer."""
        n = len(self.s)
        a = int(attack * self.rate)
        d = int(decay * self.rate)
        r = int(release * self.rate)
        body = max(0, n - a - d - r)
        for i in range(n):
            if i < a:
                g = i / max(1, a)
            elif i < a + d:
                g = 1.0 + (sustain - 1.0) * ((i - a) / max(1, d))
            elif i < a + d + body:
                g = sustain
            else:
                g = sustain * (1.0 - (i - a - d - body) / max(1, r))
            self.s[i] *= max(0.0, g)
        return self

    def decay(self, tau=0.05):
        """Exponential fall -- what a struck object actually does."""
        for i in range(len(self.s)):
            self.s[i] *= math.exp(-(i / self.rate) / tau)
        return self

    def lowpass(self, cutoff):
        """One-pole filter. Takes the fizz off noise."""
        if cutoff <= 0:
            return self
        dt = 1.0 / self.rate
        rc = 1.0 / (2.0 * math.pi * cutoff)
        alpha = dt / (rc + dt)
        prev = 0.0
        for i in range(len(self.s)):
            prev = prev + alpha * (self.s[i] - prev)
            self.s[i] = prev
        return self

    def highpass(self, cutoff):
        if cutoff <= 0:
            return self
        dt = 1.0 / self.rate
        rc = 1.0 / (2.0 * math.pi * cutoff)
        alpha = rc / (rc + dt)
        out = [0.0] * len(self.s)
        prev_in = 0.0
        prev_out = 0.0
        for i in range(len(self.s)):
            prev_out = alpha * (prev_out + self.s[i] - prev_in)
            prev_in = self.s[i]
            out[i] = prev_out
        self.s = out
        return self

    def gain(self, g):
        self.s = [v * g for v in self.s]
        return self

    def pitch_shift(self, ratio):
        """Crude resample. Enough to vary a click so it is not a metronome."""
        n = int(len(self.s) / ratio)
        out = [0.0] * n
        for i in range(n):
            src = i * ratio
            j = int(src)
            frac = src - j
            a = self.s[j] if j < len(self.s) else 0.0
            b = self.s[j + 1] if j + 1 < len(self.s) else 0.0
            out[i] = a + (b - a) * frac
        self.s = out
        return self

    # --- combination ----------------------------------------------------
    def mix(self, other, at=0.0, gain=1.0):
        start = int(at * self.rate)
        need = start + len(other.s)
        if need > len(self.s):
            self.s.extend([0.0] * (need - len(self.s)))
        for i, v in enumerate(other.s):
            self.s[start + i] += v * gain
        return self

    def append(self, other):
        self.s.extend(other.s)
        return self

    def normalise(self, peak=0.85):
        m = max((abs(v) for v in self.s), default=0.0)
        if m > 0.0001:
            self.gain(peak / m)
        return self

    def fade_edges(self, seconds=0.004):
        """Kill clicks at the ends of the buffer."""
        n = int(seconds * self.rate)
        for i in range(min(n, len(self.s))):
            g = i / max(1, n)
            self.s[i] *= g
            self.s[-1 - i] *= g
        return self

    def loopify(self, seconds=0.35):
        """Make the buffer seamless, for a bed that is going to loop forever.

        fade_edges() is wrong for a loop: it fades in *and* out, so the seam
        pumps once per cycle, which is the one thing you would notice about a
        rain bed. Crossfade the tail back over the head instead and drop it --
        the join is then continuous in level and in content.
        """
        n = int(seconds * self.rate)
        if n <= 0 or len(self.s) <= n * 2:
            return self
        tail = self.s[-n:]
        for i in range(n):
            g = i / float(n)
            self.s[i] = self.s[i] * g + tail[i] * (1.0 - g)
        del self.s[-n:]
        return self

    def seam(self):
        """How far the loop point jumps. Near zero is a clean loop."""
        if not self.s:
            return 0.0
        return abs(self.s[-1] - self.s[0])

    # --- io -------------------------------------------------------------
    def save(self, path):
        frames = bytearray()
        for v in self.s:
            c = int(max(-1.0, min(1.0, v)) * 32767)
            frames += struct.pack("<h", c)
        data_size = len(frames)
        header = b"RIFF" + struct.pack("<I", 36 + data_size) + b"WAVE"
        header += b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, self.rate,
                                        self.rate * 2, 2, 16)
        header += b"data" + struct.pack("<I", data_size)
        with open(path, "wb") as f:
            f.write(header + bytes(frames))
        return path

    def peak(self):
        return max((abs(v) for v in self.s), default=0.0)

    def seconds(self):
        return len(self.s) / float(self.rate)
