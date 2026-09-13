"""Quiet kaya and soft shell/slate for embedded lessons and review boards."""
import math
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
def build(output):
 output=Path(output)/'surfaces';output.mkdir(parents=True,exist_ok=True)
 wood=Image.open(ROOT/'art/table_scene/kaya.png').convert('RGB').resize((1536,1536),Image.Resampling.LANCZOS)
 Image.blend(wood,Image.new('RGB',wood.size,(201,153,83)),.72).save(output/'board.png')
 for name,base in [('black_stone',(27,38,43)),('white_stone',(225,222,209))]:
  image=Image.new('RGBA',(512,512));pixels=image.load()
  for y in range(512):
   for x in range(512):
    nx=(x-255.5)/251;ny=(y-255.5)/251;r2=nx*nx+ny*ny
    if r2>=1:continue
    z=math.sqrt(1-r2);light=max(0,-.32*nx-.43*ny+.84*z)
    shade=.72+.28*light
    highlight=math.exp(-((nx+.27)**2+(ny+.34)**2)/.12)*(9 if name=='black_stone' else 4)
    alpha=min(1,(1-math.sqrt(r2))*251)
    pixels[x,y]=tuple(min(255,round(c*shade+highlight)) for c in base)+(round(255*alpha),)
  image.save(output/(name+'.png'))
