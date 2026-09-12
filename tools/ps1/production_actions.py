import json
from PIL import Image

def build(blender,root,out):
    scratch=root/'.godot/world-render/actions';scratch.mkdir(parents=True,exist_ok=True)
    blender('actions_render.py',scratch)
    export(root,out)

def export(root,out):
    scratch=root/'.godot/world-render/actions'
    activities=json.loads((scratch/'activities.json').read_text())
    for name,used in activities.items():
        if not used:continue
        sheet=Image.new('RGBA',(400,512))
        for direction in range(8):
            for index,activity in enumerate(['play','read','fold','wipe','arrange']):
                # Unused slots carry idle, never a mismatched task. The manifest is tested.
                for pose in range(2):
                    path=scratch/f'{name}_{activity}_{direction}_{pose}.png'
                    if activity in used:im=Image.open(path).convert('RGBA').resize((40,64),Image.Resampling.LANCZOS)
                    else:im=Image.open(out/'people'/f'{name}_sheet.png').crop((0,direction*64,40,direction*64+64))
                    sheet.paste(im,(index*80+pose*40,direction*64))
        sheet.save(out/'people'/f'{name}_actions.png')
    (out/'people/activities.json').write_text(json.dumps(activities,indent=2)+'\n')
