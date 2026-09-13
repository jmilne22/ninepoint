"""Build the opt-in audio palette without touching production exports."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'tools/audio_preview'
sys.path.insert(0, str(SOURCE))
import numpy as np
import scipy
from dsp import RATE, read, write, room, fade, normalize, loudness, audition_loudness
import effects
import score


def sources():
    directory = SOURCE / 'sources'
    directory.mkdir(exist_ok=True)
    for name, spec in json.loads((SOURCE / 'sources.json').read_text()).items():
        path = directory / name
        if not path.exists():
            path.write_bytes(urllib.request.urlopen(spec['url'], timeout=90).read())
        if hashlib.sha256(path.read_bytes()).hexdigest() != spec['sha256']:
            raise ValueError('Source checksum mismatch: ' + name)
    return directory


def tools():
    expected = json.loads((SOURCE / 'toolchain.json').read_text())
    actual = {name: subprocess.check_output(command, text=True).splitlines()[0]
              for name, command in {'fluidsynth': ['fluidsynth', '--version'],
                                    'ffmpeg': ['ffmpeg', '-version']}.items()}
    actual.update(python=sys.version.split()[0], numpy=np.__version__, scipy=scipy.__version__)
    for name, version in expected.items():
        if actual[name] != version:
            raise ValueError(f'{name}: expected {version}; found {actual[name]}')
    return actual


def music(source, output, temporary):
    for name, match, intro in [('kettle', False, False), ('match', True, False),
                               ('match_in', True, True)]:
        midi = temporary / (name + '.mid'); raw = temporary / (name + '.wav')
        duration = score.midi(midi, match, intro)
        subprocess.run(['fluidsynth', '-ni', '-q', '-R', '0', '-C', '0',
                        '-r', str(RATE), '-g', '.5', '-T', 'wav', '-O', 's16',
                        '-F', str(raw), str(source / 'GeneralUser-GS.sf2'), str(midi)],
                       check=True, stdout=subprocess.DEVNULL)
        value = read(raw, mono=False); count = round(duration*RATE)
        if len(value) < count: raise ValueError('Truncated music render')
        tail = value[count:]
        value = value[:count].copy()
        if not intro:
            # Carry note releases across the musical bar boundary.
            length = min(len(tail), count)
            value[:length] += tail[:length]
        value = room(value, loop=not intro)
        value = fade(value, .004 if not intro else .012)
        path = output / f'{name}.wav'
        value = normalize(value, path, -21)
        write(path, value)
        (output / (name + '.mid')).write_bytes(midi.read_bytes())


def build(output, only):
    versions = tools(); source = sources(); output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='ninepoint-audio-', dir=ROOT) as temp:
        temp = Path(temp)
        (temp / '.gdignore').touch()
        with zipfile.ZipFile(source / 'kenney_impact-sounds.zip') as archive:
            archive.extractall(temp / 'kenney')
        if only != 'music': effects.build(temp / 'kenney', output)
        if only != 'effects': music(source, output, temp)
    manifest = {'tools': versions, 'sample_rate': RATE, 'assets': {}}
    for path in sorted(output.glob('*.wav')):
        value = read(path, mono=not path.stem.startswith(('kettle', 'match')))
        lufs = float(loudness(path)['input_i'])
        manifest['assets'][path.name] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
            'seconds': len(value)/RATE, 'peak_dbfs': float(20*np.log10(np.max(abs(value)))),
            'lufs': lufs if math.isfinite(lufs) else None}
        if value.ndim == 1:
            manifest['assets'][path.name]['audition_lufs'] = audition_loudness(value)
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print(f'Built {len(manifest["assets"])} audio preview assets in {output}', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT/'audio_preview')
    parser.add_argument('--only', choices=['all', 'effects', 'music'], default='all')
    args = parser.parse_args(); build(args.output.resolve(), args.only)
