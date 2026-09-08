"""Approved Sela composition pass; retained IDs keep saves and match venues stable."""
from art_specs import SPECS

NAMES={'attic':'Rooftop Room','ketelsteeg':'Market Lane','de_ketel':'The Kettle',
       'wassalon':'The Laundry','onderbrug':'The Arcade','quay':'Sea Walk',
       'academy_hall':'Sela Go Institute — Garden Court',
       'academy_study':'Sela Go Institute — Study Hall',
       'academy_class':'Sela Go Institute — Classroom',
       'academy_dorm':'Sela Go Institute — Dormitory',
       'academy_novice':'Sela Go Institute — Novice Room','bondszaal':'Assembly Hall'}


def apply(name, data):
    ground=[list(row) for row in data['ground']]
    solid=[list(row) for row in data['solid']]
    props=data['art_props']
    data['name']=NAMES[name]
    data['legend']=dict(data['legend'], **{'@':'coast_sky'})

    def cell(x,y,ch,blocked=None):
        ground[y][x]=ch
        if blocked is not None:solid[y][x]='1' if blocked else '0'

    def add(asset,x,y):
        entry={'art':asset,'position':[x,y]}
        spec=SPECS[asset];spec.decorate(entry);props.append(entry)
        if spec.footprint:
            bx,by,bw,bh=spec.footprint
            for ty in range((y+by)//16,(y+by+bh-1)//16+1):
                for tx in range((x+bx)//16,(x+bx+bw-1)//16+1):
                    solid[ty][tx]='1'

    if name=='ketelsteeg':
        props[:]=[p for p in props if not p['art'].startswith(('facade_detail','shopfront_'))]
        for x in range(34):
            for y in range(8):cell(x,y,'@')
        for asset,x in [('sela_home',16),('sela_bar',160),('sela_laundry',304)]:add(asset,x,0)
        # The old viaduct becomes a pale arcade mouth, with a visible side return.
        add('port_arch',448,48)
        add('sela_kiosk',432,224)
        for tx,ty in ((4,15),(12,15),(25,15)):
            for y in range(ty,ty+2):
                for x in range(tx,tx+2):cell(x,y,'g',False)
            add('sela_tree',tx*16-16,ty*16-24)
        # Paving branches around the trees rather than presenting a strip of lawn.
        for y in (17,18):
            for x in range(3,31):
                if solid[y][x]=='0':cell(x,y,'P')
        for y in range(14,19):
            for x in (9,10):
                if solid[y][x]=='0':cell(x,y,'P')
    elif name=='de_ketel':
        props[:]=[p for p in props if p['art']!='tall_window']
        add('school_glass',112,0);add('school_glass',208,0)
        add('sela_garden',160,144)
        # A breeze through the open shutters replaces a permanently lit coal stove.
        cell(18,4,'Q',True)
    elif name=='academy_hall':
        # Keep registration and every door connected around two planted beds.
        for y in (4,5,9,10):
            for x in (6,15):
                if solid[y][x]=='1':cell(x,y,',',False)
        add('sela_garden',96,64);add('sela_garden',192,128)
        for x in range(8,14):
            for y in range(3,12):
                if solid[y][x]=='0':cell(x,y,'P')
        for sign in data['signs']:
            if sign['text'].startswith('__TRAM__'):
                sign['prompt']='Tram 4 to Market Lane'
    elif name=='onderbrug':
        # Joos keeps his alcove while the public passage continues to the sea.
        for y in (5,6):
            cell(23,y,'>',False)
            data['warps'].append({'tile':[23,y],'map':'quay','spawn':'from_arcade',
                                  'prompt':'Sea Walk'})
        data['spawns']['from_quay']=[22,5]
        for x in range(1,23):
            if solid[5][x]=='0':cell(x,5,'P')
    elif name=='quay':
        for y in (2,3):
            cell(25,y,'>',False)
            data['warps'].append({'tile':[25,y],'map':'onderbrug','spawn':'from_quay',
                                  'prompt':'The Arcade / Market Lane'})
        data['spawns']['from_arcade']=[24,2]
        # Shelter to the side: the arrival steps must never look like a roof walk.
        for prop in props:
            if prop['art']=='long_bench':
                prop['position']=[48,56];SPECS['long_bench'].decorate(prop)
        for x in (11,12,13):cell(x,4,'P',False)
        for x in (3,4,5):cell(x,4,'P',True)
        for sign in data['signs']:
            if sign['tile']==[12,4]:sign['tile']=[4,4]
        data['spawns']['bench']=[4,5]
        add('sela_pergola',24,8)
        # Visible posts have real feet; neither crosses the bench approach.
        for x in (1,8):cell(x,3,'P',True)
        add('sela_garden',320,0)
    elif name in ('academy_study','academy_class','academy_novice','academy_dorm','wassalon'):
        add('school_glass',max(16,(data['size'][0]*16-96)//2),0)
    for sign in data['signs']:
        sign['text']=sign['text'].replace('TO THE QUAY. Steps down to the water. The bench at the bottom is the driest thing in Sela.',
            'SEA WALK. Steps through the garden. Return by the Arcade at the east end.')
    for warp in data['warps']:
        if warp['map']=='ketelsteeg' and 'Sela' in warp.get('prompt',''):
            warp['prompt']='Market Lane'
    data['ground']=[''.join(row) for row in ground]
    data['solid']=[''.join(row) for row in solid]
    return data
