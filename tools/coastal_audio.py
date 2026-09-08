"""Quiet coastal beds, synthesized without samples or changes to the music."""
from wav import Sound


def surf():
    s=Sound.noise(9.0,.12,seed=614).lowpass(650).highpass(100)
    for i,at in enumerate((.3,3.1,6.4)):
        wave=Sound.noise(2.4,.35,seed=620+i).lowpass(1150).highpass(100)
        wave.env(attack=.7,decay=.4,sustain=.4,release=.9)
        s.mix(wave,at)
    return s.loopify(.8).normalise(.11)


def breeze():
    s=Sound.noise(8.0,.15,seed=714).lowpass(420).highpass(100)
    for i,at in enumerate((.8,3.7,5.8)):
        leaves=Sound.noise(1.6,.2,seed=720+i).lowpass(1900).highpass(800)
        leaves.env(attack=.4,decay=.3,sustain=.3,release=.7)
        s.mix(leaves,at,.22)
    # Far-off traffic is a low wash without a recognisable engine loop.
    s.mix(Sound.noise(8.0,.09,seed=733).lowpass(160))
    return s.loopify(.7).normalise(.055)
