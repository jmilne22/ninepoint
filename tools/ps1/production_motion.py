"""Replace only the locomotion cells in the reproducible production atlas."""
from PIL import Image
import shutil

def build(blender,root,out,names=()):
    scratch=root/'.godot/world-render/motion'
    blender('motion_render.py',scratch,*names)
    source=out.parent.parent/'docs/ps1/world/source/motion';source.mkdir(parents=True,exist_ok=True)
    for path in sorted(scratch.glob('*_motion.blend')):
        name=path.stem.removesuffix('_motion')
        if names and name not in names:continue
        target=out/'people'/(name+'_sheet.png')
        atlas=Image.open(target).convert('RGBA')
        for direction in range(8):
            for frame in [1,2,3]:
                im=Image.open(scratch/f'{name}_{direction}_{frame}.png').convert('RGBA').resize((40,64),Image.Resampling.LANCZOS)
                atlas.paste(im,(frame*40,direction*64))
        atlas.save(target)
        shutil.copyfile(path,source/path.name)
