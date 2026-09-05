"""Two tram-window arrival views, drawn at the game's native resolution."""
from pathlib import Path
from png import Img
from palette import rgb
from gen_venue_props import box
from gen_venue_scenes import draw_text


def scene(school):
    im=Img(384,216,rgb('blue0'))
    im.rect(0,0,384,110,rgb('ink3'))
    # Distant port silhouettes and tram cables place both buildings in one city.
    for x,h in [(0,45),(22,58),(326,62),(352,47)]:box(im,x,110-h,30,h,'ink2')
    im.hline(0,20,384,rgb('ink1'));im.hline(0,24,384,rgb('ink2'))
    im.rect(0,137,384,79,rgb('asphalt1'))
    im.rect(0,139,384,20,rgb('path1'));im.hline(0,157,384,rgb('paper2'))
    for y in [175,188]:im.hline(0,y,384,rgb('ink2'));im.hline(0,y+1,384,rgb('path1'))
    if school:
        box(im,48,48,290,90,'paper2');box(im,74,33,220,23,'paper1')
        for x in range(61,326,24):
            box(im,x,64,20,52,'blue0','ink2');im.rect(x+2,66,7,47,rgb('blue2'));im.rect(x+10,67,8,45,rgb('blue1'))
            im.hline(x,86,20,rgb('paper1'))
        box(im,152,87,65,52,'ink2');box(im,160,94,48,43,'blue1');im.vline(183,94,43,rgb('paper1'))
        box(im,132,118,8,23,'rust1');draw_text(im,93,42,'ESSENVELD INSTITUUT',rgb('ink1'))
        im.rect(145,138,81,4,rgb('paper1'))
        for x in [69,307]:box(im,x,127,20,11,'wood1');im.disc(x+10,121,11,rgb('grass0'))
    else:
        # Steep civic roof, tall masonry bays and a projecting entrance porch.
        for y in range(25,61):im.hline(72-(y-25)//2,y,240+(y-25),rgb('plum0'))
        box(im,55,61,276,77,'brick1');im.hline(55,62,276,rgb('brick3'))
        for x in [69,105,242,278]:
            box(im,x,73,26,56,'paper2');box(im,x+4,76,18,48,'blue0')
            im.vline(x+12,76,48,rgb('gold1'));im.hline(x+4,98,18,rgb('gold1'))
        box(im,146,66,85,75,'paper1');draw_text(im,152,73,'BONDSZAAL',rgb('wood0'))
        box(im,162,94,50,47,'wood0');box(im,168,99,38,40,'rust0');im.vline(187,99,40,rgb('gold1'))
        for y,w in [(141,96),(145,108),(149,120)]:box(im,188-w//2,y,w,4,'path2','path0')
    # Wet marks are placed near the pavement edge, not spread over the image.
    for x,w in [(12,31),(90,23),(284,57),(201,18)]:im.hline(x,165,w,rgb('blue1'))
    box(im,15,103,25,22,'rust1');draw_text(im,23,109,'4',rgb('paper0'));im.rect(26,125,3,23,rgb('ink1'))
    return im


def build(out):
    Path(out).mkdir(parents=True,exist_ok=True)
    for name,school in [('academy_hall',True),('bondszaal',False)]:scene(school).save(str(Path(out)/('arrival_'+name+'.png')))
    return 2
if __name__=='__main__':print(build(Path(__file__).resolve().parent.parent/'art/props'))
