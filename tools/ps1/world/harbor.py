"""Jaffa-inspired working harbor: warm masonry, low sheds and fishing boats.

All meshes are original. Scenery stays on existing solid tiles or beyond the quay.
"""
import math,random
import bpy
from common import box,material,cylinder,limb,sphere
from .white_city import prism


def stone_palette(m):
    result=dict(m)
    for name,colour in [('harbor stone',(.66,.51,.32)),('harbor mortar',(.40,.35,.26)),('harbor blue',(.10,.42,.59)),('harbor green',(.14,.38,.25))]:
        result[name]=bpy.data.materials.get(name) or material(name,colour,24)
    return result


def arch(x,y,width,spring,depth,m):
    """Open voussoir arch, rather than a lintel disguising a rectangular hole."""
    m=stone_palette(m);r=width/2-.19;thick=.23
    for dx in [-r-thick/2,r+thick/2]:
        box('stone arch pier',(x+dx,y,spring/2),(thick,depth,spring),m['harbor stone'],.02)
        for z in [.32,.68,1.04,1.40]:
            if z<spring:box('pier joint',(x+dx,y-depth/2-.005,z),(thick,.01,.018),m['harbor mortar'])
    for i in range(11):
        a=i*math.pi/11+.008;b=(i+1)*math.pi/11-.008
        outline=[(x+r*math.cos(a),spring+r*math.sin(a)),(x+(r+thick)*math.cos(a),spring+(r+thick)*math.sin(a)),(x+(r+thick)*math.cos(b),spring+(r+thick)*math.sin(b)),(x+r*math.cos(b),spring+r*math.sin(b))]
        vertices=[(px,y+dy,pz) for dy in [-depth/2,depth/2] for px,pz in outline]
        mesh=bpy.data.meshes.new('voussoir');mesh.from_pydata(vertices,[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]);mesh.update()
        obj=bpy.data.objects.new('arch stone',mesh);bpy.context.collection.objects.link(obj);mesh.materials.append(m['harbor stone'])


def storehouse(x,y,w,d,height,m,variant=0):
    front=y-d/2
    box('port stone storehouse',(x,y,height/2),(w,d,height),m['harbor stone'],.035)
    box('stone roof coping',(x,y,height),(w+.12,d+.12,.14),m['cream'])
    for z in [.35,.8,1.25,1.7,2.15,2.6,3.05]:
        if z>=height:continue
        box('masonry course',(x,front-.018,z),(w,.008,.015),m['harbor mortar'])
        for i in range(int(w/.7)):
            px=x-w/2+.35+i*.7+(int(z*3)%2)*.30
            box('stone vertical joint',(px,front-.02,z-.21),(.012,.008,.40),m['harbor mortar'])
    for dx in [-w*.29,w*.29]:
        width=min(1.15,w*.26);radius=width/2
        # Filled arch-shaped dark recess in the facade, framed by separate stones.
        outline=[(x+dx-radius,0),(x+dx+radius,0)]+[(x+dx+radius*math.cos(a*math.pi/10),1.15+radius*math.sin(a*math.pi/10)) for a in range(11)]
        mesh=bpy.data.meshes.new('arched door shadow');mesh.from_pydata([(px,front-.025,z) for px,z in outline],[],[tuple(range(len(outline)))]);mesh.update()
        obj=bpy.data.objects.new('arched door shadow',mesh);bpy.context.collection.objects.link(obj);mesh.materials.append(m['metal'])
        arch(x+dx,front-.08,width+.38,1.15,.18,m)
        box('weathered harbor door',(x+dx,front-.06,.57),(width-.08,.035,1.08),m['harbor blue' if variant%2 else 'harbor green'])
        if height>3:
            box('upper shutter frame',(x+dx,front-.02,height-.68),(.63,.06,.79),m['cream'])
            box('upper sea shutter',(x+dx,front-.06,height-.68),(.52,.04,.68),m['harbor blue'])
    if variant%2:
        box('stepped roof room',(x+w*.17,y+.23,height+.46),(w*.54,d*.64,.90),m['harbor stone'])
        box('small terracotta roof',(x+w*.17,y+.23,height+.94),(w*.57,d*.68,.08),m['terra'])


def boat(x,y,length,m,green=False,angle=0):
    before=set(bpy.data.objects);w=length*.30
    outline=[(-length*.46,-w*.48),(length*.23,-w*.5),(length*.5,0),(length*.23,w*.5),(-length*.46,w*.48)]
    prism('fishing boat hull',outline,-.04,.29,m['harbor green' if green else 'harbor blue'])
    prism('white gunwale',outline,.25,.07,m['cream'])
    prism('open working deck',[(a*.9,b*.82) for a,b in outline],.32,.013,m['wood'])
    box('small wheelhouse',(-length*.17,0,.63),(length*.26,w*.69,.59),m['cream'])
    for side in [-1,1]:box('wheelhouse side glass',(-length*.17,side*w*.35,.72),(length*.20,.02,.24),m['glass'])
    box('wheelhouse front glass',(-length*.035,0,.72),(.02,w*.56,.23),m['glass'])
    box('cabin blue roof',(-length*.17,0,.96),(length*.32,w*.87,.075),m['harbor blue'])
    limb('fishing mast',(length*.10,0,.32),(length*.10,0,1.55),.025,m['metal'])
    limb('fishing boom',(length*.10,0,1.45),(length*.35,0,1.03),.02,m['cream'])
    for side in [-1,1]:
        for dx in [-length*.28,length*.18]:
            fender=cylinder('rubber fender',(dx,side*w*.51,.21),.10,.065,m['ink']);fender.rotation_euler.x=math.pi/2
    box('net box',(length*.17,0,.43),(.34,.32,.19),m['cloth'])
    for i in range(3):box('net cord',(length*.17-.10+i*.1,0,.535),(.015,.32,.018),m['cream'])
    # Transform the complete authored boat together; proportions stay consistent.
    for obj in set(bpy.data.objects)-before:
        ox,oy,oz=obj.location
        obj.location=(x+ox*math.cos(angle)-oy*math.sin(angle),y+ox*math.sin(angle)+oy*math.cos(angle),oz)
        obj.rotation_euler.z+=angle


def context(w,h,m):
    m=stone_palette(m)
    # Split around the actual stair exit at x=10.4; the old town rises behind it.
    storehouse(3.7,2.4,7.1,3.1,3.1,m,0)
    storehouse(16.5,2.5,8.1,3.3,3.6,m,1)
    for i,x in enumerate([-5,1,7,14,20,26]):storehouse(x,7.5,4.7,4,3.6+(i%3)*.5,m,i)
    # A low industrial shed keeps the port from reading as only a picturesque village.
    box('harbor shed',(-5,-1,1.45),(5,4,2.9),m['stone'])
    for side in [-1,1]:
        roof=box('corrugated shed roof',(-5,-1+side,3.15),(5.3,2.3,.12),m['metal']);roof.rotation_euler.x=-side*.26
    for i in range(12):box('shed seam',(-7.4+i*.44,-3.01,1.46),(.025,.035,2.75),m['cream'])
    box('shed faded blue band',(-5,-3.045,2.05),(5,.03,.26),m['harbor blue'])
    # Quay face begins beyond row seven; all walking lanes and review approaches remain open.
    for i in range(-12,39):
        box('quay coping block',(i*.8+.4,-6.32,.025),(.78,.29,.16),m['harbor stone'],.02)
    for x,y,length,green,angle in [(3.0,-8.5,3.3,False,.1),(8.1,-9.2,3.6,True,-.08),(15.2,-8.7,3.5,False,.22),(20.6,-10.0,2.8,True,.08),(-3,-10.2,2.9,False,-.3)]:
        boat(x,y,length,m,green,angle)
        limb('mooring line',(x-length*.25,y+.4,.31),(x-.7,-6.35,.13),.012,m['wood'])
    rng=random.Random(71)
    for i in range(26):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(-10+i*1.55,-17+rng.uniform(-.75,.75),-.08))
        rock=bpy.context.object;rock.name='angular breakwater stone'
        rock.scale=(rng.uniform(.7,1.25),rng.uniform(.6,1),rng.uniform(.35,.65))
        rock.rotation_euler=(rng.uniform(-.3,.3),rng.uniform(-.2,.2),rng.uniform(0,math.pi))
        rock.data.materials.append(m['stone'])
    # Mooring coils are off the footpath, beside existing bollards at the quay lip.
    for x in [4.4,15.6]:
        for r in [.10,.15,.20]:
            bpy.ops.mesh.primitive_torus_add(major_radius=r,minor_radius=.015,major_segments=12,minor_segments=4,location=(x,-6.22,.15))
            bpy.context.object.name='mooring rope coil';bpy.context.object.data.materials.append(m['wood'])
