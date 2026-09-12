"""Original low-poly cast. Portraits and eight-way poses share these same models."""
import math
import sys
from pathlib import Path
import bpy
from common import box, sphere, limb, material, camera, light, render, reset
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from characters import CHARACTERS
from palette import SKIN


def rgb(value):
    return tuple(int(value[i:i+2],16)/255 for i in (1,3,5))


def person(spec, pose=0, mood="neutral"):
    before=set(bpy.data.objects)
    name = spec['id']
    skin = material('skin', rgb(SKIN[spec['skin']][1]))
    skin_shadow = material('skin shade', rgb(SKIN[spec['skin']][0]))
    top = material('cloth', rgb(spec['top'][0]), 35)
    trim = material('cloth highlight', rgb(spec['top'][1]), 30)
    trouser = material('trousers', rgb(spec['bottom']), 25)
    hair = material('hair', rgb(spec['hair_col'][0]), 18)
    hair_light = material('hair highlight', rgb(spec['hair_col'][1]), 15)
    dark = material('shoe and pupil', (.025,.022,.028))
    eye = material('eye', (.79,.75,.63))
    accent = material('accessory', rgb(spec.get('accent','#b49c67')), 35)
    broad = 1.22 if spec['build']=='broad' else 1
    # Frames 0 idle, 1/2/3 walk contact/passing/contact, 4/5 activity hands.
    stride = {1:.20,2:0,3:-.20}.get(pose,0)
    seated = spec.get('activity') == 'play' and pose >= 4
    bend = .40 if seated else (.018 if pose==2 else 0)
    for side in [-1,1]:
        x = side*.105*broad
        ankle = (x, -.33 if seated else side*stride, .13)
        knee = (x, -.28 if seated else (side*stride*.45-.018 if pose in [1,2,3] else 0), .37 if seated else .47-bend)
        hip = (x, 0, .83-bend)
        limb('trouser thigh',hip,knee,.093,trouser)
        limb('trouser calf',knee,ankle,.066,trouser)
        box('boot',(x,(-.33 if seated else side*stride)-.045,.072),(.15,.25,.13),dark,.025)
    box('hips',(0,0,.81-bend),(.34*broad,.23,.19),trouser,.04)
    # Tapered torso gives shoulders and waist rather than a rectangular peg.
    verts=[]
    for z,w,d in [(.86,.155,.10),(1.20,.215*broad,.12),(1.27,.17*broad,.105)]:
        verts += [(-w,-d,z-bend),(w,-d,z-bend),(w,d,z-bend),(-w,d,z-bend)]
    faces=[(0,3,2,1),(8,9,10,11)]
    for level in [0,4]:
        faces += [(level+i,level+(i+1)%4,level+4+(i+1)%4,level+4+i) for i in range(4)]
    mesh=bpy.data.meshes.new('tailored torso')
    mesh.from_pydata(verts,[],faces)
    obj=bpy.data.objects.new('tailored torso',mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(top)
    limb('neck',(0,0,1.23-bend),(0,0,1.38-bend),.07,skin)
    head_z=1.49-bend
    sphere('face',(0,-.015,head_z),(.139 if spec.get('face_shape')=='round' else .127,.113,.159 if spec.get('face_shape')=='square' else .172),skin)
    sphere('jaw',(0,-.027,head_z-.075),(.098,.092,.082),skin)
    sphere('nose',(0,-.129,head_z-.016),(.023,.043,.032),skin_shadow)
    for x in [-.050,.050]:
        sphere('ear',(x*2.55,0,head_z-.020),(.021,.024,.041),skin)
        sphere('eye white',(x,-.118,head_z+.017),(.030,.010,.013),eye)
        sphere('pupil',(x,-.129,head_z+.016),(.009,.005,.010),dark)
        brow=box('brow',(x,-.123,head_z+.047),(.060,.012,.010),hair)
        brow.rotation_euler.y = (.24 if mood in ['worried','thinking'] else -.23 if mood=='annoyed' else .10 if spec.get('brow')=='raised' else -.05)*(1 if x<0 else -1)
    smile = .012 if mood in ['happy','pleased'] else -.009 if mood in ['annoyed','worried'] else 0
    limb('mouth',(-.028,-.119,head_z-.071+smile),(0,-.124,head_z-.073),.005,skin_shadow)
    limb('mouth',(0,-.124,head_z-.073),(.028,-.119,head_z-.071+smile),.005,skin_shadow)
    sphere('hair crown',(0,.006,head_z+.099),(.138,.119,.098),hair)
    if spec['hair']=='long':
        for x in [-.117,.117]:
            sphere('long hair',(x,.035,head_z-.055),(.055,.093,.23),hair_light)
        sphere('hair back',(0,.074,head_z-.04),(.12,.074,.23),hair)
        for x,z in [(-.075,.096),(.0,.122),(.075,.102)]:
            sphere('parted fringe',(x,-.077,head_z+z),(.059,.04,.06),hair_light)
    elif spec['hair'] in ['bob','bun','tiedback']:
        for x in [-.12,.12]:
            sphere('side hair',(x,.025,head_z+.01),(.04,.09,.13 if spec['hair']=='bob' else .10),hair)
        sphere('back hair',(0,.084,head_z+.02),(.12,.07,.14),hair)
        if spec['hair']=='bun':sphere('bun',(0,.135,head_z+.11),(.078,.082,.07),hair_light)
        if spec['hair']=='tiedback':sphere('tied hair',(0,.14,head_z-.07),(.066,.065,.19),hair_light)
    elif spec['hair']=='cap':
        sphere('cap crown',(0,.015,head_z+.12),(.15,.135,.093),accent)
        box('cap peak',(0,-.139,head_z+.09),(.24,.16,.025),accent,.015)
    elif spec['hair']=='curls':
        for i in range(11):
            a=i*math.tau/11
            sphere('curl',(math.cos(a)*.11,math.sin(a)*.091,head_z+.095),(.063,.058,.065),hair_light if i%3==0 else hair)
    else:
        for i in range(5):
            sphere('cropped fringe',(-.10+i*.05,-.075,head_z+.112),(.037,.040,.046),hair_light if i==1 else hair)
    if spec.get('beard'):
        for x in [-.082,0,.082]:
            sphere('beard',(x,-.084,head_z-.091),(.049,.05,.039),hair)
    for side in [-1,1]:
        shoulder=(side*.206*broad,0,1.20-bend)
        elbow=(side*.26*broad,side*stride*.5,1.00-bend)
        hand=(side*.255*broad,-side*stride*.7,.83-bend)
        if pose in [1,2,3]:
            # Both bones swing from the shoulder; opposing elbow/wrist offsets
            # used to reverse the joint and visibly stretch the arm each step.
            angle=-side*stride*1.55
            elbow=(shoulder[0]+side*.018, .225*math.sin(angle), shoulder[2]-.225*math.cos(angle))
            forearm_angle=angle-.16
            hand=(elbow[0],elbow[1]+.205*math.sin(forearm_angle),elbow[2]-.205*math.cos(forearm_angle))
            sphere('shoulder cap',shoulder,(.075,.073,.075),top)
            sphere('elbow joint',elbow,(.058,.057,.059),top)
        if pose>=4:
            elbow=(side*.26*broad,-.12,1.02-bend)
            hand=(side*.16,-.30-(.07 if pose==5 and side==1 else 0),.97-bend)
        limb('sleeve',shoulder,elbow,.073,top)
        limb('forearm',elbow,hand,.056,trim)
        sphere('hand',hand,(.047,.045,.065),skin)
    if spec.get('accessory')=='glasses':
        for x in [-.05,.05]:
            for z in [head_z+.002,head_z+.036]:limb('spectacle rim',(x-.036,-.14,z),(x+.036,-.14,z),.004,dark)
            for dx in [-.036,.036]:limb('spectacle side',(x+dx,-.14,head_z+.002),(x+dx,-.14,head_z+.036),.004,dark)
        limb('spectacle bridge',(-.014,-.14,head_z+.02),(.014,-.14,head_z+.02),.004,dark)
    if spec.get('accessory') in ['blazer','cardigan']:
        for side in [-1,1]:
            limb('lapel',(side*.12,-.135,1.23-bend),(side*.06,-.14,1.02-bend),.026,accent)
        for z in [.91,1.01,1.11]:sphere('button',(0,-.132,z-bend),(.013,.01,.013),accent)
    if spec.get('accessory')=='scarf':
        sphere('scarf wrap',(0,-.026,1.275-bend),(.155,.12,.051),accent)
        box('scarf end',(.071,-.134,1.11-bend),(.078,.028,.30),accent)
    if spec.get('accessory')=='apron':
        box('apron bib',(0,-.128,1.087-bend),(.29,.025,.29),accent)
        box('apron skirt',(0,-.13,.81-bend),(.36,.04,.31),accent)
        for x in [-.11,.11]:
            limb('apron strap',(x,-.12,1.20-bend),(x,-.065,1.29-bend),.018,accent)
    if name=='player':
        box('jacket zip',(0,-.124,1.05-bend),(.013,.01,.31),trim)
    if pose>=4:
        if spec.get('activity')=='wipe':
            box('cloth',(.10,-.33,.925),(.23,.16,.025),accent)
        elif spec.get('activity')=='arrange':
            sphere('bowl',(0,-.31,.96),(.12,.10,.05),hair)
        elif spec.get('activity')=='read':
            box('open book',(0,-.34,.95-bend),(.29,.2,.025),accent)
            box('pages',(0,-.34,.968-bend),(.26,.18,.012),eye)
        elif spec.get('activity')=='fold':
            box('folded cloth',(0,-.34,.95-bend),(.32,.22,.035),accent)
        elif spec.get('activity')=='play':
            sphere('held stone',(.16,-.34,.97-bend),(.027,.025,.018),dark)

    if name in ['sunny','extra_kid']:
        for obj in set(bpy.data.objects)-before:
            obj.location *= .78
            obj.scale *= .78


def build(output,preview=False,all_cast=False):
    output.mkdir(parents=True,exist_ok=True)
    cast=CHARACTERS if all_cast else [c for c in CHARACTERS if c['id'] in ['wren','kesh','tomas','player']]
    for spec in cast:
        # One editable source scene per character, used by both export cameras.
        reset(216,216)
        person(spec)
        camera((2,-5,2.55),(0,0,1.16),1.05)
        light('portrait key',(-3,-4,5),(1,.80,.60),230,4)
        light('portrait rim',(3,2,4),(.53,.71,1),170,3)
        render(output/(spec['id']+'_bust.png'))
        bpy.ops.wm.save_as_mainfile(filepath=str(output/(spec['id']+'.blend')))
        if all_cast and not spec.get('extra'):
            for mood in ['neutral','happy','annoyed','working','thinking','worried','pleased']:
                reset(216,216)
                person(spec,0,mood)
                camera((2,-5,2.55),(0,0,.94 if spec['id']=='sunny' else 1.16),1.05)
                light('portrait key',(-3,-4,5),(1,.80,.60),230,4)
                light('portrait rim',(3,2,4),(.53,.71,1),170,3)
                render(output/(spec['id']+'_'+mood+'.png'))
        for direction in range(1 if preview else 8):
            for frame in range(1 if preview else 6):
                reset(80,128)
                person(spec,frame)
                # Direction 0 faces screen down, then clockwise in 45-degree steps.
                angle=direction*math.tau/8
                cam=camera((-5*math.sin(angle),-5*math.cos(angle),3.787),(0,0,.90),2.32)
                light('sprite key',(-3,-4,6),(1,.79,.57),270,5)
                light('sprite fill',(3,1,4),(.55,.71,1),110,4)
                render(output/f'{spec["id"]}_{direction}_{frame}.png')
