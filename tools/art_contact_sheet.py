"""Inspect generated furniture on actual floor tiles, beside the unchanged player scale."""
import argparse
from pathlib import Path
from png import Img
from preview import load
from palette import rgb
from gen_venue_scenes import draw_text
from art_specs import SPECS

ROOT=Path(__file__).resolve().parent.parent


def build(root,out,names,scale=3):
    import json
    atlas=load(root/'art/tiles/town_tileset.png')
    manifest=json.loads((root/'art/tiles/tileset_manifest.json').read_text())
    floors=[]
    for name in ('floor_wood_a','floor_concrete'):
        x,y=manifest['tiles'][name];floors.append(atlas.sub(x*16,y*16,16,16))
    player=load(root/'art/sprites/player.png') if (root/'art/sprites/player.png').exists() else load(ROOT/'art/sprites/player.png')
    player=player.sub(0,0,16,24)
    cells=[]
    for name in names:
        source=load(root/('art/props/'+name+'.png'));spec=SPECS.get(name)
        if spec and spec.holds:source=source.sub(0,0,*spec.size)
        width=max(192,source.w+48);height=max(80,source.h+30)
        cell=Img(width,height,rgb('ink0'))
        for y in range(12,height,16):
            for x in range(0,width,16):cell.blit(floors[0 if x<width//2 else 1],x,y)
        draw_text(cell,3,2,name,rgb('paper0'))
        cell.blit(source,8,20);cell.blit(player,min(width-20,source.w+16),max(20,20+source.h-24))
        cells.append(cell)
    widths=[max((c.w for c in cells[i::2]),default=0) for i in range(2)]
    heights=[max(c.h for c in cells[i:i+2]) for i in range(0,len(cells),2)]
    sheet=Img(sum(widths),sum(heights),rgb('ink0'));y=0
    for row,height in enumerate(heights):
        for col in range(2):
            i=row*2+col
            if i<len(cells):sheet.blit(cells[i],0 if col==0 else widths[0],y)
        y+=height
    out.parent.mkdir(parents=True,exist_ok=True);sheet.scaled(scale).save(out)
    return out


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=ROOT)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--scale',type=int,choices=(1,2,3,4),default=3)
    parser.add_argument('assets',nargs='*',default=['playing_table','school_table','washer_bank','study_desk','bed','port_arch'])
    args=parser.parse_args();print(build(args.root,args.output,args.assets,args.scale))
