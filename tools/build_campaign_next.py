#!/usr/bin/env python3
"""Selective authoritative campaign preview assets; never overwrites production art."""
import argparse,subprocess,sys,os,importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/campaign_next'))
from identities import STYLE
p=argparse.ArgumentParser();p.add_argument('--people',nargs='*');p.add_argument('--maps',nargs='*');p.add_argument('--table',action='store_true');p.add_argument('--tram',action='store_true');p.add_argument('--surfaces',action='store_true');a=p.parse_args()
all_groups=a.people is None and a.maps is None and not a.table and not a.tram and not a.surfaces
out=Path(os.environ.get('CAMPAIGN_NEXT_OUTPUT',ROOT/'art/campaign_next'))
def blender(*args):
 subprocess.run(['blender','-b','-t','4','--python-exit-code','1','--python',str(ROOT/'tools/campaign_next/build.py'),'--',*args],check=True)
if a.people is not None or all_groups:
 from PIL import Image
 spec=importlib.util.spec_from_file_location('approved_faces',ROOT/'tools/table_scene/paint.py');paint=importlib.util.module_from_spec(spec);spec.loader.exec_module(paint)
 folder=out/'people';folder.mkdir(parents=True,exist_ok=True)
 for who in a.people or STYLE:
  atlas=Image.new('RGB',(3072,3072))
  for row,mood in enumerate(paint.MOODS):
   for col,gaze in enumerate([-12,0,12]):atlas.paste(paint.face(who,mood,gaze),(col*1024,row*512))
  atlas.save(folder/(who+'_face.png'))
 blender('people',*(a.people or STYLE))
if a.maps is not None or all_groups:
 for name in a.maps or [p.stem for p in sorted((ROOT/'data/maps').glob('*.json'))]:blender('map',name)
if a.table or all_groups:blender('table')
if a.tram or all_groups:blender('tram')

if a.surfaces or a.table or all_groups:
 from board_art import build
 build(out)
