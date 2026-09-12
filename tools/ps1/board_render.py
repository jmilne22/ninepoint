"""The Go set and presentation stills use the same materials and light as the town."""
import sys,math,random
from pathlib import Path
import bpy
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
from world.palette import make
from world.props import table,plant,bench
from world.scene import architecture
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from palette import SKIN
from people import rgb
out=Path(sys.argv[sys.argv.index('--')+1]);out.mkdir(parents=True,exist_ok=True)

def illuminate():
    light('window',(-3,-4,7),(1,.87,.67),550,4)
    light('room fill',(4,2,5),(.61,.75,1),160,4)

def bowl(m,x=0,y=0,z=0):
    cylinder('bowl foot',(x,y,z+.045),.23,.09,m['wood'])
    sphere('turned bowl',(x,y,z+.18),(.4,.4,.21),m['wood'])
    cylinder('dark interior',(x,y,z+.32),.33,.025,m['ink'])
    rng=random.Random(19)
    for i in range(27):
        a=rng.random()*math.tau;r=rng.random()**.5*.28
        sphere('white shell stone',(x+math.cos(a)*r,y+math.sin(a)*r,z+.36),(.065,.065,.03),m['white'])

# An overhead slab fills the playing rectangle; grid/teaching marks remain vector ink.
reset(256,256);m=make()
box('goban slab',(0,0,0),(2.05,2.05,.19),m['board'],.035)
# Fine along-grain variation is geometry, reproducible and intentionally restrained.
for i in range(34):
    x=-1+i*.06
    box('fine grain',(x,0,.096),(.0015,1.99,.001),m['wood'])
camera((0,0,6),(0,0,0),2.1);illuminate();render(out/'board_surface.png')
for colour in ['black','white']:
    reset(64,64);m=make()
    mat=m['ink' if colour=='black' else 'white']
    mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.25 if colour=='black' else .4
    sphere('slate' if colour=='black' else 'shell',(0,0,0),(.48,.48,.19),mat)
    camera((0,0,5),(0,0,0),1.07);illuminate();render(out/(colour+'_stone.png'))
reset(96,72);m=make();bowl(m);camera((0,-4,3),(0,0,.2),1.15);illuminate();render(out/'bowl.png')
# The table surrounds every board size; it never contains fake playing intersections.
reset(384,216);m=make()
box('table',(0,0,-.1),(7,4,.16),m['wood'],.03)
for i in range(9):box('plank seam',(-3.4+i*.8,0,-.017),(.01,4,.003),m['ink'])
bowl(m,2.55,.65);bowl(m,2.55,-.65)
camera((0,0,7),(0,0,0),7);illuminate();render(out/'table.png')
# Nigiri hand poses, with four existing cast skin tones.
for row,tone in enumerate(['skinA','skinB','skinC','skinD']):
    for pose in range(3):
        reset(104,104);skin=material('skin',rgb(SKIN[tone][1]));shade=material('knuckles',rgb(SKIN[tone][0]))
        box('wrist',(0,.36,.06),(.24,.44,.15),skin,.05)
        sphere('palm',(0,0,.07),(.23,.29,.10),skin)
        for i in range(4):
            x=-.16+i*.105
            if pose==1:
                sphere('curled finger',(x,-.18,.15),(.055,.12,.09),skin)
                limb('finger crease',(x-.03,-.28,.16),(x+.03,-.28,.16),.008,shade)
            else:
                tip=(x+(.025 if pose==2 else 0),-.45+abs(i-1.5)*.07,.04)
                limb('finger',(x,-.1,.07),tip,.044,skin)
                sphere('fingertip',tip,(.044,.06,.035),skin)
        limb('thumb',(.17,.09,.07),(.30,-.1,.12),.065,skin)
        camera((0,-1.4,5),(0,0,0),1.05);illuminate();render(out/f'hand_{row}_{pose}.png')
from stills_render import build as build_stills
build_stills(out)
