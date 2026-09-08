"""Architectural landmarks and used furniture for Sela, in code pixels."""
from pathlib import Path
from png import Img
from palette import rgb
import art_furniture as furniture
import art_architecture as architecture
import coastal_architecture as coastal
from gen_venue_props import box,table,counter,coats
from font5x7 import trimmed,advance

def draw_text(im,x,y,text,color,scale=1):
    for ch in text:
        for yy,row in enumerate(trimmed(ch) or []):
            for xx,pixel in enumerate(row):
                if pixel=='#':im.rect(x+xx*scale,y+yy*scale,scale,scale,color)
        x+=advance(ch)*scale


def study_desk():
    """The board the last tenant left, on the desk it was left on.

    This was the The Kettle bar table with papers on it: 48 by 40, three tiles
    wide and two and a half tall, in a room twelve tiles across. Standing
    beside it the player was a third of its width. It is a writing desk now,
    two tiles by two, with a board on it the size of a board.
    """
    return furniture.desk()


def bed():
    return furniture.bed()


def basket():
    im=Img(24,24);box(im,1,8,22,15,'wood2')
    for x in range(3,23,4):im.vline(x,10,11,rgb('wood0'))
    im.rect(4,3,14,9,rgb('paper1'));im.rect(11,1,10,10,rgb('teal1'));return im


def roof():
    return coastal.roof_room()


def arch():
    return coastal.arcade()


def dry_corner():
    return furniture.crate_corner()


def cargo():
    return architecture.cargo()


def notice(title):
    im=Img(48,40);box(im,0,0,48,34,'wood1');box(im,3,10,42,20,'paper1')
    draw_text(im,3,2,title,rgb('gold3'),1)
    for x in [7,24]:
        box(im,x,13,14,13,'paper0');im.hline(x+2,17,9,rgb('ink3'));im.hline(x+2,21,7,rgb('ink3'))
    im.rect(4,34,3,6,rgb('wood0'));im.rect(41,34,3,6,rgb('wood0'));return im


def reception():
    im=Img(64,40);im.blit(counter(),0,8);box(im,30,0,23,15,'teal0');box(im,32,2,19,10,'paper1')
    im.hline(35,5,13,rgb('ink3'));im.hline(35,8,9,rgb('ink3'));return im


def glass():
    return coastal.court_windows()


def directions():
    im=Img(48,24);box(im,0,0,48,24,'teal0')
    draw_text(im,2,3,'< STUDY',rgb('paper0'),1);draw_text(im,2,14,'CLASS >',rgb('paper0'),1);return im


def tram_stop():
    return coastal.tram_shelter()


def shopfront(kind):
    """A ground floor that looks like a shop, set INTO the wall.

    Market Lane's ground floor was blank brick with two 10x9 windows a bay, and
    the laundrette announced itself by having its four full-size interior
    machines drawn on the outside of its brick with no frame around them. The
    first repair went too far the other way: an opaque 48x28 slab with a
    coloured bar across the top, pasted over the brick with its own edges
    showing, which read as a sticker rather than as a building.

    So most of this asset is transparent. What it draws is a hanging board on
    two brackets, a window opening with a frame and a sill, and nothing else:
    the wall behind it is the wall, and the shop is cut into it.
    """
    im=Img(48,32)
    board,glass,name,ink={'wassalon':('teal0','blue0','LAUNDRY','paper0'),
                          'ketel':('wood0','ink1','THE KETTLE','gold3'),
                          'stationer':('wood1','ink1','PAPIER','path1')}[kind]
    # the board, hung off two brackets so it stands away from the brick
    for x in (7,40):im.rect(x,0,1,3,rgb('ink1'))
    # Full width: LAUNDRY is exactly forty-eight pixels of this font, so an
    # inset frame costs two characters and the name is the whole point.
    im.rect(0,2,48,11,rgb(board))
    im.hline(0,2,48,rgb('ink0'));im.hline(0,12,48,rgb('ink0'))
    im.hline(0,3,48,rgb('gold1' if kind!='stationer' else 'wood2'))
    width=sum(advance(ch) for ch in name)
    draw_text(im,max(0,(48-width)//2),5,name,rgb(ink),1)

    # the window: an opening in the wall, not a panel on it
    im.rect(3,16,42,14,rgb('wood0'))
    im.rect(5,18,38,11,rgb(glass))
    for x in (17,30):im.vline(x,18,11,rgb('wood0'))
    if kind=='wassalon':
        for x in (7,20,33):
            im.rect(x,20,9,8,rgb('paper1'));im.disc(x+4,24,3,rgb('blue1'))
            im.disc(x+4,24,2,rgb('paper0'))
        im.rect(6,18,2,4,rgb('blue3'))            # a streak of daylight
    elif kind=='ketel':
        # Three steps below the pavement: what reaches the street is the light.
        im.rect(5,24,38,5,rgb('gold1'))
        im.rect(5,22,38,2,rgb('gold0'))
        im.rect(8,20,6,8,rgb('wood0'))            # somebody at the near table
        im.rect(9,18,4,3,rgb('wood0'))
        for x in (21,25):im.rect(x,25,2,4,rgb('gold3'))   # two cups on the sill
        im.rect(33,21,8,7,rgb('board1'))          # and a board, always
        for i in (2,4,6):im.vline(33+i,21,7,rgb('line'))
        for i in (2,4):im.hline(33,21+i*2,8,rgb('line'))
    else:
        for y in range(19,29,2):im.hline(6,y,36,rgb('ink2'))   # the shutter, down
        im.rect(8,21,8,5,rgb('paper2'));im.hline(10,23,4,rgb('path0'))
    im.rect(2,30,44,2,rgb('paper2'))              # the stone sill
    im.hline(2,31,44,rgb('ink2'))
    return im


def demo():
    im=Img(64,48);box(im,0,0,64,43,'wood1');box(im,4,3,56,35,'teal0')
    for x in range(11,60,7):im.vline(x,6,28,rgb('teal1'))
    for y in range(7,35,7):im.hline(8,y,47,rgb('teal1'))
    for x,y,c in [(25,14,'paper0'),(32,14,'ink0'),(25,21,'ink0')]:im.disc(x,y,3,rgb(c))
    im.rect(3,44,5,4,rgb('wood0'));im.rect(56,44,5,4,rgb('wood0'));return im


def student_desk():
    return furniture.desk(True)


def number(n):
    im=Img(16,9);box(im,0,0,16,9,'paper0');draw_text(im,3,1,str(n),rgb('ink1'),1);return im


def tea():
    im=Img(48,32);im.blit(counter(),0,8);box(im,5,1,15,18,'ink3');im.hline(4,1,17,rgb('paper2'));im.rect(18,9,5,2,rgb('ink1'));return im


def snack_stool():
    im=Img(24,24);box(im,3,9,18,6,'wood2');im.rect(5,15,3,9,rgb('wood0'));im.rect(17,15,3,9,rgb('wood0'))
    box(im,7,3,12,7,'paper1');im.disc(10,5,2,rgb('gold1'));im.disc(15,5,2,rgb('gold1'));return im


ASSETS={'facade_detail':architecture.facade_detail, 'study_desk':study_desk,'bed':bed,'laundry_basket':basket,'attic_roof':roof,
'port_arch':arch,'dry_corner':dry_corner,'port_cargo':cargo,'review_board':lambda:notice('REVIEW'),
'reception':reception,'school_glass':glass,'school_directions':directions,'tram_stop':tram_stop,
'shopfront_wassalon':lambda:shopfront('wassalon'),'shopfront_ketel':lambda:shopfront('ketel'),
'shopfront_stationer':lambda:shopfront('stationer'),
'demonstration':demo,'student_desk':student_desk,'snack_stool':snack_stool,'tea_station':tea}
ASSETS.update(coastal.ASSETS)

def build(out):
    Path(out).mkdir(parents=True,exist_ok=True)
    from art_specs import validate_asset, SPECS
    for name,fn in ASSETS.items():
        spec=SPECS[name]
        if spec.holds:
            w,h=spec.size;im=Img(w*len(spec.holds),h)
            for frame in range(len(spec.holds)):im.blit(fn(frame),frame*w,0)
        else:im=fn()
        validate_asset(name,im)
        im.save(str(Path(out)/(name+'.png')))
    for n in range(1,13):number(n).save(str(Path(out)/('board_number_%d.png'%n)))
    return len(ASSETS)+12
if __name__=='__main__':print(build(Path(__file__).resolve().parent.parent/'art/props'))
