"""Encode normal-speed Godot cuts; frame ranges refer to MOVIE BEAT capture logs."""
from pathlib import Path
import subprocess,json
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/expressive_world';CACHE=Path.home()/'.cache'
world=CACHE/'ninepoint-world-showcase.avi';opening=CACHE/'ninepoint-world-opening.avi';match=CACHE/'ninepoint-world-rendered_match.avi'
clips=[(world,30,110),(opening,119,190),(world,240,320),(world,346,436),
       (world,500,645),(world,809,890),(world,975,1055),(world,1141,1221),
       (world,1307,1367),(world,1473,1560),(world,1639,1699),(world,1805,1885),
       (world,1971,2031),(world,2137,2197),(world,2308,2473),(world,2583,2700),
       (match,397,760),(match,880,970)]
def encode(source,out,start=None,end=None):
    cmd=['ffmpeg','-hide_banner','-loglevel','error','-y']
    if start is not None:cmd+=['-ss',str(start/30)]
    cmd+=['-i',str(source)]
    if end is not None:cmd+=['-t',str((end-start)/30)]
    cmd+=['-vf','scale=in_range=pc:out_range=tv,format=yuv420p','-color_range','tv',
          '-c:v','libx264','-preset','fast','-crf','20','-c:a','aac','-b:a','160k','-movflags','+faststart',str(out)]
    subprocess.run(cmd,check=True)
temp=CACHE/'ninepoint-world-cuts';temp.mkdir(exist_ok=True)
for i,(source,start,end) in enumerate(clips):encode(source,temp/f'{i:02d}.mp4',start,end)
listing=temp/'concat.txt';listing.write_text('\n'.join("file '%s'"%(temp/f'{i:02d}.mp4') for i in range(len(clips)))+'\n')
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','concat','-safe','0','-i',str(listing),'-c','copy','-movflags','+faststart',str(OUT/'showcase.mp4')],check=True)
encode(world,OUT/'full-tour.mp4')
(OUT/'movie-cuts.json').write_text(json.dumps([{'source':p.name,'start_frame':a,'end_frame':b,'fps':30} for p,a,b in clips],indent=2)+'\n')
selected=[('01_title','menus/01_a_title.png'),('02_study','film/17_academy_study_start.png'),
 ('03_conversation','film/29_wren_talk_start.png'),('04_lesson','mouse_lessons/09_g_ko_explanation.png'),
 ('05_match','rendered_match/05_ready.png'),('06_review','rendered_match/12_review_graph.png')]
shots=OUT/'screenshots';shots.mkdir(exist_ok=True)
canvas=Image.new('RGB',(1536,3*464),'#243e38');d=ImageDraw.Draw(canvas)
for i,(name,path) in enumerate(selected):
    im=Image.open(OUT/path).convert('RGB');im.save(shots/(name+'.png'))
    im=im.resize((768,432),Image.Resampling.LANCZOS)
    x=i%2*768;y=i//2*464;canvas.paste(im,(x,y+28));d.text((x+12,y+9),name.replace('_',' '),fill='#f4eddf')
canvas.save(OUT/'six-screenshots.jpg',quality=92)
print('REVIEW VIDEO SECONDS',sum((b-a)/30 for _,a,b in clips))
