#!/usr/bin/env python3
"""Build only the opt-in De Ketel assets; production has a separate Blender build."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT/'art/prototype/ketel'
SOURCE = ROOT/'docs/ps1/source'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--group', choices=['room','preview','people'], required=True)
    parser.add_argument('--blender', default=os.environ.get('BLENDER','blender'))
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    scratch = ROOT/'.godot/ps1-render'/args.group
    scratch.mkdir(parents=True, exist_ok=True)
    subprocess.run([args.blender,'--background','--threads','4','--python',str(ROOT/'tools/ps1/render.py'),'--',str(scratch),args.group], check=True)
    if args.group == 'room':
        for path in scratch.glob('*.png'):
            im = Image.open(path).convert('RGBA')
            # A small ordered colour step retains texture without covering faces in noise.
            pix = im.load()
            for y in range(im.height):
                for x in range(im.width):
                    r,g,b,a = pix[x,y]
                    bias = [[0,2],[3,1]][y%2][x%2]-1
                    pix[x,y] = tuple(max(0,min(255,((c+bias)//4)*4)) for c in (r,g,b))+(a,)
            im.save(OUT/path.name)
        shutil.copyfile(scratch/'layout.json',OUT/'layout.json')
        # Source of truth is the scripts; this editable scene is a reproducible convenience.
        shutil.copyfile(scratch/'room.blend', SOURCE/'room.blend')
    else:
        for name in ['wren','kesh','tomas','player']:
            bust = Image.open(scratch/(name+'_bust.png')).convert('RGBA')
            bust.resize((108,108),Image.Resampling.LANCZOS).save(OUT/(name+'_bust.png'))
            shutil.copyfile(scratch/(name+'.blend'),SOURCE/(name+'.blend'))
            frames = 1 if args.group=='preview' else 6
            directions = 1 if args.group=='preview' else 8
            atlas = Image.new('RGBA',(40*frames,64*directions))
            for direction in range(directions):
                for frame in range(frames):
                    cell = Image.open(scratch/f'{name}_{direction}_{frame}.png').convert('RGBA')
                    cell = cell.resize((40,64),Image.Resampling.LANCZOS)
                    atlas.paste(cell,(frame*40,direction*64))
            atlas.save(OUT/(name+('_preview' if args.group=='preview' else '_sheet')+'.png'))


if __name__=='__main__':
    main()
