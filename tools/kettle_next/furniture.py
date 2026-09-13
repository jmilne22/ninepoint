"""Kettle furniture shares the existing collision footprints and working heights."""
import math
from common import box,cylinder,sphere,limb
import bpy

STEAM = []

def rounded(name,at,size,mat,bevel=.025):
    o=box(name,at,size,mat,bevel)
    for mod in o.modifiers:
        if mod.type=='BEVEL':mod.segments=3
    return o

def cup(x,y,z,m):
    if z < 1.2: STEAM.append([x,z+.14,-y])
    cylinder('Ceramic saucer',(x,y,z),.12,.017,m['cream'],32)
    cylinder('Cup body',(x,y,z+.07),.075,.125,m['cream'],32)
    cylinder('Coffee surface',(x,y,z+.136),.057,.003,m['ink'],32)
    bpy.ops.mesh.primitive_torus_add(major_radius=.045,minor_radius=.011,major_segments=20,minor_segments=8,location=(x+.077,y,z+.075))
    o=bpy.context.object;o.name='Cup handle';o.rotation_euler.x=math.pi/2;o.data.materials.append(m['cream'])

def table(x,y,w,d,m,kind='playing_table'):
    if kind!='playing_table':
        from world.props import original_table
        return original_table(x,y,w,d,m,kind)
    rounded('Oak table',(x,y,.76),(w*.93,d*.91,.12),m['wood'],.035)
    for dx in [-w*.36,w*.36]:
        for dy in [-d*.32,d*.32]:
            rounded('Tapered table leg',(x+dx,y+dy,.35),(.09,.09,.7),m['wood'],.014)
        rounded('Table apron',(x+dx,y,.64),(.055,d*.77,.12),m['wood'],.012)
    for dy in [-d*.33,d*.33]:rounded('Table apron',(x,y+dy,.64),(w*.77,.055,.12),m['wood'],.012)
    bw=min(w*.50,.73);bd=min(d*.68,.72)
    rounded('Kaya board',(x,y,.85),(bw,bd,.067),m['board'],.009)
    for i in range(9):
        box('Board grid',(x-bw*.4+i*bw*.1,y,.884),(.004,bd*.8,.001),m['ink'])
        box('Board grid',(x,y-bd*.4+i*bd*.1,.885),(bw*.8,.004,.001),m['ink'])
    for i in range(7):sphere('Stone',(x-bw*.3+(i%4)*bw*.1,y-bd*.3+(i//3)*bd*.1,.9),(.025,.025,.013),m['white' if i%2 else 'ink'])
    for dx in [-w*.34,w*.34]:
        sphere('Bowl',(x+dx,y,.87),(.105,.105,.07),m['wood'])
        cylinder('Bowl opening',(x+dx,y,.925),.080,.006,m['ink'],32)
        for j in range(5):sphere('Bowl stone',(x+dx+.035*math.cos(j*2.4),y+.035*math.sin(j*2.4),.930),(.024,.021,.012),m['white' if dx>0 else 'ink'])
    cup(x+w*.32,y+d*.30,.826,m)
    # A folded napkin stays in the corner, clear of the board and reaching hands.
    rounded('Folded napkin',(x-w*.30,y+d*.29,.834),(.23,.17,.012),m['cloth'],.004)

def cabinet(x,y,w,d,m,kind):
    if kind!='bar_counter':
        from world.props import original_cabinet
        return original_cabinet(x,y,w,d,m,kind)
    rounded('Green bar cabinet',(x,y,.48),(w*.94,d*.89,.96),m['cloth'],.025)
    for i in range(4):
        px=x-w*.35+i*w*.235
        rounded('Inset cabinet panel',(px,y-d*.451,.49),(w*.205,.018,.72),m['wood'],.018)
        cylinder('Brass pull',(px+.13,y-d*.467,.70),.025,.04,m['amber'],16).rotation_euler.x=math.pi/2
    rounded('Counter edge',(x,y,.993),(w,d,.09),m['wood'],.025)
    rounded('Counter worktop',(x,y,1.045),(w*.96,d*.94,.022),m['stone'],.015)
    for dx in [-w*.42,w*.42]:limb('Rail bracket',(x+dx,y-d*.46,.22),(x+dx,y-d*.61,.22),.025,m['amber'])
    limb('Brass footrail',(x-w*.45,y-d*.61,.22),(x+w*.45,y-d*.61,.22),.025,m['amber'])
    # Counter staff face north. Cloth at the right-hand reach of Tomás's existing tile.
    for dx in [-w*.27,w*.29]:cup(x+dx,y+.03,1.065,m)
    rounded('Coffee machine',(x-w*.12,y+d*.22,1.27),(.54,.32,.39),m['metal'],.035)
    rounded('Coffee machine front',(x-w*.12,y+d*.22-.17,1.30),(.45,.015,.21),m['cream'],.018)
    for dx in [-.12,.12]:cylinder('Espresso knob',(x-w*.12+dx,y+d*.22-.19,1.30),.027,.025,m['ink'],16).rotation_euler.x=math.pi/2
    rounded('Drip tray',(x-w*.12,y+d*.22-.2,1.105),(.44,.16,.028),m['metal'],.008)
    for level in [1.27,1.92]:
        rounded('Backbar shelf',(x,-2.20,level),(w,.36,.065),m['wood'],.012)
        for j in range(7):
            xx=x-w*.41+j*w*.13
            if level<1.5:cup(xx,-2.2,level+.04,m)
            else:
                cylinder('Bottle',(xx,-2.20,level+.14),.057,.24,m['cloth' if j%2 else 'terra'],20)
                cylinder('Bottle neck',(xx,-2.20,level+.30),.027,.09,m['cloth'],16)
                rounded('Bottle label',(xx,-2.258,level+.13),(.075,.006,.085),m['cream'],.001)
