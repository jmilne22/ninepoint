#!/usr/bin/env python3
"""Reproducible production map, character and Go art, coordinated in Python."""
import argparse,json,os,subprocess,shutil,sys,hashlib
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'art/rendered'

def blender(script,*args):
    subprocess.run([os.environ.get('BLENDER','blender'),'--background','--threads','4','--python',str(ROOT/'tools/ps1'/script),'--',*map(str,args)],check=True)

def stamp_manifest(dest,name):
    path=dest/'layout.json'
    data=json.loads(path.read_text())
    data['source_sha256']=hashlib.sha256((ROOT/'data/maps'/f'{name}.json').read_bytes()).hexdigest()
    data['mask_channels']={'r':'ground_depth','g':'water','b':'washer'}
    path.write_text(json.dumps(data,indent=2)+'\n')

def maps(names, out=OUT):
    for name in names:
        scratch=ROOT/'.godot/world-render'/name
        blender('world_render.py',scratch,name)
        dest=out/'maps'/name;dest.mkdir(parents=True,exist_ok=True)
        for f in ['scene.png','depth.png','layout.json']:shutil.copyfile(scratch/f,dest/f)
        stamp_manifest(dest,name)
        source=out.parent.parent/'docs/ps1/world/source';source.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(scratch/'scene.blend',source/(name+'.blend'))

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--maps',nargs='*')
    parser.add_argument('--people',action='store_true')
    parser.add_argument('--actions',action='store_true')
    parser.add_argument('--board',action='store_true')
    parser.add_argument('--tram',action='store_true')
    parser.add_argument('--motion',nargs='*',help='Rebuild locomotion for selected identities, or all when empty')
    parser.add_argument('--stills',action='store_true')
    args=parser.parse_args()
    if args.maps is not None:maps(args.maps or [p.stem for p in sorted((ROOT/'data/maps').glob('*.json'))])
    if args.people:
        from ps1.production_people import build
        build(blender,ROOT,OUT)
    if args.board:
        from ps1.production_board import build
        build(blender,ROOT,OUT)

    if args.actions:
        from ps1.production_actions import build
        build(blender,ROOT,OUT)

    if args.tram and not args.board:
        from ps1.production_board import build_tram
        build_tram(blender,ROOT,OUT)

    if args.motion is not None:
        from ps1.production_motion import build
        build(blender,ROOT,OUT,args.motion)

    if args.stills and not args.board:
        from ps1.production_board import build_stills
        build_stills(blender,ROOT,OUT)
