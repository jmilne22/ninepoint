"""Original painted faces, with iris-only gaze variants for live attentive acting."""
import importlib.util,os
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(os.environ.get('KETTLE_NEXT_OUTPUT',ROOT/'art/kettle_next'));OUT.mkdir(parents=True,exist_ok=True)
spec=importlib.util.spec_from_file_location('original_face_painter',ROOT/'tools/table_scene/paint.py')
painter=importlib.util.module_from_spec(spec);spec.loader.exec_module(painter)
for who in ['player','wren','kesh','tomas']:
    atlas=Image.new('RGB',(3072,3072))
    for row,mood in enumerate(painter.MOODS):
        for col,gaze in enumerate([-12,0,12]):
            atlas.paste(painter.face(who,mood,gaze),(col*1024,row*512))
    atlas.save(OUT/(who+'_face.png'))
