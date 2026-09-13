"""Small generated nine-patch using the approved table palette."""
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[2]
im=Image.new('RGBA',(24,24),'#20332f');d=ImageDraw.Draw(im)
d.rectangle((0,0,23,23),outline='#182924',width=2)
d.rectangle((2,2,21,21),outline='#b79961',width=1)
d.rectangle((3,3,20,20),outline='#526551',width=1)
im.save(root/'art/expressive_kettle/dialogue_panel.png')

import random,math
rng=random.Random(512)
for name,wood in [('wood_grain',True),('plaster_grain',False)]:
 size=256
 im=Image.new('RGB',(size,size));pixels=im.load()
 for y in range(size):
  for x in range(size):
   n=rng.uniform(-3,3)
   wave=8*math.sin((y+2.2*math.sin(x*.024))*1.3)+4*math.sin(y*.21+x*.007) if wood else 2*math.sin(x*.20)*math.cos(y*.17)
   v=round(128+n+wave);pixels[x,y]=(v,v,v)
 if wood:
  d=ImageDraw.Draw(im)
  for j in range(28):
   y=rng.randrange(size);x=rng.randrange(size);length=rng.randrange(15,100)
   pts=[(x+k,y+math.sin(k*.06)*1.3) for k in range(length)]
   d.line(pts,fill=(109,109,109),width=1)
 im.save(root/('art/expressive_kettle/'+name+'.png'))
