"""Original orchestral revision: Beyond the Balcony / One Clear Move.

The owner requested greater anime-score drama. This is an original melody and
arrangement, not a transcription. score_v1.py preserves the earlier cafe direction.
Quarter-note beat units; stable seeds humanize individual attacks and dynamics.
"""
import random
from score_v1 import vlq
import struct

PPQ = 960
# D minor: the leap and falling answer form a recognisable eight-bar sentence.
MELODY = [
    [(0, 69, .7), (1, 74, 1.4), (2.5, 77, .5), (3, 76, .85)],
    [(0, 74, 1.6), (2, 72, .7), (3, 69, .8)],
    [(0, 70, .7), (1, 74, .7), (2, 77, 1.7)],
    [(.5, 76, .6), (1.5, 72, 1.3), (3, 69, .8)],
    [(0, 67, .7), (1, 70, .7), (2, 74, 1.6)],
    [(0, 72, .6), (1, 76, .6), (2, 79, 1.7)],
    [(0, 77, .7), (1, 76, .6), (2, 74, .6), (3, 72, .8)],
    [(0, 73, 2.3), (3, 69, .8)],
]
# The later statement opens into F major, then returns through A to D minor.
BRIGHT_MELODY = [
    [(0, 72, .7), (1, 77, 1.4), (2.5, 81, .5), (3, 79, .85)],
    [(0, 77, 1.7), (2, 76, .7), (3, 72, .8)],
    [(0, 74, .7), (1, 77, .7), (2, 82, 1.7)],
    [(0, 81, 1.4), (2, 79, .8), (3, 77, .8)],
    [(0, 79, .7), (1, 77, .7), (2, 74, 1.6)],
    [(0, 76, .7), (1, 79, .7), (2, 84, 1.6)],
    [(0, 81, .7), (1, 79, .7), (2, 77, .7), (3, 76, .8)],
    [(0, 76, 1.4), (2, 73, .7), (3, 69, .8)],
]
HARMONY = [(38,[50,57,62,65]), (34,[50,58,62,65]),
           (41,[53,60,65,69]), (36,[52,55,60,64]),
           (43,[55,58,62,67]), (36,[55,60,64,67]),
           (34,[53,58,62,65]), (33,[52,57,61,67])]
BRIGHT = [(41,[53,60,65,69]), (36,[52,55,60,64]),
          (34,[53,58,62,65]), (38,[53,57,62,65]),
          (43,[55,58,62,67]), (36,[55,60,64,67]),
          (34,[53,58,62,65]), (33,[52,57,61,67])]
# Piano, string bed, guitar, bass, violins, horn, timpani, oboe, cello, drums,
# and pizzicato strings. Stereo positions follow a small acoustic ensemble.
PROGRAMS = {0:0, 1:48, 2:24, 3:43, 4:40, 5:60, 6:47, 7:68, 8:42, 9:0, 10:45, 11:29}
PANS = {0:57, 1:79, 2:42, 3:64, 4:39, 5:78, 6:68, 7:59, 8:81, 9:64, 10:46, 11:77}


def compose(match=False, intro=False):
    rng = random.Random(1202 if match else 1201)
    bpm = 116 if match else 88
    bars = 1 if intro else (48 if match else 40)
    notes = []

    def add(ch, beat, key, length, velocity):
        # Independent attacks make the ensemble breathe; bass remains tighter.
        spread = .008 if ch in (3, 6, 9) else .022
        notes.append((ch, max(0, beat+rng.uniform(-spread,spread)), key,
                      max(.03,length), max(1,min(110,velocity+rng.randint(-5,5)))))

    if intro:
        # A compact rising entrance, deliberately resolving into the loop's D.
        for beat,key in [(0,57),(.5,62),(1,65),(1.5,69),(2,73),(3,76)]:
            add(0,beat,key,.42,68+round(beat*3))
            add(10,beat,key-12,.22,62)
        for key in [57,61,64,69]: add(1,0,key,3.7,47)
        add(6,0,45,.4,53);add(6,2.5,45,.35,59);add(6,3.5,45,.28,65)
        return bpm,4,notes

    for bar in range(bars):
        start = bar*4
        middle = 16 <= bar < 24
        bright = 24 <= bar < (40 if match else 32)
        opening = bar < 8
        last = bar >= bars-4
        root,chord = (BRIGHT if bright else HARMONY)[bar%8]
        motif = (BRIGHT_MELODY if bright else MELODY)[bar%8]
        energy = .65 if middle else (.86 if opening else (1.08 if bright else 1))
        if last: energy *= .82
        # A real melodic foreground; the orchestral lead arrives after piano alone.
        for beat,key,length in motif:
            lead = key-12 if middle else key
            add(0,start+beat,lead,length*.86,(77 if match else 68)*energy)
            if match and not middle and not opening:
                add(4,start+beat+.025,key,length*1.03,65*energy)
            elif not match and (8 <= bar < 16 or bright):
                add(7,start+beat+.03,key,length*.96,55*energy)
            elif middle:
                add(8,start+beat+.04,key-12,length*1.03,48)
        # Slow ensemble chords leave gaps for the stone's short midrange attack.
        for key in chord:
            add(1,start+.035,key,3.72,(46 if match else 40)*energy)
        bass_beats = (0,2) if middle or not match else (0,1.5,2,3.5)
        for beat in bass_beats:
            add(3,start+beat,root+(7 if beat==3.5 else 0),.85 if match else 1.6,
                (72 if match else 54)*energy)
        if match and not middle:
            # Strings move underneath long melodic notes, rather than pounding chords.
            for i in range(8):
                key = chord[[0,1,2,1,0,1,3,2][i]]
                add(10,start+i*.5,key,.26,((58 if bright else 49)+(5 if i%2==0 else 0))*energy)
                if bright: add(0,start+i*.5,key-12,.22,38)
            # A low electric-bass figure and occasional guitar dyads give rivalry
            # its forward drive within the string/piano score (owner reference set).
            if not opening and bar % 2 == 0:
                for key in (root+12, root+19):
                    add(11,start,key,.65,43*energy)
                    add(11,start+2.5,key,.3,36*energy)
            for beat in (0,2): add(9,start+beat,36,.10,64*energy)
            for beat in (1,3): add(9,start+beat,38,.12,46*energy)
            for beat in (0.5,1.5,2.5,3.5): add(9,start+beat,42,.07,28*energy)
            if bar%4==0:
                add(6,start,root+12,.8,62*energy)
            if bright and bar%2==0:
                for key in chord[1:3]: add(5,start+.03,key,2.8,52)
            if bar in (8,24,32): add(9,start,49,.18,37)
        else:
            # The room keeps an acoustic pulse and an open, expectant melody.
            for i,beat in enumerate((.5,1.5,2.5,3.5)):
                add(2,start+beat,chord[i]+(0 if middle else 12),.65,40*energy)
            if not middle:
                for beat in (1,3): add(9,start+beat,38,.14,26)
                add(9,start,36,.12,25)
        if bar%8==7 and not middle and match:
            for i in range(4): add(9,start+3+i*.25,38,.09,31+i*5)
    return bpm,bars*4,notes


def midi(path, match=False, intro=False):
    bpm,beats,notes = compose(match,intro)
    events = [(0,b'\xff\x51\x03'+int(60000000/bpm).to_bytes(3,'big'))]
    for ch,program in PROGRAMS.items():
        chosen = 33 if ch == 3 and match else (40 if ch == 9 and not match else program)
        events.extend([(0,bytes([0xc0|ch,chosen])),
                       (0,bytes([0xb0|ch,10,PANS[ch]]))])
    for ch,beat,key,duration,velocity in notes:
        on=round(beat*PPQ);off=min(round((beat+duration)*PPQ),round(beats*PPQ)-1)
        events.extend([(on,bytes([0x90|ch,key,round(velocity)])),(off,bytes([0x80|ch,key,0]))])
    events.sort(key=lambda e:e[0]);data=bytearray();previous=0
    for tick,message in events:
        data+=vlq(tick-previous)+message;previous=tick
    data+=vlq(round(beats*PPQ)-previous)+b'\xff\x2f\x00'
    path.write_bytes(b'MThd'+struct.pack('>IHHH',6,0,1,PPQ)+b'MTrk'+struct.pack('>I',len(data))+data)
    return beats*60/bpm
