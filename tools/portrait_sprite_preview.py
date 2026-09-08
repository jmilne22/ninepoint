"""Reproducible old/new cast comparison, with native sprites on real floor tiles."""
import argparse
import json
import subprocess
import tempfile
from pathlib import Path
from png import Img
from palette import rgb
from preview import load
from gen_venue_scenes import draw_text
from characters import BY_ID
from portrait_sprite_people import PROFILES, ACTIONS

ROOT=Path(__file__).resolve().parent.parent


def build(output, before_ref):
    atlas=load(ROOT/'art/tiles/town_tileset.png')
    tiles=json.loads((ROOT/'art/tiles/tileset_manifest.json').read_text())['tiles']
    floors=[]
    for name in ('floor_wood_a','floor_concrete'):
        x,y=tiles[name];floors.append(atlas.sub(x*16,y*16,16,16))
    sheet=Img(384,104*len(PROFILES),rgb('paper1'))
    overview=Img(352,312,rgb('paper1'))
    with tempfile.TemporaryDirectory() as temp:
        for i,name in enumerate(PROFILES):
            y=i*104;c=BY_ID[name]
            draw_text(sheet,4,y+2,c['name'],rgb('ink0'))
            portrait=load(ROOT/f'art/portraits/{name}.png').sub(0,0,64,64)
            sheet.blit(portrait,4,y+20)
            old=[];new=[]
            for suffix in ('','_actions'):
                path=f'art/sprites/{name}{suffix}.png'
                tmp=Path(temp)/f'{name}{suffix}.png'
                tmp.write_bytes(subprocess.check_output(['git','show',f'{before_ref}:{path}'],cwd=ROOT))
                old.append(load(tmp));new.append(load(ROOT/path))
            # Compact approval view; sprites explicitly shown at twice their
            # native pixels beside a native portrait. Full sheet keeps 1:1 scale.
            cx=(i%2)*176;cy=(i//2)*104
            draw_text(overview,cx+4,cy+2,c['name'],rgb('ink0'))
            overview.blit(portrait,cx+4,cy+20)
            for label,frames,xx in [('OLD',old,cx+80),('NEW',new,cx+128)]:
                draw_text(overview,xx,cy+20,label,rgb('ink0'))
                overview.blit(frames[0].sub(0,0,16,24).scaled(2),xx,cy+34)
            draw_text(overview,cx+80,cy+89,'SPRITES 2X',rgb('ink2'))
            activity=ACTIONS.index(c['activity'])*4*24
            for frames,yy,label in [(old,y+26,'OLD'),(new,y+62,'NEW')]:
                draw_text(sheet,78,yy+10,label,rgb('ink0'))
                for col in range(8):
                    x=120+32*col
                    for fx in (x,x+16):
                        for fy in (yy+8,yy+24):
                            sheet.blit(floors[0 if col<4 else 1],fx,fy)
                    if col<4:
                        sprite=frames[0].sub(0,col*24,16,24)
                    elif col<6:
                        sprite=frames[0].sub((col-3)*16,0,16,24)
                    else:
                        sprite=frames[1].sub((col-6)*16,activity,16,24)
                    sheet.blit(sprite,x+8,yy)
            for col,label in enumerate(('FR','LT','RT','BK','A','B','W1','W2')):
                draw_text(sheet,124+col*32,y+14,label,rgb('ink0'))
            sheet.hline(0,y+103,384,rgb('ink2'))
    output.mkdir(parents=True,exist_ok=True)
    sheet.save(output/'comparison.png')
    sheet.scaled(3).save(output/'comparison-3x.png')
    overview.scaled(3).save(output/'overview.png')
    portrait_comparison(output,before_ref)
    return output/'comparison-3x.png'


def portrait_comparison(output,before_ref):
    """Four neckline changes and two unchanged references, all at equal scale."""
    sheet=Img(288,276,rgb('paper1'))
    with tempfile.TemporaryDirectory() as temp:
        for i,name in enumerate(('tomas','bertie','abel','emil','wren','player')):
            x=(i%2)*144;y=(i//2)*92
            draw_text(sheet,x+2,y+1,BY_ID[name]['name'],rgb('ink0'))
            path=f'art/portraits/{name}.png';tmp=Path(temp)/name
            tmp.write_bytes(subprocess.check_output(['git','show',f'{before_ref}:{path}'],cwd=ROOT))
            for label,xx,im in [('OLD',x,load(tmp)),('NEW',x+72,load(ROOT/path))]:
                draw_text(sheet,xx+2,y+12,label,rgb('ink0'))
                sheet.blit(im.sub(0,0,64,64),xx,y+24)
    sheet.scaled(3).save(output/'portrait-necklines.png')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'docs/sprite-preview')
    parser.add_argument('--before-ref',default='ee5377535c7c8b94730c39ccb3b26dbb22a0682e')
    args=parser.parse_args();print(build(args.output,args.before_ref))
