"""Large cloud silhouettes, restrained dusk and the city's working roofline."""
from png import Rand
from palette import rgb, mix
from pixel_art import polygon, ellipse


def sky(im,bottom=140,quiet=False):
    im.rect(0,0,im.w,im.h,rgb('plum0' if not quiet else 'ink1'))
    # Uneven cloud banks avoid equally spaced horizontal palette bands.
    layers=[(36,'ink2'),(67,'plum1'),(94,'rust0'),(116,'rust1'),(133,'gold0')]
    for level,c in layers:
        y=level*bottom//140
        pts=[(0,y+9),(35,y+4),(75,y+7),(103,y),(151,y+3),
             (198,y-4),(231,y),(268,y-3),(309,y+3),(347,y-1),(im.w,y+5),
             (im.w,im.h),(0,im.h)]
        colour=mix(c,'ink1',.52) if quiet else rgb(c)
        polygon(im,pts,colour)
    for x,y,w in [(10,28,83),(112,43,91),(247,22,111),(198,74,120)]:
        yy=y*bottom//140
        colour=rgb('ink1') if quiet else mix('plum0','ink2',.45)
        polygon(im,[(x,yy+5),(x+12,yy+2),(x+w//2,yy),(x+w-11,yy+4),
                    (x+w,yy+6),(x+w-20,yy+8),(x+8,yy+8)],colour)
    for x,y in [(171,11),(219,18),(292,8),(343,32),(61,15)]:im.set(x,y,rgb('ink3'))


def skyline(im,y_base,colour,seed,min_h,max_h):
    r=Rand(seed);x=-4
    while x<im.w:
        w=r.rng(16,32);h=r.rng(min_h,max_h);top=y_base-h
        im.rect(x,top,w,h+40,colour)
        if r.chance(2):
            polygon(im,[(x-2,top),(x+w//2,top-10),(x+w+2,top)],colour)
            im.rect(x+w-7,top-11,3,9,colour)
        else:
            im.rect(x-1,top-3,w+2,3,colour)
            im.rect(x+4,top-7,5,5,colour)
        if colour==rgb('ink1'):
            im.hline(x+1,top+1,w-2,rgb('ink2'))
            for xx in range(x+4,x+w-3,8):
                for yy in range(top+6,y_base,9):
                    if r.chance(3):
                        im.rect(xx,yy,3,4,rgb('gold0'))
                        im.hline(xx,yy,2,rgb('gold1'))
        x+=w+r.rng(1,4)
    # Port crane and tram cables are silhouettes, never new focal lights.
    im.vline(304,y_base-53,55,colour)
    im.rect(278,y_base-53,56,2,colour)
    polygon(im,[(283,y_base-53),(303,y_base-66),(326,y_base-53)],colour)
    im.vline(330,y_base-52,24,colour)
