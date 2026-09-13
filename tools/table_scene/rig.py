"""Continuous armature clips with fixed limb lengths and eased gesture timing."""
import math
import bpy
from mathutils import Vector,Matrix,Quaternion


def create():
    data=bpy.data.armatures.new('CastRig');rig=bpy.data.objects.new('CastRig',data)
    bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig
    rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    def bone(name,a,b,parent=None):
        v=data.edit_bones.new(name);v.head=a;v.tail=b
        if parent:v.parent=data.edit_bones[parent]
    bone('root',(0,0,.5),(0,0,.88))
    bone('spine',(0,0,.88),(0,0,1.43),'root')
    bone('neck',(0,0,1.43),(0,0,1.64),'spine')
    bone('head',(0,0,1.64),(0,0,2.18),'neck')
    for s,side in [(-1,'L'),(1,'R')]:
        bone('upper_'+side,(s*.235,0,1.38),(s*.48,0,1.10),'spine')
        bone('lower_'+side,(s*.48,0,1.10),(s*.48,-.18,.85),'upper_'+side)
        bone('hand_'+side,(s*.48,-.18,.85),(s*.48,-.23,.69),'lower_'+side)
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    return rig


def aim(head,tail):
    q=(Vector(tail)-Vector(head)).to_track_quat('Y','Z')
    return Matrix.Translation(head)@q.to_matrix().to_4x4()


def solve(shoulder,wrist,pole,l1,l2):
    v=wrist-shoulder;d=min(v.length,l1+l2-.005);v.normalize()
    wrist=shoulder+v*d
    bend=pole-shoulder; bend=(bend-v*bend.dot(v)).normalized()
    along=(l1*l1-l2*l2+d*d)/(2*d)
    return shoulder+v*along+bend*math.sqrt(max(0,l1*l1-along*along)),wrist


def animate(rig, wren=False):
    durations={'idle':4.8,'thinking':4.0,'place':1.6,'surprise':2.4,'pleased':2.4,'concern':3.2,'greet':2.8}
    rig.animation_data_create()
    for name,duration in durations.items():
        action=bpy.data.actions.new(name);rig.animation_data.action=action
        end=round(duration*30)
        for frame in range(0,end+1,3):
            t=frame/end
            # Smoothstep-shaped envelopes supply anticipation, settle and recovery.
            enter=min(1,t*5);enter=enter*enter*(3-2*enter)
            leave=min(1,(1-t)*4);leave=leave*leave*(3-2*leave)
            envelope=enter*leave
            sway=math.sin(t*math.tau)
            for b in rig.pose.bones:
                b.rotation_mode='QUATERNION';b.matrix_basis=Matrix.Identity(4)
            spine=rig.pose.bones['spine']
            tilt=.009*sway + (-.055*envelope if name=='surprise' else .028*envelope if name=='thinking' else 0)
            spine.rotation_quaternion=Quaternion((1,0,0),tilt)
            bpy.context.view_layer.update()
            body=spine.matrix@rig.data.bones['spine'].matrix_local.inverted()
            head=rig.pose.bones['head']
            pitch=.015*sway + (.065*envelope if name=='thinking' else -.045*envelope if name=='surprise' else 0)
            turn=.025*sway + (.075*envelope if name in ['concern','pleased'] else 0)
            head.rotation_quaternion=Quaternion((0,0,1),turn)@Quaternion((1,0,0),pitch)
            for s,side in [(-1,'L'),(1,'R')]:
                shoulder=body@Vector((s*.235,0,1.38))
                target=Vector((s*.24,-.32,.94))
                if name=='thinking' and s==1:target=target.lerp(Vector((.11,-.26,1.47)),envelope)
                if name=='place' and s==(-1 if wren else 1):
                    # An anticipation in toward the bowl, then a deliberate reach.
                    reach=math.sin(math.pi*min(1,max(0,(t-.1)/.72)))**2
                    target+=Vector((s*.24*reach,-.27*reach,.18*reach))
                if name=='surprise':target+=Vector((s*.035,-.015,.16))*envelope
                if name=='pleased' and s==1:target+=Vector((-.055,.02,.17))*envelope
                if name=='concern' and s==1:target=target.lerp(Vector((.22,-.25,1.55)),envelope)
                if name=='greet' and s==1:target=target.lerp(Vector((.47,-.21,1.69)),envelope)
                target=body@target
                upper=rig.pose.bones['upper_'+side];lower=rig.pose.bones['lower_'+side]
                elbow,wrist=solve(shoulder,target,body@Vector((s*.48,.06,.94)),upper.bone.length,lower.bone.length)
                upper.matrix=aim(shoulder,elbow)
                bpy.context.view_layer.update()
                lower.matrix=aim(elbow,wrist)
                bpy.context.view_layer.update()
                hand=rig.pose.bones['hand_'+side]
                direction=Vector((0,-.04,-.16))
                if name in ['thinking','greet','concern']:direction=direction.lerp(Vector((0,-.06,.14)),envelope)
                hand.matrix=aim(wrist,wrist+body.to_3x3()@direction)
                bpy.context.view_layer.update()
            for b in rig.pose.bones:
                b.keyframe_insert('rotation_quaternion',frame=frame+1,group=b.name)
                b.keyframe_insert('location',frame=frame+1,group=b.name)
        action.use_fake_user=True
        # NLA strips give the exporter unambiguous, independently named clips.
        track=rig.animation_data.nla_tracks.new();track.name=name
        track.strips.new(name,1,action)
        track.mute=True
    rig.animation_data.action=None
    for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(1)
