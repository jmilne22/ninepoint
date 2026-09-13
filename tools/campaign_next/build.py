"""Blender worker. Each invocation isolates source-module hooks and material state."""
import sys,os,json
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT/'tools/campaign_next'),str(ROOT/'tools/kettle_next'),str(ROOT/'tools/table_scene'),str(ROOT/'tools')]
OUT=Path(os.environ.get('CAMPAIGN_NEXT_OUTPUT',ROOT/'art/campaign_next'));OUT.mkdir(parents=True,exist_ok=True)
a=sys.argv[sys.argv.index('--')+1:]
if a[0]=='people':
    from characters import BY_ID
    from identities import STYLE
    from people import build
    from verify import validate
    from batching import batch
    folder=OUT/'people';folder.mkdir(exist_ok=True)
    report=folder/'pose-report.json';reports=json.loads(report.read_text()) if report.exists() else []
    for who in a[1:] or list(STYLE):
        bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
        bpy.data.orphans_purge(do_recursive=True);bpy.context.scene.render.fps=30
        rig=build(BY_ID[who],STYLE[who]);result=validate(rig,who)
        result["batch_checks"]=batch(rig)
        reports=[r for r in reports if r['identity']!=who]+[result]
        bpy.ops.export_scene.gltf(filepath=str(folder/(who+'.glb')),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_yup=True)
        report.write_text(json.dumps(reports,indent=2)+'\n')
elif a[0]=='map':
    folder=OUT/'maps'/a[1];folder.mkdir(parents=True,exist_ok=True)
    if a[1]=='de_ketel':
        # Preserve the owner-approved room without approximate reconstruction.
        import room
        room.build(folder)
    else:
        import environments
        environments.build(folder,a[1])
    from environments import lighting_manifest
    lighting_manifest(folder,a[1])
elif a[0]=='lighting':
    from environments import lighting_manifest
    for folder in sorted((OUT/'maps').iterdir()):lighting_manifest(folder,folder.name)
elif a[0]=='table':
    from export import build_table
    build_table(OUT,refined=True)
elif a[0]=='tram':
    sys.path.insert(0,str(ROOT/'tools/ps1'))
    from tram_render import build
    build(OUT,live=True)
