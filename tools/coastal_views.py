"""Sela from the terrace and tram. Original Python-drawn destination illustrations."""
from png import Img
from coastal_palette import color as c
from coastal_architecture import window, plant, label, tree
from pixel_art import polygon


def title(quiet=False):
    im=Img(384,216,c('sky'))
    im.rect(0,54,384,29,c('plaster'))
    im.rect(0,83,384,72,c('sea'))
    for x,y,w in ((20,102,33),(149,91,46),(286,110,40),(91,129,30)):
        im.hline(x,y,w,c('sea_light'))
    # A clear roofline keeps the skyline separate from ground-level planting.
    for x,y,w,h in ((9,44,45,100),(59,60,63,91),(300,45,60,109),(353,70,31,84)):
        im.rect(x,y,w,h,c('stone' if quiet else 'plaster'))
        im.rect(x-2,y,w+4,4,c('light'))
        for yy in range(y+15,y+h-12,24):
            im.rect(x+6,yy,w-13,11,c('shadow'))
            im.hline(x+4,yy+11,w-9,c('light'))
    im.rect(0,154,384,62,c('stone'))
    im.rect(0,147,384,7,c('plaster'));im.hline(0,147,384,c('light'))
    return im


def arrival(school):
    im=Img(384,216,c('sky'))
    im.rect(0,130,384,86,c('road'))
    im.rect(0,136,384,30,c('paving'));im.hline(0,165,384,c('light'))
    for x in range(0,384,24):im.vline(x,139,26,c('joint'))
    im.hline(0,25,384,c('shadow'))
    for y in (182,194):
        im.hline(0,y,384,c('deep'));im.hline(0,y+1,384,c('stone'))
    if school:
        im.rect(56,34,269,103,c('plaster'))
        im.rect(42,50,92,87,c('stone'))
        im.rect(55,31,271,5,c('light'))
        im.rect(78,22,88,10,c('stone'))
        for x in (72,113,154,195,236,277):window(im,x,49,22,26,False)
        im.rect(65,72,242,8,c('plaster'));im.hline(65,72,242,c('light'))
        for x in (68,108,245,285):window(im,x,96,22,32)
        im.rect(152,89,69,48,c('deep'))
        im.rect(159,95,55,42,c('shadow'))
        for x in (154,216):im.rect(x,89,5,48,c('teal'))
        label(im,91,81,'COMMUNITY CENTRE')
        plant(im,126,125,True);plant(im,231,126,True)
    else:
        im.rect(49,39,286,98,c('stone'))
        im.rect(47,34,290,7,c('light'))
        for x in (62,98,256,292):window(im,x,59,23,63,False)
        im.rect(132,48,105,91,c('plaster'))
        label(im,142,58,'ASSEMBLY HALL')
        for x in (149,191):
            im.rect(x,79,30,59,c('teal'));im.rect(x+4,84,22,49,c('deep'))
        for y,w in ((139,113),(144,129),(149,145)):
            im.rect(186-w//2,y,w,5,c('plaster'));im.hline(186-w//2,y,w,c('light'))
        plant(im,115,125,True);plant(im,253,126,True)
    for x in (3,320):im.blit(tree(),x,92)
    im.rect(19,111,25,20,c('coral'));label(im,28,116,'4','light')
    im.rect(30,132,3,29,c('deep'))
    return im
