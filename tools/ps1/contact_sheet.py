"""Export review images from actual captures and the model-rendered cast."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT/'art/prototype/ketel'
DOCS = ROOT/'docs/ps1'


def main():
    for filename, source in [('preview.png','tour/03_wren_bust.png'), ('room_3x.png','tour/01_arrival.png')]:
        image = Image.open(DOCS/source)
        image.resize((1152,648),Image.Resampling.NEAREST).save(DOCS/filename)
    sheet = Image.new('RGB',(640,244),'#14121a')
    draw = ImageDraw.Draw(sheet)
    for i,(name,rank) in enumerate([('player','Ro'),('wren','20k'),('kesh','12k'),('tomas','8k')]):
        bust = Image.open(ART/(name+'_bust.png')).convert('RGBA')
        sheet.paste(bust,(i*160+26,12),bust)
        atlas = Image.open(ART/(name+'_sheet.png')).convert('RGBA')
        for j,direction in enumerate([0,2,4]):
            pose = atlas.crop((0,direction*64,40,(direction+1)*64))
            sheet.paste(pose,(i*160+20+j*40,136),pose)
        draw.text((i*160+20,218),name.upper()+' / '+rank,fill='#d6b777')
    sheet.save(DOCS/'cast.png')


if __name__=='__main__':
    main()
