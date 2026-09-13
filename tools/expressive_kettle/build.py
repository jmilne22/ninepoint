"""Blender/Python authored room and full-body cast for the one-area style POC."""
import sys, math, json
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(Path(__file__).parent),str(ROOT/'tools/table_scene'),str(ROOT/'tools')]
from mesh import material
from characters import CHARACTERS
from people import build_person
OUT=ROOT/'art/expressive_kettle';OUT.mkdir(parents=True,exist_ok=True)

def reset():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.data.orphans_purge(do_recursive=True);bpy.context.scene.render.fps=30

def export(name,animation=False):
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_animations=animation,
        export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_yup=True)

for spec in CHARACTERS:
    if spec['id'] in ['player','wren','kesh','tomas']:
        reset();build_person(spec);export(spec['id'],True)
reset()
M={k:material(k,c) for k,c in {'plaster':'#e8dcc0','wood':'#ac8054','edge':'#765236','cream':'#f5e8c9',
    'green':'#456c5b','dark':'#263b37','gold':'#d5ac59','blue':'#acd4d0','terra':'#c58262',
    'leaf':'#597b51','leaflight':'#86a06b','ink':'#303b35','black':'#1c282b','white':'#f3eddc'}.items()}
collisions=[]

def box(name,x,y,z,sx,sy,sz,mat,bevel=.025,solid=False):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(x,-z,y));o=bpy.context.object;o.name=name
    o.dimensions=(sx,sz,sy);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(M[mat])
    if bevel:
        mod=o.modifiers.new('Soft edges','BEVEL');mod.width=bevel;mod.segments=2
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
        o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    if solid:collisions.append([x,z,sx,sz])
    return o

def cylinder(name,x,y,z,r,depth,mat,vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=(x,-z,y))
    o=bpy.context.object;o.name=name;o.data.materials.append(M[mat]);return o

def sphere(name,x,y,z,s,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=(x,-z,y));o=bpy.context.object
    o.name=name;o.scale=s;o.data.materials.append(M[mat]);return o

box('Room foundation',0,-.18,0,10.6,.35,7.2,'edge')
for row in range(18):
    z=-3.3+row*.38
    for col in range(5):
        x=-4.1+col*2.08
        box('Oak floor',x,0,z,2.065,.055,.368,'wood',.006)
box('Back plaster',0,1.75,-3.5,10.6,3.5,.16,'plaster',solid=True)
box('Window wall',-5.22,1.75,0,.16,3.5,7.1,'plaster',solid=True)
for z in [-3.37,3.40]:box('Floor border',0,.075,z,10.4,.12,.12,'edge')
box('Wall skirting',0,.30,-3.37,10.4,.5,.10,'green')
box('Wall cap',0,3.52,-3.5,10.7,.12,.25,'cream')
box('Left cap',-5.22,3.52,0,.25,.12,7.2,'cream')
box('Left skirting',-5.10,.28,0,.12,.5,7,'green')
# Broad seaward window: painted sky, mullions, planter and a generous sill.
box('Window recess',-5.08,2.13,-.55,.035,1.95,3.65,'dark')
box('Sea glass',-5.045,2.15,-.55,.018,1.65,3.38,'blue')
for z in [-2.27,-.55,1.17]:box('Window mullion',-4.98,2.17,z,.13,1.91,.09,'cream')
for y in [1.23,2.18,3.07]:box('Window rail',-4.98,y,-.55,.13,.10,3.55,'cream')
box('Window sill',-4.94,1.19,-.55,.48,.12,3.8,'cream')
# A little coastal skyline behind the glass, kept subordinate to the room.
for j in range(7):
    z=-1.97+j*.44
    box('Distant facade',-5.025,1.55+(j%3)*.055,z,.008,.25+(j%3)*.11,.34,'cream',0)
box('Sea horizon',-5.015,1.42,-.55,.008,.028,3.32,'green',0)
# Bar on the right, backed by cups and bottles.
box('Bar cabinet',3.30,.63,-1.84,3.12,1.25,.83,'green',solid=True)
for x in [2.25,3.28,4.30]:box('Cabinet panel',x,.64,-1.407,.91,.93,.035,'dark')
box('Bar top',3.30,1.31,-1.82,3.35,.16,1.03,'wood')
box('Bar foot rail',3.28,.24,-1.26,3.2,.07,.07,'gold')
for y in [1.65,2.38,3.08]:
    box('Back shelf',3.18,y,-3.11,3.74,.10,.50,'edge')
    for j in range(8):
        x=1.65+j*.43
        if y==2.38:
            cylinder('Ceramic cup',x,y+.16,-3.1,.095,.23,'cream')
            cylinder('Cup hollow',x,y+.279,-3.1,.070,.005,'dark')
        else:
            cylinder('Bottle',x,y+.22,-3.1,.075,.32,'green' if j%2 else 'terra')
            cylinder('Bottle neck',x,y+.43,-3.1,.034,.13,'gold')
# Tables, chairs and tiny playable-looking Go sets.
def chair(x,z,angle=0):
    box('Chair seat',x,.53,z,.58,.10,.58,'green')
    for dx in [-.22,.22]:
        for dz in [-.22,.22]:box('Chair leg',x+dx,.28,z+dz,.06,.51,.06,'edge')
    box('Chair back',x,1.0,z-.25,.57,.57,.065,'green')
    collisions.append([x,z,.58,.58])

def board(x,z,n=9):
    box('Kaya board',x,.965,z,.77,.11,.80,'gold',.018)
    for i in range(n):
        a=-.31+i*.62/(n-1)
        box('Board grid',x+a,1.024,z,.006,.003,.62,'ink',0)
        box('Board grid',x,1.024,z+a,.62,.003,.006,'ink',0)
    for j in range(9):
        a=(j*5%9-4)*.0775;b=(j*7%9-4)*.0775
        sphere('Set stone',x+a,1.045,z+b,(.035,.035,.016),'black' if j%2 else 'white')
    for s in [-1,1]:cylinder('Stone bowl',x+s*.58,1.00,z+.05,.135,.17,'edge')

def table(x,z):
    box('Table top',x,.89,z,1.8,.14,1.22,'wood',.06,True)
    for dx in [-.69,.69]:
        for dz in [-.43,.43]:box('Table leg',x+dx,.45,z+dz,.09,.84,.09,'edge')
    board(x,z)

table(-2.65,-1.70);chair(-2.65,-2.6)
table(.05,.35);chair(.05,-.6);chair(.05,1.30)
# Cups and a water jug make this an everyday bar as well as a place to play.
for x,z,y in [(-2.00,-1.89,.995),(.70,.03,.995),(2.43,-1.69,1.44)]:
    cylinder('Cup saucer',x,y,z,.12,.025,'cream')
    cylinder('Coffee cup',x,y+.09,z,.08,.16,'cream')
    cylinder('Coffee',x,y+.174,z,.062,.003,'edge')
cylinder('Water jug',4.26,1.62,-1.80,.13,.48,'terra')
cylinder('Jug lip',4.26,1.88,-1.80,.10,.06,'cream')
# Ficus, a small sunlit pottery cluster and a wall board.
def plant(x,z,scale=1):
    cylinder('Terracotta pot',x,.23*scale,z,.24*scale,.45*scale,'terra')
    cylinder('Pot rim',x,.44*scale,z,.26*scale,.09*scale,'terra')
    cylinder('Soil',x,.49*scale,z,.22*scale,.008,'dark')
    cylinder('Plant stem',x,.90*scale,z,.035*scale,.85*scale,'edge')
    from mathutils import Vector
    for i in range(22):
        a=i*2.4;r=(.18+(i%3)*.07)*scale
        cy=(.86+i*.022)*scale
        bx=x+r*math.cos(a);bz=z+r*math.sin(a)
        start=Vector((x,-z,.66*scale));tip=Vector((bx,-bz,cy))
        bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.008*scale,depth=(tip-start).length,location=(start+tip)*.5)
        stem=bpy.context.object;stem.name='Leaf stem';stem.rotation_euler=(tip-start).to_track_quat('Z','Y').to_euler();stem.data.materials.append(M['leaf'])
        verts=[(bx,-bz,cy+.024*scale)];faces=[]
        for j in range(12):
            angle=j*math.tau/12
            along=.20*scale*math.cos(angle);across=.085*scale*math.sin(angle)
            vx=bx+along*math.cos(a)-across*math.sin(a)
            vz=bz+along*math.sin(a)+across*math.cos(a)
            verts.append((vx,-vz,cy-.07*abs(math.cos(angle))*scale))
        for j in range(12):faces.append((0,(j+1)%12+1,j+1))
        mesh=bpy.data.meshes.new('Ficus leaf');mesh.from_pydata(verts,[],faces);mesh.update()
        leaf=bpy.data.objects.new('Ficus leaf',mesh);bpy.context.collection.objects.link(leaf)
        leaf.data.materials.append(M['leaflight' if i%3 else 'leaf'])
        solid=leaf.modifiers.new('Leaf thickness','SOLIDIFY');solid.thickness=.005
        bpy.context.view_layer.objects.active=leaf;bpy.ops.object.modifier_apply(modifier=solid.name)
    collisions.append([x,z,.45*scale,.45*scale])
plant(-4.40,2.58,1.05);plant(4.53,1.75,.85)
box('Notice board frame',-.33,2.38,-3.38,2.04,1.32,.09,'edge')
box('Notice board',-.33,2.38,-3.31,1.85,1.14,.035,'green')
for j in range(3):
    box('Club note',-.90+j*.56,2.40+(j%2)*.10,-3.27,.40,.62,.01,'cream',0)
    for k in range(4):box('Handwritten rule',-.90+j*.56,2.54-k*.10+(j%2)*.10,-3.258,.25,.012,.002,'edge',0)
# Light patches are deliberate broad painted shapes, matching the cast's tonal steps.
box('Sun on floor',-3.52,.033,1.01,2.14,.006,1.32,'gold',0)
for z in [.70,1.32]:box('Window shadow line',-3.52,.038,z,2.14,.004,.05,'edge',0)
# Door and threshold frame the open, camera-facing edge without obscuring movement.
box('Door mat',3.13,.05,2.81,1.72,.04,.74,'green',.015)
for i in range(7):box('Mat weave',2.42+i*.23,.073,2.81,.018,.004,.68,'gold',0)
export('room')
(OUT/'layout.json').write_text(json.dumps({'collision':collisions,'bounds':[-5,5,-3.25,3.25],
    'spawn':[2.8,2.35],'people':[{'id':'wren','at':[-2.35,-.50]},{'id':'kesh','at':[-3.70,1.05]},{'id':'tomas','at':[3.60,-2.52]}]},indent=2)+'\n')
print('EXPRESSIVE KETTLE EXPORTED')
