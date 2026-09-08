"""The two illustrated screens: the title card, and the backdrop behind the cold open.

Both are 384x216 and share the same coastal light, because they are
thirty seconds apart and the second one used to be a flat #14121a rectangle --
"why is this screen just black" was a fair question about the first thing a new
player sees.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from png import Img, Rand
from palette import rgb, mix
from coastal_views import title as coastal_title
from pixel_art import polygon, ellipse, grain, mask

W, H = 384, 216


def _vignette(im, edge=0.86, strength=300, cap=150):
    for x in range(W):
        for y in range(H):
            d = max(abs(x - W / 2) / (W / 2), abs(y - H / 2) / (H / 2))
            if d > edge:
                a = int((d - edge) * strength)
                if a > 0:
                    im.set(x, y, (20, 18, 26, min(cap, a)))


def opening(out_dir):
    """Quiet coastal backdrop under Hana, the empty board and dialogue."""
    im = coastal_title(quiet=True)
    os.makedirs(out_dir, exist_ok=True)
    im.save(os.path.join(out_dir, "opening.png"))
    return W, H


def build(out_dir):
    im = coastal_title()

    # The terrace rail sits behind the table; none of its uprights crosses the board.
    im.rect(0,154,W,62,rgb('ink1'))
    im.rect(0,146,W,3,rgb('ink2'))
    im.hline(0,146,W,rgb('ink3'))
    for x in range(14,W,48):im.rect(x,149,3,67,rgb('ink0'))

    tabletop=mix('wood0','wood1',.65)
    polygon(im,[(166,133),(354,133),(401,207),(116,207)],tabletop)
    grain(im,mask(im,[tabletop]),'title-table',mix('wood0','wood1',.4),
          mix('wood0','wood1',.8),16)
    polygon(im,[(116,207),(401,207),(401,216),(116,216)],'wood0')
    im.hline(116,207,268,rgb('wood2'))

    # Parallel front/back slab edges give the goban thickness without flaring its base.
    polygon(im,[(207,127),(319,127),(359,200),(169,200)],'wood0')
    polygon(im,[(202,125),(318,125),(354,195),(166,195)],'board0')
    polygon(im,[(202,120),(318,120),(354,190),(166,190)],'board1')
    im.hline(203,120,115,rgb('board2'));im.hline(167,190,187,rgb('board2'))
    grain(im,mask(im,['board1']),'title-goban',mix('board0','board1',.9),
          mix('board1','board2',.15),9)

    def point(col,row):
        v=row/8.0
        t=v/(1.65-.65*v)
        hw=44+30*t
        return round(260-hw+col/8*2*hw),round(127+56*t),t

    for row in range(9):
        x,y,_=point(0,row);right,_,_=point(8,row)
        im.hline(x,y,right-x+1,rgb('line'))
    for col in range(9):
        x0,y0,_=point(col,0);x1,y1,_=point(col,8)
        for y in range(y0,y1+1):
            im.set(round(x0+(x1-x0)*(y-y0)/(y1-y0)),y,rgb('line'))

    # Flattened silhouettes and contact shadows place stones on the receding surface.
    for col,row,black in [(2,1,True),(5,1,False),(3,3,True),(6,3,False),
                           (2,4,True),(4,5,False),(6,5,True),(3,6,False),
                           (5,7,True),(1,6,False),(7,7,False)]:
        x,y,t=point(col,row);r=round(2+2*t);h=max(3,round(r*1.6))
        ellipse(im,x-r+1,y-h//2+2,r*2+1,h,'board0')
        ellipse(im,x-r,y-h//2,r*2+1,h,'stoneB0' if black else 'stoneW0')
        ellipse(im,x-r+1,y-h//2,max(2,r),max(1,h//2),
                'stoneB1' if black else 'stoneW1')

    # Bowls have their own place on the table, outside the playing surface.
    for x,y,white in [(341,138,False),(362,179,True)]:
        ellipse(im,x-11,y+4,25,11,'wood0')
        ellipse(im,x-11,y,23,14,'wood1');ellipse(im,x-11,y-1,23,9,'wood3')
        ellipse(im,x-9,y,19,6,'wood0')
        for dx,dy in [(-5,2),(1,1),(5,3),(-1,4)]:
            ellipse(im,x+dx-2,y+dy,5,3,'stoneW1' if white else 'stoneB1')
        im.hline(x-5,y+11,10,rgb('wood2'))

    _vignette(im)
    os.makedirs(out_dir, exist_ok=True)
    im.save(os.path.join(out_dir, 'title.png'))
    opening(out_dir)
    return W,H


if __name__ == "__main__":
    print(build(os.path.join(os.path.dirname(__file__), "..", "art", "title")))
