"""Edit the inspected Godot captures at normal speed; ffmpeg must be on PATH."""
import argparse
import json
from pathlib import Path
import subprocess

p = argparse.ArgumentParser()
p.add_argument('--root', type=Path, default=Path('docs/expressive_kettle/refinement'))
args = p.parse_args()
root = args.root
# Seconds in the complete tour; preserve the actual animation/audio timing.
segments = [(0, 9.1), (71.76, 75.86), (78.56, 81.06), (85.03, 92.8), (99.1, 103.5)]
filters = ['[0:v]trim=0:5.2,setpts=PTS-STARTPTS[v0]',
           '[0:a]atrim=0:5.2,asetpts=PTS-STARTPTS[a0]']
for i, (start, end) in enumerate(segments, 1):
    filters.extend([f'[1:v]trim={start}:{end},setpts=PTS-STARTPTS[v{i}]',
                    f'[1:a]atrim={start}:{end},asetpts=PTS-STARTPTS[a{i}]'])
filters.extend(['[0:v]trim=0:3,setpts=PTS-STARTPTS[v6]', '[0:a]atrim=0:3,asetpts=PTS-STARTPTS[a6]'])
filters.append(''.join(f'[v{i}][a{i}]' for i in range(7)) + 'concat=n=7:v=1:a=1[v][a]')
subprocess.run(['ffmpeg', '-y', '-i', str(root/'poses.mp4'), '-i', str(root/'full-tour.mp4'),
    '-filter_complex', ';'.join(filters), '-map', '[v]', '-map', '[a]',
    '-c:v', 'libx264', '-crf', '19', '-pix_fmt', 'yuv420p', '-r', '30',
    '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart', str(root/'showcase.mp4')], check=True)
(root/'evidence/edit.json').write_text(json.dumps({'poses_seconds':[0,5.2],
    'full_tour_seconds':segments, 'ending_poses_seconds':[0,3], 'speed':1.0}, indent=2)+'\n')
