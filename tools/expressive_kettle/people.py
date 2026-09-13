"""Full-body POC exports extend the approved match meshes, never their outputs."""
import math
import bpy
from mathutils import Matrix, Vector, Quaternion
from mesh import material, tube, rigid
from rig import aim, solve
from character import build


def build_person(spec):
    rig=build(spec)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for s,side in [(-1,'L'),(1,'R')]:
        for name,a,b,parent in [
            ('thigh',(s*.12,0,.64),(s*.12,0,.35),'root'),
            ('shin',(s*.12,0,.35),(s*.12,0,.10),'thigh_'+side),
            ('foot',(s*.12,0,.10),(s*.12,-.16,.08),'shin_'+side)]:
            bone=rig.data.edit_bones.new(name+'_'+side);bone.head=a;bone.tail=b
            bone.parent=rig.data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    pants=material('Leg cloth',spec['bottom']);shoe=material('Leather shoes','#443b33')
    sole=material('Shoe soles','#292f2b')
    for s,side in [(-1,'L'),(1,'R')]:
        leg=tube('Trouser leg',[(s*.12,0,.64),(s*.12,0,.42),(s*.12,0,.32),(s*.12,0,.12)], [.105,.09,.087,.07],pants,16)
        from mesh import bind
        bind(leg,rig,lambda v,side=side:{'thigh_'+side:min(1,max(0,(v.z-.28)/.14)), 'shin_'+side:1-min(1,max(0,(v.z-.28)/.14))})
        for label,mat,z,scale in [('Shoe',shoe,.09,(.095,.17,.075)),('Sole',sole,.038,(.098,.173,.025))]:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=(s*.12,-.055,z))
            obj=bpy.context.object;obj.name=label;obj.scale=scale
            bpy.ops.object.transform_apply(location=True,rotation=False,scale=True)
            obj.data.materials.append(mat);rigid(obj,rig,'foot_'+side)
    for name,duration in [('stand',4.8),('walk',.8)]:
        action=bpy.data.actions.new(name);rig.animation_data.action=action
        end=round(duration*30)
        for frame in range(end+1):
            phase=frame/end*math.tau
            for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4);b.rotation_mode='QUATERNION'
            sway=math.sin(phase)
            rig.pose.bones['spine'].rotation_quaternion=Quaternion((0,1,0),.015*sway)
            bpy.context.view_layer.update()
            for s,side in [(-1,'L'),(1,'R')]:
                shoulder=Vector((s*.235,0,1.38))
                wrist=Vector((s*.30,-.06,.80))
                if name=='walk':wrist.y+=s*.10*sway
                upper=rig.pose.bones['upper_'+side];lower=rig.pose.bones['lower_'+side]
                elbow,wrist=solve(shoulder,wrist,Vector((s*.55,.04,1.05)),upper.bone.length,lower.bone.length)
                upper.matrix=aim(shoulder,elbow);bpy.context.view_layer.update()
                lower.matrix=aim(elbow,wrist);bpy.context.view_layer.update()
                rig.pose.bones['hand_'+side].matrix=aim(wrist,wrist+Vector((0,-.025,-.16)))
                if name=='walk':
                    p=phase+(math.pi if s<0 else 0)
                    hip=Vector((s*.12,0,.64));ankle=Vector((s*.12,.19*math.cos(p),.10+.12*max(0,math.sin(p))))
                    knee,ankle=solve(hip,ankle,Vector((s*.12,-1,.36)),.29,.25)
                    rig.pose.bones['thigh_'+side].matrix=aim(hip,knee);bpy.context.view_layer.update()
                    rig.pose.bones['shin_'+side].matrix=aim(knee,ankle);bpy.context.view_layer.update()
                    rig.pose.bones['foot_'+side].matrix=aim(ankle,ankle+Vector((0,-.16,-.02)))
                bpy.context.view_layer.update()
            for b in rig.pose.bones:
                b.keyframe_insert('rotation_quaternion',frame=frame+1,group=b.name)
                b.keyframe_insert('location',frame=frame+1,group=b.name)
        track=rig.animation_data.nla_tracks.new();track.name=name
        track.strips.new(name,1,action);track.mute=True;action.use_fake_user=True
    rig.animation_data.action=None
    for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(1)
    return rig
