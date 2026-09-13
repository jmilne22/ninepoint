"""Join compatible skinned pieces; prove three deformed poses keep every vertex."""
import bpy
from mathutils.kdtree import KDTree
from mathutils import Matrix

def positions(rig,clip):
    rig.animation_data.action=next(t.strips[0].action for t in rig.animation_data.nla_tracks if t.name==clip)
    first,last=rig.animation_data.action.frame_range
    bpy.context.scene.frame_set(round(first+(last-first)*.375))
    bpy.context.view_layer.update();graph=bpy.context.evaluated_depsgraph_get();points=[]
    for obj in bpy.context.scene.objects:
        if obj.type!='MESH' or obj.parent!=rig:continue
        evaluated=obj.evaluated_get(graph);mesh=evaluated.to_mesh()
        points.extend(tuple(obj.matrix_world@v.co) for v in mesh.vertices)
        evaluated.to_mesh_clear()
    return points

def batch(rig):
    before={clip:positions(rig,clip) for clip in ['stand','run','seated']}
    rig.animation_data.action=None
    for bone in rig.pose.bones:bone.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
    groups={}
    for obj in list(bpy.context.scene.objects):
        if obj.type!='MESH' or obj.parent!=rig or 'Painted' in obj.name:continue
        bpy.context.view_layer.objects.active=obj
        for mod in list(obj.modifiers):
            if mod.type!='ARMATURE':bpy.ops.object.modifier_apply(modifier=mod.name)
        key=tuple(m.name for m in obj.data.materials)
        groups.setdefault(key,[]).append(obj)
    for key,objects in groups.items():
        if len(objects)<2:continue
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
        objects[0].name='Batched '+' '.join(key)
    checks=0
    for clip,old in before.items():
        new=positions(rig,clip);assert len(old)==len(new),(clip,'vertex count')
        tree=KDTree(len(old))
        for i,p in enumerate(old):tree.insert(p,i)
        tree.balance()
        for point in new:
            assert tree.find(point)[2]<.00002,(clip,'batch changed deformation');checks+=1
    rig.animation_data.action=None
    for bone in rig.pose.bones:bone.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(1)
    print('CAMPAIGN BATCH:',checks,'deformed vertices preserved')
    return checks
