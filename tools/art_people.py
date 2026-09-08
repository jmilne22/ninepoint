"""Walking and work poses drawn at their own proportions, never resampled."""
from png import Img
from palette import rgb, skin
from pixel_art import polygon, ellipse, panel

W,H=16,24
DIRS=['down','left','right','up']
ACTIONS=['play','read','fold','wipe','arrange']


def _hair(im,c,direction,hy,hx,hw):
    dark,light=map(rgb,c['hair_col']);style=c['hair']
    im.rect(hx,hy,hw,3,dark);im.hline(hx+1,hy,hw-2,light)
    if direction=='up':
        im.rect(hx,hy+2,hw,6,dark);im.rect(hx+1,hy+2,2,3,light)
    if style=='curls':
        for x,y in [(hx-1,hy+1),(hx+2,hy-1),(hx+5,hy-1),(hx+hw-1,hy+1)]:
            ellipse(im,x,y,4,4,dark);im.set(x+1,y,light)
    elif style in ('bob','long'):
        length=8 if style=='bob' else 13
        im.rect(hx-1,hy+2,2,length-2,dark);im.rect(hx+hw-1,hy+2,2,length-2,dark)
        im.vline(hx-1,hy+3,length-4,light)
        if direction=='up':
            im.rect(hx,hy+3,hw,length-3,dark);im.vline(hx+1,hy+2,length-4,light)
            im.hline(hx+1,hy+length-1,hw-2,light)
    elif style=='bun':
        ellipse(im,hx+2,hy-3,5,4,dark);im.hline(hx+3,hy-2,2,light)
    elif style=='tiedback':
        if direction=='up':
            im.rect(hx+3,hy+5,3,8,dark);im.vline(hx+3,hy+6,6,light)
        elif direction in ('left','right'):
            x=hx+hw-1 if direction=='left' else hx-2
            im.rect(x,hy+3,3,8,dark);im.vline(x,hy+4,5,light)
        else:
            im.vline(hx,hy+2,5,dark);im.vline(hx+hw-1,hy+2,5,dark)
    elif style=='cap':
        colour=rgb(c.get('accent','#7a6a58'))
        im.rect(hx-1,hy-1,hw+2,3,colour)
        im.hline(hx,hy-1,hw-1,rgb('path2'))
        x=hx-2 if direction=='left' else hx+2 if direction=='right' else hx-1
        im.hline(x,hy+2,hw+1,rgb('path0'))
    elif style=='short':
        im.vline(hx,hy+2,3,dark);im.vline(hx+hw-1,hy+2,3,dark)


def sprite_frame(c,direction,frame):
    im=Img(W,H)
    sd,sm,sl=skin(c['skin']);dark,light=map(rgb,c['top'])
    ink=rgb('ink0');bottom=rgb(c['bottom']);accent=rgb(c.get('accent',c['top'][1]))
    # Short characters retain a readable head; leg/torso lengths absorb height.
    height=c.get('height',22);head_y=max(1,25-height)
    bob=1 if frame==2 else 0
    hy=head_y+bob
    torso_y=min(17,head_y+9)+bob
    side=direction in ('left','right');broad=c['build']=='broad'
    left=4 if side else 3 if broad else 4
    width=7 if side else 10 if broad else 8
    ellipse(im,3,22,10,2,'ink1')
    # Shoe contacts are fixed at the cell's floor. A lifted foot loses contact.
    stride=0 if frame==0 else (-1 if frame==1 else 1)
    if side:
        for x,dy in [(5-stride,0),(8+stride,-1 if frame else 0)]:
            im.rect(x,19,3,4+dy,bottom);im.hline(x-1 if direction=='left' else x,22+dy,4,ink)
    else:
        for x,dy in [(5,-1 if frame==1 else 0),(9,-1 if frame==2 else 0)]:
            im.rect(x,19,3,4+dy,bottom);im.hline(x,22+dy,3,ink)
    polygon(im,[(left+2,torso_y),(left+width-2,torso_y),(left+width,torso_y+2),
                (left+width,20),(left,20),(left,torso_y+2)],dark)
    im.hline(left+2,torso_y,width-4,light);im.rect(left+1,torso_y+2,2,max(1,18-torso_y),light)
    im.hline(left+1,20,width-2,ink)
    acc=c.get('accessory','none')
    if direction!='up':
        if acc=='scarf':
            im.hline(left,torso_y+1,width,accent);im.rect(left+2,torso_y+2,2,3,accent)
        elif acc=='apron':
            im.rect(left+2,torso_y+2,width-4,max(1,20-torso_y-2),accent)
            im.hline(left+3,18,max(1,width-6),sd)
        elif acc in ('blazer','cardigan'):
            im.vline(left+width//2,torso_y+1,max(1,19-torso_y),accent)
            if acc=='blazer':
                im.set(left+2,torso_y+2,accent);im.set(left+width-3,torso_y+2,accent)
    elif acc=='apron':im.hline(left,18,width,accent)
    # The near sleeve swings over the body in side view, exposing its silhouette.
    arms=[(left-1,-stride),(left+width,stride)] if not side else [(7,stride)]
    for x,swing in arms:
        y=torso_y+2
        im.rect(x+swing,y,2,max(2,19-y),dark)
        im.set(x+swing,y,light);im.rect(x+swing,19,2,1,sm)
    hx=4 if direction!='right' else 5;hw=7 if side or c.get('face_shape')=='narrow' else 8
    im.rect(6,torso_y-1,4,2,sd)
    polygon(im,[(hx+1,hy),(hx+hw-1,hy),(hx+hw,hy+2),(hx+hw,hy+7),
                (hx+hw-2,hy+9),(hx+1,hy+8),(hx,hy+2)],ink)
    im.rect(hx+1,hy+2,hw-2,6,sm);im.rect(hx+1,hy+2,2,4,sl)
    im.vline(hx+hw-2,hy+3,5,sd)
    _hair(im,c,direction,hy,hx,hw)
    if direction!='up':
        ey=hy+5
        if side:
            ex=hx+1 if direction=='left' else hx+hw-2
            im.set(ex,ey,ink);im.set(hx-1 if direction=='left' else hx+hw,ey+1,sm)
        else:
            im.set(hx+2,ey,ink);im.set(hx+hw-3,ey,ink)
            im.hline(hx+3,ey+2,2,sd)
        if c.get('beard'):im.hline(hx+1,ey+2,hw-2,rgb(c['hair_col'][0]))
        if acc=='glasses':
            im.hline(hx+1,ey-1,hw-2,rgb('ink2'));im.set(hx+1,ey,rgb('ink2'))
    return im


def sprite_sheet(c):
    sheet=Img(48,96)
    for row,d in enumerate(DIRS):
        for frame in range(3):sheet.blit(sprite_frame(c,d,frame),frame*16,row*24)
    return sheet


def action_sheet(c):
    sheet=Img(32,480)
    for row,action in enumerate(ACTIONS):
        for direction,d in enumerate(DIRS):
            for beat in range(2):
                im=sprite_frame(c,d,0);sk=skin(c['skin'])[1]
                x,y,w=2,17,12
                if d=='up':y=min(16,25-c.get('height',22)+10)
                elif d in ('left','right'):x,w=(0 if d=='left' else 9),7
                if action=='read':
                    panel(im,x,y-1,w,5,'paper1','paper0','teal0')
                    im.vline(x+w//2,y,3,rgb('wood1'));im.hline(x+2,y+1,2,rgb('ink3'))
                elif action=='fold':
                    polygon(im,[(x,y),(x+w-2,y-2),(x+w,y+3),(x+1,y+4)],'paper1')
                    im.hline(x+1,y+beat,w-3,rgb('blue1'))
                elif action=='wipe':
                    im.rect(x+beat*2,y, min(6,w-2),3,rgb('paper0'))
                else:
                    # Hands work on the actual furniture, not a second floating table.
                    im.rect(x+2+beat*2,y,2,2,sk)
                    im.set(x+3+beat*2,y-1,rgb('stoneB0'))
                im.rect(x+beat,y+1,2,2,sk);im.rect(x+w-2,y,2,2,sk)
                if action=='play':
                    im.rect(4,21,8,3,(0,0,0,0))
                    im.rect(3,20,4,2,rgb(c['bottom']));im.rect(10,20,3,2,rgb(c['bottom']))
                sheet.blit(im,beat*16,(row*4+direction)*24)
    return sheet
