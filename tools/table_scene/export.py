"""Build glTF models and clips; players need only the checked-in GLBs and Godot."""
import sys,os
from pathlib import Path
import bpy,math
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(Path(__file__).parent),str(ROOT/'tools')]
from character import build
from mesh import material,mesh
from characters import CHARACTERS
OUT=Path(os.environ.get('TABLE_SCENE_OUTPUT',ROOT/'art/table_scene'));OUT.mkdir(parents=True,exist_ok=True)


def reset():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.data.orphans_purge(do_recursive=True)
    bpy.context.scene.render.fps=30


def export(name,animations=False):
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',
        export_animations=animations,export_animation_mode='NLA_TRACKS',
        export_force_sampling=True,export_materials='EXPORT',export_yup=True)



def cube(name,loc,size,mat,bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);obj=bpy.context.object
    obj.name=name;obj.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod=obj.modifiers.new('rounded joinery','BEVEL');mod.width=bevel;mod.segments=3
        bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
        obj.modifiers.new('surface normals','WEIGHTED_NORMAL')
    return obj


def stone(name,at,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,location=at)
    obj=bpy.context.object;obj.name=name;obj.scale=(.047,.047,.020)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(mat)
    for p in obj.data.polygons:p.use_smooth=True
    return obj


def bowl(x,y,colour,refined=False):
    mat=material('Bowl walnut','#6e452f');inside=material('Bowl inside','#453125')
    profile=[(.04,-.07),(.09,-.064),(.133,-.034),(.147,.025),(.151,.058),(.147,.065),(.137,.060),(.132,.02),(.108,-.025),(.065,-.043),(0,-.043)]
    v=[];faces=[]
    for r,z in profile:
        for i in range(64):
            a=math.tau*i/64;v.append((x+r*math.cos(a),y+r*math.sin(a),z))
    for row in range(len(profile)-1):
        for i in range(64):
            a=row*64+i;b=row*64+(i+1)%64;faces.append((a,b,b+64,a+64))
    obj=mesh('Turned bowl',v,faces,mat)
    if refined:
        bpy.ops.mesh.primitive_torus_add(major_radius=.144,minor_radius=.0075,major_segments=64,minor_segments=12,location=(x,y,.061))
        rim=bpy.context.object;rim.name='Polished bowl rim'
        rim.data.materials.append(material('Polished walnut','#865a3c'))
        for poly in rim.data.polygons:poly.use_smooth=True
    for i in range(11):
        a=i*2.4;r=.035 if i<3 else .086
        obj=stone('Bowl stone',(x+r*math.cos(a),y+r*math.sin(a),.015+(i%3)*.008),colour)
        obj.scale=(.72,.72,.72);obj.rotation_euler=(.1*math.cos(a),.12*math.sin(a),a)


def build_table(output=None,refined=False):
    global OUT
    if output is not None: OUT=Path(output)
    reset()
    wood=material('Kaya','#d9ac66');side=material('Board end grain','#bd8847');table=material('Table walnut','#9f764c')
    black=material('Black slate','#182127');white=material('White shell','#f1eee0')
    cube('Table',(0,0,-.125),(8.0,6.0,.14),table,.018)
    cube('Board',(0,0,.03),(1.035,1.105,.18),wood,.012)
    # The end-grain strip is geometry with a material separation, not a fake shadow.
    cube('End grain',(0,-.553,.025),(1.008,.002,.15),side,.002)
    for x,y,c in [(-.72,.10,black),(.72,.10,white)]:bowl(x,y,c,refined)
    export('table')


if __name__ == "__main__":
    for spec in [s for s in CHARACTERS if not s.get("extra")]:
        reset();build(spec);export(spec["id"],True)
    build_table()
    for name,colour in [('black_stone','#182127'),('white_stone','#f1eee0')]:
        reset();stone(name,(0,0,0),material(name,colour));export(name)
    print('TABLE SCENE ASSETS EXPORTED',OUT)
