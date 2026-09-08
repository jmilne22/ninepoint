"""Shop-painted lettering, separate from the game's compact UI bitmap font."""
from palette import rgb
from coastal_palette import color as c
from pixel_art import polygon


# Ten-pixel capitals, a seven-pixel x-height and open counters. Two-pixel
# stems keep names readable on the street without enlarging the UI font.
GLYPHS = {
    'T': '#######/#######/..##.../..##.../..##.../..##.../..##.../..##.../..##.../..##...',
    'K': '##...##/##..##./##.##../####.../###..../####.../##.##../##..##./##...##/##...##',
    'L': '##..../##..../##..../##..../##..../##..../##..../##..../######/######',
    'P': '#####./######/##..##/##..##/######/#####./##..../##..../##..../##....',
    'a': '....../....../....../.####./....##/.#####/##..##/##..##/##..##/.#####',
    'd': '....##/....##/....##/.#####/##..##/##..##/##..##/##..##/##..##/.#####',
    'e': '....../....../....../.####./##..##/######/##..../##..../##..##/.####.',
    'h': '##..../##..../##..../#####./##..##/##..##/##..##/##..##/##..##/##..##',
    'l': '##./##./##./##./##./##./##./##./##./.##',
    'n': '....../....../....../#####./##..##/##..##/##..##/##..##/##..##/##..##',
    'p': '....../....../....../#####./##..##/##..##/##..##/##..##/##..##/#####./##..../##....',
    'r': '..../..../..../#.##/##../##../##../##../##../##..',
    't': '.##./.##./.##./####/.##./.##./.##./.##./.##./..##',
    'u': '....../....../....../##..##/##..##/##..##/##..##/##..##/##..##/.#####',
    'y': '....../....../....../##..##/##..##/##..##/##..##/##..##/.#####/....##/##..##/.####.',
}


def text_width(text):
    return sum(4 if ch == ' ' else len(GLYPHS[ch].split('/')[0])+1 for ch in text)-1


def lettering(im, x, y, text, ink):
    for ch in text:
        if ch == ' ':
            x += 4
            continue
        rows=GLYPHS[ch].split('/')
        for yy,row in enumerate(rows):
            for xx,pixel in enumerate(row):
                if pixel == '#':im.set(x+xx,y+yy,ink)
        x += len(rows[0])+1


def shop_sign(im, kind, x):
    y=86;w=106;h=20
    # Each sign has a material and a quiet border, rather than text on plaster.
    fill={'laundry':c('deep'),'bar':rgb('#593f36'),'home':c('light')}[kind]
    ink={'laundry':c('light'),'bar':rgb('#f1d5a2'),'home':c('deep')}[kind]
    edge={'laundry':c('teal'),'bar':rgb('#9c7056'),'home':c('stone')}[kind]
    im.rect(x+1,y+2,w,h,c('shadow'))
    im.rect(x,y,w,h,edge);im.rect(x+1,y+1,w-2,h-2,fill)
    im.hline(x+2,y+1,w-4,c('teal_light') if kind=='laundry' else edge)
    name={'laundry':'Laundry','bar':'The Kettle','home':'Paper'}[kind]
    # The symbol and name form one centred lockup with deliberate breathing room.
    full=14+text_width(name);left=x+(w-full)//2
    lettering(im,left+14,y+4,name,ink)
    if kind=='laundry':
        im.disc(left+5,y+10,5,ink);im.disc(left+5,y+10,3,fill)
        im.hline(left+2,y+12,5,c('teal_light'));im.set(left+2,y+9,ink)
    elif kind=='bar':
        im.rect(left+1,y+8,8,7,ink);im.hline(left,y+7,10,ink)
        im.rect(left+4,y+5,3,2,ink)
        im.rect(left+9,y+8,3,5,ink);im.rect(left+9,y+9,2,3,fill)
        polygon(im,[(left+1,y+10),(left-2,y+7),(left-2,y+10),(left+1,y+14)],ink)
    else:
        im.rect(left+1,y+5,8,11,ink);im.rect(left+2,y+6,6,9,fill)
        polygon(im,[(left+5,y+5),(left+8,y+8),(left+5,y+8)],edge)
        for yy in (10,12):im.hline(left+3,y+yy,3,edge)
