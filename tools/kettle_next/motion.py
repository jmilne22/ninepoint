"""Authored arcs, soft hands and weight transfer. Blender bakes the shared rig clips."""
import math
import bpy
from mathutils import Vector, Matrix, Quaternion
from rig import solve

DURATIONS={'stand':7.1,'host':8.3,'relaxed':8.9,'listen':6.7,'counter':5.4,'seated':7.3,
    'walk':1.0,'run':.72,'idle':7.1,'table_rest':7.1,'thinking':5.7,
    'place':1.05,'surprise':1.6,'pleased':1.9,'concern':2.2,'greet':1.8,'serve':5.4}

def orient(bone,head,tail):
    axis=bone.bone.matrix_local.to_3x3()@Vector((0,1,0))
    turn=axis.normalized().rotation_difference((Vector(tail)-Vector(head)).normalized())
    return Matrix.Translation(head)@turn.to_matrix().to_4x4()@bone.bone.matrix_local.to_quaternion().to_matrix().to_4x4()

def smooth(t):
    t=min(1,max(0,t));return t*t*(3-2*t)

def animate(rig,identity,width,style=None):
    rig.animation_data_create();bones=rig.pose.bones
    for name,duration in DURATIONS.items():
        if style and name not in ["walk","run"]: duration*=style[5]
        action=bpy.data.actions.new(name);rig.animation_data.action=action;end=round(duration*30)
        for frame in range(end+1):
            t=frame/end;p=t*math.tau;wave=math.sin(p)
            env=smooth(t/.22)*smooth((1-t)/.27)
            if style: env*=style[4]
            moving=name in ['walk','run'];run=name=='run';seated=name in ['seated','idle','table_rest','thinking','place','surprise','pleased','concern']
            for b in bones:b.matrix_basis=Matrix.Identity(4);b.rotation_mode='QUATERNION'
            pelvis=bones['root']
            drop=-.075 if run else -.035 if moving else -.30 if name=='seated' else -.01
            if style and name=="seated":drop=-.42
            bob=(.032 if run else .013)*math.cos(2*p) if moving else .002*wave
            shift=(.014 if run else .02)*wave if moving else .018 if name=='relaxed' else -.008
            pelvis.matrix=Matrix.Translation((shift,-.26 if identity=='tomas' and name in ['counter','serve'] else 0,drop+bob))@Matrix.Rotation((-.055 if run else -.026)*wave if moving else .008*wave,4,'Z')@pelvis.bone.matrix_local
            lean=.12 if run else .028 if moving else (.35 if identity=='tomas' else .06) if name in ['counter','serve'] else .016
            twist=(.075 if run else .035)*wave if moving else .012*wave
            bones['spine'].rotation_quaternion=Quaternion((1,0,0),lean)@Quaternion((0,0,1),twist)
            if name=='surprise':bones['spine'].rotation_quaternion=Quaternion((1,0,0),-.06*env)
            nod=.014*math.sin(p) if name=='pleased' else -.055*env if name=='greet' else .007*wave
            bones['head'].rotation_quaternion=Quaternion((1,0,0),nod)@Quaternion((0,0,1),.016*wave if not moving else -.018*wave)
            bpy.context.view_layer.update()
            body=bones['spine'].matrix@bones['spine'].bone.matrix_local.inverted()
            hips=pelvis.matrix@pelvis.bone.matrix_local.inverted()
            for s,side in [(-1,'L'),(1,'R')]:
                shoulder=body@Vector((s*width,0,1.67))
                wrist=Vector((s*(width+.09),-.025,1.07));hand_dir=Vector((0,-.015,-.12))
                if name=='walk':
                    wrist.y+=s*.115*wave;wrist.z+=.012*math.cos(p+s*.4)
                if run:
                    # Hands travel on a small curved arc beside the ribs. Elbows drive
                    # the swing; the wrist never points forward like a rigid blade.
                    swing=s*wave
                    wrist=Vector((s*(width+.07),-.10+.16*swing,1.25+.035*math.cos(p+s*.6)))
                    hand_dir=Vector((0,-.035,-.11))
                if name=='host':
                    wrist=Vector((s*.095,-.205,1.22 if s<0 else 1.13));hand_dir=Vector((-s*.065,-.03,-.075))
                    wrist.z+=.003*wave
                if name=='relaxed':
                    wrist.x+=s*.005;wrist.z+=.025 if s>0 else 0
                if name=='listen':
                    wrist.y-=.025*env
                    bones['head'].rotation_quaternion=Quaternion((1,0,0),.025*math.sin(p)*env)
                if seated:
                    wrist=Vector((s*.235,-.26,1.20));hand_dir=Vector((0,-.095,-.055))
                    if style and name=="seated":
                        # World chairs are .40 m and tables .825 m; child seats
                        # retain their existing cushion lift while hands reach the top.
                        wrist=Vector((s*.235,-.40,1.63 if identity in ["sunny","extra_kid"] else 1.50))
                        if identity in ["kesh","bertie","sunny","orla","ivo","sora"]:
                            # The fixed host chairs sit back from the table. Rest
                            # on the lap between games instead of miming a reach.
                            wrist=Vector((s*.18,-.10,1.03))
                            hand_dir=Vector((0,-.07,-.095))
                if name in ['counter','serve']:
                    wrist=Vector((s*.24,-.46,1.34));hand_dir=Vector((0,-.115,-.005))
                    if s>0:wrist.x+=.095*wave;wrist.y+=.035*math.sin(p*2)
                if name=='thinking' and s>0:
                    wrist=wrist.lerp(Vector((.135,-.225,1.72)),env*.9)
                    hand_dir=hand_dir.lerp(Vector((0,-.055,.075)),env)
                if name=='greet' and s>0:
                    wrist=wrist.lerp(Vector((.31,-.14,1.56)),env)
                    hand_dir=hand_dir.lerp(Vector((.015,-.015,.115)),env)
                if name=='place' and s==(1 if identity=='player' else -1):
                    reach=smooth(t/.48)*smooth((1-t)/.38)
                    wrist+=Vector((s*.095,-.19,.07))*reach;hand_dir=Vector((0,-.12,-.025))
                if name=='surprise':wrist.z+=.045*env
                if name=='pleased':wrist.y-=.018*env
                if name=='concern' and s>0:wrist.z+=.06*env
                wrist=body@wrist
                if identity=='tomas' and name in ['counter','serve']:
                    wrist=Vector((s*.24+(.08*wave if s>0 else 0),-.99+.018*math.sin(p*2),1.32))
                upper=bones['upper_'+side];lower=bones['lower_'+side]
                elbow,wrist=solve(shoulder,wrist,body@Vector((s*(width+.20),.27,1.34)),upper.bone.length,lower.bone.length)
                upper.matrix=orient(upper,shoulder,elbow);bpy.context.view_layer.update()
                lower.matrix=orient(lower,elbow,wrist);bpy.context.view_layer.update()
                hand=bones['hand_'+side]
                direction=Vector((0,-.12,.01)) if identity=='tomas' and name in ['counter','serve'] else body.to_3x3()@hand_dir
                hand.matrix=orient(hand,wrist,wrist+direction)
                if seated or name in ['counter','serve']:
                    hand.matrix=hand.matrix@Matrix.Rotation(math.pi,4,'Y')
                if not seated and name not in ['counter','serve','host','greet']:
                    hand.matrix=hand.matrix@Matrix.Rotation(s*.95,4,'Y')
                # Finger flexion is relative to each knuckle's authored local frame.
                for j in range(4):
                    curl=.30+j*.06
                    if run:curl=.74+j*.025
                    if name in ['counter','serve']:curl=.10
                    if name=='greet':curl=.28*(1-env)+.07*env
                    if name=='place':curl=.6 if j>1 else .28
                    for n,factor in [('finger',1),('tip',.7)]:
                        bones['%s%d_%s'%(n,j,side)].rotation_quaternion=Quaternion((1,0,0),-curl*factor)
                bones['thumb_'+side].rotation_quaternion=Quaternion((1,0,0),-.28 if run else -.14)@Quaternion((0,0,1),s*.12)
                bones['thumbtip_'+side].rotation_quaternion=Quaternion((1,0,0),-.34 if run else -.15)
                ankle=Vector((s*.135,.025 if s>0 else -.018,.105));roll=0.;toe=0.
                if name=='seated':ankle.y=-.39
                if moving:
                    q=(t+(.5 if s<0 else 0))%1
                    swing_fraction=.60 if run else .42
                    stride=.68 if run else .48
                    if q<swing_fraction:
                        u=q/swing_fraction;ankle.y=stride*.5-stride*smooth(u)
                        ankle.z+= (.19 if run else .085)*math.sin(math.pi*u)
                        roll=-.24*math.sin(math.pi*u)
                    else:
                        u=(q-swing_fraction)/(1-swing_fraction)
                        ankle.y=-stride*.5+stride*u
                        roll=.10*(1-smooth(u/.25))-.18*smooth((u-.72)/.28)
                        toe=.20*smooth((u-.70)/.30)
                thigh=bones['thigh_'+side];shin=bones['shin_'+side]
                hip=hips@Vector((s*.12,0,.94))
                knee,ankle=solve(hip,ankle,Vector((s*.14,-1,.50)),thigh.bone.length,shin.bone.length)
                thigh.matrix=orient(thigh,hip,knee);bpy.context.view_layer.update()
                shin.matrix=orient(shin,knee,ankle);bpy.context.view_layer.update()
                foot=bones['foot_'+side]
                foot.matrix=orient(foot,ankle,ankle+Vector((0,-.12,-.04)))@Matrix.Rotation(roll,4,'X')
                bones['toe_'+side].rotation_quaternion=Quaternion((1,0,0),toe)
                bpy.context.view_layer.update()
            for b in bones:
                b.keyframe_insert('rotation_quaternion',frame=frame+1,group=b.name)
                b.keyframe_insert('location',frame=frame+1,group=b.name)
        action.use_fake_user=True;track=rig.animation_data.nla_tracks.new();track.name=name
        track.strips.new(name,1,action);track.mute=True
    rig.animation_data.action=None
    for b in bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(1)
