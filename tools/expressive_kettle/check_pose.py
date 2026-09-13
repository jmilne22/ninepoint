"""Evaluate deformed geometry, catching twisted knees and floating idle soles."""
import bpy, math

def validate(rig,identity):
    clips={t.name:t.strips[0].action for t in rig.animation_data.nla_tracks}
    legs=[o for o in bpy.context.scene.objects if o.name.startswith('Trouser leg')]
    soles=[o for o in bpy.context.scene.objects if o.name.startswith('Sole')]
    checks=0
    for name in ['stand','host','relaxed','serve','walk']:
        rig.animation_data.action=clips[name]
        start,end=clips[name].frame_range
        for ratio in [0,.25,.5,.75,1]:
            bpy.context.scene.frame_set(round(start+(end-start)*ratio))
            bpy.context.view_layer.update();graph=bpy.context.evaluated_depsgraph_get()
            for leg in legs:
                obj=leg.evaluated_get(graph);mesh=obj.to_mesh()
                for ring in [2,3]:
                    points=[obj.matrix_world@v.co for v in mesh.vertices[ring*16:(ring+1)*16]]
                    width=max(p.x for p in points)-min(p.x for p in points)
                    assert width>.10,(identity,name,ratio,'collapsed knee',width)
                    checks+=1
                obj.to_mesh_clear()
            if name!='walk':
                for sole in soles:
                    obj=sole.evaluated_get(graph);mesh=obj.to_mesh()
                    low=min((obj.matrix_world@v.co).z for v in mesh.vertices)
                    assert -.01<low<.06,(identity,name,ratio,'ungrounded sole',low)
                    checks+=1;obj.to_mesh_clear()
    rig.animation_data.action=None
    from mathutils import Matrix
    for bone in rig.pose.bones:bone.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(1)
    print('POSE CONTRACT',identity,checks,'passed')
