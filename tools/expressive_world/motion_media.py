"""Package actual Godot locomotion footage and both rendered cab inspections."""
from pathlib import Path
import subprocess
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/expressive_world/motion-fix'
source=Path.home()/'.cache/ninepoint-motion-fixed.avi'
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(source),
    '-vf','scale=in_range=pc:out_range=tv,format=yuv420p','-color_range','tv',
    '-c:v','libx264','-crf','18','-preset','fast','-c:a','aac','-b:a','160k',
    '-movflags','+faststart',str(OUT/'movement.mp4')],check=True)
canvas=Image.new('RGB',(1536,864),'#b8d3cf')
for i,name in enumerate(['west_front','east_front','west_rear_quarter','east_rear_quarter']):
    im=Image.open(OUT/'tram'/(name+'.png')).convert('RGB').resize((768,432),Image.Resampling.LANCZOS)
    canvas.paste(im,(i%2*768,i//2*432))
canvas.save(OUT/'both-cabs.jpg',quality=94)
