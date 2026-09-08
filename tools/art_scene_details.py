"""Local wear and lighting belong to places, never to a repeated floor tile."""
import json
from pathlib import Path
from png import Img, Rand
from palette import rgb
from pixel_art import polygon, ellipse, seed
from art_specs import SPECS
from art_materials import WOOD, CONCRETE
from coastal_palette import color as coastal


def tint(a,b,t):
    return tuple(int(a[i]*(1-t)+b[i]*t) for i in range(3))+(255,)


def render(name,data):
    w,h=data['size'];im=Img(w*16,h*16)
    floors={'floor_wood_a':coastal('wood'),'floor_wood_b':coastal('wood'),
            'floor_concrete':coastal('paving'),'asphalt':coastal('road'),
            'pavement':coastal('paving'),'grass_a':coastal('leaf'),
            'grass_b':coastal('leaf'),'grass_c':coastal('leaf'),'arch_shade':coastal('shadow')}
    def surface(x,y):
        tx,ty=x//16,y//16
        if not (0<=tx<w and 0<=ty<h):return None
        if data['solid'][ty][tx]!='0' or data['decor'][ty][tx]!=' ':return None
        return floors.get(data['legend'].get(data['ground'][ty][tx],''))
    if data.get('indoors'):
        club = name in ('de_ketel', 'bondszaal')
        for ty,row in enumerate(data['ground']):
            for tx,ch in enumerate(row):
                if data['legend'].get(ch) != 'wall_int': continue
                for yy in range(16):
                    y=ty*16+yy
                    if 23 <= y < 32:
                        base=rgb('wood1') if club else tint(rgb('paper1'),rgb('ink3'),.16)
                        im.rect(tx*16,y,16,1,base)
                        if y==23:im.hline(tx*16,y,16,rgb('wood2') if club else rgb('paper0'))
                        if tx%2==0 and y>24:im.set(tx*16+1,y,rgb('wood0') if club else rgb('paper2'))
    marks=Img(im.w,im.h)
    # Broad, quiet shadows at wall/floor junctions. Keep door mats untouched.
    if data.get('indoors'):
        for y in range(1,h):
            for x in range(1,w-1):
                if surface(x*16,y*16) and data['solid'][y-1][x]=='1':
                    marks.rect(x*16,y*16,16,3,(55,0,0,255))
                if surface(x*16,y*16) and data['solid'][y][x-1]=='1':
                    marks.rect(x*16,y*16,2,16,(32,0,0,255))
    for entry in data.get('art_props',[]):
        spec=SPECS.get(entry['art']);x,y=entry['position']
        if spec and spec.footprint:
            bx,by,bw,bh=spec.footprint
            # Shadows project a few pixels down-right, never enlarge collision.
            polygon(marks,[(x+bx+3,y+by+bh-3),(x+bx+bw,y+by+bh-3),
                           (x+bx+bw+5,y+by+bh+4),(x+bx+7,y+by+bh+4)],(50,0,0,255))
        if entry['art'] in ('tall_window','school_glass'):
            width=24 if entry['art']=='tall_window' else 64
            polygon(marks,[(x+5,y+48),(x+width,y+48),(x+width+22,y+81),(x+22,y+81)],(24,255,0,255))
    # Scuffs form short arcs beside the actual seats, using their own stable seed.
    for npc in data.get('npcs',[]):
        x,y=npc['tile'];r=Rand(seed(name,npc['id']))
        for _ in range(4):
            marks.hline(x*16+r.rng(-7,13),y*16+r.rng(9,20),r.rng(2,7),(18,0,0,255))
    for warp in data['warps']:
        x,y=warp['tile']
        for dx in [-5,3,12]:marks.hline(x*16+dx,y*16+21,4,(22,0,0,255))
    if not data.get('indoors'):
        # Shade stays on the ground: it never tints portraits or hides a door.
        for yy,row in enumerate(data['ground']):
            for xx,ch in enumerate(row):
                if data['legend'].get(ch)=='tree_tl':
                    ellipse(marks,xx*16-8,yy*16+20,66,34,(36,0,0,255))
        r=Rand(seed(name,'damp'))
        for y,row in enumerate(data['ground']):
            for x,ch in enumerate(row):
                tile=data['legend'].get(ch,'')
                if tile in ('drain','wall_brick_base','quay_edge'):
                    xx,yy=x*16,y*16+16
                    polygon(marks,[(xx-5,yy),(xx+19,yy),(xx+24,yy+4),(xx+7,yy+6),(xx-8,yy+3)],(24,0,0,255))
                if tile.startswith('grass') and (x+y)%7==0:
                    # A connected moss patch at the perimeter, not glitter everywhere.
                    if x<2 or y<2 or x>w-3 or y>h-3:
                        ellipse(marks,x*16,y*16,12,5,(27,0,0,255))
    for y in range(im.h):
        for x in range(im.w):
            p=marks.get(x,y);base=surface(x,y)
            if p[3] and base:
                # Opaque mask: red is strength, green chooses daylight or shadow.
                # Overlapping marks replace deliberately; canvas alpha is not involved.
                target=rgb('paper0') if p[1]>0 else rgb('ink1')
                im.set(x,y,tint(base,target,p[0]/255))
    return im


def build(map_dir,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    count=0
    for path in sorted(Path(map_dir).glob('*.json')):
        render(path.stem,json.loads(path.read_text())).save(out/('floor_details_'+path.stem+'.png'))
        count+=1
    return count
