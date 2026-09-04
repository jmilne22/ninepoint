"""Synthesises every sound in the game.

No sample library, no external service. A Go stone on a wooden board makes a
short, bright, woody knock -- a pitched burst with a very fast decay over a
tiny noise transient -- and almost everything else here is a variation on that
idea. See ART_DIRECTION.md for the visual equivalent of this argument.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wav import Sound, RATE

SOUNDS = {}


def sound(name):
    def deco(fn):
        SOUNDS[name] = fn
        return fn
    return deco


# ----------------------------------------------------------------- the board
def _stone(base_freq, brightness=1.0, tau=0.045, seed=3):
    """A 'pachi': wood resonance plus a click of contact noise."""
    s = Sound.silence(0.13)
    # two resonances an odd interval apart read as wood rather than a bell
    s.mix(Sound.tone(base_freq, 0.13, "sine", 0.9).decay(tau))
    s.mix(Sound.tone(base_freq * 2.71, 0.13, "sine", 0.28).decay(tau * 0.5))
    s.mix(Sound.tone(base_freq * 0.5, 0.13, "sine", 0.22).decay(tau * 1.4))
    click = Sound.noise(0.012, 0.7, seed=seed).lowpass(5200 * brightness)
    click.decay(0.004)
    s.mix(click, 0.0, 1.0)
    return s.fade_edges(0.003).normalise(0.8)


@sound("stone_place")
def _():
    return _stone(760, 1.0)


@sound("stone_place_alt")
def _():
    return _stone(690, 0.92, seed=11)


@sound("capture")
def _():
    """Several stones lifted off and dropped in the lid."""
    s = Sound.silence(0.42)
    for i, (at, f, seed) in enumerate([(0.0, 820, 5), (0.055, 700, 9),
                                       (0.10, 900, 13), (0.17, 640, 17),
                                       (0.235, 780, 21)]):
        s.mix(_stone(f, 1.05, 0.035, seed).gain(0.75 - i * 0.08), at)
    return s.fade_edges().normalise(0.9)


@sound("illegal")
def _():
    """A dull refusal. Deliberately unpleasant but quiet."""
    s = Sound.tone(150, 0.16, "tri", 0.8).decay(0.05)
    s.mix(Sound.tone(97, 0.16, "sine", 0.5).decay(0.06))
    return s.lowpass(900).fade_edges().normalise(0.55)


@sound("pass")
def _():
    """A soft two-note fall: nothing happened, and that was on purpose."""
    s = Sound.silence(0.34)
    s.mix(Sound.tone(520, 0.16, "sine", 0.6).decay(0.07), 0.0)
    s.mix(Sound.tone(392, 0.22, "sine", 0.6).decay(0.09), 0.10)
    return s.fade_edges().normalise(0.5)


@sound("game_win")
def _():
    s = Sound.silence(0.9)
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        s.mix(Sound.tone(f, 0.5, "tri", 0.55).decay(0.22), i * 0.11)
    return s.fade_edges().normalise(0.7)


@sound("game_lose")
def _():
    s = Sound.silence(0.9)
    for i, f in enumerate([466.16, 392.0, 311.13]):
        s.mix(Sound.tone(f, 0.55, "tri", 0.55).decay(0.26), i * 0.15)
    return s.lowpass(2600).fade_edges().normalise(0.6)


# -------------------------------------------------------------------- the town
def _footstep(seed, cutoff, thump=0.35, tau=0.018, body=120):
    s = Sound.noise(0.075, 0.9, seed=seed).lowpass(cutoff)
    s.decay(tau)
    s.mix(Sound.tone(body, 0.075, "sine", thump).decay(0.02))
    return s.fade_edges(0.002).normalise(0.32)


@sound("step_a")
def _():
    return _footstep(31, 1500)


@sound("step_b")
def _():
    return _footstep(37, 1250)


# Surface variants. The Soundscape picks the pair from the tile under the
# player's feet: floorboards in De Ketel must not sound like the wet cobbles
# outside it, and that difference is most of what tells you you are indoors.
@sound("step_wood_a")
def _():
    """Floorboards: hollow, so the body of the sound is lower and lasts."""
    return _footstep(53, 900, thump=0.55, tau=0.026, body=90)


@sound("step_wood_b")
def _():
    return _footstep(59, 780, thump=0.50, tau=0.028, body=84)


@sound("step_gravel_a")
def _():
    """Grit: bright, short, almost no body at all."""
    return _footstep(67, 3600, thump=0.12, tau=0.011)


@sound("step_gravel_b")
def _():
    return _footstep(71, 3100, thump=0.10, tau=0.013)


@sound("door")
def _():
    """A latch and a swing."""
    s = Sound.silence(0.5)
    s.mix(Sound.noise(0.03, 0.8, seed=41).lowpass(3000).decay(0.008), 0.0)
    creak = Sound.tone(220, 0.34, "saw", 0.22, detune=-60).decay(0.16)
    s.mix(creak.lowpass(1400), 0.04)
    s.mix(Sound.tone(90, 0.12, "sine", 0.5).decay(0.05), 0.33)
    return s.fade_edges().normalise(0.5)


@sound("blip")
def _():
    """One character of dialogue. Must survive being heard a thousand times."""
    s = Sound.tone(680, 0.035, "square", 0.35).decay(0.012)
    return s.lowpass(2400).fade_edges(0.002).normalise(0.22)


@sound("ui_move")
def _():
    s = Sound.tone(880, 0.045, "tri", 0.4).decay(0.018)
    return s.fade_edges(0.002).normalise(0.3)


@sound("ui_confirm")
def _():
    s = Sound.silence(0.2)
    s.mix(Sound.tone(660, 0.09, "tri", 0.5).decay(0.04), 0.0)
    s.mix(Sound.tone(990, 0.12, "tri", 0.45).decay(0.05), 0.055)
    return s.fade_edges().normalise(0.42)


@sound("toast")
def _():
    s = Sound.silence(0.28)
    s.mix(Sound.tone(784, 0.12, "sine", 0.5).decay(0.06), 0.0)
    s.mix(Sound.tone(1046.5, 0.16, "sine", 0.4).decay(0.07), 0.07)
    return s.fade_edges().normalise(0.4)


@sound("rank_up")
def _():
    s = Sound.silence(1.0)
    for i, f in enumerate([392.0, 523.25, 659.25, 783.99, 1046.5]):
        s.mix(Sound.tone(f, 0.45, "tri", 0.5).decay(0.2), i * 0.09)
    return s.fade_edges().normalise(0.65)


# --------------------------------------------------------------------- music
@sound("theme_club")
def _():
    """De Ketel. Dark wood, a coal stove, and Tomas, who is hospitable.

    F major pentatonic, and it cannot go sour. Still slow and unhurried --
    this plays under thinking, and thinking is the point -- but it was in D
    minor before, which made the warmest room in the game sound like the
    saddest. A bar you like being in is not a sad place.
    """
    bpm = 60.0
    beat = 60.0 / bpm
    bars = 8
    s = Sound.silence(bars * 4 * beat)

    _voice(s, [
        (0, "A4", 2), (2, "C5", 2),
        (4, "D5", 3), (7, "C5", 1),
        (8, "A4", 2), (10, "G4", 2),
        (12, "F4", 4),
        (16, "C5", 2), (18, "D5", 2),
        (20, "F5", 3), (23, "D5", 1),
        (24, "C5", 2), (26, "A4", 2),
        (28, "F4", 4),
    ], beat, wave="tri", amp=0.29, harm=2.0, harm_amp=0.08,
        attack=0.05, decay=0.2, sustain=0.55, release=0.5, cutoff=2200)

    _bass(s, ["F2", "C3", "D3", "A2"], beat, bars_each=2, amp=0.15)
    return s.lowpass(3200).fade_edges(0.05).normalise(0.5)


@sound("theme_street")
def _():
    """Ketelsteeg: the hub, and the track the player hears more than any other.

    G major pentatonic. It used to be A minor and slower, which made a working
    street in the afternoon sound like a funeral -- the single biggest reason
    the game came across as unrelievedly bleak. Outdoors should feel like
    somewhere you are passing through, so it still leaves long gaps rather than
    filling them; it is the key that changed, not the sparseness.
    """
    bpm = 72.0
    beat = 60.0 / bpm
    bars = 8
    s = Sound.silence(bars * 4 * beat)

    _voice(s, [
        (0, "D5", 2), (3, "E5", 1), (4, "G5", 2),
        (7, "E5", 1), (8, "D5", 3),
        (12, "B4", 4),
        (17, "D5", 2), (20, "E5", 2), (22, "D5", 2),
        (25, "B4", 2), (28, "G4", 4),
    ], beat, wave="sine", amp=0.26, harm=1.5, harm_amp=0.06,
        attack=0.06, decay=0.25, sustain=0.5, release=0.55, cutoff=2900)

    _bass(s, ["G2", "D3", "E3", "C3"], beat, bars_each=2, amp=0.12)
    return s.lowpass(3400).fade_edges(0.05).normalise(0.42)


@sound("theme_night")
def _():
    """Ketelsteeg after dark. The same street, an hour when nobody is on it.

    Same key and tempo as theme_street so the two can swap at a time change
    without the city seeming to become a different place -- but it sits on the
    relative minor of the same five notes, an octave down, with longer gaps.
    Night is allowed to be wistful. The afternoon was not.
    """
    bpm = 72.0
    beat = 60.0 / bpm
    bars = 8
    s = Sound.silence(bars * 4 * beat)

    _voice(s, [
        (0, "B3", 4),
        (6, "D4", 2),
        (10, "E4", 3),
        (14, "B3", 2),
        (18, "G3", 4),
        (24, "A3", 2),
        (27, "B3", 4),
    ], beat, wave="sine", amp=0.24, harm=2.0, harm_amp=0.05,
        attack=0.14, decay=0.35, sustain=0.45, release=0.8, cutoff=2000)

    for bar in range(0, bars, 2):
        root = "E2" if bar % 4 == 0 else "G2"
        drone = Sound.tone(n(root), 8 * beat, "sine", 0.10)
        drone.env(attack=0.8, decay=0.4, sustain=0.6, release=1.6)
        s.mix(drone.lowpass(800), bar * 4 * beat)

    return s.lowpass(2600).fade_edges(0.05).normalise(0.36)


@sound("amb_rain")
def _():
    """Drizzle. Filtered noise, and no drops: individual drops read as static.

    This wants to loop, and for a long time it did not: it ended in
    fade_edges(0.4), which fades in *and* out, so the bed dipped to silence
    once every six seconds. loopify() crossfades the tail back over the head
    instead, which is the only version of this that survives being left on.
    """
    s = Sound.noise(6.0, 0.5, seed=7).lowpass(1400).highpass(180)
    # a slow breathing, so six seconds of it does not sound like a machine
    for i in range(6):
        gust = Sound.noise(1.0, 0.16, seed=20 + i).lowpass(900)
        gust.env(attack=0.4, decay=0.2, sustain=0.6, release=0.4)
        s.mix(gust, i * 1.0)
    # A bed sits under the music, not beside it: 0.30 put the rain within 4 dB
    # of the track it was supposed to be underneath.
    return s.loopify(0.5).normalise(0.16)


@sound("amb_tram")
def _():
    """A tram going past: rail rumble, and the wires singing over the top."""
    s = Sound.silence(2.6)
    rumble = Sound.noise(2.2, 0.7, seed=11).lowpass(320)
    rumble.env(attack=0.6, decay=0.3, sustain=0.7, release=0.9)
    s.mix(rumble, 0.1)
    # the overhead line, which is the part you actually recognise
    for i, f in enumerate((523.25, 587.33)):
        wire = Sound.tone(f, 1.1, "sine", 0.07)
        wire.env(attack=0.35, decay=0.2, sustain=0.5, release=0.5)
        s.mix(wire.lowpass(2600), 0.5 + i * 0.35)
    squeal = Sound.tone(1244.51, 0.5, "tri", 0.05).decay(0.18)
    s.mix(squeal.highpass(700), 1.5)
    return s.fade_edges(0.05).normalise(0.34)


@sound("amb_gull")
def _():
    """One gull, twice. It is a port; there is always one."""
    s = Sound.silence(1.6)
    for at, f in ((0.0, 880.0), (0.55, 830.0)):
        cry = Sound.tone(f, 0.34, "saw", 0.16)
        cry.mix(Sound.tone(f * 1.5, 0.34, "sine", 0.05))
        cry.env(attack=0.03, decay=0.12, sustain=0.4, release=0.16)
        s.mix(cry.lowpass(2400).highpass(400), at)
    return s.fade_edges(0.02).normalise(0.30)


# ------------------------------------------------------------------- music
#
# Melodies are written as (start_beat, note, length_beats). Note *names*, not
# frequencies: a list of magic numbers cannot be read as music, and every one of
# these was edited a dozen times before it sounded like anything.

_SEMI = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
         "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def n(name):
    """n("A4") -> 440.0. Equal temperament, A4 = 440."""
    semis = _SEMI[name[:-1]] + (int(name[-1]) - 4) * 12 - 9
    return 440.0 * (2.0 ** (semis / 12.0))


def _voice(s, melody, beat, wave="tri", amp=0.28, harm=2.0, harm_amp=0.08,
           attack=0.05, decay=0.22, sustain=0.55, release=0.5, cutoff=2200,
           hold=0.95):
    """Lay a melody into a buffer. One note, one envelope, one harmonic.

    The harmonic is what stops a bare oscillator sounding like a test tone; a
    fifth (1.5) is warm and an octave (2.0) is bright.
    """
    for start, note_name, length in melody:
        dur = length * beat * hold
        note = Sound.tone(n(note_name), dur, wave, amp)
        if harm_amp > 0.0:
            note.mix(Sound.tone(n(note_name) * harm, dur, "sine", harm_amp))
        note.env(attack=attack, decay=decay, sustain=sustain,
                 release=length * beat * release)
        s.mix(note.lowpass(cutoff), start * beat)
    return s


def _bass(s, roots, beat, bars_each=2, amp=0.15, wave="sine", cutoff=900):
    """A held root every `bars_each` bars, cycling through `roots`."""
    span = bars_each * 4 * beat
    for i, root in enumerate(roots):
        note = Sound.tone(n(root), span, wave, amp)
        note.env(attack=0.5, decay=0.3, sustain=0.7, release=span * 0.5)
        s.mix(note.lowpass(cutoff), i * span)
    return s


# ------------------------------------------------------------------ percussion
#
# Nothing in the soundtrack had a drum in it until the battle themes: the town
# tracks are beds and a bed with a backbeat is not a bed. A game that counts is
# a different matter, and the difference between "music playing" and "a fight"
# is almost entirely the kick.

## tools/check_melody.py renders with this off, so its Goertzel probe hears the
## tune rather than a snare. A broadband hit under a note is exactly what a
## pitch detector cannot see past.
DRUMS = True

## Each theme records its lead line here as it renders, so check_melody.py can
## compare what came out of the wav against what was written, without the
## melodies having to live somewhere other than the track that owns them.
LEADS = {}


def _kick(amp=0.6):
    """A kick is a pitch sweep, not a low note: 110 Hz falling to 38 in a sixth
    of a second. Sound.tone's `detune` ramps the frequency across the buffer,
    which is what it was there for. The steady tone underneath is the part you
    feel rather than hear on a laptop speaker.
    """
    s = Sound.tone(110.0, 0.16, "sine", amp, detune=-72.0)
    s.decay(0.055)
    s.mix(Sound.tone(58.0, 0.16, "sine", amp * 0.4).decay(0.09))
    return s


def _snare(seed=101, amp=0.42):
    """Noise for the wires and a short tuned body under it for the drum. The
    same shape as _footstep -- a burst over a thump -- opened out and pitched up.
    """
    s = Sound.noise(0.13, amp, seed=seed).highpass(900).lowpass(6500)
    s.decay(0.05)
    s.mix(Sound.tone(190.0, 0.13, "tri", amp * 0.3).decay(0.035))
    return s


def _hat(seed=202, amp=0.2, tau=0.014):
    """Filtered noise with almost no tail. Kept below the master lowpass of the
    fast tracks on purpose: a hat you can pick out is a hat that is too loud.
    """
    return Sound.noise(0.06, amp, seed=seed).highpass(3800).decay(tau)


def _drums(s, beat, bars, kick="", snare="", hat="", amp=1.0, seed=1):
    """Lay a drum pattern into a buffer.

    One string per voice, sixteen characters, one per semiquaver -- a tracker
    grid, for the same reason melodies are written as note names: `"x...x..."`
    reads as a rhythm and a list of beat offsets does not. `x` is a hit, `X` is
    an accented one, and `.` or a space is nothing. The pattern repeats for
    every bar.

    The three hits are synthesised once each and mixed in repeatedly. wav.py is
    per-sample pure Python, so rebuilding a hat 128 times is the difference
    between a build measured in seconds and one measured in minutes -- and
    Sound.mix() only reads its argument, so one buffer is safe to reuse.
    """
    if not DRUMS:
        return s
    step = beat / 4.0
    for pattern, hit in ((kick, _kick()), (snare, _snare(seed=seed + 1)),
                         (hat, _hat(seed=seed + 2))):
        if not pattern:
            continue
        for bar in range(bars):
            for i, ch in enumerate(pattern):
                if ch in ". ":
                    continue
                at = (bar * 4 * beat) + i * step
                s.mix(hit, at, gain=amp * (1.35 if ch == "X" else 1.0))
    return s


def _pulse_bass(s, roots, beat, bars, per_beat=2, amp=0.20, wave="tri",
                cutoff=1000, hold=0.42):
    """A bass that moves, as against _bass()'s held root.

    _bass is right for a town: one note a bar, sitting under everything. A game
    that counts wants the pulse, and the pulse is the whole difference between
    theme_match and theme_battle -- the notes are barely busier, the *rate* is.
    One note is synthesised per distinct root and mixed in repeatedly.
    """
    voices = {}
    span = beat / per_beat
    for bar in range(bars):
        root = roots[bar % len(roots)]
        if root not in voices:
            note = Sound.tone(n(root), span * hold * per_beat, wave, amp)
            note.env(attack=0.005, decay=0.06, sustain=0.35, release=span * 0.4)
            voices[root] = note.lowpass(cutoff)
        for i in range(4 * per_beat):
            s.mix(voices[root], bar * 4 * beat + i * span)
    return s


@sound("theme_institute")
def _():
    """The Essenveld Instituut: glass, concrete and timetables.

    All four Instituut rooms used to play theme_club -- the same track as the
    bar three steps below the pavement in Steenbeek -- which flattened the one
    opposition the whole setting is built on. This is the daylight half: A major
    pentatonic, brisk, and carrying a steady quaver tick underneath that is
    frankly the timetable. Nothing here is sad; the Instituut does not think
    anything is wrong.
    """
    bpm = 84.0
    beat = 60.0 / bpm
    bars = 8
    s = Sound.silence(bars * 4 * beat)

    _voice(s, [
        (0, "E5", 1), (1, "F#5", 1), (2, "A5", 2),
        (4, "F#5", 1), (5, "E5", 1), (6, "C#5", 2),
        (8, "B4", 1), (9, "C#5", 1), (10, "E5", 2),
        (12, "C#5", 4),
        (16, "E5", 1), (17, "F#5", 1), (18, "A5", 2),
        (20, "B5", 2), (22, "A5", 2),
        (24, "F#5", 1), (25, "E5", 1), (26, "C#5", 2),
        (28, "A4", 4),
    ], beat, wave="tri", amp=0.26, harm=2.0, harm_amp=0.06, cutoff=3000)

    # the tick: an arpeggio on the half-beat, quiet enough to be a floor rather
    # than a part. This is the difference between "a school" and "a bar".
    tick = ["A3", "C#4", "E4", "C#4"]
    for i in range(bars * 8):
        note = Sound.tone(n(tick[i % 4]), beat * 0.4, "sine", 0.055)
        note.env(attack=0.01, decay=0.08, sustain=0.3, release=beat * 0.3)
        s.mix(note.lowpass(2400), i * beat * 0.5)

    _bass(s, ["A2", "F#2", "D3", "E3"], beat, bars_each=2, amp=0.14)
    return s.lowpass(3600).fade_edges(0.05).normalise(0.44)


@sound("theme_match")
def _():
    """Under a game of Go: the most important track here and the one that must
    least be noticed.

    A minor pentatonic, but it leans on C and ends on G rather than falling back
    to the root -- so it reads as *focused* rather than as sad. That distinction
    is the whole brief. A game of Go is tense and absorbing; it is not a
    bereavement, and the first version of this scored it like one.

    Still only eight notes in half a minute, with a low pulse every fourth beat
    that is closer to a clock than a part. Anything busier competes with reading
    the position, which is the one thing the player is here to do.
    """
    bpm = 58.0
    beat = 60.0 / bpm
    bars = 8
    s = Sound.silence(bars * 4 * beat)

    _voice(s, [
        (0, "E4", 3),
        (4, "G4", 2),
        (7, "A4", 3),
        (12, "C5", 4),
        (17, "A4", 2),
        (20, "G4", 2),
        (23, "E4", 3),
        (27, "G4", 4),
    ], beat, wave="sine", amp=0.22, harm=2.0, harm_amp=0.05,
        attack=0.15, decay=0.35, sustain=0.45, release=0.8, cutoff=2100)

    for i in range(bars):
        pulse = Sound.tone(n("A2"), beat * 2.2, "sine", 0.12)
        pulse.env(attack=0.45, decay=0.4, sustain=0.4, release=beat * 1.1)
        s.mix(pulse.lowpass(520), i * 4 * beat)

    return s.lowpass(2800).fade_edges(0.06).normalise(0.36)


@sound("theme_quay")
def _():
    """Grey water and one bench, south past the park. Where you go after losing.

    The quay shipped silent, which read as an asset that had not been made
    rather than as quiet. D minor, slower than anything else in the game, and
    the phrase falls every time and never resolves -- it ends on the fifth, in
    the wrong octave, and then the loop starts it over.
    """
    bpm = 50.0
    beat = 60.0 / bpm
    bars = 8
    s = Sound.silence(bars * 4 * beat)

    _voice(s, [
        (0, "A4", 3), (4, "F4", 2), (7, "D4", 4),
        (12, "E4", 3),
        (16, "F4", 2), (19, "D4", 2), (22, "C4", 4),
        (27, "A3", 5),
    ], beat, wave="sine", amp=0.24, harm=1.5, harm_amp=0.05,
        attack=0.22, decay=0.45, sustain=0.42, release=0.8, cutoff=1700)

    # two drones a fifth apart, one of them very slightly sharp. The beating
    # between them is slow and uneven, which is the water.
    for bar in range(0, bars, 4):
        for freq, amp in ((n("D2"), 0.13), (n("A2") * 1.004, 0.09)):
            drone = Sound.tone(freq, 16 * beat, "sine", amp)
            drone.env(attack=2.0, decay=0.8, sustain=0.7, release=3.0)
            s.mix(drone.lowpass(700), bar * 4 * beat)

    return s.lowpass(2400).fade_edges(0.08).normalise(0.32)


@sound("theme_arches")
def _():
    """Onderbrug: crates for tables, cash on the crate, and nobody asking to
    see your papers.

    The arches used to play the street's theme, so the one place in the game
    with no rules sounded exactly like the pavement above it. A walking bass on
    every beat -- the only steady pulse in the soundtrack -- with the melody
    landing late and off the beat. E minor pentatonic, and it swings, because
    the money table is the one place in Verhaven having a good time.
    """
    bpm = 68.0
    beat = 60.0 / bpm
    bars = 8
    s = Sound.silence(bars * 4 * beat)

    walk = ["E2", "G2", "A2", "B2", "D3", "B2", "A2", "G2"]
    for i in range(bars * 4):
        note = Sound.tone(n(walk[i % 8]), beat * 0.85, "tri", 0.20)
        note.env(attack=0.02, decay=0.15, sustain=0.45, release=beat * 0.5)
        s.mix(note.lowpass(1100), i * beat)

    _voice(s, [
        (0, "B4", 2), (3.5, "D5", 1), (5, "B4", 1), (6, "A4", 2),
        (10, "G4", 2), (13.5, "E4", 2),
        (16, "B4", 2), (19.5, "D5", 1), (21, "E5", 2),
        (24, "D5", 1), (25, "B4", 1), (26, "A4", 2), (29, "E4", 3),
    ], beat, wave="tri", amp=0.22, harm=2.0, harm_amp=0.05,
        attack=0.03, decay=0.2, sustain=0.4, release=0.45, cutoff=2400)

    return s.lowpass(3000).fade_edges(0.05).normalise(0.40)


@sound("theme_title")
def _():
    """The title screen. D major, and it means it.

    Written minor first, which was wrong: this is the first thing anybody hears
    and it was setting the whole game up as a lament. Ninepoint is about getting
    better at something, which is a hopeful subject. The phrase still climbs to
    the ninth and holds -- the title refers to the nine star points -- but it
    now climbs in a key that sounds like arriving somewhere.
    """
    bpm = 76.0
    beat = 60.0 / bpm
    bars = 8
    s = Sound.silence(bars * 4 * beat)

    melody = [
        (0, "D4", 1), (1, "F#4", 1), (2, "A4", 2),
        (4, "B4", 1), (5, "A4", 1), (6, "D5", 2),
        (8, "A4", 1), (9, "B4", 1), (10, "A4", 1), (11, "F#4", 1),
        (12, "E4", 4),
        (16, "F#4", 1), (17, "A4", 1), (18, "B4", 2),
        (20, "D5", 2), (22, "E5", 2),
        (24, "D5", 2), (26, "B4", 2),
        (28, "A4", 4),
    ]
    _voice(s, melody, beat, wave="tri", amp=0.27, harm=1.5, harm_amp=0.09,
           attack=0.03, decay=0.22, sustain=0.6, release=0.55, cutoff=3000)
    _voice(s, [(st + 0.04, nm, ln) for st, nm, ln in melody], beat,
           wave="sine", amp=0.07, harm_amp=0.0,
           attack=0.09, decay=0.3, sustain=0.45, release=0.6, cutoff=3600)

    # D - A - B minor - G. The most reassuring four chords there are, and the
    # reason this reads as confident rather than merely fast.
    _bass(s, ["D2", "A2", "B2", "G2"], beat, bars_each=2, amp=0.16)
    return s.lowpass(3600).fade_edges(0.05).normalise(0.46)


@sound("amb_room")
def _():
    """Indoors, with the music off. Almost nothing -- a low hiss and the hum
    of a room somebody is in. It exists because a bar with no bed under it
    sounds like a vacuum, and you notice the vacuum more than the room.
    """
    # Almost all hum and almost no hiss. The first version lowpassed at 420 and
    # normalised to 0.16, which put broadband noise about 11 dB under the music
    # -- and broadband noise at that level does not read as "a room", it reads
    # as a tap left running in the next room. Filtered far lower and dropped to
    # a third of the level, it reads as the building.
    s = Sound.noise(5.0, 0.5, seed=53).lowpass(260)
    s.mix(Sound.tone(96.0, 5.0, "sine", 0.06))
    s.mix(Sound.tone(143.0, 5.0, "sine", 0.03))
    return s.loopify(0.6).normalise(0.05)


@sound("amb_canal")
def _():
    """Water against a quay wall: slow, irregular, and nearly all low end.

    The laps are deliberately not evenly spaced -- a metronome of water is the
    giveaway that a loop is a loop.
    """
    s = Sound.noise(7.0, 0.22, seed=61).lowpass(700).highpass(90)
    for i, at in enumerate((0.4, 2.1, 3.4, 5.2, 6.1)):
        lap = Sound.noise(0.9, 0.5, seed=70 + i).lowpass(520).highpass(140)
        lap.env(attack=0.25, decay=0.3, sustain=0.4, release=0.35)
        s.mix(lap, at)
    return s.loopify(0.7).normalise(0.12)


@sound("tram_bell")
def _():
    """A tram bell is a small hard bell hit once: the same construction as a
    stone on a board, an octave and a half up and allowed to ring."""
    s = Sound.silence(1.1)
    for f, amp, tau in ((1046.50, 0.90, 0.36), (2811.0, 0.30, 0.16), (4200.0, 0.12, 0.07)):
        s.mix(Sound.tone(f, 1.1, "sine", amp).decay(tau))
    s.mix(Sound.noise(0.008, 0.5, seed=83).lowpass(7000).decay(0.003))
    return s.fade_edges(0.004).normalise(0.30)


@sound("stove_crackle")
def _():
    """The coal stove at De Ketel. Four ticks, no two the same length, because
    evenly spaced ticks read as a clock rather than as a fire."""
    s = Sound.silence(0.9)
    for i, (at, amp) in enumerate(((0.0, 0.9), (0.13, 0.4), (0.38, 0.7), (0.62, 0.35))):
        tick = Sound.noise(0.03, amp, seed=90 + i).lowpass(2600).highpass(500)
        tick.decay(0.006)
        s.mix(tick, at)
    return s.fade_edges(0.004).normalise(0.20)


@sound("fryer")
def _():
    """The snack window on Ketelsteeg. Hot fat is bright noise that swells."""
    s = Sound.noise(1.4, 0.6, seed=97).lowpass(5200).highpass(1200)
    s.env(attack=0.25, decay=0.3, sustain=0.6, release=0.6)
    return s.fade_edges(0.02).normalise(0.16)


@sound("washer")
def _():
    """A front-loader in the wassalon. A motor holding one low note, and the
    load coming round twice -- unevenly, because a load is never balanced.

    The room has no music and no stove, so the machines are the whole of its
    noise. Two thumps and not four, for the same reason stove_crackle uses
    uneven ticks: an even one reads as a rhythm you start counting, and this
    is meant to be furniture you stop hearing.
    """
    s = Sound.noise(1.7, 0.30, seed=113).lowpass(420).highpass(60)
    s.env(attack=0.35, decay=0.40, sustain=0.70, release=0.50)
    s.mix(Sound.tone(78.0, 1.7, "sine", 0.10))     # the motor, on one note
    s.mix(Sound.tone(117.0, 1.7, "sine", 0.04))
    for i, at in enumerate((0.22, 0.94)):
        thump = Sound.noise(0.14, 0.7, seed=120 + i).lowpass(300).highpass(50)
        thump.env(attack=0.01, decay=0.06, sustain=0.30, release=0.08)
        s.mix(thump, at)
    return s.fade_edges(0.02).normalise(0.14)


@sound("pigeons")
def _():
    """Wings going up off a wet pavement: four beats, accelerating."""
    s = Sound.silence(0.9)
    for i, at in enumerate((0.0, 0.16, 0.29, 0.39)):
        beat = Sound.noise(0.09, 0.8, seed=101 + i).lowpass(1500).highpass(220)
        beat.env(attack=0.01, decay=0.03, sustain=0.3, release=0.05)
        s.mix(beat, at)
    return s.fade_edges(0.01).normalise(0.22)


# --------------------------------------------------------------- battle themes
#
# theme_match is written to be ignored, and that is right for a lesson, a puzzle
# and a game in the park. It is wrong for the rival who keeps score, for the man
# under the arches with no papers, and for the exam that ends Act 2, all of
# which used to sound exactly like a lesson. MatchMusic.theme_for() draws the
# line and it draws it where the day economy already drew one: a game that costs
# you an hour and goes on your record gets music, a free one gets the bed.
#
# These run 96-144 bpm against the town's 50-84. They are deliberately louder in
# the top end too (a master lowpass around 5000 rather than 2800), because the
# whole point is that the register changes when a game matters. What they do NOT
# change is the voice: the same oscillators, the same _voice() harmonic, the
# same normalise band, so a battle theme is recognisably this game's soundtrack
# playing faster rather than a track borrowed from a different one.


@sound("theme_battle")
def _():
    """A game that counts. E minor pentatonic at 132, and it is having a good
    time about it.

    The tune is not much busier than theme_match's -- eight bars of it would fit
    the same page. What changes is underneath: a bass on every quaver instead of
    a root once a bar, and a backbeat. Upbeat is a rhythm section decision, not a
    melodic one, which is why the melody can still leave room to read the board.

    Ends on the fifth rather than the root so the loop drives back round instead
    of arriving. Nothing in a game of Go has finished when the phrase does.
    """
    bpm = 132.0
    beat = 60.0 / bpm
    bars = 16
    s = Sound.silence(bars * 4 * beat)

    melody = [
        (0, "E5", 1), (1, "G5", 0.5), (1.5, "E5", 0.5), (2, "B4", 1), (3, "D5", 1),
        (4, "E5", 2), (6.5, "D5", 1.5),
        (8, "B4", 1), (9, "D5", 0.5), (9.5, "B4", 0.5), (10, "A4", 1), (11, "B4", 1),
        (12, "G4", 2), (14.5, "A4", 1.5),
        (16, "E5", 1), (17, "G5", 0.5), (17.5, "A5", 0.5), (18, "B5", 2),
        (20, "A5", 1), (21, "G5", 1), (22, "E5", 2),
        (24, "D5", 1), (25, "E5", 0.5), (25.5, "G5", 0.5), (26, "E5", 2),
        (28, "B4", 1.5), (29.5, "D5", 2.5),
        (32, "B5", 1), (33, "A5", 0.5), (33.5, "G5", 0.5), (34, "E5", 2),
        (36, "G5", 1), (37, "A5", 1), (38, "B5", 2),
        (40, "D6", 1), (41, "B5", 1), (42, "A5", 2),
        (44, "G5", 1), (45, "E5", 1), (46, "D5", 2),
        (48, "E5", 1), (49, "G5", 0.5), (49.5, "E5", 0.5), (50, "B4", 1), (51, "D5", 1),
        (52, "E5", 2), (54.5, "G5", 1.5),
        (56, "A5", 1), (57, "B5", 1), (58, "D6", 2),
        (60, "A5", 2), (62, "B5", 2),
    ]
    LEADS["theme_battle"] = melody
    _voice(s, melody, beat, wave="tri", amp=0.26, harm=2.0, harm_amp=0.07,
           attack=0.01, decay=0.12, sustain=0.5, release=0.3, cutoff=4000,
           hold=0.9)
    # The same doubling theme_title uses: a quiet sine four hundredths of a beat
    # late turns one oscillator into something with a body.
    _voice(s, [(st + 0.04, nm, ln) for st, nm, ln in melody], beat,
           wave="sine", amp=0.06, harm_amp=0.0,
           attack=0.02, decay=0.2, sustain=0.4, release=0.35, cutoff=4200)

    _pulse_bass(s, ["E2", "E2", "G2", "G2", "A2", "A2", "B2", "D3"],
                beat, bars, per_beat=2, amp=0.20)
    _drums(s, beat, bars,
           kick="X.......x...x...",
           snare="....X.......X...",
           hat="x.x.x.x.x.x.x.x.", seed=11)
    return s.lowpass(5000).fade_edges(0.05).normalise(0.46)


@sound("theme_battle_in")
def _():
    """Four beats that land on theme_battle's downbeat, played once as the board
    appears. Audio.play_music() finds this by the "<track>_in" convention, so an
    intro is added to any theme by adding a wav and nothing else.

    A rising fifth-and-octave stab over a noise swell -- the oldest trick there
    is for "something is about to start", and it works because the ear hears the
    swell stop rather than the note start.
    """
    bpm = 132.0
    beat = 60.0 / bpm
    s = Sound.silence(beat * 4.6)

    _voice(s, [(0, "E4", 0.5), (0.5, "B4", 0.5), (1, "E5", 0.5),
               (1.5, "G5", 0.5), (2, "B5", 2.4)], beat,
           wave="tri", amp=0.30, harm=2.0, harm_amp=0.10,
           attack=0.01, decay=0.1, sustain=0.55, release=0.5, cutoff=4200)
    # The swell fills the two beats before the landing and stops dead on it.
    swell = Sound.noise(beat * 2.0, 0.45, seed=77).lowpass(2600)
    swell.env(attack=beat * 1.92, decay=0.005, sustain=1.0, release=0.04)
    s.mix(swell, 0.0)
    _drums(s, beat, 1, kick="X...x...X.......", snare="............X...", seed=13)
    return s.lowpass(5000).fade_edges(0.02).normalise(0.46)


@sound("theme_rival")
def _():
    """Kesh. The battle theme, but it is him.

    Same key and same family as theme_battle on purpose, and it opens by quoting
    that track's first interval before going somewhere else -- Kesh is not a
    different kind of game, he is the game with someone in it who is counting.
    Twelve bpm faster, and the phrase ends on the flat seventh, so the cadence
    never closes. He keeps a record of your meetings; it is not over.
    """
    bpm = 144.0
    beat = 60.0 / bpm
    bars = 16
    s = Sound.silence(bars * 4 * beat)

    melody = [
        (0, "E5", 0.5), (0.5, "G5", 0.5), (1, "E5", 1), (2, "D5", 0.5),
        (2.5, "B4", 1.5),
        (4, "E5", 0.5), (4.5, "G5", 0.5), (5, "A5", 1), (6, "B5", 2),
        (8, "A5", 0.5), (8.5, "G5", 0.5), (9, "E5", 1), (10, "G5", 2),
        (12, "D5", 0.5), (12.5, "E5", 0.5), (13, "B4", 3),
        (16, "B5", 0.5), (16.5, "A5", 0.5), (17, "G5", 1), (18, "A5", 2),
        (20, "G5", 0.5), (20.5, "E5", 0.5), (21, "D5", 1), (22, "E5", 2),
        (24, "G5", 1), (25, "A5", 1), (26, "B5", 1), (27, "D6", 1),
        (28, "B5", 2), (30, "A5", 2),
        (32, "E5", 0.5), (32.5, "G5", 0.5), (33, "B5", 1), (34, "A5", 2),
        (36, "G5", 0.5), (36.5, "A5", 0.5), (37, "G5", 1), (38, "E5", 2),
        (40, "D5", 0.5), (40.5, "E5", 0.5), (41, "G5", 1), (42, "B5", 2),
        (44, "A5", 1), (45, "G5", 1), (46, "E5", 2),
        (48, "B5", 1), (49, "D6", 1), (50, "B5", 2),
        (52, "A5", 1), (53, "G5", 1), (54, "E5", 2),
        (56, "G5", 0.5), (56.5, "A5", 0.5), (57, "B5", 1), (58, "E5", 2),
        (60, "G5", 2), (62, "D5", 2),
    ]
    LEADS["theme_rival"] = melody
    _voice(s, melody, beat, wave="saw", amp=0.20, harm=2.0, harm_amp=0.06,
           attack=0.01, decay=0.1, sustain=0.45, release=0.28, cutoff=3400,
           hold=0.88)
    _voice(s, [(st + 0.05, nm, ln) for st, nm, ln in melody], beat,
           wave="tri", amp=0.10, harm_amp=0.0,
           attack=0.02, decay=0.18, sustain=0.4, release=0.3, cutoff=4200)

    _pulse_bass(s, ["E2", "E2", "D3", "D3", "G2", "G2", "A2", "B2"],
                beat, bars, per_beat=2, amp=0.21)
    # Busier than theme_battle's, and the extra kick lands off the beat: he is
    # ahead of you, which is his entire manner at the board.
    _drums(s, beat, bars,
           kick="X.....x.x.....x.",
           snare="....X.......X..X",
           hat="x.xxx.x.x.xxx.x.", seed=21)
    return s.lowpass(5200).fade_edges(0.05).normalise(0.47)


@sound("theme_rival_in")
def _():
    """Kesh sitting down. Three notes and a hit; he does not need longer."""
    bpm = 144.0
    beat = 60.0 / bpm
    s = Sound.silence(beat * 4.4)
    _voice(s, [(0, "B4", 0.5), (0.5, "E5", 0.5), (1, "G5", 0.5),
               (1.5, "B5", 2.6)], beat,
           wave="saw", amp=0.26, harm=2.0, harm_amp=0.08,
           attack=0.01, decay=0.09, sustain=0.5, release=0.5, cutoff=3800)
    _drums(s, beat, 1, kick="X...X...X.......", snare="........X...X..X", seed=23)
    return s.lowpass(5000).fade_edges(0.02).normalise(0.46)


@sound("theme_ghost")
def _():
    """Joos, under the arches. No card, no papers, and a rank he will not state.

    The heaviest thing in the game, and heavy is a rhythm: half time, kick on
    one and snare on three, so every bar has a hole in it that the riff falls
    into. C phrygian -- the flat second is the whole reason it sounds like a
    threat rather than a mood.

    There is almost no melody. One low saw riff, a bar long, repeated twelve
    times without developing, and a single high note held over the top that
    never moves. A theme that refuses to go anywhere is the correct theme for a
    man who will not tell you how strong he is.
    """
    bpm = 96.0
    beat = 60.0 / bpm
    bars = 12
    s = Sound.silence(bars * 4 * beat)

    # One bar, twelve times. The repetition is the character; resist adding a
    # variation to it, which is what the first version of this did and lost.
    riff = [(0, "C2", 0.5), (0.75, "C2", 0.25), (1.5, "C2", 0.5),
            (2, "D#2", 0.5), (2.5, "C2", 0.5), (3, "C#2", 1.0)]
    figure = [(st + bar * 4, nm, ln) for bar in range(bars) for st, nm, ln in riff]
    _voice(s, figure, beat, wave="saw", amp=0.26, harm=2.0, harm_amp=0.05,
           attack=0.004, decay=0.07, sustain=0.6, release=0.25, cutoff=900,
           hold=0.9)
    LEADS["theme_ghost"] = figure

    # The note over the top. It is the fifth, it never resolves, and it is only
    # just loud enough to notice you have been hearing it.
    for bar in range(0, bars, 4):
        held = Sound.tone(n("G5"), 16 * beat, "sine", 0.075)
        held.env(attack=2.2, decay=1.0, sustain=0.8, release=2.4)
        s.mix(held.lowpass(2600), bar * 4 * beat)

    _drums(s, beat, bars,
           kick="X...............",
           snare="........X.......",
           hat="x...x...x...x...", amp=1.1, seed=31)
    return s.lowpass(3200).fade_edges(0.06).normalise(0.44)


@sound("theme_ghost_in")
def _():
    """One hit and a silence, and then the riff. Nobody introduces Joos."""
    bpm = 96.0
    beat = 60.0 / bpm
    s = Sound.silence(beat * 4.2)
    _voice(s, [(0, "C2", 2.0), (2.5, "C#2", 1.5)], beat,
           wave="saw", amp=0.30, harm=2.0, harm_amp=0.05,
           attack=0.004, decay=0.1, sustain=0.55, release=0.5, cutoff=900)
    _drums(s, beat, 1, kick="X.......X.......", seed=33)
    return s.lowpass(3000).fade_edges(0.03).normalise(0.44)


@sound("theme_teacher")
def _():
    """Hana, five dan, actually playing you rather than teaching you.

    The one battle theme with no backbeat: hats and nothing else, because she is
    not fighting and pretending otherwise would be a lie about the character. F
    major, and the bass does not leave the tonic for four whole bars -- the
    harmony moves about a third as often as anything else here.

    It is still a battle theme. What makes it one is that it does not stop.
    """
    bpm = 88.0
    beat = 60.0 / bpm
    bars = 12
    s = Sound.silence(bars * 4 * beat)

    melody = [
        (0, "C5", 2), (2, "A4", 2),
        (4, "F4", 3), (7, "G4", 1),
        (8, "A4", 2), (10, "C5", 2),
        (12, "A4", 4),
        (16, "D5", 2), (18, "C5", 2),
        (20, "A4", 3), (23, "G4", 1),
        (24, "F4", 2), (26, "G4", 2),
        (28, "A4", 4),
        (32, "C5", 1), (33, "D5", 1), (34, "F5", 2),
        (36, "E5", 2), (38, "C5", 2),
        (40, "D5", 2), (42, "A4", 2),
        (44, "F4", 4),
    ]
    LEADS["theme_teacher"] = melody
    _voice(s, melody, beat, wave="tri", amp=0.25, harm=1.5, harm_amp=0.09,
           attack=0.05, decay=0.24, sustain=0.6, release=0.55, cutoff=2800)
    _voice(s, [(st + 0.05, nm, ln) for st, nm, ln in melody], beat,
           wave="sine", amp=0.07, harm_amp=0.0,
           attack=0.1, decay=0.3, sustain=0.5, release=0.6, cutoff=3200)

    # F, then B flat, then C: three chords in thirty-three seconds. Immovable.
    _bass(s, ["F2", "A#2", "C3"], beat, bars_each=4, amp=0.16)
    _drums(s, beat, bars, hat="x..xx..xx..xx..x", amp=0.55, seed=41)
    return s.lowpass(3600).fade_edges(0.06).normalise(0.42)


@sound("theme_wall")
def _():
    """Orla Finn, four kyu, top of the lower league. The wall.

    Four on the floor: a kick on every single beat, which is pressure rather
    than aggression, and the difference matters -- Orla does not attack you, she
    is simply still there. Four bars with no tune at all, just a two-note figure
    and the pulse, before anything resembling a melody arrives. When it does it
    is a scale walking up, and it gets cut off before it reaches the top. Twice.
    """
    bpm = 120.0
    beat = 60.0 / bpm
    bars = 16
    s = Sound.silence(bars * 4 * beat)

    melody = [
        # Four bars of the figure. Not a melody: a thing that keeps happening.
        (0, "A4", 1), (2, "E4", 1),
        (4, "A4", 1), (6, "E4", 1),
        (8, "A4", 1), (10, "E4", 1),
        (12, "A4", 1), (14, "E4", 1),
        # The scale. It gets to the seventh and stops.
        (16, "A4", 1), (17, "B4", 1), (18, "C5", 1), (19, "D5", 1),
        (20, "E5", 1), (21, "F5", 1), (22, "G5", 2),
        (24, "A4", 1), (26, "E4", 1), (28, "A4", 1), (30, "E4", 1),
        (32, "C5", 1), (33, "D5", 1), (34, "E5", 1), (35, "F5", 1),
        (36, "G5", 1), (37, "A5", 1), (38, "B5", 2),
        (40, "E5", 2), (42, "C5", 2),
        (44, "A4", 1), (46, "E4", 1),
        (48, "A4", 1), (49, "C5", 1), (50, "E5", 1), (51, "G5", 1),
        (52, "A5", 4),
        (56, "G5", 2), (58, "E5", 2),
        (60, "A4", 1), (62, "E4", 1),
    ]
    LEADS["theme_wall"] = melody
    _voice(s, melody, beat, wave="tri", amp=0.24, harm=2.0, harm_amp=0.06,
           attack=0.02, decay=0.14, sustain=0.5, release=0.35, cutoff=3400,
           hold=0.92)

    _pulse_bass(s, ["A2", "A2", "A2", "A2", "F2", "F2", "G2", "G2"],
                beat, bars, per_beat=2, amp=0.19)
    _drums(s, beat, bars,
           kick="X...x...x...x...",
           snare="....x.......x...",
           hat="..x...x...x...x.", amp=0.9, seed=51)
    return s.lowpass(4600).fade_edges(0.05).normalise(0.45)


@sound("theme_exam")
def _():
    """Marguerite Sable at the desk, and the qualifying exam she runs.

    This is theme_institute's key and theme_institute's quaver tick, and both
    have gone serious: the tick is now a dry unvarying quarter note, which is a
    clock, and the mode keeps flattening the third on its way past. She runs the
    league and she runs the exam, so the registrar's theme being the
    institution's theme is the truth about her rather than a shortcut.

    Restrained drums -- a kick twice a bar and nothing else. The clock is the
    percussion, and putting a hat over it would be arguing with it.
    """
    bpm = 100.0
    beat = 60.0 / bpm
    bars = 12
    s = Sound.silence(bars * 4 * beat)

    melody = [
        (0, "A4", 2), (2, "C#5", 1), (3, "E5", 1),
        (4, "F#5", 2), (6, "E5", 2),
        (8, "C5", 2), (10, "B4", 2),
        (12, "A4", 4),
        (16, "E5", 1), (17, "F#5", 1), (18, "A5", 2),
        (20, "G5", 2), (22, "E5", 2),
        (24, "C5", 1), (25, "B4", 1), (26, "A4", 2),
        (28, "B4", 4),
        (32, "C#5", 2), (34, "E5", 2),
        (36, "A5", 2), (38, "F#5", 2),
        (40, "E5", 2), (42, "C5", 2),
        (44, "A4", 4),
    ]
    LEADS["theme_exam"] = melody
    _voice(s, melody, beat, wave="tri", amp=0.25, harm=2.0, harm_amp=0.06,
           attack=0.03, decay=0.2, sustain=0.55, release=0.45, cutoff=3000)

    # The clock. One note, one level, on every beat, for the whole track. It is
    # meant to be slightly unpleasant by the third listen.
    tick = Sound.tone(n("E4"), beat * 0.3, "sine", 0.07)
    tick.env(attack=0.005, decay=0.06, sustain=0.25, release=beat * 0.2)
    tick = tick.lowpass(2600)
    for i in range(bars * 4):
        s.mix(tick, i * beat)

    _bass(s, ["A2", "F#2", "D3", "E3", "A2", "E3"], beat, bars_each=2, amp=0.15)
    _drums(s, beat, bars, kick="X.......x.......", amp=0.85, seed=61)
    return s.lowpass(3800).fade_edges(0.06).normalise(0.42)


@sound("theme_cup")
def _():
    """The Beginner Cup, at the Bondszaal. An occasion.

    D major, which is theme_title's key and is not a coincidence: the Cup is the
    first time the promise the title screen makes actually comes due, and the
    two tracks are meant to be relatives. Saw waves under a low cutoff and a
    slower attack, which is as close to brass as four oscillators get.

    The only theme here with a real fanfare in it. It is allowed: everything
    else in this game happens in a back room, and this happens in a hall.
    """
    bpm = 112.0
    beat = 60.0 / bpm
    bars = 16
    s = Sound.silence(bars * 4 * beat)

    melody = [
        (0, "D5", 1), (1, "F#5", 1), (2, "A5", 2),
        (4, "G5", 1), (5, "F#5", 1), (6, "E5", 2),
        (8, "F#5", 1), (9, "G5", 1), (10, "A5", 2),
        (12, "D5", 4),
        (16, "A5", 1), (17, "B5", 1), (18, "D6", 2),
        (20, "C#6", 2), (22, "A5", 2),
        (24, "B5", 1), (25, "A5", 1), (26, "G5", 2),
        (28, "F#5", 4),
        (32, "D5", 1), (33, "E5", 1), (34, "F#5", 1), (35, "G5", 1),
        (36, "A5", 2), (38, "B5", 2),
        (40, "A5", 1), (41, "F#5", 1), (42, "E5", 2),
        (44, "D5", 4),
        (48, "F#5", 1), (49, "A5", 1), (50, "D6", 2),
        (52, "B5", 2), (54, "G5", 2),
        (56, "A5", 2), (58, "F#5", 2),
        (60, "E5", 2), (62, "A5", 2),
    ]
    LEADS["theme_cup"] = melody
    _voice(s, melody, beat, wave="saw", amp=0.20, harm=2.0, harm_amp=0.07,
           attack=0.06, decay=0.2, sustain=0.65, release=0.4, cutoff=2000)
    # A third below, in the same voice. Two brass parts, not one with a chorus.
    thirds = {"D5": "A4", "E5": "B4", "F#5": "D5", "G5": "E5", "A5": "F#5",
              "B5": "G5", "C#6": "A5", "D6": "A5"}
    _voice(s, [(st, thirds.get(nm, nm), ln) for st, nm, ln in melody], beat,
           wave="saw", amp=0.11, harm=2.0, harm_amp=0.03,
           attack=0.07, decay=0.24, sustain=0.6, release=0.4, cutoff=1700)

    _pulse_bass(s, ["D2", "D2", "G2", "G2", "A2", "A2", "D2", "A2"],
                beat, bars, per_beat=1, amp=0.20, wave="sine", cutoff=800,
                hold=0.7)
    _drums(s, beat, bars,
           kick="X...x...X...x...",
           snare="....X..x....X.x.",
           hat="x.x.x.x.x.x.x.x.", amp=0.9, seed=71)
    return s.lowpass(4400).fade_edges(0.05).normalise(0.46)


@sound("theme_cup_in")
def _():
    """The hall going quiet. A rising fanfare and a roll into the downbeat."""
    bpm = 112.0
    beat = 60.0 / bpm
    s = Sound.silence(beat * 4.8)
    _voice(s, [(0, "D4", 0.5), (0.5, "A4", 0.5), (1, "D5", 0.5),
               (1.5, "F#5", 0.5), (2, "A5", 2.6)], beat,
           wave="saw", amp=0.26, harm=2.0, harm_amp=0.08,
           attack=0.05, decay=0.12, sustain=0.65, release=0.5, cutoff=2200)
    _drums(s, beat, 1, kick="X.......X.......",
           snare="........x.x.xxXx", seed=73)
    return s.lowpass(4400).fade_edges(0.03).normalise(0.46)


def build(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    written = []
    for name, fn in sorted(SOUNDS.items()):
        s = fn()
        path = os.path.join(out_dir, name + ".wav")
        s.save(path)
        written.append((name, round(s.seconds(), 3), round(s.peak(), 2)))
    return written


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    for row in build(os.path.join(here, "..", "audio")):
        print("%-16s %5.3fs peak %.2f" % row)
