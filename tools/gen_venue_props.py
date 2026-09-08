"""Large, readable furniture. Deterministic Python pixels, shared town palette."""
from pathlib import Path
from png import Img
from palette import rgb
import art_furniture as furniture


def box(im,x,y,w,h,fill,edge='ink1'):
    im.rect(x,y,w,h,rgb(fill));im.frame(x,y,w,h,rgb(edge))


def washer_bank(frame=0):
    """Four human-scale machines. Only the cloth inside each drum moves."""
    from pixel_art import panel, ellipse
    im=Img(80,26)
    for i in range(4):
        x=i*20
        panel(im,x,1,20,24,'paper1','paper0','ink2')
        im.rect(x+2,3,16,3,rgb('paper2'));im.hline(x+3,3,5,rgb('teal0'))
        im.set(x+15,4,rgb('ink3'));im.set(x+17,4,rgb('ink2'))
        ellipse(im,x+3,8,15,16,'paper2');ellipse(im,x+3,8,14,14,'ink2')
        ellipse(im,x+4,9,12,12,'paper0');ellipse(im,x+5,10,10,10,'blue0')
        offsets=[(1,4),(3,4),(4,2),(2,1)]
        dx,dy=offsets[(frame+i)%4]
        ellipse(im,x+5+dx,10+dy,5,4,'rust1' if i%2 else 'paper2')
        im.hline(x+7,11,3,rgb('blue2'));im.vline(x+15,14,3,rgb('ink1'))
        im.hline(x+2,24,16,rgb('ink2'));im.hline(x+2,7,15,rgb('paper0'))
    return im


def counter(laundry=False):
    return furniture.counter(laundry)


def table():
    """A table with a board on it.

    The table is the right size for a bar; the board on it was not. It was 24
    by 22 -- one and a half times a person's width, and it floated off the back
    edge -- so every room with a game in it read as furniture at two different
    scales. A goban is about 45cm across, which is a person's shoulders: on a
    16 by 24 sprite that is a tile. The bowls came down with it.
    """
    return furniture.table()


def bench():
    return furniture.bench()


def coats():
    return furniture.coats()


def window():
    return furniture.window()


def shelf():
    return furniture.shelf()


def kettle_sign():
    im=Img(48,40);im.hline(1,2,46,rgb('ink1'));im.vline(5,2,8,rgb('ink1'))
    box(im,0,9,46,30,'teal0','gold1');im.disc(21,25,10,rgb('gold2'));im.rect(13,18,17,11,rgb('gold2'))
    im.rect(18,13,6,3,rgb('ink1'));im.rect(13,16,17,2,rgb('gold3'))
    im.rect(29,20,8,3,rgb('gold2'));im.rect(34,17,3,5,rgb('gold2'))
    im.disc(10,23,6,rgb('gold2'));im.disc(10,23,3,rgb('teal0'));return im


def novice_table(person):
    source=furniture.table('school');im=Img(48,48)
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


ASSETS={'school_table':lambda:furniture.table('school'),
        'tournament_table':lambda:furniture.table('tournament'), 'washer_bank':washer_bank,'folding_counter':lambda:counter(True),'bar_counter':counter,
        'playing_table':table,'long_bench':bench,'coat_rack':coats,'tall_window':window,'book_shelf':shelf,'kettle_sign':kettle_sign}

for person in ['noor','ivo','lea','emil','sora']:
    ASSETS['novice_'+person]=lambda person=person:novice_table(person)

def build(out):
    Path(out).mkdir(parents=True,exist_ok=True)
    from art_specs import SPECS, validate_asset
    for name,fn in ASSETS.items():
        spec=SPECS[name]
        if spec.holds:
            w,h=spec.size
            im=Img(w*len(spec.holds),h)
            for frame in range(len(spec.holds)):im.blit(fn(frame),frame*w,0)
        else:im=fn()
        validate_asset(name,im)
        im.save(str(Path(out)/(name+'.png')))
    return len(ASSETS)

if __name__=='__main__':print(build(Path(__file__).resolve().parent.parent/'art/props'))
