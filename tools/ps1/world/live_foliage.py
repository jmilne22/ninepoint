"""Curved leaf silhouettes for the approved live-world palette, without foliage balls."""
import math,random,bpy
from common import limb

def crown(x,y,m,tree):
    rng=random.Random(round(x*77+y*99));verts=[];faces=[]
    total=70 if tree else 28
    for i in range(total):
        angle=i*2.399;radius=rng.uniform(.22,.72) if tree else rng.uniform(.10,.30)
        z=(1.18 if tree else .53)+rng.uniform(0,.60 if tree else .36)
        cx=x+radius*math.cos(angle);cy=y+radius*math.sin(angle)
        length=.22 if tree else .15;width=length*.46
        base=len(verts);verts.append((cx,cy,z+.028))
        for j in range(10):
            a=j*math.tau/10;u=math.cos(a)*length;v=math.sin(a)*width
            verts.append((cx+u*math.cos(angle)-v*math.sin(angle),cy+u*math.sin(angle)+v*math.cos(angle),z-abs(math.cos(a))*.055))
        for j in range(10):
            faces.append((base,base+j+1,base+(j+1)%10+1))
            faces.append(tuple(reversed(faces[-1])))
        if i%10==0:limb('leaf branch',(x,y,z-.30),(cx,cy,z),.012,m['wood'])
    mesh=bpy.data.meshes.new('leaf canopy');mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new('individual ficus leaves',mesh);bpy.context.collection.objects.link(obj)
    obj.data.materials.append(m['leaf']);obj.data.materials.append(m['leaf_light'])
    for polygon in mesh.polygons:polygon.material_index=(polygon.index//20)%3==0
