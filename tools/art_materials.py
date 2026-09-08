"""Quiet town surfaces: structure first, small connected marks second."""
from png import Img, Rand
from palette import rgb, mix
from pixel_art import ellipse, polygon, stamp, seed

WOOD = mix('wood1', 'wood2', .58)
WOOD_SEAM = mix('wood1', 'wood2', .37)
CONCRETE = mix('paper2', 'ink3', .12)


def wood_floor(im, s, variant=0):
    im.rect(0, 0, 16, 16, WOOD)
    im.hline(0, 15, 16, WOOD_SEAM)
    im.hline(0, 0, 16, mix('wood1','wood2',.64))
    if variant == 0:
        im.vline(10, 0, 15, WOOD_SEAM)
    r=Rand(s)
    for _ in range(2):
        x,y=r.rng(1,11),r.rng(3,12)
        im.hline(x,y,r.rng(2,4),mix('wood1','wood2',.51))


def concrete_floor(im,s):
    im.rect(0,0,16,16,CONCRETE)
    # A quiet fleck, without drawing a square round every grid cell.
    im.hline(4,7,3,mix('paper2','ink3',.15))
    im.hline(10,12,2,mix('paper2','ink3',.09))


def plaster(im,s):
    im.rect(0,0,16,16,rgb('paper1'))
    im.hline(2,6,5,mix('paper1','paper2',.12))
    im.hline(9,11,3,mix('paper1','paper0',.16))


def asphalt(im,s,base='asphalt1'):
    im.rect(0,0,16,16,rgb(base))
    r=Rand(s)
    for _ in range(2):
        x,y=r.rng(1,12),r.rng(1,13)
        im.hline(x,y,r.rng(2,3),mix(base,'asphalt2',.20))


def paving(im,s):
    im.rect(0,0,16,16,rgb('path2'))
    seam=mix('path1','path2',.58)
    im.hline(0,8,16,seam);im.vline(8,0,8,seam);im.vline(4,8,8,seam)
    im.hline(0,9,4,mix('path2','path3',.33))
    im.hline(9,1,6,mix('path2','path3',.33))
    im.hline(11,12,3,mix('path1','path2',.8))


def brick(im,s,base="brick1",mortar="brick0",hi="brick2"):
    im.rect(0,0,16,16,mix(mortar,base,.32))
    r=Rand(s)
    for row,y in enumerate(range(0,16,4)):
        for x in range(-8 if row%2 else 0,16,8):
            col=mix(base,hi,r.pick([.15,.24,.32]))
            im.rect(x+1,y+1,7,3,col)
            im.hline(x+1,y+1,5,mix(base,hi,.46))
            if r.chance(3):im.hline(x+3,y+3,3,mix(mortar,base,.8))


def grass(im,s,kind='plain'):
    im.rect(0,0,16,16,rgb('grass1'))
    if kind=='plain':return
    r=Rand(s)
    for _ in range(2 if kind=='tufts' else 3):
        x,y=r.rng(1,11),r.rng(2,11)
        stamp(im,x,y,['..s.','sls.','.ll.'],
              {'s':mix('grass0','grass1',.6),'l':mix('grass1','grass2',.65)})
        if kind=='flowers':
            im.set(x+1,y,rgb('paper1'));im.set(x+2,y+1,rgb('gold1'))


def foliage(im,s,hedge=False):
    im.rect(0,0,im.w,im.h,rgb('grass1'))
    ellipse(im,1,im.h-6,im.w-2,5,'grass0')
    r=Rand(s)
    for x,y,w,h in ([(0,2,11,11),(7,1,10,12),(3,0,10,10)] if hedge else
                      [(2,7,24,21),(12,3,20,22),(0,2,23,22),(7,0,20,18)]):
        ellipse(im,x,y,w,h,'grass0')
        ellipse(im,x,y,w-2,h-3,'grass1')
        ellipse(im,x+2,y+1,max(2,w-7),max(2,h-8),'grass2')
        if r.chance(2):im.hline(x+4,y+2,3,mix('grass2','grass3',.55))
    if not hedge:
        im.rect(13,25,6,7,rgb('wood0'));im.rect(14,25,2,6,rgb('wood2'))
        im.hline(10,31,12,rgb('grass0'))


def tree_quad(im,s,quad):
    tree=Img(32,32);foliage(tree,seed('park-tree'))
    x,y={'tl':(0,0),'tr':(16,0),'bl':(0,16),'br':(16,16)}[quad]
    im.blit(tree.sub(x,y,16,16),0,0)


def water(im,s,frame=0,canal=False):
    base='blue0' if canal else 'blue1'
    im.rect(0,0,16,16,rgb(base))
    # Frame offsets move only the crests; the water body never boils with noise.
    for x,y,w in [(1,3,8),(10,11,5)]:
        yy=(y+frame)%16
        im.hline(x,yy,w,mix(base,'blue1' if canal else 'blue2',.52))
        im.hline(x+2,yy+1,max(1,w-5),mix(base,'blue1' if canal else 'blue2',.24))


def puddle(im,s,frame=0):
    asphalt(im,s)
    polygon(im,[(2,7),(6,5),(12,6),(15,9),(12,12),(4,11)],'blue0')
    im.hline(4,7+frame,6,mix('blue0','blue1',.8))
    im.hline(9,10,3,mix('blue0','blue1',.6))


def window(im,s):
    brick(im,s)
    im.rect(2,2,12,11,rgb('brick0'))
    im.rect(3,3,10,9,rgb('wood0'));im.rect(4,4,8,7,rgb('blue0'))
    im.rect(5,4,2,5,rgb('blue1'));im.vline(8,4,7,rgb('paper2'))
    im.hline(4,7,8,rgb('paper2'))
    im.hline(2,12,12,rgb('path2'));im.hline(3,13,12,rgb('brick0'))


def roof(im,s,rust=False):
    dark,base,light=('rust0','rust1','rust2') if rust else ('ink1','ink2','ink3')
    im.rect(0,0,16,16,rgb(base))
    for y in range(0,16,4):
        im.hline(0,y+3,16,rgb(dark))
        for x in range(-4 if y%8 else 0,16,8):
            im.vline(x,y,3,rgb(dark));im.hline(x+1,y,6,mix(base,light,.5))


def eave(im,s):
    im.rect(0,0,16,16,rgb('ink2'))
    im.hline(0,1,16,rgb('ink3'));im.hline(0,3,16,rgb('ink1'))
    im.rect(0,9,16,4,rgb('wood0'));im.hline(0,9,16,rgb('wood2'))
    im.rect(0,13,16,3,rgb('ink1'))


def canal_variant(im,s,frame=0,quiet=False):
    im.rect(0,0,16,16,rgb('blue0'))
    if quiet:
        im.hline(3,(12+frame)%16,4,mix('blue0','blue1',.20))
    else:
        im.hline(0,(6+frame)%16,13,mix('blue0','blue1',.40))
        im.hline(4,(7+frame)%16,4,mix('blue0','blue1',.22))
