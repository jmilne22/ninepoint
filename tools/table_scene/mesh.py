"""Small smooth mesh vocabulary; the silhouette comes from authored cross sections."""
import math
import bpy
from mathutils import Vector


def material(name,colour):
    m=bpy.data.materials.new(name);m.use_nodes=True
    c=tuple((int(colour[i:i+2],16)/255/12.92 if int(colour[i:i+2],16)/255 <= .04045 else ((int(colour[i:i+2],16)/255+.055)/1.055)**2.4) for i in (1,3,5))
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1)
    p.inputs['Roughness'].default_value=.85
    m.diffuse_color=(*c,1)
    return m


def mesh(name,vertices,faces,mat,uvs=None):
    data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for p in data.polygons:p.use_smooth=True
    if uvs:
        layer=data.uv_layers.new()
        for poly in data.polygons:
            for li in poly.loop_indices:layer.data[li].uv=uvs[data.loops[li].vertex_index]
    return obj


def loft(name,rings,mat,sides=24,flatten=False):
    verts=[];uv=[]
    low=rings[0][0];high=rings[-1][0]
    for z,w,d,cy in rings:
        for i in range(sides+1):
            a=i*math.tau/sides;x=w*math.sin(a);y=d*math.cos(a)
            if flatten and abs(a-math.pi)<.8:y=-d*(1-.08*((a-math.pi)/.8)**2)
            verts.append((x,y+cy,z));uv.append((i/sides,(z-low)/max(.001,high-low)))
    faces=[]
    for j in range(len(rings)-1):
        for i in range(sides):
            k=j*(sides+1)+i;faces.append((k,k+sides+1,k+sides+2,k+1))
    faces.append(tuple(reversed(range(sides))))
    faces.append(tuple((len(rings)-1)*(sides+1)+i for i in range(sides)))
    return mesh(name,verts,faces,mat,uv)


def tube(name,centres,radii,mat,sides=16,aspect=1):
    vertices=[]
    for j,point in enumerate(centres):
        p=Vector(point)
        direction=Vector(centres[min(j+1,len(centres)-1)])-Vector(centres[max(0,j-1)])
        direction.normalize()
        right=direction.cross(Vector((0,1,0)))
        if right.length<.05:right=direction.cross(Vector((1,0,0)))
        right.normalize();front=right.cross(direction).normalized()
        for i in range(sides):
            a=i*math.tau/sides
            vertices.append(p+radii[j]*(right*math.cos(a)+front*math.sin(a)*aspect))
    faces=[]
    for j in range(len(centres)-1):
        for i in range(sides):
            k=j*sides+i;n=j*sides+(i+1)%sides
            faces.append((k,k+sides,n+sides,n))
    faces.extend([tuple(reversed(range(sides))),tuple((len(centres)-1)*sides+i for i in range(sides))])
    return mesh(name,vertices,faces,mat)


def ribbon(name,rows,mat):
    # Rows carry centre, width and bow: broad flowing hair or a folded scarf.
    verts=[];sides=6
    for centre,width,bow in rows:
        for j in range(sides+1):
            t=j/sides*2-1
            verts.append((centre[0]+t*width,centre[1]-bow*(1-t*t),centre[2]))
    faces=[]
    for r in range(len(rows)-1):
        for j in range(sides):
            k=r*(sides+1)+j;faces.append((k,k+sides+1,k+sides+2,k+1))
    obj=mesh(name,verts,faces,mat)
    mod=obj.modifiers.new('cloth thickness','SOLIDIFY');mod.thickness=.008
    bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def bind(obj,rig,weights):
    obj.parent=rig
    groups={n:obj.vertex_groups.new(name=n) for n in rig.data.bones.keys()}
    for vertex in obj.data.vertices:
        for bone,weight in weights(vertex.co).items():
            if weight>0:groups[bone].add([vertex.index],weight,'REPLACE')
    modifier=obj.modifiers.new('skin','ARMATURE');modifier.object=rig


def rigid(obj,rig,bone):bind(obj,rig,lambda _:{bone:1})
