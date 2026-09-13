"""Rebuild review sheets and normal-speed chapters from the final captured evidence."""
import subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/campaign_next'
CACHE=Path.home()/'.cache/ninepoint-campaign-next'
font=ImageFont.truetype(str(ROOT/'art/fonts/DejaVuSans.ttf'),22)
def media(*args):
    subprocess.run([sys.executable,'tools/campaign_next/media.py',*args],cwd=ROOT,check=True)

for source,name,trim in [('environments','environments',0),('cast','cast',.1),('movement','movement',.1),('kettle_next','wren-match',0)]:
    raw=CACHE/(source+'.avi');movie=OUT/(name+'.mp4')
    if not movie.exists() or movie.stat().st_mtime<raw.stat().st_mtime:
        media('--movie',str(raw),name,'--trim-end',str(trim))
media('--compare')
for name in ['03_nigiri_call']:
    sheet=Image.new('RGB',(1536,478),'#eee5d2');draw=ImageDraw.Draw(sheet)
    for col,(folder,label) in enumerate([('baseline-board','CURRENT MAIN'),('table_nigiri','CAMPAIGN PREVIEW')]):
        source=OUT/folder/(name+'.png')
        draw.text((col*768+16,10),label,font=font,fill='#30483b')
        sheet.paste(Image.open(source).convert('RGB').resize((768,432),Image.Resampling.LANCZOS),(col*768,46))
    sheet.save(OUT/'comparisons'/('board_'+name[3:]+'.jpg'),quality=92)
for pattern,name in [('cast/body_*.png','body-sheet'),('cast/pose_*_run.png','running-sheet'),('portraits/*.png','portrait-sheet'),('match-cast/*.png','match-sheet'),('campaign/*.png','environment-sheet'),('table_adoption/*.png','boards-sheet'),('capture_practice/*.png','capture-sheet')]:
    media('--sheet',pattern,name)
for page in range(7):
    media('--sheet',f'cast/pose_{page:02d}_*.png',f'pose-{page}-sheet')
    sheet=Image.new('RGB',(1536,1404),'#eee5d2')
    draw=ImageDraw.Draw(sheet)
    for row,angle in enumerate([0,90,180]):
        for col,(folder,label) in enumerate([('baseline-cast','CURRENT MAIN'),('cast','CAMPAIGN PREVIEW')]):
            source=OUT/folder/f'body_{page:02d}_{angle:03d}.png'
            draw.text((col*768+16,row*468+6),label,font=font,fill='#30483b')
            sheet.paste(Image.open(source).convert('RGB').resize((768,432),Image.Resampling.LANCZOS),(col*768,row*468+36))
    sheet.save(OUT/f'cast-comparison-{page}-sheet.jpg',quality=92)

chapters=[('environments','Sela: twelve environments'),('cast','The complete cast'),('movement','Locomotion'),('wren-match','Wren: game, reaction and review')]
metadata=[';FFMETADATA1'];start=0
for name,title in chapters:
    duration=float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','default=nw=1:nk=1',str(OUT/(name+'.mp4'))],text=True))
    end=start+round(duration*1000)
    metadata.extend(['[CHAPTER]','TIMEBASE=1/1000',f'START={start}',f'END={end}',f'title={title}'])
    start=end
(CACHE/'chapters.txt').write_text('\n'.join(metadata)+'\n')
(CACHE/'concat.txt').write_text(''.join("file '"+str(OUT/(name+'.mp4'))+"'\n" for name,_ in chapters))
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','concat','-safe','0','-i',str(CACHE/'concat.txt'),'-i',str(CACHE/'chapters.txt'),'-map_metadata','1','-map_chapters','1','-vf','scale=1280:720','-c:v','libx264','-threads','4','-crf','23','-preset','fast','-c:a','copy','-movflags','+faststart',str(OUT/'campaign-film.mp4')],check=True)
subprocess.run([sys.executable,'tools/campaign_next/review_page.py'],cwd=ROOT,check=True)
