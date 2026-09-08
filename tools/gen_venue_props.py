"""Large, readable furniture. Deterministic Python pixels, shared town palette."""
from pathlib import Path
from png import Img
from palette import rgb


def box(im,x,y,w,h,fill,edge='ink1'):
    im.rect(x,y,w,h,rgb(fill));im.frame(x,y,w,h,rgb(edge))


def washer_bank():
    """Four machines. They used to be 32 by 36 each -- twice a person's width
    and half again their height -- which is what a screenshot of this room
    looked wrong for. A front loader is about 60cm across beside somebody 170cm
    tall, so beside a 16 by 24 sprite it is a little over a tile."""
    im=Img(80,26)
    for i in range(4):
        x=i*20
        box(im,x,1,20,23,'paper1');im.hline(x+1,2,18,rgb('paper0'))
        box(im,x+2,3,16,4,'paper2');im.rect(x+3,4,5,1,rgb('teal0'))
        im.set(x+16,4,rgb('ink3'))
        im.disc(x+10,15,7,rgb('ink2'));im.disc(x+10,15,6,rgb('paper0'))
        im.disc(x+10,15,4,rgb('blue0'));im.disc(x+10,16,2,rgb('blue1'))
        im.rect(x+8,16,3,3,rgb('paper2' if i%2 else 'rust1'))
        im.hline(x+7,10,3,rgb('blue2'))
        im.hline(x+2,24,15,rgb('ink1'))
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
    """A table with a board on it.

    The table is the right size for a bar; the board on it was not. It was 24
    by 22 -- one and a half times a person's width, and it floated off the back
    edge -- so every room with a game in it read as furniture at two different
    scales. A goban is about 45cm across, which is a person's shoulders: on a
    16 by 24 sprite that is a tile. The bowls came down with it.
    """
    im=Img(48,32)
    box(im,4,25,4,7,'wood0');box(im,40,25,4,7,'wood0')
    box(im,0,5,48,22,'wood1');im.hline(2,6,44,rgb('wood3'))
    box(im,16,9,16,14,'gold2')
    for i in range(6):
        im.hline(18,11+i*2,13,rgb('wood1'));im.vline(18+i*2,11,11,rgb('wood1'))
    im.disc(9,15,2,rgb('ink1'));im.disc(39,18,2,rgb('paper0'))
    for x,y,c in [(20,13,'ink0'),(26,17,'paper0'),(22,17,'ink0')]:im.set(x,y,rgb(c))
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


def novice_table(person):
    source=table();im=Img(48,48)
    for y in range(source.h):
        for x in range(source.w):im.set(x,y,source.get(x,y))
    # Seats are behind the standing sprites; the aisle remains clear.
    for x in [2,32]:
        box(im,x,34,13,8,'wood2');im.rect(x+1,42,2,5,rgb('wood0'));im.rect(x+10,42,2,5,rgb('wood0'))
    if person=='noor':
        box(im,1,8,11,13,'paper0');im.rect(3,10,7,4,rgb('blue2'));im.hline(3,17,6,rgb('ink3'));im.disc(7,12,3,rgb('ink1'))
    elif person=='ivo':
        box(im,0,17,10,7,'paper1');im.rect(2,19,10,2,rgb('gold2'));im.set(12,19,rgb('ink1'))
    elif person=='lea':
        for y in [16,18,20]:box(im,0,y,11,6,'paper0')
        im.hline(2,22,7,rgb('blue1'))
    elif person=='emil':
        box(im,0,17,11,9,'wood0');im.disc(4,20,2,rgb('gold2'));im.rect(7,20,2,5,rgb('ink3'))
    elif person=='sora':
        box(im,1,33,15,10,'teal1');im.hline(3,34,10,rgb('teal2'));im.set(8,38,rgb('teal0'))
    return im


ASSETS={'washer_bank':washer_bank,'folding_counter':lambda:counter(True),'bar_counter':counter,
        'playing_table':table,'long_bench':bench,'coat_rack':coats,'tall_window':window,'book_shelf':shelf,'kettle_sign':kettle_sign}

for person in ['noor','ivo','lea','emil','sora']:
    ASSETS['novice_'+person]=lambda person=person:novice_table(person)

def build(out):
    Path(out).mkdir(parents=True,exist_ok=True)
    for name,fn in ASSETS.items():fn().save(str(Path(out)/(name+'.png')))
    return len(ASSETS)

if __name__=='__main__':print(build(Path(__file__).resolve().parent.parent/'art/props'))
