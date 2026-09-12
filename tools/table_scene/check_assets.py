"""Check exported face orientation, skin binding and continuous animation clips."""
import json, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]

def read(path):
    raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
    data=json.loads(raw[20:20+length]);return data,raw[28+length:]

def values(data,raw,index):
    a=data['accessors'][index];v=data['bufferViews'][a['bufferView']]
    components={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
    fmt={5126:'f',5123:'H',5121:'B',5125:'I'}[a['componentType']]
    step=struct.calcsize('<'+fmt*components);offset=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from('<'+fmt*components,raw,offset+i*v.get('byteStride',step)) for i in range(a['count'])]

for who in ['player','wren']:
    data,raw=read(ROOT/'art/table_scene'/f'{who}.glb')
    clips={a['name']:a for a in data['animations']}
    assert set(clips)=={'idle','thinking','place','surprise','pleased','concern','greet'}
    for name,a in clips.items():
        samples=[values(data,raw,s['input']) for s in a['samplers']]
        assert max(len(t) for t in samples)>30 and max(t[-1][0] for t in samples)>1.4,(who,name,'not continuous')
    head=next(m for m in data['meshes'] if m['name']=='Painted head')['primitives'][0]['attributes']
    points=values(data,raw,head['POSITION']);normals=values(data,raw,head['NORMAL'])
    forward=[n[2] for p,n in zip(points,normals) if p[2]>.15 and abs(p[0])<.08]
    assert forward and min(forward)>0,(who,'head faces inward')
    assert 'TEXCOORD_0' in head,(who,'missing face UVs')
    hand=next(m for m in data['meshes'] if m['name']=='Hand')['primitives'][0]['attributes']
    points=values(data,raw,hand['POSITION'])
    assert .72<min(p[1] for p in points)<.77,(who,'head resizing changed the hand bind mesh')
    assert max(abs(p[0]) for p in points)<.55,(who,'hand no longer meets wrist')
    print(who+': seven continuous clips, outward face UV mesh, unchanged hand bind position')
print('TABLE SCENE ASSET CONTRACTS: passed')
