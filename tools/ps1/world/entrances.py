"""Physical entrances, grouped from existing warp tiles without moving gameplay."""
import math
import bpy
from mathutils import Vector,Matrix
from common import box,cylinder


def door(x,y,width,m,glass=False,opened=False,rotation=0):
    before=set(bpy.data.objects)
    height=1.96
    if not opened:
        box('doorway recess',(0,0,height/2),(width+.15,.08,height+.12),m['ink'])
    for dx in [-width/2,width/2]:
        box('door jamb',(dx,-.06,height/2),(.09,.15,height+.14),m['cream'])
    box('door lintel',(0,-.06,height),(width+.18,.16,.12),m['cream'])
    box('stone threshold',(0,-.10,.03),(width+.16,.42,.06),m['stone'])
    # A nearly edge-on open leaf leaves the actual transition approach readable.
    leaf_before=set(bpy.data.objects)
    leaf_w=width-.10
    box('door leaf',(0,-.10,.97),(leaf_w,.065,1.86),m['metal' if glass else 'wood'],.018)
    if glass:
        box('door glazing',(0,-.14,1.14),(leaf_w-.13,.018,1.30),m['glass'])
        box('door midrail',(0,-.16,.65),(leaf_w,.018,.045),m['cream'])
        box('glass reflection',(-leaf_w*.20,-.153,1.34),(.035,.009,.84),m['cream'])
    else:
        for z in [.43,1.30]:
            box('recessed door panel',(0,-.14,z),(leaf_w-.16,.017,.61),m['floor'],.01)
    if glass and width>1.25 and not opened:
        box('double door meeting stile',(0,-.17,.97),(.04,.035,1.86),m['cream'])
        for dx in [-.09,.09]:box('paired pull handle',(dx,-.21,.97),(.026,.06,.24),m['metal'])
    box('handle plate',(leaf_w*.32,-.16,.91),(.045,.025,.18),m['amber'])
    box('door handle',(leaf_w*.25,-.20,.93),(.13,.07,.032),m['metal'])
    if opened:
        hinge=Vector((-width/2,0,0));turn=Matrix.Rotation(math.radians(-78),4,'Z')
        for obj in set(bpy.data.objects)-leaf_before:
            obj.location=hinge+turn.to_3x3()@(obj.location-hinge)
            obj.rotation_euler.z-=math.radians(78)
    turn=Matrix.Rotation(rotation,4,'Z')
    for obj in set(bpy.data.objects)-before:
        obj.location=Vector((x,y,0))+turn.to_3x3()@obj.location
        obj.rotation_euler.z+=rotation
        if opened:obj['depth_sorted']=True


def groups(data):
    result=[]
    for warp in data.get('warps',[]):
        x,y=warp['tile']
        key=(warp['map'],warp['spawn'])
        found=next((g for g in result if g['key']==key and any(abs(x-a)+abs(y-b)==1 for a,b in g['tiles'])),None)
        if found:found['tiles'].append((x,y))
        else:result.append({'key':key,'tiles':[(x,y)]})
    return result


def interiors(data,m):
    if not data.get('indoors'):return
    w,h=data['size']
    for group in groups(data):
        tiles=group['tiles'];x=sum(t[0]+.5 for t in tiles)/len(tiles)*.8;y=-sum(t[1]+.5 for t in tiles)/len(tiles)*.8
        rotation=math.pi/2 if tiles[0][0] in [0,w-1] else 0
        # Side doors are positioned on the wall plane; front ones remain cut away.
        door(x,y,.68*len(tiles),m,glass=data['id'].startswith('academy'),opened=True,rotation=rotation)
