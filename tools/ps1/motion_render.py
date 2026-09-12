"""Selective locomotion rebuild; activities and portrait sources remain unchanged."""
import sys,math
from pathlib import Path
import bpy
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import reset,camera,light,render
from people import person,CHARACTERS
args=sys.argv[sys.argv.index('--')+1:];out=Path(args[0]);out.mkdir(parents=True,exist_ok=True)
names=args[1:]
for spec in CHARACTERS:
    if names and spec['id'] not in names:continue
    for pose in [1,2,3]:
        reset(80,128);person(spec,pose)
        cam=camera((0,-5,3.787),(0,0,.9),2.32)
        light('sprite key',(-3,-4,6),(1,.79,.57),270,5)
        light('sprite fill',(3,1,4),(.55,.71,1),110,4)
        for direction in range(8):
            from mathutils import Vector
            angle=direction*math.tau/8
            cam.location=(-5*math.sin(angle),-5*math.cos(angle),3.787)
            cam.rotation_euler=(Vector((0,0,.9))-cam.location).to_track_quat('-Z','Y').to_euler()
            render(out/f'{spec["id"]}_{direction}_{pose}.png')
        if pose==1:bpy.ops.wm.save_as_mainfile(filepath=str(out/(spec['id']+'_motion.blend')))
