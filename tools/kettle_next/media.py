"""Package unaccelerated Godot movies and matching before/after screenshots."""
import argparse,subprocess
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/kettle_next';OUT.mkdir(parents=True,exist_ok=True)
p=argparse.ArgumentParser();p.add_argument('--movie',nargs=2,metavar=('SOURCE','NAME'));p.add_argument('--compare',action='store_true');p.add_argument('--review',action='store_true');a=p.parse_args()
if a.movie:
    source,name=a.movie
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',source,
        '-vf','scale=in_range=pc:out_range=tv,format=yuv420p','-color_range','tv',
        '-c:v','libx264','-crf','18','-preset','fast','-c:a','aac','-b:a','160k',
        '-movflags','+faststart',str(OUT/(name+'.mp4'))],check=True)
if a.compare:
    font=ImageFont.truetype(str(ROOT/'art/fonts/DejaVuSans.ttf'),25)
    for frame in ['cast_0','cast_90','run_3','room']:
        images=[Image.open(OUT/(f'{kind}-room/01_room_start.png' if frame=='room' else f'{kind}-cast/{frame}.png')).convert('RGB') for kind in ['baseline','prototype']]
        sheet=Image.new('RGB',(1536,480),'#e6dfce');d=ImageDraw.Draw(sheet)
        for i,(im,label) in enumerate(zip(images,['CURRENT MAIN','KETTLE PROTOTYPE'])):
            sheet.paste(im.resize((768,432),Image.Resampling.LANCZOS),(i*768,48))
            d.text((24+i*768,10),label,font=font,fill='#244139')
        sheet.save(OUT/(frame+'-comparison.jpg'),quality=94)

if a.review:
    playlist=OUT/'review-clips.txt'
    playlist.write_text("".join("file '"+str(OUT/(name+'.mp4'))+"'\n" for name in ['prototype-cast','prototype-motion','kettle-film']))
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','concat','-safe','0',
        '-i',str(playlist),'-c','copy','-movflags','+faststart',str(OUT/'review-film.mp4')],check=True)
    playlist.unlink()
