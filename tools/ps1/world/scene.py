"""Render map geometry and a ground-depth mask from the same meshes/camera.

Logical map coordinates are retained. One tile is .8 metres; the orthographic
camera is 45 degrees around the plane and 30 degrees above it, at 32 px/metre.
"""
import json,math,sys,random
from pathlib import Path
import bpy
from common import reset,box,cylinder,light,camera,render,material
from .palette import make
from .props import prop
from .surroundings import context,daylight
from .entrances import door,groups,interiors
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from art_specs import SPECS
ROOT=Path(__file__).resolve().parents[3]
UNIT=.8
PX=32

def marked(fn):
    before=set(bpy.data.objects)
    fn()
    for o in set(bpy.data.objects)-before:
        if o.type=='MESH':o['depth_sorted']=True

def architecture(kind,x,y,w,d,m,door_centres=None):
    if kind.startswith('sela_') and kind in ['sela_home','sela_bar','sela_laundry']:
        from .white_city import facade
        facade(kind,x,y,w,d,m,door_centres)
    elif kind=='port_arch':
        from .harbor import arch
        arch(x,y,w,1.48,.48,m)
    elif kind=='sela_pergola':
        for dx in [-w*.45,w*.45]:box('column',(x+dx,y,1.25),(.25,.35,2.5),m['plaster'])
        box('lintel',(x,y,2.5),(w,.45,.3),m['plaster' if kind=='port_arch' else 'wood'])
        if kind=='sela_pergola':
            for i in range(8):box('pergola slat',(x-w*.46+i*w*.13,y,2.7),(.08,1.4,.12),m['wood'])
    elif kind in ['school_glass','tall_window']:
        box('window frame',(x,y,1.45),(w,.12,1.65),m['cream'])
        box('cold glass',(x,y-.07,1.45),(w-.14,.04,1.5),m['glass'])
        for dx in [-w*.33,0,w*.33]:box('window mullion',(x+dx,y-.1,1.45),(.04,.06,1.5),m['cream'])
    elif kind=='kettle_sign' or kind.startswith('shopfront'):
        box('signboard',(x,y,1.7),(w*.85,.12,.43),m['wood'])
        for i in range(5):box('sign lettering',(x-w*.3+i*w*.15,y-.07,1.7),(.06,.02,.2),m['amber'])
    else:raise ValueError(kind)


def build(output,map_id):
    data=json.loads((ROOT/'data/maps'/f'{map_id}.json').read_text())
    w,h=data['size']; span=(w+h)*UNIT
    width=math.ceil(span*PX/math.sqrt(2))+64
    height=math.ceil(span*PX/math.sqrt(8))+128
    scene=reset(width,height); scene.cycles.samples=16
    m=make(data.get('indoors'),map_id=='de_ketel')
    data['id']=map_id
    context(data,m,architecture)
    # The plane carries tile seams, tactile grain and baked shadows, never occlusion depth.
    rng=random.Random(map_id)
    for row in range(h):
        for col in range(w):
            name=data['legend'].get(data['ground'][row][col],'')
            if name in ['void','coast_sky']:continue
            x,y=(col+.5)*UNIT,-(row+.5)*UNIT
            if name.startswith('wall_int') or name=='wall_side':
                if row < 2:continue
                box('wall foundation',(x,y,-.055),(UNIT,UNIT,.10),m['floor'])
                if row==2 or col==0:
                    box('cutaway wall',(x,y,1.15),(UNIT,.16,2.3) if row==2 else (.12,UNIT,2.3),m['plaster'])
                    box('wainscot',(x,y,0.35),(UNIT,.18,.7) if row==2 else (.14,UNIT,.7),m['wood'])
                elif row < h-1 and col < w-1:
                    marked(lambda x=x,y=y:box('room divider',(x,y,.55),(UNIT*.95,UNIT*.95,1.1),m['plaster']))
                else:
                    box('cutaway skirting',(x,y,.08),(UNIT,.10,.16) if row==h-1 else (.10,UNIT,.16),m['wood'])
                continue
            kind='paving'
            if 'floor_wood' in name:kind='floor'
            elif name in ['floor_mat','rug']:kind='cloth'
            elif 'canal' in name:kind='water'
            elif 'grass' in name or name in ['bush','gravel']:kind='grass'
            elif name in ['asphalt','tram_rail_h','puddle','drain']:kind='asphalt'
            # Sea Walk has one continuous water mesh: separate tile tops expose a
            # rectangular height seam where the playable map ends.
            if not (kind=='water' and map_id=='quay'):
                box('ground',(x,y,-.055),(UNIT+.004 if kind=='water' else UNIT-.012,UNIT+.004 if kind=='water' else UNIT-.012,.1),m[kind])
            if kind=='floor':
                for a in [-.26,0,.26]:box('plank seam',(x+a,y,.001),(.008,UNIT,.002),m['wood'])
            if 'tram_rail' in name:
                for off in [-.20,.20]:box('steel rail',(x,y+off,.005),(UNIT,.025,.015),m['metal'])
            if kind=='water':
                for i in range(2):box('sea ripple',(x+rng.uniform(-.2,.2),y+rng.uniform(-.3,.3),.002),(.34,.011,.003),m['glass'])
            if name in ['door_int','door_wood','door_glass','door_club','stairs_down','stairs_up']:
                box('door threshold',(x,y,.02),(UNIT*.92,UNIT*.85,.06),m['amber'])
            if name in ['fence_h','fence_post']:
                marked(lambda x=x,y=y:box('seawall rail',(x,y,.5),(UNIT,.055,.06),m['metal']))
            if name in ['plant_int','planter','bush','bench','stone_table','noticeboard','lamp_post','tram_pole','post_box','bollard','bike_rack']:
                # Art props with explicit footprints replace legacy tile objects.
                covered=False
                for p in data.get('art_props',[]):
                    spec=SPECS.get(p['art']);fp=spec.footprint if spec else None
                    if fp:
                        px,py=p['position'];a,b,c,d=fp
                        if px+a-8<=col*16<=px+a+c and py+b-8<=row*16<=py+b+d:covered=True
                if not covered:
                    k={'bench':'long_bench','stone_table':'playing_table'}.get(name,name)
                    marked(lambda k=k,x=x,y=y:prop(k,x,y,.70,.65,m))
    for p in data.get('art_props',[]):
        kind=p['art']
        if kind.startswith('floor_details') or kind.startswith('board_number') or kind in ['attic_roof','facade_detail']:continue
        spec=SPECS[kind]; px,py=p['position']
        if spec.footprint:
            a,b,c,d=spec.footprint
            x,y=(px+a+c/2)/16*UNIT,-(py+b+d/2)/16*UNIT
            marked(lambda:prop(kind,x,y,c/16*UNIT,d/16*UNIT,m))
        else:
            c,d=spec.size
            if kind in ['coat_rack','book_shelf','snack_stool','school_directions','demonstration']:
                x,y=(px+c/2)/16*UNIT,-(py+d)/16*UNIT
                marked(lambda:prop(kind,x,y,c/16*UNIT,.3,m))
            else:
                x,y=(px+c/2)/16*UNIT,-(py+d/2)/16*UNIT
                if kind in ['school_glass','tall_window']:y=-(max(2.3,py/16))*UNIT
                entries=None
                if kind in ['sela_home','sela_bar','sela_laundry']:
                    target_map={'sela_home':'attic','sela_bar':'de_ketel','sela_laundry':'wassalon'}[kind]
                    entries=[(sum(t[0]+.5 for t in g['tiles'])/len(g['tiles'])*UNIT,max(.92,.72*len(g['tiles']))) for g in groups(data) if g['key'][0]==target_map]
                architecture(kind,x,y,c/16*UNIT,d/16*UNIT,m,entries)
    # Chairs occupy the host's tile; their shallow backs leave the far approaches clear.
    for npc in data.get('npcs',[]):
        if npc.get('idle') != 'play':continue
        x=(npc['tile'][0]+.5)*UNIT;y=-(npc['tile'][1]+.94)*UNIT
        def chair():
            box('chair seat',(x,y,.39),(.43,.40,.065),m['wood'],.02)
            for dx in [-.17,.17]:
                for dy in [-.15,.15]:box('chair leg',(x+dx,y+dy,.19),(.045,.045,.38),m['wood'])
        marked(chair)
    target=(w*UNIT/2,-h*UNIT/2,32/(PX*math.cos(math.pi/6)))
    cam=camera((target[0]+80,target[1]-80,target[2]+math.sqrt(12800)*math.tan(math.pi/6)),target,width/PX)
    interiors(data,m)
    daylight(scene,w*UNIT,h*UNIT,data.get('indoors'),map_id=='de_ketel')
    output.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output/'scene.blend'))
    render(output/'scene.png')
    # A second render measures each visible surface's ground contact depth.
    # Emission removes illumination from the mask; Raw prevents a gamma curve.
    def mask_material(sorted_depth, water=False, washer=False):
        mat=bpy.data.materials.new('depth and animated material');mat.use_nodes=True
        nodes,links=mat.node_tree.nodes,mat.node_tree.links;nodes.clear()
        combine=nodes.new('ShaderNodeCombineXYZ')
        combine.inputs[1].default_value=float(water)
        combine.inputs[2].default_value=float(washer)
        if sorted_depth:
            geom=nodes.new('ShaderNodeNewGeometry');xyz=nodes.new('ShaderNodeSeparateXYZ')
            sub=nodes.new('ShaderNodeMath');sub.operation='SUBTRACT'
            divide=nodes.new('ShaderNodeMath');divide.operation='DIVIDE';divide.inputs[1].default_value=span
            links.new(geom.outputs['Position'],xyz.inputs[0]);links.new(xyz.outputs['X'],sub.inputs[0]);links.new(xyz.outputs['Y'],sub.inputs[1]);links.new(sub.outputs[0],divide.inputs[0]);links.new(divide.outputs[0],combine.inputs[0])
        emission=nodes.new('ShaderNodeEmission');out=nodes.new('ShaderNodeOutputMaterial')
        links.new(combine.outputs[0],emission.inputs['Color']);links.new(emission.outputs[0],out.inputs['Surface'])
        return mat
    masks={}
    for obj in bpy.data.objects:
        if obj.type!='MESH':continue
        key=(bool(obj.get('depth_sorted')),bool(obj.data.materials and obj.data.materials[0]==m['water']) or obj.name.startswith('sea ripple'),obj.name.startswith('washer glass'))
        if key not in masks:masks[key]=mask_material(*key)
        obj.data.materials.clear();obj.data.materials.append(masks[key])
    scene.view_settings.view_transform='Raw';scene.cycles.samples=1;scene.cycles.use_denoising=False
    scene.render.image_settings.color_depth='16'
    render(output/'depth.png')
    (output/'layout.json').write_text(json.dumps({'id':map_id,'size':[width,height],'origin':[h*UNIT*PX/math.sqrt(2)+32,96],'basis':UNIT*PX/math.sqrt(2)/16,'span':16*(w+h),'camera':[45,30],'source_size':[w,h]},indent=2)+'\n')
