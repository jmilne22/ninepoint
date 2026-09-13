"""Encode actual Godot footage and make inspection sheets from the encoded video."""
from pathlib import Path
import argparse, subprocess
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('movie',type=Path);args=p.parse_args()
out=ROOT/'docs/table_scene';out.mkdir(exist_ok=True)
subprocess.run(['ffmpeg','-y','-i',str(args.movie),'-c:v','libx264','-crf','18','-preset','slow',
                '-pix_fmt','yuv420p','-af','volume=0.85','-c:a','aac','-b:a','192k','-movflags','+faststart',
                str(out/'showcase.mp4')],check=True)
shots=sorted((out/'screenshots').glob('0*.png'))
sheet=Image.new('RGB',(1536,3*466),'#20312c');d=ImageDraw.Draw(sheet)
for i,path in enumerate(shots[:6]):
    x=(i%2)*768;y=(i//2)*466
    sheet.paste(Image.open(path).convert('RGB'),(x,y+25));d.text((x+14,y+7),path.stem.replace('_',' '),fill='#efe4cc')
sheet.save(out/'six-screenshots.jpg',quality=94)
# Closely-spaced frames retain the evidence needed to judge the hand arcs and transitions.
frames=out/'motion-frames';frames.mkdir(exist_ok=True)
subprocess.run(['ffmpeg','-y','-i',str(out/'showcase.mp4'),'-vf','fps=4,scale=384:216',str(frames/'%03d.png')],check=True)
paths=sorted(frames.glob('*.png'))
for start in range(0,len(paths),24):
    contact=Image.new('RGB',(4*384,6*236),'#20312c');d=ImageDraw.Draw(contact)
    for i,path in enumerate(paths[start:start+24]):
        x=(i%4)*384;y=(i//4)*236
        contact.paste(Image.open(path),(x,y+20));d.text((x+5,y+4),f'{(start+i)/4:.2f} s',fill='white')
    contact.save(out/f'motion-{start//24+1:02d}.jpg',quality=94)
for path in paths:path.unlink()
frames.rmdir()
subprocess.run(['ffmpeg','-y','-ss','10','-t','6','-i',str(out/'showcase.mp4'),'-vf',
                'fps=15,scale=768:432:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse',
                str(out/'reaction.gif')],check=True)
print('Actual footage, six screenshots and motion inspection sheets:',out)
