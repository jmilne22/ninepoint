"""Balanced full-body proportions, extending the approved original identity meshes."""
import bpy
from mathutils import Matrix
from mesh import material, tube, rigid, bind
from character import build
from motion import animate

LIFT=.28

def build_person(spec):
    rig=build(spec)
    # The table bust is not a full-body proportion guide. Give the legs room and
    # reduce the head modestly, preserving the painted face and hair silhouette.
    rig.animation_data_clear()
    for obj in list(bpy.context.scene.objects):
        if obj.type!='MESH':continue
        head=obj.vertex_groups.get('head')
        is_head=head and any(g.group==head.index and g.weight>.9 for v in obj.data.vertices for g in v.groups)
        for v in obj.data.vertices:
            if is_head:
                v.co.x*=.88;v.co.y*=.90;v.co.z=1.56+(v.co.z-1.56)*.89
            v.co.z+=LIFT
    bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for bone in rig.data.edit_bones:
        bone.head.z+=LIFT;bone.tail.z+=LIFT
    for s,side in [(-1,'L'),(1,'R')]:
        for name,a,b,parent in [
            ('thigh',(s*.12,0,.92),(s*.12,0,.49),'root'),
            ('shin',(s*.12,0,.49),(s*.12,0,.10),'thigh_'+side),
            ('foot',(s*.12,0,.10),(s*.12,-.16,.08),'shin_'+side)]:
            bone=rig.data.edit_bones.new(name+'_'+side);bone.head=a;bone.tail=b
            bone.parent=rig.data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    pants=material('Leg cloth',spec['bottom']);shoe=material('Leather shoes','#443b33')
    sole=material('Shoe soles','#292f2b')
    for s,side in [(-1,'L'),(1,'R')]:
        leg=tube('Trouser leg',[(s*.12,0,.91),(s*.12,0,.71),(s*.12,0,.51),(s*.12,0,.43),(s*.12,0,.14)], [.105,.10,.087,.084,.064],pants,16)
        bind(leg,rig,lambda v,side=side:{'thigh_'+side:min(1,max(0,(v.z-.41)/.16)), 'shin_'+side:1-min(1,max(0,(v.z-.41)/.16))})
        for label,mat,z,scale in [('Shoe',shoe,.09,(.092,.165,.072)),('Sole',sole,.038,(.095,.169,.025))]:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=(s*.12,-.055,z))
            obj=bpy.context.object;obj.name=label;obj.scale=scale
            bpy.ops.object.transform_apply(location=True,rotation=False,scale=True)
            obj.data.materials.append(mat);rigid(obj,rig,'foot_'+side)
    animate(rig,spec['id'])
    from check_pose import validate
    validate(rig,spec['id'])
    return rig
