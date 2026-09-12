"""Daylight and non-playable context around the existing logical maps."""
import math,random
import bpy
from mathutils import Vector
from common import box,material,light,cylinder,sphere


def daylight(scene,w,h,indoor=False,club=False):
    scene.world.use_nodes=True
    background=scene.world.node_tree.nodes.get('Background')
    background.inputs['Color'].default_value=(.72,.83,1,1)
    background.inputs['Strength'].default_value=.20 if club else .26 if indoor else .70
    centre=Vector((w/2,-h/2,0))
    if not indoor:
        bpy.ops.object.light_add(type='SUN',location=(0,0,12))
        sun=bpy.context.object;sun.name='high afternoon sun'
        sun.rotation_euler=(math.radians(25),math.radians(-22),math.radians(-30))
        sun.data.energy=1.8;sun.data.angle=math.radians(12);sun.data.color=(1,.97,.91)
    else:
        # Broad pale floors clipped under the former 1100/650 W fills. Keep
        # daylight readable while retaining plaster, bedding and floor grain.
        for name,offset,colour,power,size in [
            ('window daylight',(-3,2,6),(.86,.93,1),500,5),
            ('room bounce',(3,-3,5),(1,.91,.76),240 if club else 230,6)]:
            obj=light(name,centre+Vector(offset),colour,power,size)
            obj.rotation_euler=(centre-obj.location).to_track_quat('-Z','Y').to_euler()


def context(data,m,architecture):
    w,h=[v*.8 for v in data['size']];indoor=data.get('indoors',False)
    # An opaque support plane fills every camera corner. It is real scene geometry,
    # not a screen-colour patch; daylight/shadows remain continuous at map borders.
    extent=(w+h)*3+40
    muted=material('surrounding concrete',(.58,.62,.62) if not indoor else (.61,.65,.65),0)
    box('continuous surrounding ground',(w/2,-h/2,-.13),(extent,extent,.12),muted)
    if indoor:
        # The cutaway sits within a building slab, with a quiet circulation margin.
        box('building slab',(w/2,-h/2,-.09),(w+2.4,h+2.4,.12),m['stone'])
        for side in [-1,1]:
            x=-1.5 if side==-1 else w+1.5
            box('surrounding corridor seam',(x,-h/2,-.062),(.015,h+8,.002),m['metal'])
        return
    rng=random.Random('context-'+data['id'])
    # Broad paving courses continue into adjacent blocks, at less detail than the
    # playable street. Clear low boundaries below explain where walking ends.
    for i in range(-25,55):
        box('paving course',(i*1.6,-h/2,-.066),(.013,extent,.002),m['stone'])
        box('paving cross joint',(w/2,i*1.6,-.065),(extent,.013,.002),m['stone'])
    if data['id']=='quay':
        box('continuing sea',(w/2,-5.6-extent/2,-.055),(extent,extent,.07),m['water'])
        for i in range(45):
            x=rng.uniform(-25,w+25);y=-h-rng.uniform(0,22)
            box('distant sea glint',(x,y,-.018),(rng.uniform(.4,1.4),.015,.002),m['glass'])
        from .harbor import context as harbor_context
        harbor_context(w,h,m)
    else:
        # A back street and neighboring flat-roof buildings provide actual depth
        # beyond the old rectangular board, without inventing new entrances to play.
        box('continuing side street',(w/2,4,-.052),(extent,3,.04),m['asphalt'])
        for i in range(-3,8):
            x=i*5.4
            from .white_city import facade
            facade('sela_home',x,9+(i%2)*.5,4.5+(i%3)*.15,5,m,variant=i%5)
        for x in [-7,w+7]:
            for j in range(4):
                y=-1-j*4.6
                facade('sela_home',x,y,4.6,3.8,m,variant=(j+int(x))%5)
    # Border coping and planting are visible barriers wherever the data has no exit.
    exits={tuple(p['tile']) for p in data.get('warps',[])}
    cols,rows=data['size']
    for x,y in [(x,rows-1) for x in range(cols)]+[(0,y) for y in range(rows)]+[(cols-1,y) for y in range(rows)]:
        if (x,y) in exits:continue
        name=data['legend'].get(data['ground'][y][x],'')
        if 'canal' in name or name in ['coast_sky','void']:continue
        cx,cy=(x+.5)*.8,-(y+.5)*.8
        # Only reinforce already solid boundaries; open paths retain their geometry.
        if name not in ['wall_side','wall_int','fence_h','fence_post','bush'] and not name.startswith('wall_int'):continue
        box('boundary coping',(cx,cy,.24),(.78,.20,.48) if y==rows-1 else (.20,.78,.48),m['stone'],.025)
