#!/usr/bin/env python3
"""Exercise each distinct map doorway using its authored coordinates."""
import json
from pathlib import Path
root=Path(__file__).resolve().parent.parent
steps=[{'save':'invited'},{'wait':.8},{'tap':'move_down'},{'tap':'interact'},{'world_wait':True},
       {'experience':'visit','map':'academy_hall','spawn':'from_tram'},{'projected':True}]
for path in sorted((root/'data/maps').glob('*.json')):
    data=json.loads(path.read_text());seen=set()
    for warp in data['warps']:
        key=(warp['map'],warp.get('spawn',''))
        if key in seen:continue
        seen.add(key)
        steps += [{'experience':'visit','map':path.stem,'spawn':next(iter(data['spawns']))},
                  {'walk_to':warp['tile'],'timeout':30},
                  {'experience':'map','map':warp['map']},
                  {'shot':path.stem+'_to_'+warp['map']}]
(root/'tools/autopilot/rendered_doors.json').write_text(json.dumps(steps,indent=2)+'\n')
