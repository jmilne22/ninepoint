"""Verify the first recorded placement against its event and contact frames."""
import json
from pathlib import Path
import subprocess
import numpy as np
from scipy.signal import correlate
from dsp import RATE,read,filter_audio
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/audio_preview'
records=[json.loads(line.split('AUDIO TRACE ',1)[1]) for line in (OUT/'preview.log').read_text().splitlines() if 'AUDIO TRACE ' in line]
event=next(e for e in records if e['sound'].startswith('stone_thwack'))
video=OUT/'preview.mp4';mixed=read(video)
reference=read(ROOT/'audio'/(event['sound']+'.wav'))
reference=np.interp(np.arange(0,len(reference),event['pitch']),np.arange(len(reference)),reference)
reference=filter_audio(reference,600,'highpass')
expected=event['frame']/30;start=round((expected-.2)*RATE)
window=filter_audio(mixed[start:round((expected+.5)*RATE)],600,'highpass')
lag=int(np.argmax(correlate(window,reference,mode='valid',method='fft')))
onset=(start+lag)/RATE
result={'event_frame':event['frame'],'event_seconds':expected,'correlated_audio_onset_seconds':onset,'audio_offset_ms':round((onset-expected)*1000,2),'sample':event['sound'],'pitch':event['pitch']}
(OUT/'recorded-sync.json').write_text(json.dumps(result,indent=2)+'\n')
frames=[event['frame']-3,event['frame']-1,event['frame'],event['frame']+1]
cache=Path('/home/user/.cache/ninepoint-audio-capture')
sheet=Image.new('RGB',(1536,478),'#eee7d8');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype(str(ROOT/'art/fonts/DejaVuSans.ttf'),17)
for i,frame in enumerate(frames):
    path=cache/f'contact-{frame}.png'
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(video),'-vf',f'select=eq(n\\,{frame})','-frames:v','1',str(path)],check=True)
    picture=Image.open(path).convert('RGB')
    # A board crop makes the 180ms drop visible at the four successive times.
    w,h=picture.size;picture=picture.crop((int(w*.30),int(h*.16),int(w*.70),int(h*.76)))
    picture.thumbnail((380,432))
    sheet.paste(picture,(i*384,42))
    draw.text((i*384+8,8),f'Frame {frame} / {frame/30:.3f}s',fill='#263d35',font=font)
sheet.save(OUT/'contact-frames.jpg',quality=94)
print(json.dumps(result,indent=2))
if abs(result['audio_offset_ms'])>67:raise SystemExit('Recorded contact differs by more than two video frames')
