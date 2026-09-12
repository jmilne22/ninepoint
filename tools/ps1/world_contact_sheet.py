"""Contact sheets and integer enlargements of actual in-game captures."""
import argparse,math
from pathlib import Path
from PIL import Image,ImageDraw
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('folder',type=Path)
parser.add_argument('output',type=Path)
parser.add_argument('--scale',type=int,default=1)
args=parser.parse_args()
files=sorted(args.folder.glob('*.png')) if args.folder.is_dir() else [args.folder]
cols=min(3,len(files));rows=math.ceil(len(files)/cols)
canvas=Image.new('RGB',(384*cols,232*rows),(20,20,24));draw=ImageDraw.Draw(canvas)
for i,path in enumerate(files):
    x,y=i%cols*384,i//cols*232
    im=Image.open(path).convert('RGB')
    if im.size!=(384,216):raise ValueError((path,im.size))
    canvas.paste(im,(x,y));draw.text((x+4,y+217),path.stem,fill=(225,217,193))
if len(files)==1:canvas=Image.open(files[0]).convert('RGB')
if args.scale!=1:canvas=canvas.resize((canvas.width*args.scale,canvas.height*args.scale),Image.Resampling.NEAREST)
args.output.parent.mkdir(parents=True,exist_ok=True);canvas.save(args.output)
