"""Four original identities on a tailored full-body rig, shared by every camera."""
import math
import bpy
from mathutils import Vector
from mesh import material, mesh, loft, tube, ribbon, bind, rigid
from palette import SKIN
import character

PROPORTIONS={'player':(.235,.145,1.0),'wren':(.225,.15,.98),
             'kesh':(.235,.14,1.04),'tomas':(.285,.185,1.02)}

def skeleton(width):
    data=bpy.data.armatures.new('KettleRig');rig=bpy.data.objects.new('KettleRig',data)
    bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig
    rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    def bone(n,a,b,parent=None):
        v=data.edit_bones.new(n);v.head=a;v.tail=b
        if parent:v.parent=data.edit_bones[parent]
    bone('root',(0,0,.94),(0,0,1.12))
    bone('spine',(0,0,1.12),(0,0,1.70),'root')
    bone('neck',(0,0,1.70),(0,0,1.91),'spine')
    bone('head',(0,0,1.91),(0,0,2.39),'neck')
    for s,side in [(-1,'L'),(1,'R')]:
        sh=(s*width,0,1.67);el=(s*(width+.105),.015,1.36);wr=(s*(width+.13),-.025,1.08)
        bone('clavicle_'+side,(0,0,1.65),sh,'spine')
        bone('upper_'+side,sh,el,'clavicle_'+side)
        bone('lower_'+side,el,wr,'upper_'+side)
        bone('hand_'+side,wr,(wr[0],-.035,.96),'lower_'+side)
        for j in range(4):
            x=wr[0]+(j-1.5)*.026;z=.979;length=[.083,.092,.084,.067][j]
            bone('finger%d_%s'%(j,side),(x,-.035,z),(x,-.041,z-length*.55),'hand_'+side)
            bone('tip%d_%s'%(j,side),(x,-.041,z-length*.55),(x,-.047,z-length),'finger%d_%s'%(j,side))
        bone('thumb_'+side,(wr[0]-s*.04,-.035,1.025),(wr[0]-s*.072,-.057,.99),'hand_'+side)
        bone('thumbtip_'+side,(wr[0]-s*.072,-.057,.99),(wr[0]-s*.078,-.067,.955),'thumb_'+side)
        bone('thigh_'+side,(s*.12,0,.94),(s*.125,-.02,.51),'root')
        bone('shin_'+side,(s*.125,-.02,.51),(s*.125,0,.105),'thigh_'+side)
        bone('foot_'+side,(s*.125,0,.105),(s*.125,-.12,.065),'shin_'+side)
        bone('toe_'+side,(s*.125,-.12,.065),(s*.125,-.23,.045),'foot_'+side)
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    return rig

def finish(obj):
    mod=obj.modifiers.new('soft construction','SUBSURF');mod.levels=1
    bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

def build(spec):
    # Reuse the exact approved head, hair and painted UVs. Everything below is rebuilt.
    character.animate=lambda *args:None
    old=character.build(spec);heads=[]
    for obj in list(bpy.context.scene.objects):
        if obj.type!='MESH':continue
        if obj.vertex_groups.get('head'):
            group=obj.vertex_groups['head'].index
            keep=any(g.group==group and g.weight>.9 for v in obj.data.vertices for g in v.groups)
        else:keep=False
        if keep:
            for v in obj.data.vertices:
                v.co.x*=.88;v.co.y*=.90;v.co.z=1.56+(v.co.z-1.56)*.89+.28
            obj.modifiers.clear();obj.vertex_groups.clear();obj.parent=None;heads.append(obj)
        else:bpy.data.objects.remove(obj,do_unlink=True)
    bpy.data.objects.remove(old,do_unlink=True)
    width,depth,height=PROPORTIONS[spec['id']];rig=skeleton(width)
    for obj in heads:rigid(obj,rig,'head')
    skin=material('Skin',SKIN[spec['skin']][2]);cloth=material('Cloth',spec['top'][0])
    trim=material('Cloth trim',spec['top'][1]);pants=material('Trousers',spec['bottom'])
    seam=material('Stitched cloth',spec['top'][1]);shoe=material('Leather','#413a34');sole=material('Rubber sole','#292d29')
    broad=spec['id']=='tomas';wren=spec['id']=='wren'
    waist=width*(.85 if wren else .91)
    torso=loft('Tailored body',[(.94,waist*.95,depth*.92,0),(1.00,waist,depth,0),
        (1.12,waist*.96,depth*.94,0),(1.34,width*.99,depth*1.03,-.004),
        (1.52,width*1.08,depth*1.06,0),(1.63,width*1.04,depth*.93,0),
        (1.72,width*.65,depth*.65,0),(1.76,.086,.074,0)],cloth,32)
    pieces=[torso]
    for s,side in [(-1,'L'),(1,'R')]:
        wr=s*(width+.13)
        sleeve=tube('Sleeve',[(s*(width-.065),0,1.65),(s*width,0,1.65),
            (s*(width+.06),.01,1.49),(s*(width+.105),.015,1.36),
            (s*(width+.12),-.002,1.24),(wr,-.025,1.105)],
            [.108,.115,.098,.088,.079,.063],cloth,16)
        pieces.append(sleeve)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in pieces:obj.select_set(True)
    bpy.context.view_layer.objects.active=torso;bpy.ops.object.join()
    mod=torso.modifiers.new('continuous shoulder','REMESH');mod.mode='VOXEL';mod.voxel_size=.013
    bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=torso.modifiers.new('relaxed cloth','SMOOTH');mod.factor=.7;mod.iterations=4;bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=torso.modifiers.new('efficient surface','DECIMATE');mod.ratio=.32;bpy.ops.object.modifier_apply(modifier=mod.name)
    for v in torso.data.vertices:
        x,y,z=v.co
        # Small compression folds are geometry, so they shade consistently in motion.
        fold=math.exp(-((z-1.05)/.08)**2)*.006*math.sin(x*48+z*23)
        v.co.y += math.copysign(fold,y)
    for p in torso.data.polygons:p.use_smooth=True
    def weights(v):
        x,y,z=v;side='R' if x>=0 else 'L';x=abs(x)
        if x<width*.74 or (z<1.35 and x<width*.98):return {'spine':1}
        arm=min(1,max(0,(x-width*.72)/(width*.4)))
        lower=min(1,max(0,(1.44-z)/.19))
        return {'spine':1-arm,'upper_'+side:arm*(1-lower),'lower_'+side:arm*lower}
    bind(torso,rig,weights)
    rigid(finish(loft('Neck',[(1.68,.085,.074,0),(1.78,.077,.068,0),(1.91,.078,.07,0)],skin)),rig,'neck')
    rigid(loft('Soft hem',[(.936,waist*1.055,depth*1.09,0),(.985,waist*1.055,depth*1.09,0)],trim),rig,'spine')
    rigid(loft('Collar rib',[(1.729,.104,.081,0),(1.77,.099,.080,0)],trim),rig,'neck')
    rigid(finish(loft('Trouser seat',[(.81,.205,.116,0),(.89,.205,.121,0),(1.02,.180,.114,0)],pants)),rig,'root')
    for s,side in [(-1,'L'),(1,'R')]:
        wr=s*(width+.13)
        rigid(tube('Ribbed cuff',[(wr,-.020,1.145),(wr,-.028,1.096)],[.067,.065],trim,20),rig,'lower_'+side)
        rigid(tube('Wrist transition',[(wr,-.025,1.126),(wr,-.025,1.065)],[.037,.033],skin,16),rig,'lower_'+side)
        palm=loft('Palm',[(.969,.047,.026,-.035),(1.01,.056,.029,-.034),(1.05,.045,.026,-.028),(1.08,.032,.024,-.025)],skin,20)
        for v in palm.data.vertices:v.co.x+=wr
        rigid(finish(palm),rig,'hand_'+side)
        for j in range(4):
            name='finger%d_%s'%(j,side);b=rig.data.bones[name];tip=rig.data.bones['tip%d_%s'%(j,side)]
            a=b.head_local;mid=b.tail_local;end=tip.tail_local
            obj=tube('Articulated finger',[a,mid,end,end+Vector((0,0,-.005))],[.014,.013,.011,.004],skin,10)
            bind(obj,rig,lambda v,n=name,j=j,side=side,z=mid.z:{n:min(1,max(0,(v.z-z+.014)/.028)),
                'tip%d_%s'%(j,side):1-min(1,max(0,(v.z-z+.014)/.028))})
        b=rig.data.bones['thumb_'+side];tip=rig.data.bones['thumbtip_'+side]
        thumb=tube('Articulated thumb',[b.head_local,b.tail_local,tip.tail_local],[.023,.019,.010],skin,12)
        bind(thumb,rig,lambda v,side=side,z=b.tail_local.z:{'thumb_'+side:min(1,max(0,(v.z-z+.013)/.026)),
            'thumbtip_'+side:1-min(1,max(0,(v.z-z+.013)/.026))})
        leg=tube('Trouser leg',[(s*.12,0,.94),(s*.125,0,.80),(s*.125,-.018,.56),
            (s*.125,-.02,.47),(s*.125,-.006,.29),(s*.125,0,.15)],
            [.112,.113,.088,.09,.081,.076],pants,20,.87)
        bind(leg,rig,lambda v,side=side:{'thigh_'+side:min(1,max(0,(v.z-.43)/.16)),
            'shin_'+side:1-min(1,max(0,(v.z-.43)/.16))})
        rigid(tube('Trouser cuff',[(s*.125,0,.17),(s*.125,0,.137)],[.078,.079],pants,20,.9),rig,'shin_'+side)
        for label,mat,z,scale in [('Shoe upper',shoe,.083,(.088,.17,.075)),('Sole',sole,.027,(.094,.177,.026))]:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=(s*.125,-.055,z))
            obj=bpy.context.object;obj.name=label;obj.scale=scale
            bpy.ops.object.transform_apply(location=True,rotation=False,scale=True)
            obj.data.materials.append(mat)
            for p in obj.data.polygons:p.use_smooth=True
            bind(obj,rig,lambda v,side=side:{'toe_'+side:min(.8,max(0,(-v.y-.105)/.09)),
                'foot_'+side:1-min(.8,max(0,(-v.y-.105)/.09))})
        for j in range(3):
            obj=tube('Shoe lace',[(s*.125-.04,-.06-j*.028,.14-j*.008),(s*.125+.04,-.06-j*.028,.14-j*.008)],[.006,.006],trim,8)
            rigid(obj,rig,'foot_'+side)
    if wren:
        scarf=material('Scarf',spec.get('accent','#dacd9a'))
        rigid(loft('Scarf wrap',[(1.72,.122,.10,-.006),(1.78,.126,.102,-.006),(1.83,.109,.088,-.003)],scarf),rig,'neck')
        for x,length in [(-.065,.35),(.06,.24)]:
            obj=ribbon('Folded scarf',[((x,-.124,1.79),.047,.018),((x+.01,-.175,1.59),.048,.022),
                ((x+.02,-.17,1.79-length),.045,.009)],scarf);rigid(obj,rig,'spine')
    if broad:
        # Preserve Tomás's cream shirt inside his established green jacket.
        inner=material('Cream shirt','#e8dfc5')
        obj=ribbon('Shirt front',[((0,-depth*.70-.010,1.71),.087,.008),
            ((0,-depth*1.04-.005,1.55),.104,.008),((0,-depth*.94-.012,1.12),.12,.006)],inner)
        rigid(obj,rig,'spine')
        for side in [-1,1]:
            obj=ribbon('Jacket lapel',[((side*.10,-depth*.71,1.69),.024,.004),
                ((side*.14,-depth*.99,1.56),.022,.006),((side*.13,-depth*.97,1.43),.016,.004)],trim)
            rigid(obj,rig,'spine')
        apron=material('Apron','#4c665a')
        obj=ribbon('Bar apron',[((0,-depth-.012,1.42),.155,.012),((0,-depth-.025,1.15),.18,.02),
            ((0,-depth-.015,.94),.175,.014)],apron);rigid(obj,rig,'spine')
        pocket=ribbon('Apron pocket',[((0,-depth-.05,1.22),.10,.008),((0,-depth-.05,1.12),.10,.008)],trim);rigid(pocket,rig,'spine')
    rig.scale.z=height
    rig['identity']=spec['id'];rig['height_scale']=height
    from motion import animate
    animate(rig,spec['id'],width)
    return rig
