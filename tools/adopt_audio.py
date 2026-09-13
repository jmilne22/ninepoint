"""Publish the approved rendered audio into the production sound-name contract."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
ASSETS = {
    'theme_club': 'kettle', 'theme_battle': 'match', 'theme_battle_in': 'match_in',
    'capture': 'capture_group', 'capture_single': 'capture_single',
    'bowl_rattle': 'bowl_rattle', 'stone_place': 'stone_thwack_0',
    **{f'stone_thwack_{i}': f'stone_thwack_{i}' for i in range(6)},
}


def build(output, source=ROOT / 'audio_preview'):
    output = Path(output)
    manifest = json.loads((source / 'manifest.json').read_text())
    # Validate the complete set before replacing any production file.
    for name in set(ASSETS.values()):
        path = source / f'{name}.wav'
        expected = manifest['assets'][path.name]['sha256']
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise ValueError(f'Rendered audio checksum mismatch: {path}')
    output.mkdir(parents=True, exist_ok=True)
    for target, name in ASSETS.items():
        shutil.copyfile(source / f'{name}.wav', output / f'{target}.wav')
    # Background tables keep their quiet positional mix, using the new contact.
    for name in ['stone_place_alt.wav', 'stone_place_alt.wav.import']:
        (output / name).unlink(missing_ok=True)
    return list(ASSETS)


if __name__ == '__main__':
    print('Published production audio:', ', '.join(build(ROOT / 'audio')))
