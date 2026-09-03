"""Does each track actually play the notes it was written with?

The sibling of tools/check_lessons.py, which exists because a Go position you
wrote by eye is not a Go position you checked. The same is true of a melody: a
list of note names renders into a wav through _voice(), an envelope, a filter
and a normalise, and nothing between here and the speaker would notice an
octave typo, two notes landing on the same beat, or a phrase that was silently
truncated because its start beat ran off the end of the buffer.

A version of this was run once by hand during M17 and never committed, which is
why the check had to be rewritten to add the battle themes. It is committed now.

What this can and cannot tell you, stated plainly because the first version of
this file claimed more than it did and a check that overstates itself is worse
than no check:

  It CAN tell you the wav does not contain the note list. A note swamped by its
  own harmonic so the track sounds an octave up, a note a filter or an envelope
  quietly removed, a tempo that does not match the beats the melody was written
  in, and a note whose start beat lands past the end of the bar count -- all of
  those are the wav disagreeing with the list, and each was confirmed by
  breaking a track on purpose and watching this fail.

  That last one needs its own test rather than a pitch probe, because
  Sound.mix() extends the buffer to fit whatever you hand it: a note at beat 620
  of a 64-beat track is not lost, it just leaves four minutes of silence in the
  middle of a loop. Nothing else in the pipeline would mention it.

  It CANNOT tell you the note list is the tune you meant. The list is the spec:
  edit "E5" to "E4" and both the wav and the expectation move together, and this
  reports ok. Nothing mechanical can check that, and pretending otherwise is how
  you end up trusting a green gate. Reading the notes is still a person's job.

Method: render with percussion off (a broadband hit under a note is exactly what
a pitch detector cannot see past), then for each written note take a window from
inside its sustain and ask two questions of it. First, is the written pitch the
strongest reading -- against a semitone either side and an octave either way?
Second, is it actually there: its Goertzel energy against the window's own RMS,
which collapses when the note has been filtered away even though every candidate
falls together and the first test still passes it. It took a deliberately broken
render to notice the first test alone did not catch that.

    python3 tools/check_melody.py            # every track that registers a lead
    python3 tools/check_melody.py theme_cup  # just one
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_audio
from wav import RATE

## How far off the mark counts as wrong. The written note has to beat its best
## rival by this much, so a near-tie is a failure rather than a coin toss.
MARGIN = 1.35

## Where in the note to listen. The attack is a transient and the release
## overlaps whatever comes next, so both ends are useless.
WINDOW_START = 0.20
WINDOW_END = 0.75

## Below this the note is too short to resolve a semitone at its own pitch and
## is skipped rather than guessed at -- see _resolvable().
MIN_WINDOW = 0.045

## How much of a window's energy has to be at the written pitch for the note to
## count as present. Healthy notes across the seven battle themes measure 0.34
## to 0.60; a melody lowpassed into nothing measures under 0.02. The floor sits
## an order of magnitude below the quietest real note and well above the noise,
## because this test exists to catch an absent note, not to grade a mix.
PRESENT = 0.15


def goertzel(samples, rate, freq):
    """Energy at one frequency. The generalised form, which takes the exact
    frequency rather than rounding to a bin -- at 0.3 s a bin is 3.3 Hz wide and
    two semitones down at C2 are only 3.9 Hz apart, so rounding would decide the
    answer before the filter did.
    """
    w = 2.0 * math.pi * freq / rate
    cw, sw = math.cos(w), math.sin(w)
    coeff = 2.0 * cw
    s1 = s2 = 0.0
    for x in samples:
        s0 = x + coeff * s1 - s2
        s2, s1 = s1, s0
    return math.hypot(s1 - s2 * cw, s2 * sw) / max(1, len(samples))


def _semitones(freq, steps):
    return freq * (2.0 ** (steps / 12.0))


def _resolvable(freq, window_seconds):
    """Can a window this long tell this note from its neighbour at all?

    Frequency resolution is 1/T. A semitone at C2 is 3.9 Hz, which needs a
    quarter of a second; a semitone at C5 is 31 Hz and needs a thirtieth. A
    short low note is not a failure, it is out of this instrument's range.
    """
    return window_seconds * abs(_semitones(freq, 1) - freq) >= 1.0


def check_track(name, verbose=False):
    gen_audio.DRUMS = False
    try:
        s = gen_audio.SOUNDS[name]()
    finally:
        gen_audio.DRUMS = True
    melody = gen_audio.LEADS.get(name)
    if not melody:
        return ["%s registers no lead line in gen_audio.LEADS" % name]

    # The lead is written in beats; recover the seconds-per-beat from the track
    # itself, since a theme's bpm is a local in its own function.
    bpm = _bpm_for(name)
    beat = 60.0 / bpm
    bars = int(_declared(name, "bars"))

    problems = []
    # Sound.mix() grows the buffer rather than refusing, so a mistyped start
    # beat reads as a longer track and never as an error. Half a beat of slack
    # covers the last note's release tail.
    want_seconds = bars * 4 * beat
    if s.seconds() > want_seconds + beat * 0.5:
        problems.append(
            "%s: renders %.2fs but declares %d bars at %g bpm (%.2fs) -- a note "
            "is landing past the end and stretching the loop"
            % (name, s.seconds(), bars, bpm, want_seconds))

    checked = skipped = 0
    for start, note_name, length in melody:
        want = gen_audio.n(note_name)
        dur = length * beat
        a = int((start * beat + dur * WINDOW_START) * RATE)
        b = int((start * beat + dur * WINDOW_END) * RATE)
        b = min(b, len(s.s))
        seconds = (b - a) / float(RATE)
        if seconds < MIN_WINDOW or not _resolvable(want, seconds):
            skipped += 1
            continue
        if a >= len(s.s):
            problems.append("%s: %s at beat %g falls past the end of the buffer"
                            % (name, note_name, start))
            continue
        window = s.s[a:b]
        rms = math.sqrt(sum(v * v for v in window) / max(1, len(window)))
        scores = {}
        for label, steps in (("as written", 0), ("a semitone flat", -1),
                             ("a semitone sharp", 1),
                             ("an octave low", -12), ("an octave high", 12)):
            scores[label] = goertzel(window, RATE, _semitones(want, steps))
        best = max(scores, key=scores.get)
        rival = max(v for k, v in scores.items() if k != "as written")
        present = scores["as written"] / max(1e-9, rms)
        checked += 1
        if present < PRESENT:
            problems.append(
                "%s: %s at beat %g is barely in the wav at all (%.3f of the "
                "window's energy, floor %.2f)" % (name, note_name, start,
                                                  present, PRESENT))
        elif best != "as written" or scores["as written"] < rival * MARGIN:
            problems.append(
                "%s: %s at beat %g reads as %s (written %.4f, %s %.4f)"
                % (name, note_name, start, best, scores["as written"],
                   best, scores[best]))
        elif verbose:
            print("    %-4s beat %-6g ok (%.4f vs %.4f)"
                  % (note_name, start, scores["as written"], rival))
    return problems, checked, skipped


def _declared(name, field):
    """A track's own `bpm = ` or `bars = `, read back out of its source.

    Every theme opens with both, so this is exact rather than a guess -- and it
    stays exact when somebody retunes or lengthens a track, which a table
    duplicated over here would not.
    """
    import inspect
    prefix = field + " = "
    for line in inspect.getsource(gen_audio.SOUNDS[name]).splitlines():
        line = line.strip()
        if line.startswith(prefix):
            return float(line[len(prefix):].strip())
    raise SystemExit("check_melody: %s declares no %s" % (name, field))


def _bpm_for(name):
    return _declared(name, "bpm")


def main(argv):
    gen_audio.LEADS.clear()
    # Rendering is what registers a lead, so everything has to be built once
    # before we know which tracks have one to check.
    names = argv[1:]
    if not names:
        for key in sorted(gen_audio.SOUNDS):
            gen_audio.DRUMS = False
            try:
                gen_audio.SOUNDS[key]()
            except Exception:
                pass
            finally:
                gen_audio.DRUMS = True
        names = sorted(gen_audio.LEADS)
    if not names:
        raise SystemExit("check_melody: nothing registers a lead line")

    bad = 0
    for name in names:
        problems, checked, skipped = check_track(name)
        note = "" if not skipped else " (%d too low or short to resolve)" % skipped
        if problems:
            bad += len(problems)
            print("FAIL %-16s %d notes checked%s" % (name, checked, note))
            for p in problems:
                print("       " + p)
        else:
            print("ok   %-16s %d notes checked%s" % (name, checked, note))
    if bad:
        raise SystemExit("check_melody: %d note(s) did not render as written" % bad)
    print("check_melody: every written note is in the wav")


if __name__ == "__main__":
    main(sys.argv)
