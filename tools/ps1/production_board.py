from PIL import Image,ImageDraw
import shutil

def build(blender,root,out):
    scratch=root/'.godot/world-render/board';scratch.mkdir(parents=True,exist_ok=True)
    blender('board_render.py',scratch)
    dest=out/'ui';dest.mkdir(parents=True,exist_ok=True)
    for f in scratch.glob('*.png'):
        if not f.name.startswith('hand_'):shutil.copyfile(f,dest/f.name)
    hands=Image.new('RGBA',(26*3,26*4))
    for row in range(4):
        for pose in range(3):hands.paste(Image.open(scratch/f'hand_{row}_{pose}.png').resize((26,26),Image.Resampling.LANCZOS),(pose*26,row*26))
    hands.save(dest/'hands.png')
    Image.open(dest/'bowl.png').resize((42,32),Image.Resampling.LANCZOS).save(dest/'bowl.png')
    # Small UI frames stay code-authored: restrained bevels and readable paper.
    for name,inside in [('panel',(207,196,168)),('panel_dark',(27,34,31))]:
        im=Image.new('RGB',(16,16),(39,39,33));d=ImageDraw.Draw(im)
        for inset,col in [(1,(139,131,108)),(2,(191,179,140)),(3,(69,69,56)),(4,inside)]:d.rectangle((inset,inset,15-inset,15-inset),fill=col)
        im.save(dest/(name+'.png'))
    source=out.parent.parent/'docs/ps1/world/source';source.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(scratch/'presentation.blend',source/'presentation.blend')
    build_tram(blender,root,out)


def build_tram(blender,root,out):
    scratch=root/'.godot/world-render/tram';scratch.mkdir(parents=True,exist_ok=True)
    blender('tram_render.py',scratch)
    dest=out/'ui';dest.mkdir(parents=True,exist_ok=True)
    for f in [*scratch.glob('tram*.png'),scratch/'tram.json']:
        shutil.copyfile(f,dest/f.name)
    source=out.parent.parent/'docs/ps1/world/source';source.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(scratch/'tram.blend',source/'tram.blend')


def build_stills(blender,root,out):
    scratch=root/'.godot/world-render/stills'
    blender('stills_render.py',scratch)
    dest=out/'ui';dest.mkdir(parents=True,exist_ok=True)
    for file in scratch.glob('*.png'):shutil.copyfile(file,dest/file.name)
    source=out.parent.parent/'docs/ps1/world/source';source.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(scratch/'presentation.blend',source/'presentation.blend')
