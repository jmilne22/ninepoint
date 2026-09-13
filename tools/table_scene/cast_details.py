"""Identity-specific hair and clothes, using the shared cast palette and silhouettes."""
import math
import bpy
from mesh import material,mesh,loft,tube,ribbon,rigid

def ball(name,at,size,mat,rig,bone='head'):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=at)
    obj=bpy.context.object;obj.name=name;obj.scale=size
    bpy.ops.object.transform_apply(location=True,rotation=False,scale=True)
    obj.data.materials.append(mat)
    for p in obj.data.polygons:p.use_smooth=True
    rigid(obj,rig,bone)
    return obj

def hair(spec,rig,base,highlight):
    style=spec['hair']
    if style in ['long','bob','tiedback','bun']:
        low=1.72 if style=='bob' else 1.90 if style in ['bun','tiedback'] else 1.48
        vertices=[];faces=[];segments=40
        for z,w,d in [(low,.225,.13),((low+2.08)/2,.245,.17),(2.08,.23,.18)]:
            for j in range(segments+1):
                a=math.pi+.8+j*(math.tau-1.6)/segments
                vertices.append((w*math.sin(a),d*math.cos(a)+.03,z+.018*math.cos(a*3)))
        for row in range(2):
            for j in range(segments):
                k=row*(segments+1)+j;faces.append((k,k+segments+1,k+segments+2,k+1))
        obj=mesh('Hair silhouette',vertices,faces,base)
        mod=obj.modifiers.new('hair volume','SOLIDIFY');mod.thickness=.022
        bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
        rigid(obj,rig,'head')
    if style=='curls':
        # Overlapping low lobes make a compact curl silhouette, not individual spikes.
        for row,(z,r,count) in enumerate([(2.055,.21,12),(2.14,.15,10),(2.20,.065,5)]):
            for i in range(count):
                a=(i/count+row*.035)*math.tau
                ball('Curl', (math.sin(a)*r,math.cos(a)*r*.8,z),(.073,.067,.075),highlight if i%5==0 else base,rig)
    elif style=='cap':
        hat=material('Cap',spec.get('accent','#7a6a58'))
        rigid(loft('Flat cap',[(2.045,.25,.19,.015),(2.13,.25,.19,.025),(2.19,.16,.13,.04),(2.22,.025,.025,.04)],hat),rig,'head')
        ball('Cap peak',(0,-.17,2.04),(.24,.12,.019),hat,rig)
    else:
        points=[(-.16,2.14,-.19),(-.065,2.21,-.09),(.055,2.22,.0),(.16,2.16,.11)]
        if style in ['short','bun','tiedback']:points=[(-.16,2.10,-.185),(-.065,2.16,-.12),(.055,2.18,-.035),(.16,2.12,.14)]
        for i,(x,z,tip) in enumerate(points):
            obj=ribbon('Swept hair',[((x,-.14,z),.091,.03),((x-.012,-.185,z-.06),.082,.025),((tip,-.186,z-.16),.025,0)],highlight if i==1 else base)
            rigid(obj,rig,'head')
    if style=='bun':
        ball('Hair bun',(.16,.11,2.20),(.11,.10,.11),base,rig)
    if style=='tiedback':
        tie=material('Hair tie',spec.get('accent','#8c4034'))
        ball('Tied hair',(0,.18,1.91),(.075,.10,.16),base,rig)
        ball('Hair tie',(0,.22,2.01),(.06,.03,.03),tie,rig)
        rigid(tube('Ponytail',[(0,.24,2.0),(.05,.28,1.87),(.07,.29,1.60),(.09,.25,1.45)], [.065,.075,.062,.018],base),rig,'head')

def clothes(spec,rig,trim):
    kind=spec['accessory'];accent=material('Accent',spec.get('accent',spec['top'][1]))
    if kind=='scarf':
        rigid(loft('Scarf fold',[(1.43,.128,.10,-.004),(1.49,.14,.11,-.005),(1.54,.119,.091,-.005)],accent),rig,'neck')
        for x,length in [(-.068,.43),(.059,.27)]:
            rigid(ribbon('Scarf tail',[((x,-.13,1.49),.058,.019),((x+.01,-.157,1.31),.056,.018),((x+.026,-.151,1.49-length),.05,.009)],accent),rig,'spine')
    if kind=='glasses':
        frame=material('Spectacle frame','#3c3030')
        # Fine wire in front of the painted eyes; no opaque eye-white geometry.
        for side in [-1,1]:
            path=[]
            for i in range(33):
                a=i*math.tau/32;path.append((side*.091+.070*math.cos(a),-.178,1.917+.044*math.sin(a)))
            rigid(tube('Glasses lens',path,[.004]*len(path),frame,8),rig,'head')
        rigid(tube('Glasses bridge',[(-.021,-.18,1.922),(0,-.186,1.928),(.021,-.18,1.922)],[.004]*3,frame,8),rig,'head')
    if kind=='apron':
        rigid(ribbon('Apron',[((0,-.154,1.32),.135,.006),((0,-.158,1.0),.19,.01),((0,-.188,.64),.195,.006)],accent),rig,'spine')
        for side in [-1,1]:rigid(ribbon('Apron strap',[((side*.10,-.08,1.43),.022,.005),((side*.11,-.162,1.30),.022,.003)],accent),rig,'spine')
    if kind in ['blazer','cardigan']:
        for side in [-1,1]:
            rigid(ribbon('Lapel',[((side*.10,-.08,1.44),.039,.008),((side*.10,-.16,1.28),.05,.008),((side*.035,-.16,1.1),.017,.003)],trim),rig,'spine')
        for z in [.91,1.02,1.13]:ball('Button',(.013,-.156,z),(.011,.006,.011),accent,rig,'spine')
    if spec['id']=='ivo':
        pencil=material('Pencil','#d9ac66')
        rigid(tube('Pencil behind ear',[(.211,.01,1.77),(.231,-.01,2.01)],[.008,.008],pencil,8),rig,'head')
