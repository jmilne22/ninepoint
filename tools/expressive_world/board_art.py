"""Smooth slate/shell teaching stones, with the approved table's kaya grain."""
import math,os
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(os.environ.get('EXPRESSIVE_WORLD_OUTPUT',ROOT/'art/expressive_world'))/'surfaces'
OUT.mkdir(parents=True,exist_ok=True)
Image.open(ROOT/'art/table_scene/kaya.png').convert('RGB').resize((768,768),Image.Resampling.LANCZOS).save(OUT/'board.png')
for name,base in [('black_stone',(24,33,39)),('white_stone',(241,238,224))]:
    image=Image.new('RGBA',(256,256));pixels=image.load()
    for y in range(256):
        for x in range(256):
            nx=(x-127.5)/125;ny=(y-127.5)/125;r2=nx*nx+ny*ny
            if r2>=1:continue
            z=math.sqrt(1-r2)
            light=max(0,(-.32*nx-.43*ny+.84*z))
            shade=.64+.36*light
            highlight=math.exp(-((nx+.27)**2+(ny+.34)**2)/.075)*(22 if name=='black_stone' else 8)
            alpha=min(1,(1-math.sqrt(r2))*125)
            pixels[x,y]=tuple(min(255,round(c*shade+highlight)) for c in base)+(round(255*alpha),)
    image.save(OUT/(name+'.png'))
print('EXPRESSIVE TEACHING ART: kaya and smooth slate/shell')
