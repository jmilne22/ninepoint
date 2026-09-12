"""Original low-poly tram, informed by the Tel Aviv Red Line CRRC exterior.

Five separately rendered sections retain ground sorting along the long vehicle.
Reference links and deliberate scale compression: docs/ps1/world/tram.md.
"""
import sys, math, json
from pathlib import Path
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import reset, material, box, limb, cylinder, camera, light, render


def mesh(name, verts, faces, mat):
    data=bpy.data.meshes.new(name);data.from_pydata(verts, [], faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def cab(sign, m):
    # Cross-sections form a raked, wraparound screen rather than a box with a decal.
    rings=[(.32,.64,1.15),(.53,.75,1.26),(.80,.79,1.24),
           (.96,.80,1.17),(1.60,.79,.94),(2.10,.70,.58),
           (2.27,.57,.37),(2.35,.34,.20)]
    for j in range(len(rings)-1):
        verts=[]
        for z,width,reach in rings[j:j+2]:
            for k in range(13):
                a=-math.pi/2+k*math.pi/12
                verts.append((sign*(6.06+reach*math.cos(a)),width*math.sin(a),z))
        mat=m['glass'] if j in [3,4] else m['silver'] if j==2 else m['white']
        mesh('curved cab windscreen' if j in [3,4] else 'rounded cab shell',verts,
             [(k,k+1,k+14,k+13) for k in range(12)],mat)
    box('cab roof crown',(sign*6.13,0,2.28),(.5,.68,.13),m['white'],.08)
    for side in [-1,1]:
        # Lamp recesses follow the front quarter panels, below the windscreen.
        x=sign*7.10;y=side*.43
        lamp=box('headlight recess',(x,y,.84),(.09,.30,.15),m['rubber'],.035)
        lamp.rotation_euler.z=sign*side*.38
        bulb=box('headlight',(x+sign*.05,y,.84),(.02,.16,.055),m['lamp'],.014)
        bulb.rotation_euler.z=sign*side*.38
        box('cab side glass',(sign*6.02,side*.805,1.57),(.36,.015,.76),m['glass'],.04)
        # Sela keeps its own small transport lozenge, not the operator's logo.
        badge=box('Sela turquoise badge',(sign*5.91,side*.808,.98),(.12,.018,.12),m['teal'])
        badge.rotation_euler.y=math.pi/4
    limb('windscreen wiper',(sign*7.245,-.22,.99),(sign*6.98,.13,1.53),.013,m['rubber'])
    limb('wiper blade',(sign*7.03,-.04,1.40),(sign*6.86,.24,1.70),.014,m['rubber'])
    box('coupler recess',(sign*7.29,0,.39),(.05,.32,.13),m['rubber'],.02)


def build(out):
    out.mkdir(parents=True,exist_ok=True)
    scene=reset(384,272)
    m={key:material(key,col) for key,col in {
        'white':(.82,.85,.85),'silver':(.44,.50,.53),'rubber':(.035,.042,.046),
        'glass':(.018,.038,.055),'reflection':(.10,.17,.21),
        'vent':(.20,.25,.27),'teal':(.06,.40,.44),'lamp':(.91,.95,.81),
    }.items()}
    for key in ['white','glass','silver']:
        m[key].node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.35 if key=='glass' else .65
    centres=[-4.92,-2.46,0,2.46,4.92]
    for i,x in enumerate(centres):
        before=set(bpy.data.objects)
        box('white low floor shell',(x,0,1.28),(2.28,1.60,2.03),m['white'],.13)
        box('recessed underframe',(x,0,.27),(2.20,1.21,.26),m['rubber'],.035)
        for side in [-1,1]:
            y=side*.804
            box('continuous dark window band',(x,y,1.55),(2.08,.025,.85),m['glass'],.025)
            box('sky reflection',(x,y+side*.016,1.81),(1.98,.008,.075),m['reflection'])
            # Flush double doors: dark outlines run below the window belt.
            door=x+(.36 if i%2==0 else -.34)
            box('door recess',(door,y+side*.022,1.18),(.64,.014,1.70),m['rubber'],.012)
            for dx in [-.161,.161]:
                box('white door leaf',(door+dx,y+side*.033,1.17),(.304,.011,1.66),m['white'])
                box('door glass',(door+dx,y+side*.042,1.57),(.243,.008,.86),m['glass'])
            box('door request button',(door+.24,y+side*.051,.98),(.036,.01,.054),m['teal'])
            box('window mullion',(x-.80,y+side*.02,1.54),(.035,.015,.83),m['silver'])
        box('roof equipment fairing',(x,0,2.32),(1.74,1.18,.20),m['white'],.10)
        for side in [-1,1]:
            for n in range(10):
                box('roof ventilation slot',(x-.68+n*.14,side*.597,2.33),(.038,.018,.12),m['vent'])
        for dx in [-.64,.64]:
            for side in [-1,1]:
                wheel=cylinder('partly shrouded wheel',(x+dx,side*.57,.22),.22,.11,m['rubber'])
                wheel.rotation_euler.x=math.pi/2
        if i<4:
            joint=x+1.23
            box('flexible gangway',(joint,0,1.24),(.18,1.46,1.94),m['rubber'],.06)
            for dx in [-.06,0,.06]:
                box('accordion rib',(joint+dx,0,1.24),(.022,1.55,2.01),m['vent'],.055)
        if i in [0,4]:cab(-1 if i==0 else 1,m)
        if i==2:
            box('pantograph mounting',(x,0,2.48),(.64,.60,.10),m['vent'])
            for side in [-1,1]:
                limb('pantograph lower arm',(-.35,side*.25,2.52),(.22,side*.25,2.95),.026,m['vent'])
                limb('pantograph upper arm',(.22,side*.25,2.95),(-.25,side*.25,3.26),.020,m['vent'])
            limb('contact shoe',(-.25,-.53,3.26),(-.25,.53,3.26),.026,m['rubber'])
        for obj in set(bpy.data.objects)-before:obj['tram_section']=i
    # Match the world's 45-degree azimuth, 30-degree elevation and 32 px/unit.
    target=Vector((0,0,.72))
    cam=camera(target+Vector((10,-10,math.sqrt(200/3))),target,12)
    light('coastal daylight',(-3,-5,9),(1,.93,.82),1050,6)
    light('sky fill',(5,4,6),(.62,.78,1),600,5)
    bpy.context.view_layer.update()
    origin=world_to_camera_view(scene,cam,Vector((0,0,0)))
    manifest={'size':[384,272],'origin':[round(origin.x*384),round((1-origin.y)*272)],
              'sections':[{'texture':f'tram_{i}.png','ground':[x*20,0]} for i,x in enumerate(centres)]}
    (out/'tram.json').write_text(json.dumps(manifest,indent=2)+'\n')
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'tram.blend'))
    render(out/'tram.png')
    objects=[obj for obj in bpy.data.objects if 'tram_section' in obj]
    for i in range(5):
        for obj in objects:obj.hide_render=obj['tram_section']!=i
        render(out/f'tram_{i}.png')

if __name__=='__main__':
    build(Path(sys.argv[sys.argv.index('--')+1]))
