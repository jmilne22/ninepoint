#!/usr/bin/env python3
"""Python coordinates all live-world model exports; campaign maps remain authoritative."""
import argparse,subprocess,sys,os
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--people',action='store_true');p.add_argument('--tram',action='store_true');p.add_argument('--maps',nargs='*');a=p.parse_args()
all_groups=not a.people and not a.tram and a.maps is None
output=Path(os.environ.get('EXPRESSIVE_WORLD_OUTPUT',root/'art/expressive_world'))
subprocess.run([sys.executable,str(root/'tools/expressive_kettle/paint.py')],env={**os.environ,'EXPRESSIVE_SURFACES':str(output/'surfaces')},check=True)
subprocess.run([sys.executable,str(root/'tools/expressive_world/board_art.py')],check=True)
script=root/'tools/expressive_world/build.py'
def run(args):subprocess.run(['blender','--background','--threads','4','--python-exit-code','1','--python',str(script),'--',*args],check=True)
if a.people or all_groups:
    subprocess.run([sys.executable,str(root/'tools/table_scene/paint.py')],env={**os.environ,'TABLE_SCENE_ALL':'1','TABLE_SCENE_OUTPUT':str(output/'people')},check=True)
    run(['people'])
if a.maps is not None or all_groups:run(['maps',*(a.maps or [x.stem for x in sorted((root/'data/maps').glob('*.json'))])])

if a.tram or all_groups:run(['tram'])
