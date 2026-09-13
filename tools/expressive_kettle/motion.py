"""Grounded idle/gesture/stride clips: hands have a purpose and feet retain contact."""
import math
import bpy
from mathutils import Matrix, Vector, Quaternion
from rig import aim, solve

DURATIONS={'stand':6,'host':6,'relaxed':7,'serve':6,'walk':1.0,'listen':4,
    'table_rest':6,'idle':6,'thinking':4,'place':1.6,'surprise':2.4,'pleased':2.4,'concern':3.2,'greet':2.8}


def orient(bone,head,tail):
    # Preserve each bone's authored roll. A generic track-quaternion flips down-facing
    # leg bones and twists the blended knee vertices into a diamond.
    rest_axis=(bone.bone.matrix_local.to_3x3()@Vector((0,1,0))).normalized()
    turn=rest_axis.rotation_difference((Vector(tail)-Vector(head)).normalized())
    return Matrix.Translation(head)@turn.to_matrix().to_4x4()@bone.bone.matrix_local.to_quaternion().to_matrix().to_4x4()


def animate(rig,identity):
    rig.animation_data_create()
    for name,duration in DURATIONS.items():
        action=bpy.data.actions.new(name);rig.animation_data.action=action
        end=round(duration*30)
        for frame in range(end+1):
            t=frame/end;p=t*math.tau;sway=math.sin(p)
            enter=min(1,t*5);enter=enter*enter*(3-2*enter)
            leave=min(1,(1-t)*4);leave=leave*leave*(3-2*leave)
            env=enter*leave
            for b in rig.pose.bones:
                b.matrix_basis=Matrix.Identity(4);b.rotation_mode='QUATERNION'
            hip=rig.pose.bones['root']
            shift=.025 if name in ['relaxed','stand','listen'] else -.01
            # PoseBone.location is in bone axes, so place the pelvis in world axes.
            hip.matrix=Matrix.Translation((shift,0,(-.06+.010*math.cos(p*2)) if name=='walk' else (-.022+.003*sway)))@hip.bone.matrix_local
            spine=rig.pose.bones['spine']
            lean=.025 if name=='host' else -.05 if name=='relaxed' else 0
            pitch=.075 if name=='serve' else .02 if name in ['host','table_rest','idle'] else 0
            spine.rotation_quaternion=Quaternion((0,1,0),lean+.006*sway)@Quaternion((1,0,0),pitch)
            rig.pose.bones['head'].rotation_quaternion=Quaternion((0,0,1),.012*sway)@Quaternion((1,0,0),-.012*sway)
            bpy.context.view_layer.update()
            body=spine.matrix@spine.bone.matrix_local.inverted()
            pelvis=hip.matrix@hip.bone.matrix_local.inverted()
            for s,side in [(-1,'L'),(1,'R')]:
                shoulder=body@Vector((s*.235,0,1.66))
                wrist=Vector((s*.255,-.025,.99))
                hand_dir=Vector((0,-.015,-.16))
                if name=='host':
                    wrist=Vector((s*.085,-.215,1.19 if s==1 else 1.08))
                    hand_dir=Vector((-s*.09,-.02,-.10))
                if name=='relaxed':
                    wrist=Vector((s*.25,-.02,.99+( .025 if s<0 else 0)))
                if name=='serve':
                    wrist=Vector((s*.28,-.46,1.59))
                    if s>0:wrist.x+=.075*sway;wrist.y+=.022*math.sin(p*2)
                    hand_dir=Vector((0,-.15,-.025))
                if name in ['idle','table_rest','thinking','place','surprise','pleased','concern']:
                    wrist=Vector((s*.24,-.30,1.20))
                    hand_dir=Vector((0,-.14,-.02))
                if name=='thinking' and s==1:
                    wrist=wrist.lerp(Vector((.11,-.27,1.73)),env)
                    hand_dir=hand_dir.lerp(Vector((0,-.05,.13)),env)
                if name=='place' and s==1:
                    reach=math.sin(math.pi*min(1,max(0,(t-.1)/.72)))**2
                    wrist+=Vector((.17*reach,-.24*reach,.02*reach))
                if name=='surprise': wrist+=Vector((s*.015,-.02,.08))*env
                if name=='pleased':rig.pose.bones['head'].rotation_quaternion=Quaternion((1,0,0),.03*math.sin(p))
                if name=='concern' and s==1:
                    wrist=wrist.lerp(Vector((.19,-.26,1.72)),env)
                    hand_dir=hand_dir.lerp(Vector((0,-.05,.13)),env)
                if name=='greet' and s==1:
                    wrist=wrist.lerp(Vector((.33,-.23,1.53)),env)
                    hand_dir=hand_dir.lerp(Vector((.02,-.07,.12)),env)
                if name=='listen' and s==1:
                    wrist=Vector((.20,-.16,1.05+.025*sway))
                if name=='walk':wrist.y+=s*.12*sway
                wrist=body@wrist
                upper=rig.pose.bones['upper_'+side];lower=rig.pose.bones['lower_'+side]
                elbow,wrist=solve(shoulder,wrist,body@Vector((s*.32,.06,1.23)),upper.bone.length,lower.bone.length)
                upper.matrix=orient(upper,shoulder,elbow);bpy.context.view_layer.update()
                lower.matrix=orient(lower,elbow,wrist);bpy.context.view_layer.update()
                hand=rig.pose.bones['hand_'+side]
                hand.matrix=orient(hand,wrist,wrist+body.to_3x3()@hand_dir)
                if name in ['stand','relaxed','walk','listen']:
                    hand.matrix=hand.matrix@Matrix.Rotation(s*.7,4,'Y')
                # Both soles remain down at rest; a small stagger releases the knees.
                ankle=Vector((s*.145, .035 if s>0 else -.025,.10))
                if name=='walk':
                    q=(t+( .5 if s<0 else 0))%1
                    if q<.5:
                        # Swing eases forward, with clearance through the middle.
                        u=q*2;smooth=u*u*(3-2*u)
                        ankle.y=.26-.52*smooth;ankle.z=.10+.09*math.sin(math.pi*u)
                    else:
                        # Linear stance cancels root travel instead of skating.
                        ankle.y=-.26+(q-.5)*1.04
                thigh=rig.pose.bones['thigh_'+side];shin=rig.pose.bones['shin_'+side]
                hip_at=pelvis@Vector((s*.12,0,.92))
                knee,ankle=solve(hip_at,ankle,Vector((s*.15,-1,.50)),thigh.bone.length,shin.bone.length)
                thigh.matrix=orient(thigh,hip_at,knee);bpy.context.view_layer.update()
                shin.matrix=orient(shin,knee,ankle);bpy.context.view_layer.update()
                foot=rig.pose.bones['foot_'+side]
                foot.matrix=orient(foot,ankle,ankle+Vector((0,-.16,-.02)))
                bpy.context.view_layer.update()
            for b in rig.pose.bones:
                b.keyframe_insert('rotation_quaternion',frame=frame+1,group=b.name)
                b.keyframe_insert('location',frame=frame+1,group=b.name)
        action.use_fake_user=True
        track=rig.animation_data.nla_tracks.new();track.name=name
        track.strips.new(name,1,action);track.mute=True
    rig.animation_data.action=None
    for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(1)
