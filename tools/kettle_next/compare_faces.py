"""Every neutral-gaze expression must retain the approved facial pixels exactly."""
from pathlib import Path
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parents[2]
for who in ['player','wren','kesh','tomas']:
    source=Image.open(ROOT/f'art/expressive_world/people/{who}_face.png').convert('RGB')
    new=Image.open(ROOT/f'art/kettle_next/{who}_face.png').convert('RGB')
    assert ImageChops.difference(source,new.crop((1024,0,2048,3072))).getbbox() is None,who
print('All 24 neutral-gaze expression images preserve the approved facial pixels.')
