"""Original coastal modernist facades: silhouettes and shade before small detail.

References and the choices taken from them live in docs/ps1/polish/references.md.
Door centres come from the map's existing warps; balconies stay above head height.
"""
import math
import bpy
from common import box,material,cylinder
from .entrances import door


def prism(name,outline,z,height,mat):
    n=len(outline)
    vertices=[(x,y,h) for h in [z,z+height] for x,y in outline]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
    mesh.materials.append(mat)
    return obj


def rounded_front(x,front,w,depth):
    r=min(.65,w*.16,depth*.8); left=x-w/2;right=x+w/2
    points=[(left,front+depth),(right,front+depth),(right,front+r)]
    for i in range(1,7):
        a=-math.pi/2*i/6
        points.append((right-r+r*math.cos(a),front+r+r*math.sin(a)))
    points.append((left+r,front))
    for i in range(1,7):
        a=-math.pi/2-math.pi/2*i/6
        points.append((left+r+r*math.cos(a),front+r+r*math.sin(a)))
    return points


def pane(x,y,z,w,h,m,shutters=False):
    box('recessed window',(x,y,z),(w,.04,h),m['metal'])
    box('window glass',(x,y-.026,z),(w-.12,.018,h-.10),m['glass'])
    box('window centre bar',(x,y-.045,z),(.025,.04,h),m['cream'])
    if shutters:
        for side in [-1,1]:
            box('folded shutter',(x+side*(w/2+.10),y-.08,z),(.16,.10,h),m['cloth'])


def facade(kind,x,y,w,d,m,door_centres=None,variant=None):
    variant={'sela_home':0,'sela_bar':1,'sela_laundry':2}[kind] if variant is None else variant%5
    height=[4.5,3.85,4.15,3.6,4.75][variant]
    wall=bpy.data.materials.get('white city plaster '+str(variant))
    if not wall:
        wall=material('white city plaster '+str(variant),[(.83,.81,.72),(.77,.76,.66),(.80,.83,.79),(.70,.69,.59),(.86,.82,.73)][variant],18)
    front=y-d/2
    # A real recess: the upper wall sits behind the balcony, so the dark band is
    # cast shade, not a black stripe painted onto the elevation.
    setback=.50 if variant in [0,1,4] else .12
    box('ground floor',(x,y,1.02),(w,d,2.04),wall,.025)
    box('upper residence',(x,y+setback/2,(height+2.04)/2),(w,d-setback,height-2.04),wall,.025)
    box('flat roof coping',(x,y+.08,height),(w+.08,d-.06,.14),m['cream'])
    if variant in [0,4]:
        for z in ([2.22,3.50] if variant==0 else [2.30,3.70]):
            outline=rounded_front(x,front-.10,w*.96,.80)
            prism('rounded balcony floor',outline,z,.10,m['cream'])
            # The parapet follows the same curved edge, with a gap behind it.
            outer=outline[2:]+[outline[0]]
            for a,b in zip(outer,outer[1:]):
                dx,dy=b[0]-a[0],b[1]-a[1]
                part=box('curved balcony parapet',((a[0]+b[0])/2,(a[1]+b[1])/2,z+.31),(math.hypot(dx,dy)+.015,.095,.40),wall)
                part.rotation_euler.z=math.atan2(dy,dx)
            for dx in [-w*.29,w*.29]:pane(x+dx,front+setback-.015,z+.58,w*.29,.78,m)
    elif variant==1:
        box('deep loggia floor',(x,front+.12,2.18),(w,.83,.13),m['cream'])
        box('horizontal balcony parapet',(x,front-.22,2.51),(w-.10,.13,.50),wall)
        for dx in [-w*.47,w*.47]:box('loggia end cheek',(x+dx,front+.10,2.95),(.13,.74,1.4),wall)
        for dx in [-w*.32,0,w*.32]:pane(x+dx,front+.48,3.04,w*.25,.91,m)
        box('deep shade canopy',(x,front+.1,3.67),(w+.10,.92,.13),m['cream'])
    elif variant==2:
        stair_x=x+w*.31
        pane(stair_x,front-.015,2.76,.61,2.38,m)
        for z in [1.76,2.32,2.89,3.46]:box('stairwell crossbar',(stair_x,front-.055,z),(.61,.04,.055),m['cream'])
        for z in [2.57,3.57]:
            for dx in [-w*.32,0]:pane(x+dx,front+.10,z,w*.22,.62,m,True)
        box('stair tower coping',(stair_x,y,height+.18),(w*.22,d*.88,.35),wall)
    else:
        for dx in [-w*.31,0,w*.31]:pane(x+dx,front+.10,2.92,w*.22,.83,m,True)
        box('roof terrace room',(x-w*.19,y+.36,height+.29),(w*.43,max(.5,d*.55),.58),wall)
        for dx in [-w*.46,w*.46]:box('terrace side rail',(x+dx,y,height+.25),(.035,d,.035),m['metal'])
        box('terrace front rail',(x,front+.07,height+.25),(w,.035,.035),m['metal'])
    # Side elevations matter to a fixed diagonal camera as much as the front.
    for dy in [-d*.22,d*.22]:
        obj=box('side window recess',(x+w/2+.012,y+dy,2.9),(.035,.74,.8),m['metal'])
        box('side shutter',(x+w/2+.036,y+dy,2.9),(.035,.64,.70),m['cloth'])
    awning=m['cloth'] if variant in [2,4] else m['red'] if variant==1 else m['cream']
    box('entrance shade',(x,front-.18,2.02),(w*.89,.57,.09),awning)
    for dx in [-w*.31,w*.31]:pane(x+dx,front-.02,1.02,w*.23,1.45,m)
    for centre,width in ([(x,.92)] if door_centres is None else door_centres):
        door(centre,front-.08,width,m,glass=kind!='sela_home')
    # One sparse roof element makes heights legible without a field of tiny noise.
    if variant in [1,3]:
        cylinder('roof water tank',(x+w*.26,y+.1,height+.31),.22,.52,m['cream'])
