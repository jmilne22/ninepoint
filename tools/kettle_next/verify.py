"""Evaluate exported-pose source geometry, including hands and feet, before export."""
import bpy,math
from mathutils import Matrix

def validate(rig,who):
    checks=0;clips={t.name:t.strips[0].action for t in rig.animation_data.nla_tracks}
    for side in ['L','R']:
        for name in ['hand_','thumb_','thumbtip_','toe_']+['finger%d_'%j for j in range(4)]+['tip%d_'%j for j in range(4)]:
            assert rig.data.bones.get(name+side);checks+=1
    for name in clips:
        rig.animation_data.action=clips[name];start,end=clips[name].frame_range
        for ratio in [0,.125,.25,.375,.5,.625,.75,.875,1]:
            bpy.context.scene.frame_set(round(start+(end-start)*ratio));bpy.context.view_layer.update()
            graph=bpy.context.evaluated_depsgraph_get()
            for obj in [o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==rig]:
                eval_obj=obj.evaluated_get(graph);m=eval_obj.to_mesh()
                assert all(math.isfinite(c) for v in m.vertices for c in v.co),(who,name,obj.name,'nonfinite')
                assert max((v.co.length for v in m.vertices),default=0)<4,(who,name,obj.name,'exploded')
                checks+=2;eval_obj.to_mesh_clear()
            for side in ['L','R']:
                hand=rig.pose.bones['hand_'+side]
                assert (hand.head-rig.pose.bones['lower_'+side].tail).length<.005,(who,name,'detached wrist');checks+=1
            if name in ['stand','host','relaxed','listen']:
                for obj in [o for o in bpy.context.scene.objects if o.name.startswith('Sole')]:
                    eo=obj.evaluated_get(graph);m=eo.to_mesh();low=min(v.co.z for v in m.vertices)
                    assert -.025<low<.045,(who,name,'sole',low);checks+=1;eo.to_mesh_clear()
    rig.animation_data.action=None
    for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(1)
    print('KETTLE NEXT POSES',who,checks,'passed')
    return {'identity':who,'checks':checks,'clips':list(clips),'bones':len(rig.data.bones)}
