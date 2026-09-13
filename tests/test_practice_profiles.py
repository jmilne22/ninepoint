import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import gen_practice_profiles as profiles

class PracticeProfiles(unittest.TestCase):
    def test_novice_anchors_and_interpolation(self):
        values = [profiles.beginner_temperature(n) for n in range(11)]
        self.assertEqual(values[0], 4.0)
        self.assertEqual(values[3], 2.75)
        self.assertEqual(values[5], 2.0)
        self.assertEqual(values[7], 1.5)
        self.assertEqual(values[10], 1.0)
        self.assertTrue(all(a > b for a, b in zip(values, values[1:])))

    def test_exports_match_sources(self):
        for rank in range(35):
            label = f'{30-rank}k' if rank < 30 else f'{rank-29}d'
            for style in profiles.STYLES:
                path = ROOT / f'packaging/katago/config/practice/{label}_{style}.cfg'
                self.assertEqual(path.read_text(), profiles.config(rank, style))
                native = label if rank >= 10 else '20k'
                self.assertIn(f'humanSLProfile = preaz_{native}\n', path.read_text())

if __name__ == '__main__': unittest.main()
