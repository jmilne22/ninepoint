"""Original coastal buildings: silhouettes and sheltered thresholds, not photo filters."""
from png import Img, Rand
from coastal_palette import color as c
from palette import rgb
from pixel_art import panel, polygon, ellipse
from font5x7 import trimmed, advance


def label(im,x,y,text,color='deep'):
    for ch in text:
        for yy,row in enumerate(trimmed(ch) or []):
            for xx,p in enumerate(row):
                if p=='#':im.set(x+xx,y+yy,c(color))
        x+=advance(ch)


def plant(im,x,y,large=False):
    # Low strap leaves belong to a visible pot, rather than a miniature tree.
    reach=10 if large else 7
    im.rect(x-5,y+3,11,8,c('coral'));im.hline(x-6,y+2,13,c('coral_light'))
    for dx,dy in ((-reach,-3),(-4,-8),(1,-10),(5,-7),(reach,-2)):
        polygon(im,[(x,y+3),(x+dx,y+dy),(x+dx+2,y+dy+1),(x+2,y+3)],'sela_leaf_dark')
        polygon(im,[(x,y+2),(x+dx,y+dy),(x+dx+1,y+dy+2)],'sela_leaf')


def window(im,x,y,w,h,shutters=True):
    im.rect(x,y,w,h,c('stone'))
    im.rect(x+2,y+2,w-4,h-4,c('deep'))
    im.rect(x+3,y+3,max(2,w//3),h-7,c('shadow'))
    im.hline(x-2,y+h,w+4,c('light'))
    im.vline(x+w//2,y+2,h-4,c('teal_light'))
    if shutters:
        for xx in (x-5,x+w):
            im.rect(xx,y,5,h,c('teal'))
            for yy in range(y+3,y+h,4):im.hline(xx,yy,5,c('deep'))


def facade(kind):
    im=Img(128,128)
    top={'home':4,'bar':19,'laundry':10}[kind]
    x0=5 if kind=='bar' else 0
    width=118 if kind=='bar' else 128
    # Recessed roof room and a projecting parapet create different silhouettes.
    im.rect(x0+12,top,82,13,c('stone'))
    im.hline(x0+11,top,84,c('light'))
    im.rect(x0,top+12,width,116-top,c('plaster'))
    im.rect(x0+width-7,top+13,7,115-top,c('stone'))
    im.rect(x0-1,top+10,width+2,4,c('light'))
    for yy in (top+24,top+55):
        if yy>86:continue
        im.rect(x0+9,yy,96,22,c('shadow'))
        for xx in (x0+17,x0+54,x0+86):window(im,xx,yy+2,13,17,False)
        im.rect(x0+6,yy+16,103,9,c('plaster'))
        im.hline(x0+6,yy+16,103,c('light'))
        im.hline(x0+8,yy+25,101,c('stone'))
    # Street level stays at the common door row, irrespective of roof height.
    color='coral' if kind=='bar' else 'teal'
    im.rect(x0+5,101,104,23,c('deep'))
    im.rect(x0+4,99,106,4,c(color))
    for xx in range(x0+7,x0+107,12):im.rect(xx,99,5,4,c('plaster'))
    name={'home':'PAPER','bar':'THE KETTLE','laundry':'LAUNDRY'}[kind]
    label(im,x0+8,89,name)
    if kind=='home':
        for yy in range(105,124,3):im.hline(x0+7,yy,100,c('shadow'))
        im.rect(9,114,11,8,c('plaster'))
    else:
        for xx in range(x0+9,x0+106,24):
            im.rect(xx,106,18,15,c('shadow'));im.vline(xx+1,106,11,c('teal_light'))
        if kind=='bar':
            im.rect(34,116,16,6,rgb('board1'))
            for xx in (37,41,45):im.vline(xx,116,6,rgb('line'))
        else:
            for xx in (16,40,64):
                im.rect(xx,110,12,12,c('plaster'));im.disc(xx+6,116,4,c('deep'))
    im.hline(x0,126,width,c('stone'))
    # Local repairs and a drain pipe belong to one facade, never a tile grid.
    im.rect(x0+112,78,3,46,c('stone'))
    im.rect(x0+1,84,5,9,c('coral_light'))
    return im


def roof_room():
    im=Img(192,48)
    im.rect(0,0,192,48,c('plaster'))
    im.rect(40,3,112,28,c('sky'))
    im.rect(40,22,112,9,c('sea'))
    im.hline(41,23,110,c('sea_light'))
    for x in (42,141):
        im.rect(x,2,9,30,c('teal'))
        for y in range(5,30,4):im.hline(x,y,9,c('deep'))
    im.rect(36,32,121,4,c('light'));im.hline(36,36,121,c('stone'))
    for x in (39,90,147):im.vline(x,23,9,c('stone'))
    plant(im,18,37,True);plant(im,172,37)
    return im


def arcade():
    im=Img(112,88,c('plaster'))
    ellipse(im,11,7,90,72,'sela_shadow')
    im.rect(11,43,90,45,c('shadow'))
    ellipse(im,21,16,70,59,'sela_deep')
    im.rect(21,45,70,43,c('deep'))
    im.hline(0,1,112,c('light'));im.hline(0,5,112,c('stone'))
    for x in (8,94):
        im.rect(x,46,10,42,c('plaster'));im.hline(x-2,46,14,c('light'))
        im.rect(x,81,10,7,c('stone'))
    return im


def court_windows():
    im=Img(96,48)
    im.rect(0,0,96,48,c('plaster'))
    for x in (9,39,69):window(im,x,7,19,30)
    im.hline(0,43,96,c('stone'))
    return im


def pergola():
    im=Img(128,48)
    for x in (5,118):im.rect(x,14,4,34,c('wood'))
    polygon(im,[(0,2),(112,2),(128,20),(7,20)],'sela_wood')
    for x in range(2,116,8):
        polygon(im,[(x,2),(x+3,2),(x+14,19),(x+11,19)],'sela_plaster')
    im.hline(7,21,121,c('deep'))
    return im


def kiosk(frame=0):
    im=Img(48,48)
    im.rect(6,19,36,24,c('plaster'));im.rect(10,20,28,13,c('deep'))
    polygon(im,[(7,8),(37,8),(47,18),(0,18)],'sela_teal')
    im.hline(0,19,48,c('teal_light'));im.rect(4,33,40,5,c('wood'))
    for x in range(3,46,8):
        im.rect(x,19,4,2+(1 if frame==1 and x%3 else 0),c('plaster'))
    label(im,12,24,'TEA','light')
    for x in (9,35):im.rect(x,39,4,8,c('stone'))
    return im


def garden():
    im=Img(48,32)
    im.rect(0,15,48,15,c('stone'));im.rect(1,14,46,5,c('light'))
    for x in (10,25,38):
        im.disc(x,12,9,c('leaf_dark'));im.disc(x-2,9,6,c('leaf'))
    im.hline(0,30,48,c('shadow'))
    return im


def tree(frame=0):
    """Boulevard ficus: branching pale wood under a broad, uneven crown."""
    im=Img(64,56)
    bark,lit,crease=map(rgb,('#a4a596','#d1cdba','#737d71'))
    dark,leaf,light=map(rgb,('#293f35','#416149','#65805a'))
    # The roots stay inside the existing 16x16 collision foot.
    polygon(im,[(24,55),(27,48),(28,34),(22,28),(15,21),(18,20),
                (29,29),(31,18),(34,18),(34,31),(44,22),(48,20),
                (45,26),(35,37),(35,48),(39,55)],bark)
    polygon(im,[(25,54),(29,47),(30,34),(21,25),(18,22),(23,25),
                (32,32),(33,23),(34,35),(32,49),(32,54)],lit)
    im.vline(34,39,11,crease);im.vline(29,42,7,bark)
    polygon(im,[(33,52),(37,55),(34,55)],crease)
    crown=Img(64,56)
    polygon(crown,[(3,15),(6,14),(5,10),(11,9),(12,6),(20,6),
        (23,2),(30,3),(34,1),(40,4),(46,3),(48,7),(54,9),(53,12),
        (60,15),(61,21),(58,23),(62,26),(59,31),(54,33),(48,32),
        (45,35),(38,33),(33,35),(28,32),(22,35),(18,32),(11,32),
        (8,29),(3,28),(4,24),(1,21)],dark)
    for points in [ [(6,15),(14,9),(24,10),(28,17),(20,23),(8,22)],
                    [(19,9),(24,4),(34,5),(41,10),(36,18),(28,16)],
                    [(38,8),(46,6),(51,12),(57,17),(52,24),(42,22)],
                    [(17,23),(24,19),(33,21),(37,27),(29,31),(19,30)] ]:
        polygon(crown,points,leaf)
    # Small connected leaf clusters break the mass, without rings or oval blobs.
    rng=Rand(509)
    for i in range(85):
        x=rng.rng(4,57);y=rng.rng(5,30)
        shade=light if y<18 and x<48 else leaf
        if all(crown.get(xx,yy)[3] for xx,yy in ((x,y),(x+2,y),(x,y+1))):
            crown.hline(x,y,2+(i%2),shade)
            if i%3==0:crown.hline(x+1,y+1,2,shade)
    # The lowest leaves leave narrow gaps where the fork enters the crown.
    for x,y in ((20,29),(32,29),(43,27)):
        crown.rect(x,y,2,3,(0,0,0,0))
    for x,y in ((5,17),(55,23),(17,8)):
        crown.hline(x+(1 if frame==1 else 0),y,3,light)
    im.blit(crown,0,0)
    return im


ASSETS={
    'sela_home':lambda:facade('home'), 'sela_bar':lambda:facade('bar'),
    'sela_laundry':lambda:facade('laundry'), 'sela_pergola':pergola,
    'sela_kiosk':kiosk, 'sela_garden':garden, 'sela_tree':tree,
}
