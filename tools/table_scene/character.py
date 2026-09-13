"""Original continuous-mesh cast, built for a close camera rather than map sprites."""
import math
import bpy
from mathutils import Vector
from mesh import material,mesh,loft,tube,ribbon,rigid,bind
from rig import create,animate
from palette import SKIN
import cast_details


def build(spec):
    rig=create();name=spec['id'];wren=name=='wren'
    skin=material('Skin',SKIN[spec['skin']][2])
    face=material('Face',SKIN[spec['skin']][2])
    top=material('Cloth',spec['top'][0]);trim=material('ClothTrim',spec['top'][1])
    hair=material('Hair',spec['hair_col'][0]);hair_hi=material('HairLight',spec['hair_col'][1])
    pants=material('Trousers',spec['bottom']);scarf=material('Scarf',spec.get('accent','#6d9ac0'))
    shirt=loft('Tailored shirt',[(.63,.21,.12,0),(.72,.205,.13,0),(.96,.19,.13,0),
        (1.15,.23,.145,0),(1.32,.29,.13,0),(1.40,.23,.12,0),(1.45,.105,.075,0)],top)
    pieces=[shirt]
    for s in [-1,1]:
        sleeve=tube('Sleeve',[(s*.20,0,1.36),(s*.31,0,1.32),(s*.43,0,1.18),
            (s*.48,0,1.1),(s*.49,-.10,.98),(s*.48,-.17,.89)], [.115,.12,.095,.087,.072,.065],top)
        pieces.append(sleeve)
    # A joined, remeshed garment removes the disconnected-ball shoulders of ART-10.
    bpy.ops.object.select_all(action='DESELECT')
    for obj in pieces:obj.select_set(True)
    bpy.context.view_layer.objects.active=shirt;bpy.ops.object.join()
    remesh=shirt.modifiers.new('continuous cloth','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.015
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth=shirt.modifiers.new('tailored surface','SMOOTH');smooth.factor=.85;smooth.iterations=5
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    for p in shirt.data.polygons:p.use_smooth=True
    if name not in ['player','wren']:
        for vertex in shirt.data.vertices:
            if vertex.co.z<.80 and abs(vertex.co.x)<.30:
                vertex.co.y*=1.30
    if spec['build']=='broad':
        for vertex in shirt.data.vertices:
            x=abs(vertex.co.x);vertex.co.x*=1+.18*max(0,1-max(0,x-.20)/.15)
    def shirt_weights(v):
        x,y,z=v;side='R' if x>=0 else 'L';x=abs(x)
        if x<.205 or (z<1.15 and x<.27):return {'spine':1}
        upper=min(1,max(0,(x-.205)/.105))
        lower=min(1,max(0,(1.17-z)/.16))
        return {'spine':1-upper,'upper_'+side:upper*(1-lower),'lower_'+side:upper*lower}
    bind(shirt,rig,shirt_weights)
    rigid(loft('Trousers',[(.46,.23,.14,0),(.66,.22,.14,0),(.75,.20,.13,0)],pants),rig,'root')
    neck=loft('Neck',[(1.40,.07,.065,0),(1.57,.075,.068,0),(1.68,.083,.068,0)],skin)
    rigid(neck,rig,'neck')
    head=loft('Painted head',[(1.64,.034,.04,-.035),(1.69,.105,.087,-.022),
        (1.76,.170,.125,-.012),(1.85,.206,.155,0),(1.96,.220,.171,.003),
        (2.055,.210,.167,.012),(2.12,.162,.137,.02),(2.18,.035,.03,.02)],face,64,True)
    sub=head.modifiers.new('soft face silhouette','SUBSURF');sub.levels=2
    bpy.context.view_layer.objects.active=head;bpy.ops.object.modifier_apply(modifier=sub.name)
    rigid(head,rig,'head')
    for s,side in [(-1,'L'),(1,'R')]:
        ear=loft('Ear',[(1.80,.027,.025,0),(1.83,.041,.032,0),(1.91,.033,.022,0),(1.94,.013,.011,0)],skin,16)
        for v in ear.data.vertices:v.co.x+=s*.21;v.co.y+=.015
        rigid(ear,rig,'head')
        cuff=tube('Cuff',[(s*.48,-.15,.915),(s*.48,-.18,.875)],[.069,.068],trim)
        rigid(cuff,rig,'lower_'+side)
        palm=tube('Hand',[(s*.48,-.18,.87),(s*.48,-.20,.82),(s*.48,-.22,.75)],[.043,.057,.048],skin,16,.50)
        rigid(palm,rig,'hand_'+side)
        for i in range(4):
            x=s*.48+(i-1.5)*.026
            finger=tube('Finger',[(x,-.22,.765),(x,-.237,.714),(x,-.25,.692),(x,-.255,.687)],
                [.014,.014,.012,.005],skin,10,.8)
            rigid(finger,rig,'hand_'+side)
        thumb=tube('Thumb',[(s*.48+s*.049,-.21,.81),(s*.48+s*.072,-.238,.77),(s*.48+s*.064,-.255,.75)],
            [.022,.018,.008],skin,12)
        rigid(thumb,rig,'hand_'+side)
    # A broad cap and tapered, layered locks give a clean, designed hair silhouette.
    cap=loft('Hair crown',[(2.045,.223,.178,.018),(2.13,.205,.17,.025),(2.19,.145,.13,.027),(2.22,.025,.025,.02)],hair)
    rigid(cap,rig,'head')
    if wren:
        verts=[];faces=[];segments=40
        for z,w,d in [(1.48,.235,.13),(1.64,.245,.16),(1.89,.241,.185),(2.08,.23,.18)]:
            for j in range(segments+1):
                a=math.pi+.80+j*(math.tau-1.60)/segments
                verts.append((w*math.sin(a),d*math.cos(a)+.03,z+.025*math.cos(a*3)))
        for row in range(3):
            for j in range(segments):
                k=row*(segments+1)+j;faces.append((k,k+1,k+segments+2,k+segments+1))
        curtain=mesh('Long hair curtain',verts,faces,hair)
        mod=curtain.modifiers.new('hair volume','SOLIDIFY');mod.thickness=.022
        bpy.context.view_layer.objects.active=curtain;bpy.ops.object.modifier_apply(modifier=mod.name)
        rigid(curtain,rig,'head')
        locks=[(-.15,-.19,2.12,-.205,1.93),(-.06,-.185,2.18,-.14,2.00),(.05,-.185,2.17,-.045,2.02),(.16,-.14,2.13,.11,1.96)]
        for x,y,z,tip,low in locks:
            obj=ribbon('Swept fringe',[((x,y,z),.095,.035),((x-.01,y-.025,z-.065),.087,.03),((tip,y-.024,low),.009,0)],hair_hi)
            rigid(obj,rig,'head')
        wrap=loft('Scarf fold',[(1.43,.128,.10,-.004),(1.49,.14,.11,-.005),(1.54,.119,.091,-.005)],scarf)
        rigid(wrap,rig,'neck')
        for x,length in [(-.068,.43),(.059,.27)]:
            obj=ribbon('Scarf tail',[((x,-.13,1.49),.058,.019),((x+.01,-.157,1.31),.056,.018),
                ((x+.026,-.151,1.49-length),.05,.009)],scarf)
            rigid(obj,rig,'spine')
    elif name=='player':
        for i,(x,z,tip) in enumerate([(-.16,2.14,-.19),(-.065,2.21,-.09),(.055,2.22,.0),(.16,2.16,.11)]):
            obj=ribbon('Cropped swept hair',[((x,-.14,z),.091,.03),((x-.012,-.185,z-.06),.082,.025),((tip,-.186,z-.16),.025,0)],hair_hi if i==1 else hair)
            rigid(obj,rig,'head')
        collar=loft('Collar',[(1.415,.113,.083,-.007),(1.445,.106,.079,-.007)],trim)
        rigid(collar,rig,'neck')
    if name not in ['player','wren']:
        cast_details.hair(spec,rig,hair,hair_hi)
        cast_details.clothes(spec,rig,trim)
    # Larger heads and a short visible neck keep expressions legible at 768 pixels.
    for obj in list(bpy.context.scene.objects):
        if obj.type == 'MESH' and obj.vertex_groups.get('head') and any(g.group == obj.vertex_groups['head'].index and g.weight > .9 for v in obj.data.vertices for g in v.groups):
            for vertex in obj.data.vertices:
                vertex.co.x *= 1.30
                vertex.co.y *= 1.15
                vertex.co.z = 1.64 + (vertex.co.z - 1.64) * 1.12 - .08
        if obj.type == 'MESH' and obj.name == 'Neck':
            for vertex in obj.data.vertices:
                vertex.co.z = 1.40 + (vertex.co.z - 1.40) * .70
    animate(rig,name != "player")
    return rig
