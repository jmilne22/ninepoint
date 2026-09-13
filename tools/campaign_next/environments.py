"""Campaign furniture and surfaces on authoritative, unchanged map footprints."""
import math,json,hashlib,sys
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
ROOMS={
'attic':('bba07d','d9d2be','6d8174',.34,.77,-27),
'ketelsteeg':('bca482','e3dccb','78956b',.43,.89,-32),
'wassalon':('c2bbaa','e0ded0','71918a',.43,.72,-18),
'onderbrug':('a49c8b','c8c6b7','69837a',.44,.66,-36),
'quay':('c9bba0','ddd6c4','6d9697',.48,.87,-35),
'academy_hall':('bca584','ded9c6','607d6d',.40,.76,-24),
'academy_study':('ad9375','dbd4bf','6a8170',.36,.75,-30),
'academy_class':('b9a17f','e2ddc9','718977',.42,.74,-20),
'academy_novice':('baa07f','e4dac5','788b70',.41,.77,-28),
'academy_dorm':('b6a087','ddd4c1','71877d',.35,.70,-32),
'bondszaal':('aa8e6b','e1d8bd','526f60',.38,.83,-22),
}
MAP='';STEAM=[];original_table=None;original_cabinet=None;original_bench=None

def build(output,map_id):
    global MAP,original_table,original_cabinet,original_bench
    MAP=map_id;STEAM.clear()
    sys.path.insert(0,str(ROOT/'tools/ps1'))
    from world import props
    original_table=props.table;original_cabinet=props.cabinet;original_bench=props.bench
    props.table=table;props.cabinet=cabinet;props.bench=bench
    import live_export
    live_export.export=export
    from world.scene import build as scene
    scene(output,map_id,live=True)

def rounded(*args,**kwargs):
    from furniture import rounded as fn
    return fn(*args,**kwargs)

def cup(x,y,z,m):
    from furniture import cup as fn
    fn(x,y,z,m);STEAM.append([x,z+.14,-y])

def table(x,y,w,d,m,kind='playing_table'):
    from common import box,cylinder,limb
    from furniture import table as kettle_table
    if kind not in ['study_desk','student_desk']:
        # Same construction as Kettle; personal items distinguish each purpose.
        kettle_table(x,y,w,d,m,'playing_table')
    else:
        original_table(x,y,w,d,m,kind)
    for dy in [-d*.34,d*.34]:
        rounded('Mortised apron',(x,y+dy,.64),(w*.80,.045,.11),m['wood'],.01)
    if MAP=='bondszaal':
        for dx in [-w*.32,w*.32]:rounded('Hall trestle',(x+dx,y,.12),(.14,d*.77,.14),m['wood'],.024)
        limb('Hall stretcher',(x-w*.32,y,.24),(x+w*.32,y,.24),.045,m['wood'])
    if kind in ['study_desk','student_desk'] or kind.startswith('novice_'):
        # Existing narrative props remain on the table, with no new interaction.
        px=x-w*.30;py=y+d*.27
        rounded('Personal notebook',(px,py,.838),(.23,.17,.029),m['blue' if MAP=='academy_study' else 'cream'],.006)
        for j in range(4):box('Notebook rule',(px,py-.05+j*.027,.854),(.15,.002,.001),m['wood'])
        limb('Resting pencil',(px-.07,py+.035,.859),(px+.06,py+.055,.859),.006,m['amber'])
    if MAP in ['attic','academy_study','academy_dorm'] and kind in ['study_desk','student_desk']:
        cup(x+w*.30,y-d*.22,.825,m)

def cabinet(x,y,w,d,m,kind):
    from common import cylinder,box
    original_cabinet(x,y,w,d,m,kind)
    if kind=='washer_bank':
        count=max(1,round(w/.7))
        for j in range(count):
            cx=x-w*.5+(j+.5)*w/count
            knob=cylinder('Washer selector',(cx+.075,y-d*.516,.83),.031,.022,m['cream'],24);knob.rotation_euler.x=math.pi/2
            rounded('Detergent drawer',(cx-.09,y-d*.505,.88),(.13,.021,.05),m['stone'],.006)
            for k in range(3):box('Vent slot',(cx-.08+k*.06,y-d*.49,.19),(.025,.014,.005),m['metal'])
        rounded('Folded towel bottom',(x+w*.27,y,1.02),(.39,.27,.035),m['cloth'],.012)
        rounded('Folded towel top',(x+w*.27,y,1.055),(.36,.25,.032),m['cream'],.012)
    else:
        for j in range(max(1,round(w/.65))):
            px=x-w*.36+(j+.5)*w*.72/max(1,round(w/.65))
            handle=cylinder('Cabinet brass pull',(px,y-d*.497,.67),.020,.025,m['amber'],16);handle.rotation_euler.x=math.pi/2
        if kind=='folding_counter':
            for j in range(3):rounded('Folded cloth',(x-w*.25,y,1.07+j*.034),(.38-j*.018,.29,.03),m['cream' if j%2 else 'cloth'],.01)
        if kind=='tea_station':cup(x+w*.27,y-d*.12,1.047,m)
        if kind=='reception':
            rounded('Registration folio',(x-w*.25,y-d*.16,1.063),(.36,.27,.028),m['cloth'],.008)
            box('Folio paper',(x-w*.25,y-d*.16,1.079),(.32,.23,.002),m['cream'])

def bench(x,y,w,d,m):
    from common import limb
    original_bench(x,y,w,d,m)
    for dx in [-w*.43,w*.43]:
        rounded('Bench arm',(x+dx,y,.63),(.06,d*.85,.06),m['wood'],.016)
        limb('Arm support',(x+dx,y-d*.28,.40),(x+dx,y-d*.28,.62),.022,m['metal'])

def export(output,data):
    from common import box,limb
    from live_export import PALETTE
    from furniture import STEAM as cups
    floor,plaster,cloth,ambient,sun,angle=ROOMS[MAP]
    palette={**PALETTE,'floor':floor,'plaster':plaster,'cloth':cloth,'wood':'967658','white':'e5e0d3'}
    mats={m.name.split('.')[0]:m for m in bpy.data.materials}
    # Replace the segmented back/side wall by identical contiguous runs.
    runs={}
    for obj in list(bpy.data.objects):
        if obj.name.startswith(('cutaway wall','wainscot')):
            horizontal=obj.dimensions.x>obj.dimensions.y
            key=(obj.name.split('.')[0],horizontal,round(obj.location.y if horizontal else obj.location.x,4))
            runs.setdefault(key,[]).append(obj)
        if obj.name.startswith('plank seam'):bpy.data.objects.remove(obj,do_unlink=True)
        elif obj.name.startswith('ground') and obj.data.materials and obj.data.materials[0].name.split('.')[0] in ['floor','paving']:
            obj.dimensions.x=.800;obj.dimensions.y=.800
    for (kind,horizontal,fixed),objects in runs.items():
        objects.sort(key=lambda o:o.location.x if horizontal else o.location.y)
        groups=[]
        for o in objects:
            at=o.location.x if horizontal else o.location.y
            if not groups or at-groups[-1][-1][0]>.81:groups.append([])
            groups[-1].append((at,o))
        for group in groups:
            first=group[0][1];a=group[0][0]-.4;b=group[-1][0]+.4
            z=first.location.z;mat=first.data.materials[0];height=first.dimensions.z;thickness=first.dimensions.y if horizontal else first.dimensions.x
            for _,o in group:bpy.data.objects.remove(o,do_unlink=True)
            at=((a+b)/2,fixed,z) if horizontal else (fixed,(a+b)/2,z)
            size=(b-a,thickness,height) if horizontal else (thickness,b-a,height)
            rounded('Continuous '+kind,at,size,mat,.007)
    for seat in [o for o in bpy.data.objects if o.name.startswith('chair seat')]:
        x,y=seat.location.x,seat.location.y
        for dx in [-.17,.17]:
            rounded('Chair upright',(x+dx,y+.16,.58),(.034,.043,.46),mats['wood'],.008)
            limb('Chair stretcher',(x+dx,y-.15,.19),(x+dx,y+.15,.19),.013,mats['wood'])
        rounded('Chair curved rail',(x,y+.16,.77),(.37,.045,.066),mats['wood'],.015)
        rounded('Seat cushion',(x,y,.435),(.36,.33,.035),mats['cloth'],.013)
    # Subtle structural detailing follows existing objects, never arbitrary path positions.
    for obj in list(bpy.data.objects):
        if obj.type!='MESH':continue
        if obj.name.startswith('window frame'):
            x,y,z=obj.location;w=obj.dimensions.x
            rounded('Window sill',(x,y-.13,z-.84),(w+.06,.33,.06),mats['cream'],.013)
        if obj.name.startswith('book') and not obj.name.startswith('book_shelf'):
            x,y,z=obj.location
            box('Book spine label',(x,y-.106,z+.07),(.055,.004,.046),mats['cream'])
        for mod in obj.modifiers:
            if mod.type=='BEVEL':mod.segments=3
    for mat in bpy.data.materials:
        key=mat.name.split('.')[0]
        if key in palette:
            h=palette[key];mat.diffuse_color=tuple(int(h[i:i+2],16)/255 for i in (0,2,4))+(1,)
        mat.use_nodes=True;n=mat.node_tree.nodes;n.clear();bs=n.new('ShaderNodeBsdfPrincipled');bs.inputs['Base Color'].default_value=mat.diffuse_color;bs.inputs['Roughness'].default_value=.84
        o=n.new('ShaderNodeOutputMaterial');mat.node_tree.links.new(bs.outputs[0],o.inputs[0])
    for obj in list(bpy.data.objects):
        if obj.type in ['CAMERA','LIGHT']:bpy.data.objects.remove(obj,do_unlink=True)
    groups={}
    for obj in list(bpy.context.scene.objects):
        if obj.type!='MESH':continue
        bpy.context.view_layer.objects.active=obj
        for mod in list(obj.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
        groups.setdefault(tuple(m.name for m in obj.data.materials),[]).append(obj)
    for key,objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name='Campaign_'+'_'.join(key)
    bpy.ops.export_scene.gltf(filepath=str(output/'room.glb'),export_format='GLB',export_animations=False,export_yup=True)
    source=ROOT/'data/maps'/(MAP+'.json')
    (output/'room-manifest.json').write_text(json.dumps({'map':MAP,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'metres_per_tile':.8,'steam':STEAM+cups,'ambient':ambient,'sun':sun,'angle':angle,'indoors':data.get('indoors',False)},indent=2)+'\n')

def lighting_manifest(output,map_id):
    """Window fills come from the very same prop rectangles as the geometry."""
    from art_specs import SPECS
    source=ROOT/'data/maps'/(map_id+'.json');data=json.loads(source.read_text())
    file=output/'room-manifest.json';manifest=json.loads(file.read_text())
    fills=[]
    if data.get('indoors'):
        for prop in data.get('art_props',[]):
            if prop['art'] not in ['school_glass','tall_window']:continue
            px,py=prop['position'];width=SPECS[prop['art']].size[0]
            fills.append([(px+width/2)*.05,1.55,max(2.3,py/16)*.8+.32])
    manifest['window_fills']=fills
    manifest['seats']=[npc['id'] for npc in data.get('npcs',[]) if npc.get('idle')=='play']
    file.write_text(json.dumps(manifest,indent=2)+'\n')
