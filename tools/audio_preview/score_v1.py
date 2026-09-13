"""Original Sela melody: 'A Seat at the Table', and its match variation.

Note lists and arrangements are source; FluidSynth only supplies instruments.
Beats are quarter notes. Fixed seeds preserve the performed timing on rebuild.
"""
import random
import struct

PPQ = 960
MELODY = [
    [(0, 76, 1), (1.5, 73, .5), (2, 71, 1), (3, 69, .7)],
    [(.5, 73, 1), (2, 76, 1.6)],
    [(0, 78, 1.4), (1.5, 76, .5), (2.5, 73, 1)],
    [(0, 71, 2), (2.5, 68, 1)],
    [(0, 69, .8), (1, 73, .8), (2, 76, 1.7)],
    [(.5, 78, 1), (2, 80, 1.6)],
    [(0, 76, 1), (1.5, 73, .5), (2, 71, 1.6)],
    [(0, 73, 1.5), (2, 71, 1.7)],
]
CHORDS = [(45, [57, 61, 64, 68]), (42, [57, 61, 64, 68]),
          (38, [57, 61, 66, 69]), (40, [56, 59, 62, 66]),
          (45, [56, 61, 64, 69]), (49, [56, 59, 64, 68]),
          (47, [57, 62, 66, 69]), (40, [56, 59, 64, 66])]
PROGRAMS = {0: 0, 1: 4, 2: 24, 3: 32, 4: 48, 9: 40}
PANS = {0: 57, 1: 77, 2: 43, 3: 64, 4: 74, 9: 64}


def compose(match=False, intro=False):
    rng = random.Random(902 if match else 901)
    bpm = 112 if match else 84
    bars = 1 if intro else (48 if match else 40)
    notes = []

    def add(channel, beat, key, length, velocity):
        time = max(0, beat + rng.uniform(-.012, .012))
        notes.append((channel, time, key, max(.04, length),
                      max(1, min(110, velocity + rng.randint(-4, 4)))))

    for bar in range(bars):
        root, chord = CHORDS[bar % 8]
        start = bar * 4
        # A genuine middle section changes register, density and harmonic colour.
        middle = not intro and 16 <= bar < 24
        ending = not intro and bar >= bars - 8
        if middle:
            root, chord = CHORDS[(bar + 1) % 8]
        motif = MELODY[bar % 8]
        if bar % 8 not in (3, 7) or ending or intro:
            for beat, key, length in motif:
                add(0, start + beat, key - (12 if middle else 0), length * .9,
                    55 if middle else (72 if match else 65))
        for offset in (0, 2.25):
            for i, key in enumerate(chord):
                add(1, start + offset + i * .014, key, 1.5, 38 if middle else 46)
        # Fingerpicked guitar answers the piano, with space on the last bar.
        for i, beat in enumerate((.5, 1.25, 2, 3.25)):
            if bar % 8 == 7 and beat > 2: continue
            add(2, start + beat, chord[i] + (0 if middle else 12), .6,
                36 if middle else 48)
        for beat in ((0, 2) if not match or middle else (0, 1.5, 2, 3.5)):
            add(3, start + beat, root + (7 if beat == 3.5 else 0),
                1.3 if beat in (0, 2) else .35, 60 if match else 54)
        if match and (8 <= bar < 16 or 24 <= bar < 40):
            for key in (chord[0] + 12, chord[2] + 12):
                add(4, start, key, 3.6, 34)
        if not middle:
            for beat in (0, 2): add(9, start + beat, 36, .12, 52 if match else 27)
            for beat in (1, 3): add(9, start + beat, 38, .15, 45 if match else 29)
            for beat in (0, 1, 2, 3): add(9, start + beat + .5, 42, .08, 30)
    return bpm, bars * 4, notes


def vlq(value):
    parts = [value & 127]
    while value >> 7:
        value >>= 7
        parts.insert(0, (value & 127) | 128)
    return bytes(parts)


def midi(path, match=False, intro=False):
    bpm, beats, notes = compose(match, intro)
    events = [(0, b'\xff\x51\x03' + int(60000000 / bpm).to_bytes(3, 'big'))]
    for ch, program in PROGRAMS.items():
        # Standard kit in match; brushes in the room.
        events += [(0, bytes([0xc0 | ch, 0 if ch == 9 and match else program])),
                   (0, bytes([0xb0 | ch, 10, PANS[ch]]))]
    for ch, beat, key, duration, vel in notes:
        on = round(beat * PPQ)
        off = min(round((beat + duration) * PPQ), round(beats * PPQ) - 1)
        events += [(on, bytes([0x90 | ch, key, vel])),
                   (off, bytes([0x80 | ch, key, 0]))]
    events.sort(key=lambda e: e[0])
    data = bytearray(); previous = 0
    for tick, message in events:
        data += vlq(tick - previous) + message
        previous = tick
    data += vlq(round(beats * PPQ) - previous) + b'\xff\x2f\x00'
    path.write_bytes(b'MThd' + struct.pack('>IHHH', 6, 0, 1, PPQ)
                     + b'MTrk' + struct.pack('>I', len(data)) + data)
    return beats * 60 / bpm
