"""Render only activities actually used by each character's map and story states."""
import sys,math,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import reset,camera,light,render
from people import person,CHARACTERS
args=sys.argv[sys.argv.index('--')+1:];out=Path(args[0]);out.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[2]
activities={}
for path in (root/'data/maps').glob('*.json'):
    data=json.loads(path.read_text());npcs=list(data.get('npcs',[]))
    for state in data.get('presence_states',[]):npcs+=state.get('npcs',[])
    for npc in npcs:
        active=activities.setdefault(npc['id'],set())
        for value in [npc.get('idle','')]+[v.get('idle','') for v in npc.get('activity_variations',[])]:
            if value in ['play','read','fold','wipe','arrange']:active.add(value)
(out/'activities.json').write_text(json.dumps({k:sorted(v) for k,v in activities.items()},indent=2))
for spec in CHARACTERS:
    for activity in sorted(activities.get(spec['id'],[])):
        for direction in range(8):
            for pose in range(2):
                reset(80,128);person(dict(spec,activity=activity),4+pose)
                angle=direction*math.tau/8
                camera((-5*math.sin(angle),-5*math.cos(angle),3.787),(0,0,.9),2.32)
                light('sprite key',(-3,-4,6),(1,.79,.57),270,5)
                light('sprite fill',(3,1,4),(.55,.71,1),110,4)
                render(out/f'{spec["id"]}_{activity}_{direction}_{pose}.png')
