"""Small generated nine-patch using the approved table palette."""
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[2]
im=Image.new('RGBA',(24,24),'#20332f');d=ImageDraw.Draw(im)
d.rectangle((0,0,23,23),outline='#182924',width=2)
d.rectangle((2,2,21,21),outline='#b79961',width=1)
d.rectangle((3,3,20,20),outline='#526551',width=1)
im.save(root/'art/expressive_kettle/dialogue_panel.png')
