"""Contracts for production live assets, including source-map identity and rig clips."""
import json,struct,hashlib,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from characters import CHARACTERS

def gltf(path):
    raw=path.read_bytes();assert raw[:4]==b'glTF',path
    length=struct.unpack_from('<I',raw,12)[0]
    return json.loads(raw[20:20+length])

checks=0
for spec in CHARACTERS:
    root=ROOT/'art/expressive_world/people';data=gltf(root/(spec['id']+'.glb'))
    assert data.get('skins'),spec['id']
    clips={a['name'] for a in data['animations']}
    assert {'stand','host','relaxed','serve','walk','listen','thinking','greet','seated','counter'}<=clips,(spec['id'],clips)
    assert (root/(spec['id']+'_face.png')).is_file(),spec['id']
    checks+=3
for source in sorted((ROOT/'data/maps').glob('*.json')):
    root=ROOT/'art/expressive_world/maps'/source.stem
    manifest=json.loads((root/'manifest.json').read_text())
    assert manifest['source_sha256']==hashlib.sha256(source.read_bytes()).hexdigest(),source
    assert manifest['size']==json.loads(source.read_text())['size'],source
    data=gltf(root/'room.glb');assert data.get('meshes'),source
    checks+=3
assert gltf(ROOT/'art/expressive_world/tram.glb').get('meshes');checks+=1
assert (ROOT/'art/fonts/LICENSE.txt').is_file();checks+=1
for name in ['board','black_stone','white_stone']:
    assert (ROOT/'art/expressive_world/surfaces'/(name+'.png')).is_file(),name
    checks+=1
print('EXPRESSIVE WORLD ASSETS:',checks,'passed; all maps/cast/tram present')
