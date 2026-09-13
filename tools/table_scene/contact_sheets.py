"""Arrange captured engine frames for inspection; this does not generate game art."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]/'docs/table_scene/adoption'
for page in range(7):
    paths=[ROOT/'gallery'/f'{kind}_{page:02d}.png' for kind in ['cast','gesture']]
    if not all(p.exists() for p in paths):continue
    sheet=Image.new('RGB',(768,864))
    for row,path in enumerate(paths):sheet.paste(Image.open(path),(0,row*432))
    sheet.save(ROOT/'gallery'/f'pair_{page:02d}.jpg',quality=92)
