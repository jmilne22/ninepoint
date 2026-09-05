"""Large, readable furniture. Deterministic Python pixels, shared town palette."""
from pathlib import Path
from png import Img
from palette import rgb


def box(im,x,y,w,h,fill,edge='ink1'):
    im.rect(x,y,w,h,rgb(fill));im.frame(x,y,w,h,rgb(edge))


def washer_bank():
    im=Img(128,40)
    for i in range(4):
        x=i*32
        box(im,x,2,32,36,'paper1');im.hline(x+1,3,30,rgb('paper0'))
        box(im,x+3,5,26,7,'paper2');im.rect(x+6,7,8,2,rgb('teal0'))
        im.disc(x+24,8,2,rgb('ink3'))
        im.disc(x+16,24,12,rgb('ink2'));im.disc(x+16,24,10,rgb('paper0'))
        im.disc(x+16,24,8,rgb('blue0'));im.disc(x+16,26,5,rgb('blue1'))
        im.rect(x+12,25,7,4,rgb('paper2' if i%2 else 'rust1'))
        im.hline(x+11,18,6,rgb('blue2'));im.rect(x+24,22,2,5,rgb('ink2'))
        im.hline(x+4,38,24,rgb('ink1'))
    return im


def counter(laundry=False):
    im=Img(64,32)
    box(im,1,12,62,18,'wood1');im.hline(2,13,60,rgb('wood2'))
    for x in [4,23,43]:box(im,x,16,17,12,'wood0');im.rect(x+11,18,3,1,rgb('gold1'))
    box(im,0,6,64,10,'paper1' if laundry else 'wood2');im.hline(2,7,60,rgb('paper0' if laundry else 'wood3'))
    im.hline(4,15,12,rgb('wood1'))
    if laundry:
        for x,c in [(7,'teal1'),(32,'rust1')]:
            box(im,x,0,20,9,c);im.hline(x+2,3,16,rgb('paper1'));im.hline(x+2,6,16,rgb('paper1'))
    else:
        for x in [7,17,43]:
            box(im,x,2,6,7,'paper0');im.rect(x+6,4,2,3,rgb('paper2'))
    return im


def table():
    im=Img(48,32)
    box(im,4,25,4,7,'wood0');box(im,40,25,4,7,'wood0')
    box(im,0,5,48,22,'wood1');im.hline(2,6,44,rgb('wood3'))
    box(im,12,2,24,22,'gold2')
    for i in range(7):
        im.hline(15,5+i*2,17,rgb('wood1'));im.vline(15+i*3,5,15,rgb('wood1'))
    im.disc(7,12,4,rgb('ink1'));im.disc(41,17,4,rgb('paper0'))
    for x,y,c in [(18,9,'ink0'),(27,15,'paper0'),(21,15,'ink0')]:im.disc(x,y,1,rgb(c))
    return im


def bench():
    im=Img(48,24)
    box(im,2,0,44,10,'wood1');im.hline(3,1,42,rgb('wood3'))
    box(im,0,12,48,6,'wood2');im.rect(3,18,3,6,rgb('ink1'));im.rect(42,18,3,6,rgb('ink1'))
    return im


def coats():
    im=Img(48,32);box(im,0,2,48,4,'wood1')
    for x,c in [(4,'blue1'),(18,'rust1'),(33,'teal0')]:
        im.rect(x+4,3,1,5,rgb('gold2'));box(im,x,10,13,17,c)
        im.rect(x+4,7,5,5,rgb(c));im.vline(x+6,12,15,rgb('ink2'))
    return im


def window():
    im=Img(32,48);box(im,0,0,32,48,'paper1');box(im,3,3,26,41,'blue0')
    for x in [5,17]:
        for y in [5,25]:box(im,x,y,10,17,'blue1','blue2');im.vline(x+2,y+2,10,rgb('blue3'))
    im.hline(1,45,30,rgb('paper0'));return im


def shelf():
    im=Img(48,32);box(im,0,0,48,32,'wood0')
    for y in [2,17]:
        for x,c in [(3,'rust1'),(10,'teal1'),(18,'paper1'),(25,'blue1'),(34,'plum1')]:
            box(im,x,y,6,11,c);im.hline(x+1,y+3,4,rgb('paper2'))
        im.hline(1,y+12,46,rgb('wood2'))
    return im


def kettle_sign():
    im=Img(48,40);im.hline(1,2,46,rgb('ink1'));im.vline(5,2,8,rgb('ink1'))
    box(im,0,9,46,30,'teal0','gold1');im.disc(21,25,10,rgb('gold2'));im.rect(13,18,17,11,rgb('gold2'))
    im.rect(18,13,6,3,rgb('ink1'));im.rect(13,16,17,2,rgb('gold3'))
    im.rect(29,20,8,3,rgb('gold2'));im.rect(34,17,3,5,rgb('gold2'))
    im.disc(10,23,6,rgb('gold2'));im.disc(10,23,3,rgb('teal0'));return im


ASSETS={'washer_bank':washer_bank,'folding_counter':lambda:counter(True),'bar_counter':counter,
        'playing_table':table,'long_bench':bench,'coat_rack':coats,'tall_window':window,'book_shelf':shelf,'kettle_sign':kettle_sign}

def build(out):
    Path(out).mkdir(parents=True,exist_ok=True)
    for name,fn in ASSETS.items():fn().save(str(Path(out)/(name+'.png')))
    return len(ASSETS)

if __name__=='__main__':print(build(Path(__file__).resolve().parent.parent/'art/props'))
