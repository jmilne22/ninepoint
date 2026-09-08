"""Native-size interpretations of the protected portrait hair and face shapes."""
from palette import rgb, skin
from pixel_art import ellipse, polygon, stamp


# Crowns are drawn as clusters, with broken fringes and light on their left planes.
# A silhouette includes its side locks: curls must frame a face, not sit as a hat.
CROWNS = {
    'crop': [
        '....hhhh....', '...hHHHhhh..', '..hHHHhhhhh.', '.hhhhhhhhhh.',
        '.hhh.hhh.hh.', '.hh......h..',
    ],
    'short': [
        '....hhhh....', '..hhHHHhhh..', '.hhHHHhhhhh.', '.hhhhhhhhhh.',
        '.hhh.hhh.hh.', '.hh......hh.', '.hh......hh.',
    ],
    'long': [
        '...hhhhh....', '..hHHHhhhh..', '.hHHHhhhhhh.', '.hHHhhhhhhh.',
        '.hHhhh.hhhh.', '.hHh....hhh.', '.hH......hh.',
    ],
    'curls': [
        '...hh..hh...', '..hHHhhHHh..', '.hhHhhhhHhh.', 'hHHhhhhhhHHh',
        'hHhhhhhhhhHh', '.hh......hh.', 'hHh......hHh', 'hHh......hHh',
        '.hhh....hhh.', '..hh....hh..',
    ],
    'bun': [
        '....hhh.....', '...hHHhh....', '..hhHHhhhh..', '.hhhhhhhhhh.',
        '.hhh....hhh.', '.hh......hh.',
    ],
}


def _stamp_hair(im, c, x, y, rows):
    stamp(im, x, y, rows, {'h': c['hair_col'][0], 'H': c['hair_col'][1]})


def hair_back(im, c, direction, x, y):
    dark, light = map(rgb, c['hair_col'])
    if c['hair'] == 'long':
        polygon(im, [(x+3,y+2),(x+9,y+2),(x+11,y+5),(x+12,y+14),
                     (x+10,y+16),(x+7,y+15),(x+4,y+16),(x,y+15),(x+1,y+5)], dark)
        im.rect(x+1,y+5,2,9,light)
        im.hline(x+2,y+14,2,light)
        if direction == 'up':
            im.rect(x+4,y+4,2,8,light)
            im.vline(x+8,y+6,8,dark)


def _back(im, c, x, y):
    dark, light = map(rgb, c['hair_col'])
    if c['hair'] == 'curls':
        _stamp_hair(im,c,x,y,CROWNS['curls'])
        ellipse(im,x+2,y+3,8,8,dark)
        im.rect(x+2,y+4,2,2,light)
        im.rect(x+1,y+7,2,2,light)
    else:
        ellipse(im,x+1,y+1,10,10,dark)
        _stamp_hair(im,c,x,y,CROWNS[c['hair']])
        im.rect(x+2,y+4,2,3,light)
        if c['hair'] != 'long':
            im.hline(x+4,y+10,4,dark)


def head(im, c, direction, x, y):
    if direction == 'up':
        _back(im,c,x,y)
        return
    sd, sm, sl = skin(c['skin'])
    dark = rgb(c['hair_col'][0])
    side = direction in ('left','right')
    # Work in left-facing coordinates, then mirror geometry only. The lighting
    # is painted in world coordinates afterwards, so right views are not relit.
    def px(u):
        return x + (11-u if direction == 'right' else u)
    if side:
        shape = [(3,2),(8,2),(10,4),(10,8),(8,10),(4,10),(2,8),(2,6),(1,6),(2,5)]
        polygon(im,[(px(u),y+v) for u,v in shape],sm)
        im.vline(x+3,y+4,4,sl)
        im.vline(x+8,y+5,4,sd)
        _side_hair(im,c,direction,x,y)
        im.set(px(2),y+5,rgb('paper1'))
        im.set(px(3),y+5,rgb('ink0'))
        im.set(px(2),y+7,sd)
        im.hline(min(px(2),px(3)),y+8,2,sd)
        im.set(px(7),y+6,sl)
        if c.get('beard'):
            polygon(im,[(px(u),y+v) for u,v in [(2,7),(4,8),(8,7),(8,9),(6,11),(3,10)]],dark)
            im.hline(min(px(2),px(4)),y+8,3,sd)
        if c['accessory'] == 'glasses':
            im.frame(min(px(1),px(4)),y+5,4,3,rgb('ink1'))
            im.hline(min(px(5),px(7)),y+5,3,rgb('ink1'))
        return
    shape = c.get('face_shape','round')
    jaw = {'round': [(10,8),(8,10),(4,10),(2,8)],
           'square': [(10,9),(9,10),(3,10),(2,9)],
           'narrow': [(9,8),(7,11),(5,11),(3,8)]}[shape]
    polygon(im,[(x+u,y+v) for u,v in [(3,2),(9,2),(10,4)]+jaw+[(2,4)]],sm)
    im.rect(x+3,y+3,3,4,sl)
    im.vline(x+9,y+4,4,sd)
    im.hline(x+5,y+10,3,sd)
    im.set(x+1,y+6,sm); im.set(x+10,y+6,sd)
    _stamp_hair(im,c,x,y,CROWNS[c['hair']])
    # Tiny faces need spacing and eyebrows more than additional surface noise.
    for ex in (3,7):
        im.set(x+ex,y+6,rgb('paper1'))
        im.set(x+ex+1,y+6,rgb('ink0'))
        if c['brow'] == 'angled':
            im.set(x+ex,y+4,dark)
            im.set(x+ex+(1 if ex==3 else -1),y+5,dark)
        elif c['brow'] == 'raised':
            im.set(x+ex,y+4,dark)
        else:
            im.hline(x+ex,y+4,2,dark)
    im.set(x+6,y+7,sd)
    im.hline(x+5,y+9,2,sd)
    if c.get('mouth') in ('smile','grin'):
        im.set(x+7,y+8,sd)
    if c.get('mouth') == 'grin':
        im.hline(x+5,y+8,3,rgb('ink1'))
        im.set(x+6,y+8,rgb('paper1'))
    if c.get('beard'):
        polygon(im,[(x+2,y+7),(x+4,y+8),(x+8,y+8),(x+10,y+7),
                    (x+10,y+10),(x+8,y+11),(x+4,y+11),(x+2,y+10)],dark)
        im.hline(x+5,y+9,3,sd)
    if c['accessory'] == 'glasses':
        for ex in (1,7):
            im.frame(x+ex,y+5,4,3,rgb('ink1'))
            im.set(x+ex+1,y+6,sl)
            im.set(x+ex+2,y+6,rgb('ink0'))
        im.hline(x+5,y+6,2,rgb('ink1'))


def _side_hair(im,c,direction,x,y):
    dark,light = map(rgb,c['hair_col'])
    right = direction == 'right'
    def px(u):
        return x+(11-u if right else u)
    rows = CROWNS[c['hair']]
    # Front fringes open at the nose; the larger hair mass stays behind the ear.
    side = [''.join(row[u] if u>=3 or v<4 else '.' for u in range(12))
            for v,row in enumerate(rows)]
    if right:
        side = [row[::-1] for row in side]
    _stamp_hair(im,c,x,y,side)
    if c['hair'] in ('long','short'):
        im.rect(min(px(8),px(9)),y+4,2,10 if c['hair']=='long' else 4,dark)
        im.vline(x+2 if right else x+9,y+5,8 if c['hair']=='long' else 2,light)
    elif c['hair']=='bun':
        im.rect(min(px(8),px(9)),y+5,2,4,dark)
    if right:
        # Replace the mirrored crown highlight with a small upper-left cluster.
        for yy,row in enumerate(side):
            for xx,ch in enumerate(row):
                if ch=='H': im.set(x+xx,y+yy,dark)
        im.hline(x+3,y+2,3,light)
        im.set(x+2,y+3,light)
