"""Furniture built from top, apron and legs, measured beside a 16x24 person."""
from png import Img
from palette import rgb, mix
from pixel_art import ellipse, polygon, panel, grain, mask


def goban(im,x,y,w=16,h=14):
    panel(im,x,y,w,h,'board1','board2','board0')
    for gx in range(x+2,x+w-1,2):im.vline(gx,y+2,h-4,rgb('line'))
    for gy in range(y+2,y+h-1,2):im.hline(x+2,gy,w-4,rgb('line'))
    for dx,dy,c in [(4,4,'stoneB0'),(8,8,'stoneW1'),(4,8,'stoneB0')]:
        im.set(x+dx,y+dy,rgb(c))
    im.hline(x+1,y+h,w-1,rgb('wood0'))


def bowl(im,x,y,white=False):
    ellipse(im,x,y+2,6,4,'wood0');ellipse(im,x,y,6,4,'wood3')
    ellipse(im,x+1,y+1,4,2,'stoneW0' if white else 'stoneB0')
    im.hline(x+1,y,3,rgb('wood2'))


def cup(im,x,y):
    im.rect(x+1,y+5,5,1,rgb('wood0'))
    panel(im,x,y,5,5,'paper1','paper0','paper2')
    im.rect(x+5,y+1,2,3,rgb('paper2'));im.set(x+5,y+2,rgb('wood1'))
    im.hline(x+1,y+1,3,rgb('wood0'))


def table(kind='club'):
    im=Img(48,32)
    base,hi,lo=('wood2','wood3','wood0') if kind=='club' else ('paper2','paper1','ink2')
    for x in [4,40]:
        panel(im,x,22,4,10,'wood1' if kind=='club' else 'ink2',base,lo)
        im.hline(x,31,6,rgb(lo))
    polygon(im,[(1,10),(46,10),(48,14),(48,24),(45,27),(3,27),(0,24),(0,14)],lo)
    panel(im,1,15,46,10,base,hi,lo)
    im.hline(2,24,43,rgb('wood1' if kind=='club' else 'ink3'))
    polygon(im,[(3,5),(44,5),(47,8),(47,20),(1,20),(1,8)],base)
    im.hline(4,5,39,rgb(hi));im.vline(1,8,12,rgb(hi))
    if kind=='club':
        grain(im,mask(im,[base]),'club-table',mix('wood1','wood2',.5),mix('wood2','wood3',.5),8)
        im.hline(5,18,5,rgb('wood3'));im.hline(37,10,5,rgb('wood1'))
    elif kind=='tournament':
        # Portable federation tables: a dark apron and folding frame below the pale top.
        im.hline(3,23,42,rgb('ink2'));im.hline(6,29,35,rgb('ink3'))
        for x in (5,39):
            im.rect(x,24,3,3,rgb('ink2'));im.set(x,24,rgb('paper1'))
    goban(im,16,8);bowl(im,6,12);bowl(im,36,15,True)
    return im


def counter(laundry=False):
    im=Img(64,32)
    for x in [4,55]:panel(im,x,24,4,8,'wood0','wood1','ink1')
    panel(im,1,12,62,17,'wood1','wood2','wood0')
    for x in [4,24,44]:
        panel(im,x,17,16,10,'wood0','wood2','wood0')
        im.rect(x+2,19,12,6,rgb('wood1'));im.hline(x+10,18,3,rgb('gold1'))
    panel(im,0,6,64,10,'paper1' if laundry else 'wood2','paper0' if laundry else 'wood3','wood0')
    if laundry:
        for x,c in [(7,'teal1'),(32,'rust1')]:
            polygon(im,[(x,2),(x+15,0),(x+21,3),(x+20,9),(x,9)],c)
            im.hline(x+2,3,14,rgb('paper1'));im.hline(x+2,6,16,rgb('paper2'))
    else:
        grain(im,mask(im,['wood2']),'bar-counter',mix('wood1','wood2',.7),'wood3',9)
        for x in [7,18,44]:cup(im,x,2)
        im.rect(30,8,8,4,rgb('paper2'));im.hline(30,8,7,rgb('paper1'))
    return im


def bench():
    im=Img(48,24)
    for x in [4,41]:panel(im,x,2,3,22,'ink2','ink3','ink1')
    for y in [0,5]:panel(im,1,y,46,4,'wood1','wood3','wood0')
    panel(im,0,12,48,5,'wood2','wood3','wood0')
    im.hline(4,14,40,rgb('wood1'));im.hline(20,1,8,rgb('wood2'))
    return im


def coats():
    im=Img(48,32);panel(im,0,2,48,4,'wood1','wood2','wood0')
    for x,c,light in [(3,'blue0','blue1'),(18,'rust0','rust1'),(33,'teal0','teal1')]:
        im.rect(x+5,3,1,5,rgb('gold1'))
        polygon(im,[(x+4,8),(x+8,8),(x+13,13),(x+11,21),(x+9,19),(x+10,29),(x+1,29),(x+2,18),(x,21),(x-1,14)],c)
        polygon(im,[(x+4,9),(x+5,12),(x+4,26),(x+1,27),(x+2,14)],light)
        im.vline(x+7,13,14,rgb('ink1'));im.set(x+7,16,rgb('paper2'))
    return im


def window():
    im=Img(32,48)
    panel(im,0,0,32,48,'paper2','paper0','ink2')
    panel(im,3,2,26,42,'wood0','ink2','ink1')
    for x in [5,17]:
        for y in [4,25]:
            panel(im,x,y,10,18,'blue0','paper1','ink1')
            polygon(im,[(x+1,y+2),(x+4,y+2),(x+4,y+13),(x+1,y+15)],'blue1')
            im.vline(x+2,y+3,7,rgb('blue2'))
    panel(im,0,44,32,3,'paper1','paper0','paper2')
    return im


def shelf():
    im=Img(48,32);panel(im,0,0,48,32,'wood0','wood3','ink1')
    for y in [2,17]:
        for x,w,h,c in [(3,5,10,'rust1'),(9,6,11,'teal0'),(16,4,8,'paper1'),(22,7,10,'blue0'),(30,4,11,'plum1'),(36,8,7,'wood2')]:
            panel(im,x,y+11-h,w,h,c,'paper2','ink1')
            im.hline(x+1,y+4,max(1,w-2),rgb('paper2'))
        panel(im,1,y+12,46,3,'wood1','wood3','wood0')
    return im


def bed():
    im=Img(32,48)
    panel(im,0,0,32,48,'wood0','wood2','ink1')
    panel(im,2,3,28,40,'paper1','paper0','paper2')
    polygon(im,[(6,5),(25,5),(28,8),(26,14),(5,14),(4,9)],'paper0')
    im.hline(7,13,17,rgb('paper2'))
    panel(im,3,17,26,24,'blue1','blue2','blue0')
    polygon(im,[(4,20),(8,18),(7,35),(4,39)],'blue2')
    polygon(im,[(24,20),(27,18),(27,40),(19,40),(23,36)],'blue0')
    im.hline(8,21,14,rgb('blue0'));im.hline(4,18,22,rgb('paper1'))
    panel(im,1,42,30,4,'wood1','wood3','wood0')
    return im


def desk(student=False):
    w=48 if student else 32;im=Img(w,24 if student else 32)
    height=im.h
    for x in [3,w-6]:panel(im,x,height-10,3,10,'wood1','wood2','wood0')
    panel(im,0,4 if student else 7,w,14 if student else 19,'wood2','wood3','wood0')
    grain(im,mask(im,['wood2']),'school-desk' if student else 'study-desk',mix('wood1','wood2',.7),'wood3',5)
    im.hline(3,height-8,w-6,rgb('wood1'))
    if student:
        panel(im,9,6,14,9,'paper1','paper0','paper2');im.hline(11,9,8,rgb('ink3'))
        im.hline(28,10,9,rgb('gold1'));im.set(37,10,rgb('ink1'))
    else:
        goban(im,9,10,14,13);bowl(im,2,12)
        panel(im,0,0,9,7,'teal0','teal1','wood0');panel(im,23,1,9,6,'paper0','paper0','paper2')
        im.hline(25,3,5,rgb('ink3'));im.hline(25,5,4,rgb('ink3'))
    return im


def crate_corner():
    im=Img(80,48)
    polygon(im,[(0,0),(77,0),(80,6),(2,8)],'teal0');im.hline(2,1,74,rgb('teal1'))
    # Exactly the existing solid footprint (x8..55, y32..47), with a real crate.
    panel(im,8,26,48,21,'wood1','wood2','wood0')
    for x in [11,24,37,50]:im.vline(x,32,14,rgb('wood0'))
    panel(im,8,26,48,8,'wood2','wood3','wood0')
    for y in [35,44]:panel(im,9,y,46,3,'wood2','wood3','wood0')
    for x in [11,51]:
        for y in [36,45]:im.set(x,y,rgb('ink2'))
    goban(im,24,18);bowl(im,13,24);bowl(im,44,25,True)
    panel(im,61,29,17,17,'wood1','wood2','wood0')
    im.rect(63,31,13,4,rgb('paper2'));im.hline(64,32,10,rgb('paper1'))
    return im
