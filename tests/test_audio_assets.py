"""Audition measurements and source integrity, independent of playback code."""
import hashlib
import json
from pathlib import Path
import unittest
import wave
ROOT=Path(__file__).resolve().parents[1]

class AudioAssets(unittest.TestCase):
    def test_sources(self):
        for name,spec in json.loads((ROOT/'tools/audio_preview/sources.json').read_text()).items():
            self.assertEqual(hashlib.sha256((ROOT/'tools/audio_preview/sources'/name).read_bytes()).hexdigest(),spec['sha256'])

    def test_export_contracts(self):
        manifest=json.loads((ROOT/'audio_preview/manifest.json').read_text())
        self.assertEqual(len(manifest['assets']),24)
        for name,spec in manifest['assets'].items():
            path=ROOT/'audio_preview'/name
            with self.subTest(name=name),wave.open(str(path)) as stream:
                self.assertEqual(stream.getframerate(),48000)
                self.assertEqual(stream.getnchannels(),2 if name in ['kettle.wav','match.wav','match_in.wav'] else 1)
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),spec['sha256'])
                self.assertLess(spec['peak_dbfs'],-1)
                if name.startswith('stone_'):self.assertLess(abs(spec['audition_lufs']+24),.5)
                if name in ['kettle.wav','match.wav']:
                    self.assertGreaterEqual(spec['seconds'],90)
                    self.assertLessEqual(spec['seconds'],120)

if __name__=='__main__':unittest.main()
