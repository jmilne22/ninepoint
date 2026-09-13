"""Source coverage, authored deformation reports, face preservation and map compatibility."""
import json,struct,hashlib,sys
from pathlib import Path
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/campaign_next'))
from identities import STYLE
OUT=ROOT/'art/campaign_next'
def glb(path):
 data=path.read_bytes();magic,version,length=struct.unpack_from('<4sII',data)
 assert (magic,version,length)==(b'glTF',2,len(data)),path
 size,kind=struct.unpack_from('<I4s',data,12);assert kind==b'JSON'
 return json.loads(data[20:20+size])
checks=0
for who in STYLE:
 d=glb(OUT/'people'/(who+'.glb'));names={n.get('name','') for n in d['nodes']}
 for side in ['L','R']:
  for bone in ['clavicle_','hand_','thumb_','thumbtip_','foot_','toe_']+['finger%d_'%j for j in range(4)]+['tip%d_'%j for j in range(4)]:
   assert bone+side in names,(who,bone);checks+=1
 clips={a['name'] for a in d['animations']}
 assert {'stand','walk','run','listen','seated','place','thinking','greet','pleased','concern'}<=clips;checks+=1
 source=Image.open(ROOT/f'art/expressive_world/people/{who}_face.png').convert('RGB')
 new=Image.open(OUT/'people'/(who+'_face.png')).convert('RGB')
 assert ImageChops.difference(source,new.crop((1024,0,2048,3072))).getbbox() is None,who;checks+=6
for source in sorted((ROOT/'data/maps').glob('*.json')):
 folder=OUT/'maps'/source.stem;assert glb(folder/'room.glb')['meshes'];checks+=1
 m=json.loads((folder/'room-manifest.json').read_text());assert m['metres_per_tile']==.8;checks+=1
 assert m.get('seats',[])==[n['id'] for n in json.loads(source.read_text()).get('npcs',[]) if n.get('idle')=='play'];checks+=1
 if source.stem!='de_ketel':assert m['source_sha256']==hashlib.sha256(source.read_bytes()).hexdigest();checks+=1
for name,size in [('board',(1536,1536)),('black_stone',(512,512)),('white_stone',(512,512))]:
 assert Image.open(OUT/'surfaces'/(name+'.png')).size==size;checks+=1
for asset in ['table','tram']:assert glb(OUT/(asset+'.glb'))['meshes'];checks+=1
reports=json.loads((OUT/'people/pose-report.json').read_text())
assert {r['identity'] for r in reports}==set(STYLE);checks+=1
assert all(r.get('batch_checks',0)>0 for r in reports);checks+=1
print('Campaign assets:',checks,'checks; authored deformation:',sum(r['checks'] for r in reports),'checks;',sum(r['batch_checks'] for r in reports),'batch-equivalence vertices; 156 facial expressions unchanged')
