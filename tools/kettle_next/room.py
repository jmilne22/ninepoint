"""Rebuild the real campaign Kettle using its original map and furniture footprints."""
import sys,math,json
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]

def build(output):
    sys.path.insert(0,str(ROOT/'tools/ps1'))
    from world import props
    import furniture
    props.original_table=props.table;props.original_cabinet=props.cabinet
    props.table=furniture.table;props.cabinet=furniture.cabinet
    import live_export
    live_export.export=export
    from world.scene import build as scene
    scene(output,'de_ketel',live=True)

def export(output,data):
    from common import box,cylinder,limb
    from furniture import rounded,STEAM
    from live_export import PALETTE
    # Preserve coherent cream/green/wood with quieter floor and deeper cabinet tones.
    palette={**PALETTE,'wood':'987351','floor':'b79a76','plaster':'ded5c0','cloth':'526e5e','stone':'d1c6ae'}
    for mat in bpy.data.materials:
        key=mat.name.split('.')[0]
        if key in palette:
            h=palette[key];c=tuple(int(h[i:i+2],16)/255 for i in (0,2,4))+(1,)
            mat.diffuse_color=c
        mat.use_nodes=True;n=mat.node_tree.nodes;n.clear();p=n.new('ShaderNodeBsdfPrincipled')
        p.inputs['Base Color'].default_value=mat.diffuse_color;p.inputs['Roughness'].default_value=.85
        o=n.new('ShaderNodeOutputMaterial');mat.node_tree.links.new(p.outputs[0],o.inputs[0])
    mats={m.name.split('.')[0]:m for m in bpy.data.materials}
    # The old repeated wall segments cast a visible sawtooth across plaster.
    for obj in list(bpy.data.objects):
        if obj.type in ['CAMERA','LIGHT'] or obj.name.startswith(('plank seam','cutaway wall','wainscot')) or (obj.name.startswith('ground') and .7<obj.location.x<15.3 and -10.5<obj.location.y<-2.3):
            bpy.data.objects.remove(obj,do_unlink=True)
    rounded('Continuous back plaster',(8,-2.0,1.15),(15.2,.16,2.3),mats['plaster'],.014)
    rounded('Continuous side plaster',(.4,-6.2,1.15),(.14,8.4,2.3),mats['plaster'],.014)
    rounded('Green back dado',(8,-2.11,.30),(15.2,.055,.6),mats['cloth'],.008)
    rounded('Green side dado',(.49,-6.2,.30),(.055,8.4,.6),mats['cloth'],.008)
    rounded('Back dado rail',(8,-2.15,.625),(15.2,.09,.035),mats['wood'],.006)
    # Real long boards replace the old 16-pixel ground mesh grid.
    for col in range(48):
        x=.8+(col+.5)*.30
        for row in range(4):
            low=max(2.4,2.4+row*2.6-(col%3)*.70)
            high=min(10.4,2.4+(row+1)*2.6-(col%3)*.70)
            if high>low:
                rounded('Long oak floor',(x,-(low+high)/2,-.026),(.298,high-low-.002,.054),mats['floor'],.001)
    # The solid divider becomes an upholstered settle with timber edging.
    for obj in list(bpy.data.objects):
        if not obj.name.startswith('room divider'):continue
        obj.data.materials.clear();obj.data.materials.append(mats['cloth'])
        obj.dimensions.z=.74;obj.location.z=.37
        rounded('Settle top',(obj.location.x,obj.location.y,.76),(.73,.73,.08),mats['wood'],.024)
    # Shallow curved backs and stretchers make the existing host seats readable
    # as constructed furniture without enlarging their collision footprint.
    for seat in [o for o in bpy.data.objects if o.name.startswith('chair seat')]:
        x,y=seat.location.x,seat.location.y
        for dx in [-.17,.17]:
            rounded('Chair back upright',(x+dx,y+.16,.57),(.037,.043,.46),mats['wood'],.009)
            limb('Chair side stretcher',(x+dx,y-.15,.20),(x+dx,y+.15,.20),.015,mats['wood'])
        rounded('Chair back rail',(x,y+.165,.77),(.38,.043,.065),mats['wood'],.015)
        for dx in [-.09,0,.09]:
            rounded('Chair back spindle',(x+dx,y+.165,.64),(.022,.028,.24),mats['wood'],.007)
    # Brass coat pegs remain exactly on the existing readable back-wall feature.
    for j in range(4):
        limb('Coat peg',(7.0+j*.25,-2.20,1.58),(7.0+j*.25,-2.32,1.58),.018,mats['amber'])
    rounded('Club picture frame',(4.9,-2.16,1.63),(1.12,.08,.68),mats['wood'],.018)
    rounded('Club picture paper',(4.9,-2.21,1.63),(.98,.01,.55),mats['cream'],.005)
    for j in range(5):box('Picture coastal roof',(4.5+j*.19,-2.224,1.49+(j%3)*.035),(.15,.003,.10+(j%3)*.07),mats['cloth'])
    for x in [7.25,12.05]:
        rounded('Deep window sill',(x,-2.22,.76),(2.25,.38,.075),mats['cream'],.017)
        rounded('Window lower trim',(x,-2.10,1.58),(2.20,.045,.055),mats['wood'],.007)
    # Keep static batching, but separate the foliage so only leaves can sway.
    groups={}
    for obj in list(bpy.data.objects):
        if obj.type!='MESH':continue
        bpy.context.view_layer.objects.active=obj
        for mod in list(obj.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
        key=tuple(m.name for m in obj.data.materials)
        groups.setdefault(key,[]).append(obj)
    for key,objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
        objects[0].name='Kettle_'+'_'.join(key)
    bpy.ops.export_scene.gltf(filepath=str(output/'room.glb'),export_format='GLB',export_animations=False,export_yup=True)
    (output/'room-manifest.json').write_text(json.dumps({'map':'de_ketel','coordinates':'unchanged','metres_per_tile':.8,'steam':STEAM},indent=2)+'\n')

    # The cleaning cloth is a separate source asset attached to the live palm.
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    cloth=rounded('Cleaning cloth',(0,0,0),(.25,.19,.009),mats['cream'],.003)
    for mod in list(cloth.modifiers):
        bpy.context.view_layer.objects.active=cloth;bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.export_scene.gltf(filepath=str(output/'cloth.glb'),export_format='GLB',export_animations=False,export_yup=True)
