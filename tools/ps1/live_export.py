"""Keep campaign geometry/doors; export a clean palette for the live cel renderer."""
import bpy,json,hashlib
from pathlib import Path

PALETTE={'wood':'98704c','floor':'bc9668','plaster':'e8dcc0','stone':'c6baa2',
 'paving':'cabc9f','asphalt':'687475','water':'60979b','grass':'89996c','leaf':'587951',
 'leaf_light':'91a675','terra':'c58262','metal':'344d47','glass':'9fc6c4','cream':'f5e8c9',
 'amber':'d5ac59','board':'d3a66b','ink':'303b35','white':'f3eddc','cloth':'547768',
 'blue':'648994','red':'b76e55'}

def export(output,data):
    for mat in bpy.data.materials:
        key=mat.name.split('.')[0]
        if key in PALETTE:
            h=PALETTE[key];col=tuple(int(h[i:i+2],16)/255 for i in (0,2,4))+(1,)
            mat.diffuse_color=col
        else:col=tuple(mat.diffuse_color)
        mat.use_nodes=True;nodes=mat.node_tree.nodes;nodes.clear()
        bs=nodes.new('ShaderNodeBsdfPrincipled');bs.inputs['Base Color'].default_value=col
        bs.inputs['Roughness'].default_value=1
        out=nodes.new('ShaderNodeOutputMaterial');mat.node_tree.links.new(bs.outputs[0],out.inputs[0])
    for obj in list(bpy.data.objects):
        if obj.type in ['CAMERA','LIGHT']:bpy.data.objects.remove(obj,do_unlink=True)
    # Joining static surfaces by material avoids thousands of live draw calls.
    groups={}
    for obj in list(bpy.context.scene.objects):
        if obj.type!='MESH':continue
        bpy.context.view_layer.objects.active=obj
        for mod in list(obj.modifiers):
            bpy.ops.object.modifier_apply(modifier=mod.name)
        key=tuple(m.name for m in obj.data.materials)
        groups.setdefault(key,[]).append(obj)
    for objects in groups.values():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
    bpy.ops.export_scene.gltf(filepath=str(output/'room.glb'),export_format='GLB',export_animations=False,export_yup=True)
    root=Path(__file__).resolve().parents[2]
    source=root/'data/maps'/(data['id']+'.json')
    (output/'manifest.json').write_text(json.dumps({'id':data['id'],'size':data['size'],
      'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'metres_per_tile':.8},indent=2)+'\n')
