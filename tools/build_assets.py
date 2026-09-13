"""Selective, deterministic asset builds. Output roots mirror the project layout."""
import argparse, os, subprocess, sys
from pathlib import Path
import gen_tiles, gen_characters, gen_ui, gen_title, gen_audio
import gen_venue_props, gen_venue_scenes, gen_arrivals
import gen_font, gen_nigiri_art, gen_tileset_resource, gen_props
import gen_maps

ROOT=Path(__file__).resolve().parent.parent
GROUPS=('tiles','props','venues','arrivals','sprites','portraits','ui','title','font','ceremony','audio','rendered','table_scene','expressive_world')
OPTIONAL_GROUPS=('kettle_next','campaign_next')
ALIASES={'environments':('tiles','props','venues','arrivals'),
         'characters':('sprites','portraits'),
         'presentation':('ui','title','ceremony')}


def build(groups, output):
    art=output/'art'
    for group in (*GROUPS,*OPTIONAL_GROUPS):
        if group not in groups:continue
        if group=='campaign_next':
            subprocess.run([sys.executable,str(ROOT/'tools/build_campaign_next.py')],env=dict(os.environ,CAMPAIGN_NEXT_OUTPUT=str(art/'campaign_next')),check=True)
            result='complete campaign presentation preview'
        elif group=='kettle_next':
            subprocess.run([sys.executable,str(ROOT/'tools/build_kettle_next.py')],env=dict(os.environ,KETTLE_NEXT_OUTPUT=str(art/'kettle_next')),check=True)
            result='opt-in Kettle model, motion and room prototype'
        elif group=='expressive_world':
            subprocess.run([sys.executable,str(ROOT/'tools/build_expressive_world.py')],env=dict(os.environ,EXPRESSIVE_WORLD_OUTPUT=str(art/'expressive_world')),check=True)
            result='live campaign maps, complete expressive cast and tram'
        elif group=='table_scene':
            env=dict(os.environ,TABLE_SCENE_OUTPUT=str(art/'table_scene'))
            subprocess.run([sys.executable,str(ROOT/'tools/table_scene/paint.py')],env=env,check=True)
            subprocess.run(['blender','-b','-t','6','--python',str(ROOT/'tools/table_scene/export.py')],env=env,check=True)
            result='21 expressive cast models, continuous clips, face atlases and table'
        elif group=='rendered':
            from build_world_art import maps, blender
            from ps1.production_people import build as people
            from ps1.production_board import build as board
            from ps1.production_actions import build as actions
            destination=art/'rendered'
            maps([p.stem for p in sorted((ROOT/'data/maps').glob('*.json'))],destination)
            people(blender,ROOT,destination)
            board(blender,ROOT,destination)
            actions(blender,ROOT,destination)
            result='twelve maps, full cast, activities and Go set'
        elif group=='tiles':
            result=gen_tiles.build(art/'tiles')
            gen_tileset_resource.build(output)
        elif group=='props':result=gen_props.build(art/'props')
        elif group=='venues':
            result=gen_venue_props.build(art/'props')+gen_venue_scenes.build(art/'props')
            gen_maps.build(output)
        elif group=='arrivals':result=gen_arrivals.build(art/'props')
        elif group in ('sprites','portraits'):
            result=gen_characters.build(art/'sprites',art/'portraits',
                                       sprites=group=='sprites',portraits=group=='portraits')
        else:
            module={'ui':gen_ui,'title':gen_title,'font':gen_font,'ceremony':gen_nigiri_art,'audio':gen_audio}[group]
            destination=output/'audio' if group=='audio' else art/('title' if group=='title' else 'ui')
            result=module.build(destination)
        print(group,result)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--groups',nargs='+',default=['all'],choices=['all',*GROUPS,*OPTIONAL_GROUPS,*ALIASES])
    parser.add_argument('--output',type=Path,default=ROOT,help='Project-shaped output root; default is this checkout.')
    args=parser.parse_args()
    groups=set()
    for group in args.groups:groups.update(GROUPS if group=='all' else ALIASES.get(group,(group,)))
    build(groups,args.output.resolve())


if __name__=='__main__':main()
