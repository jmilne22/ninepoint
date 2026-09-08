"""Architecture at the existing footprints: recesses, load-bearing shapes and trim."""
from png import Img
from palette import rgb, mix
from pixel_art import panel, polygon, ellipse, grain, mask
from art_materials import brick
import math


def arch():
    im=Img(112,88)
    im.rect(0,0,112,88,rgb('brick0'))
    # One shared spring line joins the curved masonry to the straight piers.
    ellipse(im,6,8,100,80,'ink1');im.rect(6,48,100,40,rgb('ink1'))
    ellipse(im,17,17,78,64,'asphalt0');im.rect(17,49,78,39,rgb('asphalt0'))
    ring=set()
    for y in range(8,49):
        for x in range(6,106):
            dx,dy=x+.5-56,48-y-.5
            outer=(dx/50)**2+(dy/40)**2
            inner=(dx/39)**2+(dy/31)**2
            if outer<=1 and inner>=1:
                c=mix('brick1','brick2',.65 if x<56 else .3)
                im.set(x,y,c)
                ring.add((x,y))
    # Rasterize continuous one-pixel joints; a narrow angular test leaves dotted cuts.
    for i in range(1,11):
        angle=i*math.pi/11
        x0,y0=56+39*math.cos(angle),48-31*math.sin(angle)
        x1,y1=56+50*math.cos(angle),48-40*math.sin(angle)
        steps=math.ceil(max(abs(x1-x0),abs(y1-y0)))
        for step in range(steps+1):
            x,y=round(x0+(x1-x0)*step/steps),round(y0+(y1-y0)*step/steps)
            if (x,y) in ring:im.set(x,y,rgb('brick0'))
    for x in [6,95]:
        panel(im,x,48,11,36,'brick1','brick2','brick0')
        for y in [57,66,75]:
            im.hline(x+1,y,9,rgb('brick0'))
            im.hline(x+1,y+1,8,mix('brick1','brick2',.35))
        # Narrow impost and foot courses stay centred on the load-bearing pier.
        panel(im,x-1,46,13,4,'brick1','brick2','brick0')
        panel(im,x-1,82,13,6,'brick0','brick1','ink1')
    return im


def roof():
    im=Img(192,48)
    for x in range(192):
        h=max(8,32-min(x,191-x)//3)
        im.vline(x,0,h,rgb('wood0'))
        if x%16==0:im.vline(x,0,h,rgb('wood1'))
        if x%32==0:im.vline(x,0,h+5,rgb('wood2'))
    for a,b in [(0,69),(191,124)]:
        polygon(im,[(a,0),(a+3 if a==0 else a-3,0),(b,27),(b-4 if a==0 else b+4,27)],'wood2')
    panel(im,77,3,42,29,'wood1','wood3','ink1')
    panel(im,81,6,34,21,'blue0','paper2','wood0')
    for x in [83,100]:
        polygon(im,[(x,8),(x+6,8),(x+6,20),(x,24)],'blue1')
        im.vline(x+1,9,7,rgb('blue2'))
    im.vline(98,7,18,rgb('paper1'));im.hline(82,16,32,rgb('paper1'))
    panel(im,76,30,44,3,'wood1','wood2','wood0')
    return im


def glass():
    im=Img(96,48);panel(im,0,0,96,48,'ink2','paper1','ink1')
    for x in range(3,94,15):
        im.rect(x,3,12,38,rgb('blue0'))
        polygon(im,[(x+1,4),(x+5,4),(x+5,29),(x+1,33)],'blue1')
        im.vline(x+2,5,14,rgb('blue2'))
        im.vline(x+12,2,40,rgb('paper2'))
        im.hline(x,26,12,rgb('ink2'))
    panel(im,0,42,96,5,'paper2','paper0','ink2')
    return im


def facade_detail():
    """Narrow downpipe and masonry returns fit against existing street walls."""
    im=Img(128,64)
    for x in [1,121]:
        panel(im,x,0,5,62,'brick1','brick2','brick0')
        for y in range(8,64,8):im.hline(x,y,5,rgb('brick0'))
    panel(im,114,2,3,58,'ink2','ink3','ink1')
    for y in [10,32,54]:im.hline(113,y,5,rgb('ink1'))
    im.hline(110,59,7,rgb('ink2'))
    return im


def cargo():
    im=Img(64,32)
    for x,y in [(0,8),(23,3),(43,12)]:
        panel(im,x,y,20,20,'wood1','wood2','wood0')
        im.rect(x+1,y+1,18,4,rgb('wood2'))
        for dx in [4,10,16]:im.vline(x+dx,y+6,13,rgb('wood0'))
        for yy in [y+6,y+17]:panel(im,x+1,yy,18,3,'wood2','wood3','wood0')
        for xx in [x+2,x+16]:im.set(xx,y+7,rgb('ink2'))
    return im
