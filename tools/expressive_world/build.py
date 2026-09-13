"""Export campaign geometry and the approved full-body cast for live Godot rendering."""
import sys,json,os
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
args=sys.argv[sys.argv.index('--')+1:]
mode=args[0]
OUT=Path(os.environ.get('EXPRESSIVE_WORLD_OUTPUT',ROOT/'art/expressive_world'));OUT.mkdir(parents=True,exist_ok=True)
(OUT/'people').mkdir(exist_ok=True)
if mode=='people':
    sys.path[:0]=[str(ROOT/'tools/expressive_kettle'),str(ROOT/'tools/table_scene'),str(ROOT/'tools')]
    from people import build_person
    from motion import DURATIONS
    DURATIONS.update(seated=6,counter=6)
    from characters import CHARACTERS
    for spec in CHARACTERS:
        bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
        bpy.data.orphans_purge(do_recursive=True);bpy.context.scene.render.fps=30
        build_person(spec)
        bpy.ops.export_scene.gltf(filepath=str(OUT/'people'/(spec['id']+'.glb')),export_format='GLB',
            export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_yup=True)
elif mode=='tram':
    sys.path[:0]=[str(ROOT/'tools/ps1'),str(ROOT/'tools')]
    from tram_render import build
    build(OUT,live=True)
else:
    sys.path[:0]=[str(ROOT/'tools/ps1'),str(ROOT/'tools')]
    from world.scene import build
    for name in args[1:]:build(OUT/'maps'/name,name,live=True)
