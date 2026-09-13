"""Selective Blender export. No production assets are overwritten."""
import sys,json,os
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(Path(__file__).parent),str(ROOT/'tools/table_scene'),str(ROOT/'tools')]
OUT=Path(os.environ.get('KETTLE_NEXT_OUTPUT',ROOT/'art/kettle_next'));OUT.mkdir(parents=True,exist_ok=True)
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['people']
if args[0]=='people':
    from characters import BY_ID
    from people import build
    from verify import validate
    report_path=OUT/'pose-report.json'
    reports=json.loads(report_path.read_text()) if report_path.exists() else []
    for who in args[1:] or ['player','wren','kesh','tomas']:
        bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
        bpy.data.orphans_purge(do_recursive=True);bpy.context.scene.render.fps=30
        rig=build(BY_ID[who])
        reports=[r for r in reports if r['identity']!=who]
        reports.append(validate(rig,who))
        bpy.ops.export_scene.gltf(filepath=str(OUT/(who+'.glb')),export_format='GLB',
            export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_yup=True)
    (OUT/'pose-report.json').write_text(json.dumps(reports,indent=2)+'\n')
elif args[0]=='room':
    from room import build
    build(OUT)
elif args[0]=='table':
    from export import build_table
    build_table(OUT,refined=True)
