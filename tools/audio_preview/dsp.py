"""48 kHz offline audio processing; no nondeterministic effects."""
import json
import subprocess
import tempfile
from pathlib import Path
import numpy as np
from scipy import signal
from scipy.io import wavfile

RATE = 48000


def read(path, mono=True):
    channels = 1 if mono else 2
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path),
        '-f', 'f32le', '-ar', str(RATE), '-ac', str(channels), '-'])
    value = np.frombuffer(raw, dtype='<f4').astype(np.float64)
    return value if mono else value.reshape(-1, 2)


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    if np.max(np.abs(value)) >= .98:
        raise ValueError(f'{path.name}: insufficient headroom')
    wavfile.write(path, RATE, np.round(value * 32767).astype('<i2'))


def filter_audio(value, cutoff, kind='lowpass'):
    return signal.sosfilt(signal.butter(2, cutoff, btype=kind, fs=RATE, output='sos'), value, axis=0)


def fade(value, seconds=.002):
    value = value.copy(); n = min(round(seconds * RATE), len(value)//2)
    shape = (-1,) if value.ndim == 1 else (-1, 1)
    value[:n] *= np.linspace(0, 1, n).reshape(shape)
    value[-n:] *= np.linspace(1, 0, n).reshape(shape)
    return value


def loudness(path):
    result = subprocess.run(['ffmpeg', '-hide_banner', '-i', str(path),
        '-af', 'loudnorm=I=-23:TP=-1:LRA=7:print_format=json', '-f', 'null', '-'],
        capture_output=True, text=True, check=True).stderr
    return json.JSONDecoder().raw_decode(result[result.rfind('{'):])[0]


def normalize(value, path, target=-23, repeated=False):
    # Measure isolated effects as a repeatable one-hit-per-second audition.
    measured = value
    if repeated:
        hit = np.pad(value, (0, max(0, RATE-len(value))))
        measured = np.tile(hit, 8)
    measured = measured * min(1, .8 / max(1e-10, np.max(np.abs(measured))))
    scale = min(1, .8 / max(1e-10, np.max(np.abs(value))))
    with tempfile.TemporaryDirectory(prefix='ninepoint-loudness-') as directory:
        temp = Path(directory) / 'measure.wav'
        write(temp, measured)
        gain = 10 ** ((target - float(loudness(temp)['input_i'])) / 20) * scale
    return value * gain


def audition_loudness(value):
    value = np.tile(np.pad(value, (0, max(0, RATE-len(value)))), 8)
    with tempfile.TemporaryDirectory(prefix='ninepoint-loudness-') as directory:
        path = Path(directory) / 'measure.wav'
        write(path, value)
        return float(loudness(path)['input_i'])


def room(value, loop=False):
    # Short, asymmetric early reflections retain a close table perspective.
    out = value.copy()
    for seconds, gain in ((.019, .09), (.037, .065), (.061, .04), (.113, .025)):
        delay = round(seconds * RATE)
        wet = np.roll(value[:, ::-1], delay, axis=0)
        if not loop: wet[:delay] = 0
        out += wet * gain
    return out
