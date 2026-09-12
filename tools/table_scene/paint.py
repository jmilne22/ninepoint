"""Painted facial features and quiet timber grain for the 3D table experiment."""
from pathlib import Path
import math, random
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/table_scene'
OUT.mkdir(parents=True,exist_ok=True)
MOODS=['neutral','thinking','smile','surprise','concern','blink']


def bezier(points, steps=24):
    out=[]
    for i in range(steps+1):
        t=i/steps
        ps=list(points)
        while len(ps)>1:ps=[(a[0]*(1-t)+b[0]*t,a[1]*(1-t)+b[1]*t) for a,b in zip(ps,ps[1:])]
        out.append(ps[0])
    return out


def line(d,points,color,width=2):
    d.line(bezier(points),fill=color,width=width,joint='curve')


def face(who,mood):
    # The same UV face is painted on the continuous head mesh, with no raised
    # eye whites, cheek plugs, mouth tubes or separate nose-shadow geometry.
    im=Image.new('RGB',(1024,512),'#f0c9a8')
    d=ImageDraw.Draw(im)
    ink='#382e2b';brow='#89592d' if who=='wren' else '#45332b'
    for side in [-1,1]:
        cx=512+side*72;cy=249
        width=51 if who=='wren' else 47
        height=31 if who=='wren' else 29
        if mood=='surprise':height=43
        if mood in ['thinking','concern']:height=19
        if mood=='smile':height=15
        if mood=='blink':
            line(d,[(cx-width,cy),(cx,cy+13),(cx+width,cy-1)],ink,4)
        else:
            top=bezier([(cx-width,cy+3),(cx-20,cy-height-14),(cx+17,cy-height-8),(cx+width,cy)])
            bottom=bezier([(cx+width,cy),(cx+20,cy+height+2),(cx-16,cy+height+1),(cx-width,cy+3)])
            eye=Image.new('L',im.size);ed=ImageDraw.Draw(eye);ed.polygon(top+bottom,fill=255)
            layer=Image.new('RGB',im.size,'#fff8e8');ld=ImageDraw.Draw(layer)
            gaze=(-5 if who=='wren' else 5) if mood in ['neutral','thinking'] else 0
            ix=cx+gaze
            ld.ellipse((ix-22,cy-34,ix+22,cy+35),fill='#795132' if who=='wren' else '#435c64')
            ld.ellipse((ix-18,cy-30,ix+18,cy+6),fill='#45392b' if who=='wren' else '#293e48')
            ld.ellipse((ix-9,cy-25,ix+9,cy+25),fill='#20272a')
            ld.ellipse((ix-9,cy-13,ix-1,cy-3),fill='#fffdf0')
            ld.ellipse((ix+5,cy+11,ix+9,cy+15),fill='#e5dcb9')
            im.paste(layer,(0,0),eye);d=ImageDraw.Draw(im)
            d.line(top,fill=ink,width=4,joint='curve')
            d.line(bottom,fill='#986e56',width=2,joint='curve')
        by=cy-49
        slope=0
        if mood in ['thinking','concern']:slope=-side*10
        if mood=='surprise':by-=12
        if mood=='smile':by+=4
        line(d,[(cx-width,by+slope),(cx-5,by-9),(cx+width-3,by-slope)],brow,5)
    # Tiny nose indications are paint, integrated into the face rather than objects.
    line(d,[(509,281),(504,293),(511,294)],'#c79879',2)
    line(d,[(516,294),(519,294)],'#d3a185',2)
    if mood=='surprise':
        d.ellipse((503,325,523,349),fill='#603d37')
        d.ellipse((508,341,518,348),fill='#b67565')
    elif mood=='smile':
        outline=bezier([(478,328),(514,345),(546,326)])
        lower=bezier([(546,326),(516,369),(478,328)])
        d.polygon(outline+lower,fill='#663f37')
        d.polygon(bezier([(483,331),(515,342),(541,330)])+bezier([(541,330),(516,349),(483,331)]),fill='#fff1d9')
    elif mood=='concern':
        line(d,[(488,339),(512,327),(538,339)],ink,3)
    else:
        lift=5 if who=='wren' else 2
        line(d,[(485,334-lift),(513,346),(539,333-lift)],ink,3)
    return im


for who in ['player','wren']:
    atlas=Image.new('RGB',(1024,512*len(MOODS)))
    for row,mood in enumerate(MOODS):atlas.paste(face(who,mood),(0,row*512))
    atlas.save(OUT/f'{who}_face.png')
# Restrained straight grain. The geometry and light supply volume, not dark noise.
rng=random.Random(611)
im=Image.new('RGB',(1024,1024));pixels=im.load()
for y in range(1024):
    for x in range(1024):
        grain=2.5*math.sin(x*.17+.45*math.sin(y*.008))+1.2*math.sin(x*.041+y*.001)
        grain+=rng.uniform(-.7,.7)
        pixels[x,y]=tuple(round(c+grain) for c in (221,175,103))
im.save(OUT/'kaya.png')
print('Painted face atlases and kaya grain:',OUT)
