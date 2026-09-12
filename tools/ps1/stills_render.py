"""Opening, title and travel stills share the city's daytime lighting and doors."""
import sys
from pathlib import Path
import bpy
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import reset,box,camera,render
from world.palette import make
from world.props import table,plant,bench
from world.scene import architecture
from world.surroundings import daylight


def build(out):
    out.mkdir(parents=True,exist_ok=True)
    for name in ['title','opening','arrival_academy_hall','arrival_bondszaal']:
        scene=reset(384,216);m=make()
        box('continuous paving',(0,0,-.1),(80,80,.16),m['paving'])
        if name in ['title','opening']:
            architecture('sela_home',1,2,4,1.3,m)
            architecture('sela_bar',-3,2,3.5,1.3,m)
            plant(3,-1,m,True);plant(-3.5,-2,m,True)
            table(.8,-1,1.45,1,m);bench(2,-2.3,1.5,.5,m)
            box('sea',(-1,-18,-.06),(80,29,.07),m['water'])
            camera((10,-13,10),(0,0,.5),11.7)
        else:
            width=6 if name.endswith('hall') else 7
            architecture('sela_home',0,2,width,2,m)
            for x in [-2.5,2.5]:plant(x,-.5,m,True)
            for x in [-1.6,0,1.6]:architecture('port_arch',x,.1,1.6,.3,m)
            camera((9,-13,8),(0,0,.6),10.7)
        daylight(scene,0,0)
        render(out/(name+'.png'))
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'presentation.blend'))

if __name__=='__main__':build(Path(sys.argv[sys.argv.index('--')+1]))
