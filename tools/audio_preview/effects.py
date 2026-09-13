"""Recorded wood/contact layers plus original damped board resonances."""
import numpy as np
from dsp import RATE, read, filter_audio, fade, normalize, write

FAMILIES = {'snap': (640, .042, .42), 'thunk': (390, .071, .68),
            'deep': (265, .093, .78), 'thwack': (780, .024, .28)}


def stone(source, contact, family, variant):
    if family == "thwack":
        return thwack(source, contact, variant)
    frequency, decay, body = FAMILIES[family]
    frequency *= 1 + (variant - 2.5) * .012
    size = round(.30 * RATE); t = np.arange(size) / RATE
    out = np.zeros(size)
    for layer, length, gain in [(source, .12, .65), (contact, .014, .20)]:
        # Trim source silence to place the recorded transient at the event.
        active = np.flatnonzero(np.abs(layer) > np.max(np.abs(layer)) * .08)
        layer = layer[active[0]:] if len(active) else layer
        layer = layer[:round(length * RATE)]
        layer = layer / max(1e-8, np.max(np.abs(layer)))
        out[:len(layer)] += layer * np.exp(-np.arange(len(layer))/RATE/.028) * gain
    for ratio, amp, tau in [(1, 1, 1), (2.63, .25, .4), (.48, .40, 1.2), (4.17, .08, .2)]:
        out += np.sin(2*np.pi*frequency*ratio*t) * np.exp(-t/(decay*tau)) * body * amp
    return fade(filter_audio(out, 8500), .0006)


def thwack(source, contact, variant):
    """A palm-like broad attack and hard contact, followed by a dry wooden body."""
    rng = np.random.default_rng(7100 + variant)
    count = round(.22 * RATE); t = np.arange(count) / RATE
    out = np.zeros(count)
    for layer, duration, tau, gain in [(source, .065, .013, 1.15),
                                       (contact, .016, .005, .32)]:
        active = np.flatnonzero(abs(layer) > max(abs(layer)) * .08)
        layer = layer[active[0]:][:round(duration * RATE)]
        layer = filter_audio(layer, 380, 'highpass')
        layer /= max(1e-8, max(abs(layer)))
        out[:len(layer)] += layer * np.exp(-np.arange(len(layer))/RATE/tau) * gain
    # A very short dense slap gives the contact its broad THWACK, not a bell note.
    slap = filter_audio(filter_audio(rng.normal(size=count), 950, 'highpass'), 4300)
    out += slap * np.exp(-t/.0065) * 1.35
    for hz, gain, tau in [(760, .40, .018), (1230, .19, .009), (310, .25, .027)]:
        hz *= 1 + (variant-2.5)*.009
        out += np.sin(2*np.pi*hz*t) * np.exp(-t/tau) * gain
    # Soft saturation densifies the contact without making its peak win the A/B.
    out = np.tanh(out * 2.4)
    return fade(filter_audio(out, 7200), .0003)


def build(archive, output):
    wood = [read(archive / f'Audio/impactWood_medium_{i:03}.ogg') for i in range(5)]
    glass = [read(archive / f'Audio/impactGlass_light_{i:03}.ogg') for i in range(5)]
    for family in FAMILIES:
        for i in range(6):
            p = output / f'stone_{family}_{i}.wav'
            value = stone(wood[i % 5], glass[(i+2) % 5], family, i)
            value = normalize(value, p, -24, repeated=True)
            write(p, value)
    # Bowl contacts have a hard, irregular rattle, distinct from the wooden board.
    for name, timings in {'capture_single': [0, .075],
                          'capture_group': [0, .042, .105, .145, .225, .31],
                          'bowl_rattle': [0, .058, .092, .157, .22, .263, .35, .42]}.items():
        out = np.zeros(round((timings[-1] + .19) * RATE))
        for i, at in enumerate(timings):
            layer = glass[i % 5]; active = np.flatnonzero(abs(layer) > max(abs(layer))*.06)
            layer = layer[active[0]:][:round(.16*RATE)]
            layer = filter_audio(layer, 700, 'highpass')
            layer = layer / max(1e-8, max(abs(layer)))
            layer *= np.exp(-np.arange(len(layer))/RATE/.028) * (.55-i*.035)
            start = round(at*RATE); out[start:start+len(layer)] += layer
        p = output / f'{name}.wav'
        write(p, normalize(fade(out), p, -29, repeated=True))
