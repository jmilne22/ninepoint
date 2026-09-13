"""Review packaging from real game captures. No playback-speed changes."""
import argparse,subprocess
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/campaign_next'
p=argparse.ArgumentParser();p.add_argument('--movie',nargs=2);p.add_argument('--trim-end',type=float,default=0.0);p.add_argument('--compare',action='store_true');p.add_argument('--sheet',nargs=2);a=p.parse_args()
font=ImageFont.truetype(str(ROOT/'art/fonts/DejaVuSans.ttf'),22)
if a.movie:
 source,name=a.movie
 trim=[]
 if a.trim_end:
  length=float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','default=nw=1:nk=1',source],text=True))
  trim=['-t',str(length-a.trim_end)]
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',source,*trim,'-vf','scale=in_range=pc:out_range=tv,format=yuv420p','-color_range','tv','-c:v','libx264','-threads','4','-crf','19','-preset','fast','-c:a','aac','-b:a','128k','-movflags','+faststart',str(OUT/(name+'.mp4'))],check=True)
if a.compare:
 folder=OUT/'comparisons';folder.mkdir(exist_ok=True)
 for before in sorted((OUT/'baseline').glob('*.png')):
  after=OUT/'campaign'/before.name
  if not after.exists():continue
  sheet=Image.new('RGB',(1536,478),'#eee5d2');draw=ImageDraw.Draw(sheet)
  for i,(source,label) in enumerate([(before,'CURRENT MAIN'),(after,'CAMPAIGN PREVIEW')]):
   sheet.paste(Image.open(source).convert('RGB').resize((768,432),Image.Resampling.LANCZOS),(768*i,46))
   draw.text((20+768*i,10),label,font=font,fill='#30483b')
  sheet.save(folder/(before.stem+'.jpg'),quality=92)
if a.sheet:
 pattern,name=a.sheet;files=sorted(OUT.glob(pattern));w=512;h=312
 sheet=Image.new('RGB',(w*3,h*((len(files)+2)//3)),'#eee5d2');d=ImageDraw.Draw(sheet)
 for i,file in enumerate(files):
  x=(i%3)*w;y=(i//3)*h
  d.text((x+8,y+2),file.stem,font=font,fill='#30483b')
  sheet.paste(Image.open(file).convert('RGB').resize((512,288),Image.Resampling.LANCZOS),(x,y+24))
 sheet.save(OUT/(name+'.jpg'),quality=92)
