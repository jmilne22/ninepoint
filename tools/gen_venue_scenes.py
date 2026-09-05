"""Architectural landmarks and used furniture for Verhaven, in code pixels."""
from pathlib import Path
from png import Img
from palette import rgb
from gen_venue_props import box,table,counter,coats
from font5x7 import trimmed,advance

def draw_text(im,x,y,text,color,scale=1):
    for ch in text:
        for yy,row in enumerate(trimmed(ch) or []):
            for xx,pixel in enumerate(row):
                if pixel=='#':im.rect(x+xx*scale,y+yy*scale,scale,scale,color)
        x+=advance(ch)*scale


def study_desk():
    im=Img(48,40);im.blit(table(),0,8)
    box(im,0,0,10,10,'teal0');box(im,32,1,14,8,'paper0')
    for y in [3,5]:im.hline(34,y,10,rgb('ink3'))
    im.rect(42,9,2,8,rgb('rust2'));return im


def bed():
    im=Img(32,48);box(im,0,0,32,48,'wood0');box(im,2,3,28,40,'paper1')
    box(im,5,5,22,10,'paper0');box(im,3,18,26,23,'blue1');im.hline(3,19,26,rgb('blue2'))
    im.rect(3,37,26,3,rgb('blue0'));return im


def basket():
    im=Img(24,24);box(im,1,8,22,15,'wood2')
    for x in range(3,23,4):im.vline(x,10,11,rgb('wood0'))
    im.rect(4,3,14,9,rgb('paper1'));im.rect(11,1,10,10,rgb('teal1'));return im


def roof():
    im=Img(192,48)
    for x in range(192):
        h=max(8,32-min(x,191-x)//3);im.vline(x,0,h,rgb('wood0'))
        if x%32==0:im.vline(x,0,h+5,rgb('wood2'))
    box(im,78,5,40,26,'wood2');box(im,82,7,32,19,'blue1')
    im.vline(98,7,19,rgb('paper1'));im.hline(82,16,32,rgb('paper1'));return im


def arch():
    im=Img(112,88)
    for x in range(112):
        dx=(x-56)/48
        roof=20+int(28*(1-min(1,dx*dx))**.5)
        im.vline(x,0,88 if abs(x-56)>46 else 62-roof,rgb('brick0'))
        if abs(x-56)<47:im.vline(x,62-roof,5,rgb('brick2'))
    for y in range(0,88,12):
        im.hline(0,y,10,rgb('brick1'));im.hline(102,y,10,rgb('brick1'))
    return im


def dry_corner():
    im=Img(80,48);box(im,0,0,80,8,'teal0');im.hline(1,1,78,rgb('teal1'))
    im.blit(table(),8,16);box(im,60,28,18,18,'wood1');im.frame(62,30,14,14,rgb('wood3'));return im


def cargo():
    im=Img(64,32)
    for x,y in [(0,8),(24,4),(43,12)]:
        box(im,x,y,20,20,'wood1');im.frame(x+2,y+2,16,16,rgb('wood3'));im.vline(x+9,y,20,rgb('wood0'))
    return im


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
    im=Img(96,48)
    box(im,0,0,96,48,'ink2');box(im,3,2,90,41,'blue0')
    for x in range(4,96,16):
        box(im,x,3,13,37,'blue1','blue2');im.vline(x+2,5,27,rgb('blue3'))
    im.hline(0,43,96,rgb('paper1'));return im


def directions():
    im=Img(48,24);box(im,0,0,48,24,'teal0')
    draw_text(im,2,3,'< STUDY',rgb('paper0'),1);draw_text(im,2,14,'CLASS >',rgb('paper0'),1);return im


def marker():
    im=Img(32,48);im.rect(14,8,3,40,rgb('ink2'));box(im,0,0,32,28,'rust1')
    draw_text(im,5,3,'TRAM',rgb('paper0'),1);draw_text(im,13,15,'4',rgb('gold3'),1);return im


def demo():
    im=Img(64,48);box(im,0,0,64,43,'wood1');box(im,4,3,56,35,'teal0')
    for x in range(11,60,7):im.vline(x,6,28,rgb('teal1'))
    for y in range(7,35,7):im.hline(8,y,47,rgb('teal1'))
    for x,y,c in [(25,14,'paper0'),(32,14,'ink0'),(25,21,'ink0')]:im.disc(x,y,3,rgb(c))
    im.rect(3,44,5,4,rgb('wood0'));im.rect(56,44,5,4,rgb('wood0'));return im


def student_desk():
    im=Img(48,24);box(im,0,0,48,18,'wood2');im.hline(1,1,46,rgb('wood3'))
    box(im,8,3,14,10,'paper1');im.hline(10,7,10,rgb('ink3'))
    im.rect(3,18,3,6,rgb('wood0'));im.rect(41,18,3,6,rgb('wood0'));return im


def number(n):
    im=Img(16,9);box(im,0,0,16,9,'paper0');draw_text(im,3,1,str(n),rgb('ink1'),1);return im


def tea():
    im=Img(48,32);im.blit(counter(),0,8);box(im,5,1,15,18,'ink3');im.hline(4,1,17,rgb('paper2'));im.rect(18,9,5,2,rgb('ink1'));return im


def snack_stool():
    im=Img(24,24);box(im,3,9,18,6,'wood2');im.rect(5,15,3,9,rgb('wood0'));im.rect(17,15,3,9,rgb('wood0'))
    box(im,7,3,12,7,'paper1');im.disc(10,5,2,rgb('gold1'));im.disc(15,5,2,rgb('gold1'));return im


ASSETS={'study_desk':study_desk,'bed':bed,'laundry_basket':basket,'attic_roof':roof,
'port_arch':arch,'dry_corner':dry_corner,'port_cargo':cargo,'review_board':lambda:notice('REVIEW'),
'reception':reception,'school_glass':glass,'school_directions':directions,'tram_marker':marker,
'demonstration':demo,'student_desk':student_desk,'snack_stool':snack_stool,'tea_station':tea}

def build(out):
    Path(out).mkdir(parents=True,exist_ok=True)
    for name,fn in ASSETS.items():fn().save(str(Path(out)/(name+'.png')))
    for n in range(1,13):number(n).save(str(Path(out)/('board_number_%d.png'%n)))
    return len(ASSETS)+12
if __name__=='__main__':print(build(Path(__file__).resolve().parent.parent/'art/props'))
