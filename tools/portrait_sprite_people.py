"""Six-character portrait-led preview. Other cast keep the M47 renderer."""
from png import Img
from palette import rgb, skin
from pixel_art import polygon, ellipse
from portrait_sprite_heads import hair_back, head


# These are sprite art choices, not identity overrides. Portrait inputs stay frozen.
PROFILES = {
    'player': dict(head_y=2, shoulders=8, stance=0),
    'wren': dict(head_y=3, shoulders=8, stance=-1),
    'kesh': dict(head_y=1, shoulders=9, stance=1),
    'tomas': dict(head_y=1, shoulders=11, stance=0),
    'nadia': dict(head_y=2, shoulders=8, stance=0),
    'sunny': dict(head_y=6, shoulders=7, stance=0),
}
DIRS = ['down','left','right','up']
ACTIONS = ['play','read','fold','wipe','arrange']


def _legs(im,c,direction,frame,seated):
    bottom=rgb(c['bottom']); shoe=rgb('ink0')
    if seated:
        polygon(im,[(3,19),(7,19),(7,22),(3,22)],bottom)
        polygon(im,[(9,19),(13,19),(13,22),(9,22)],bottom)
        im.hline(2,22,4,shoe); im.hline(10,22,4,shoe)
        return
    side=direction in ('left','right')
    stride=0 if frame==0 else -1 if frame==1 else 1
    legs=[(5-stride,0),(8+stride,-1 if frame else 0)] if side else [
        (4,-1 if frame==1 else 0),(9,-1 if frame==2 else 0)]
    for x,lift in legs:
        im.rect(x,19,3,3+lift,bottom)
        toe=-1 if direction=='left' else 1 if direction=='right' else 0
        im.hline(x+toe,22+lift,3,shoe)
        im.set(x+toe,21+lift,rgb('ink2'))


def _body(im,c,p,direction,ty,frame,action):
    dark,light=map(rgb,c['top']); sd,sm,sl=skin(c['skin'])
    accent=rgb(c.get('accent',c['top'][1]))
    side=direction in ('left','right')
    width=7 if side else p['shoulders']
    left=(16-width)//2
    # A relaxed hem and shoulder slope avoid a rectangular tunic on every body.
    polygon(im,[(left+2,ty),(left+width-2,ty),(left+width,ty+3),
                (left+width,19),(left+width-2,21),(left+1,20),(left,ty+3)],dark)
    polygon(im,[(left+2,ty+1),(left+width-3,ty+1),(left+width-2,ty+3),
                (left+width-2,19),(left+1,19),(left+1,ty+3)],light)
    im.hline(left+2,20,width-3,dark)
    if direction!='up':
        im.hline(6,ty,4,sd)
        im.hline(6,ty+1,3,accent if c['accessory']=='scarf' else dark)
        if c['accessory']=='scarf':
            im.hline(left,ty+1,width,accent)
            im.rect(left+1,ty+2,2,3,accent)
        elif c['accessory']=='apron':
            im.rect(left+2,ty+2,width-4,7,accent)
            im.hline(left+3,ty+6,width-6,rgb('paper2'))
    elif c['accessory']=='apron':
        im.hline(left,ty+5,width,accent)
    if action:
        _working_arms(im,c,direction,ty,action,frame,left,width)
        return
    swing=0 if frame==0 else -1 if frame==1 else 1
    arms=[(left,-swing),(left+width-1,swing)] if not side else [(8,swing)]
    for x,s in arms:
        wrist=min(19,ty+5)+s
        polygon(im,[(x,ty+2),(x+2,ty+3),(x+2,wrist),(x,wrist+1),(x-1,wrist-1)],dark)
        im.vline(x,ty+3,max(1,wrist-ty-3),light)
        im.rect(x,wrist,2,2,sm)
        im.set(x,wrist,sl)


def _working_arms(im,c,direction,ty,action,beat,left,width):
    dark,light=map(rgb,c['top']); sd,sm,sl=skin(c['skin'])
    side=direction in ('left','right')
    front=direction!='up'
    y=max(16,ty+3) if front else ty+1
    # Bent elbows replace the walking arms. Hands and the object share a pose.
    if side:
        wrist=2+beat if direction=='left' else 12-beat
        polygon(im,[(7,ty+2),(10,ty+3),(10,y+3),(wrist,y+3),
                    (wrist,y+1),(8,y+1)],dark)
        im.hline(min(8,wrist),y+1,abs(8-wrist)+1,light)
        hands=[(wrist,y+1),(wrist,y-1)]
        ox=0 if direction=='left' else 9; ow=7
    else:
        hands=[(5+beat,y+1),(10-beat,y+1)]
        for x,wx in [(left,5+beat),(left+width-1,10-beat)]:
            polygon(im,[(x,ty+2),(x+1,ty+2),(x+2,y+3),
                        (wx,y+3),(wx,y+1),(x,y+1)],dark)
            im.hline(min(x,wx),y+1,abs(x-wx)+1,light)
        ox=3;ow=10
    if action=='read':
        polygon(im,[(ox,y-1),(ox+ow//2,y),(ox+ow,y-1),(ox+ow,y+3),
                    (ox+ow//2,y+4),(ox,y+3)],'teal0')
        im.rect(ox+1,y,ow-2,3,rgb('paper1'))
        im.vline(ox+ow//2,y,3,rgb('wood1'))
    elif action=='fold':
        polygon(im,[(ox,y),(ox+ow-1,y-1),(ox+ow,y+3),(ox+1,y+3)],'paper1')
        im.hline(ox+1,y+1+beat,ow-2,rgb('blue1'))
    elif action=='wipe':
        im.rect(ox+beat,y+1,ow-2,2,rgb('paper0'))
    else:
        hands[0]=(hands[0][0],y-beat)
        im.set(hands[0][0],y-beat-1,rgb('stoneB0'))
    for x,yy in hands:
        im.rect(x,yy,2,2,sm);im.set(x,yy,sl)


def sprite_frame(c,direction,frame,action=''):
    p=PROFILES[c['id']]; im=Img(16,24)
    bob=1 if frame==2 and not action else 0
    hy=p['head_y']+bob
    hx=2
    if direction in ('left','right'):
        hx+=p['stance']*(-1 if direction=='left' else 1)
    ty=hy+10
    ellipse(im,3,22,10,2,'ink1')
    _legs(im,c,direction,frame if not action else 0,action=='play')
    hair_back(im,c,direction,hx,hy)
    # Back hair must cover the shoulders; front hair falls behind the collar.
    if direction=='up':
        _body(im,c,p,direction,ty,frame,action)
        hair_back(im,c,direction,hx,hy)
        head(im,c,direction,hx,hy)
        if action:
            # Rear-facing work happens beyond the shoulders. Long hair hides the
            # central object, but must not erase both moving hands as well.
            left=(16-p['shoulders'])//2
            for x in (max(0,left-2),min(14,left+p['shoulders'])):
                im.rect(x,ty+2,2,3,rgb(c['top'][0]))
                im.rect(x,ty+1-frame,2,2,skin(c['skin'])[1])
                im.set(x,ty+1-frame,skin(c['skin'])[2])
    else:
        _body(im,c,p,direction,ty,frame,action)
        head(im,c,direction,hx,hy)
    return im


def action_sheet(c):
    sheet=Img(32,480)
    for row,action in enumerate(ACTIONS):
        for facing,direction in enumerate(DIRS):
            for beat in range(2):
                sheet.blit(sprite_frame(c,direction,beat,action),beat*16,(row*4+facing)*24)
    return sheet
