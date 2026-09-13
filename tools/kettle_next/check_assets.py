"""Contract for the optional prototype: complete rigs and unchanged face identities."""
import json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/kettle_next'

def glb(path):
    data=path.read_bytes();magic,version,length=struct.unpack_from('<4sII',data)
    assert magic==b'glTF' and version==2 and length==len(data),path
    size,kind=struct.unpack_from('<I4s',data,12);assert kind==b'JSON'
    return json.loads(data[20:20+size])

checks=0
for who in ['player','wren','kesh','tomas']:
    data=glb(OUT/(who+'.glb'));names={n.get('name','') for n in data['nodes']}
    for side in ['L','R']:
        for name in ['clavicle_','hand_','thumb_','thumbtip_','foot_','toe_']+['finger%d_'%j for j in range(4)]+['tip%d_'%j for j in range(4)]:
            assert name+side in names,(who,name+side);checks+=1
    clips={a['name'] for a in data['animations']}
    for clip in ['stand','walk','run','listen','counter','seated','thinking','place','greet','pleased','concern']:
        assert clip in clips,(who,clip);checks+=1
    assert (OUT/(who+'_face.png')).is_file();checks+=1
for name in ['room','cloth','table']:
    assert glb(OUT/(name+'.glb'))['meshes'];checks+=1
report=json.loads((OUT/'pose-report.json').read_text())
assert {r['identity'] for r in report}=={'player','wren','kesh','tomas'};checks+=1
print('Kettle prototype assets:',checks,'checks passed')
