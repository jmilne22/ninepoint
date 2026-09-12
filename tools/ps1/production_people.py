from PIL import Image
import sys,shutil

def build(blender,root,out):
    sys.path.insert(0,str(root/'tools'))
    from characters import CHARACTERS
    scratch=root/'.godot/world-render/people';scratch.mkdir(parents=True,exist_ok=True)
    blender('people_render.py',scratch)
    export(root,out)

def export(root,out):
    sys.path.insert(0,str(root/"tools"))
    from characters import CHARACTERS
    scratch=root/".godot/world-render/people"
    dest=out/'people';dest.mkdir(parents=True,exist_ok=True)
    source=out.parent.parent/'docs/ps1/world/source';source.mkdir(parents=True,exist_ok=True)
    for spec in CHARACTERS:
        name=spec['id']
        if not (scratch/f'{name}_7_5.png').exists():raise FileNotFoundError('Incomplete character render: '+name)
        atlas=Image.new('RGBA',(240,512))
        for direction in range(8):
            for frame in range(6):
                cell=Image.open(scratch/f'{name}_{direction}_{frame}.png').convert('RGBA').resize((40,64),Image.Resampling.LANCZOS)
                atlas.paste(cell,(frame*40,direction*64))
        atlas.save(dest/(name+'_sheet.png'))
        if not spec.get('extra'):
            strip=Image.new('RGBA',(108*7,108));small=Image.new('RGBA',(64*7,64))
            for i,mood in enumerate(['neutral','happy','annoyed','working','thinking','worried','pleased']):
                im=Image.open(scratch/(name+'_'+mood+'.png')).convert('RGBA')
                strip.paste(im.resize((108,108),Image.Resampling.LANCZOS),(108*i,0))
                small.paste(im.resize((64,64),Image.Resampling.LANCZOS),(64*i,0))
            strip.save(dest/(name+'_busts.png'));small.save(dest/(name+'_portraits.png'))
            strip.crop((0,0,108,108)).save(dest/(name+'_bust.png'))
        shutil.copyfile(scratch/(name+'.blend'),source/(name+'.blend'))

    # Ceremony onlookers come from the same rendered cast, at the existing band size.
    crowd=Image.new('RGBA',(384,34),(20,24,24,255))
    for i,name in enumerate(['wren','kesh','pip','bertie','nadia','hana','tomas','marguerite','joos','ilse','sunny','orla']):
        path=dest/(name+'_bust.png')
        if path.exists():
            bust=Image.open(path).resize((44,44),Image.Resampling.LANCZOS)
            crowd.alpha_composite(bust,(i*32-5,2))
    (out/'ui').mkdir(parents=True,exist_ok=True)
    crowd.save(out/'ui/crowd.png')
