"""Composition pass for existing maps. Entrances and services remain reachable."""

def dress(name, data):
    ground=[list(row) for row in data['ground']]
    solid=[list(row) for row in data['solid']]
    props=data.setdefault('art_props',[])
    def art(asset,x,y):props.append({'art':asset,'position':[x,y]})
    def cell(x,y,tile,block=None):
        ground[y][x]=tile
        if block is not None:solid[y][x]='1' if block else '0'
    def furniture(asset,x,y,width,base_y):
        art(asset,x*16,y*16)
        for dx in range(width):cell(x+dx,base_y,'O',True)
    if name=='attic':
        art('attic_roof',0,0);art('study_desk',144,40);art('bed',16,64)
    elif name=='wassalon':
        art('laundry_basket',96,120)
    elif name=='ketelsteeg':
        art('kettle_sign',176,72)
        art('washer_bank',320,80)
        art('tram_marker',0,112)
    elif name=='de_ketel':
        for y in range(6,10):
            for x in range(7,13):cell(x,y,'1',False)
        for tx,ty in [(4,5),(4,10),(15,5),(15,10)]:
            for y in [ty-1,ty,ty+1]:cell(tx,y,'1',False)
        furniture('bar_counter',1,4,4,5)
        furniture('playing_table',7,4,3,5)
        furniture('playing_table',14,4,3,5)
        furniture('playing_table',3,9,3,10)
        art('coat_rack',48,112);art('book_shelf',272,8)
        art('tall_window',208,0)
        for y in [9,10]:cell(7,y,'i',True)
        for npc in data['npcs']:
            if npc['id']=='wren':npc.update(tile=[8,6],dir='up',idle='arrange')
            if npc['id']=='kesh':npc.update(tile=[15,6],dir='up',idle='play')
            if npc['id']=='tomas':npc.update(tile=[2,6],dir='up',idle='wipe')
        for sign in data['signs']:
            if sign['tile']==[15,5]:sign.update(tile=[8,5],text="Wren's teaching board. Spare stones are in the drawer.")
    elif name=='onderbrug':
        for y in range(4,10):
            for x in range(1,23):
                if ground[y][x] in '%7GE':cell(x,y,'a',False)
        for x in [3,4,10,11,17,18]:cell(x,2,'m',True);cell(x,3,'7',False)
        art('port_arch',32,0);art('port_arch',240,0)
        art('dry_corner',272,80);art('port_cargo',144,112)
        data['npcs'][0]['tile']=[19,8]
        data['spawns']['arch']=[18,8]
        for sign in data['signs']:
            if sign['tile']==[5,6]:sign.update(tile=[19,7],text='A board on a dry crate. Felt underneath stops it rocking.')
    elif name=='quay':
        art('long_bench',176,56);art('review_board',256,24)
    elif name=='academy_hall':
        # The wide cross-corridor is the strongest shape in the school.
        for y in range(3,7):
            for x in range(8,14):cell(x,y,',',False)
        for x in [6,15]:
            for y in [3,4,5,9,10]:cell(x,y,'+',True)
        art('school_glass',32,0);art('school_glass',208,0)
        art('reception',16,24);art('long_bench',256,144)
        art('school_directions',128,8)
        for sign in data['signs']:
            if sign['tile']==[1,4]:sign.update(tile=[4,3],text='ESSENVELD INSTITUUT. Study hall west. Classroom east. Dormitory upstairs.')
    elif name=='academy_study':
        # Ilse's references, Sunny's small seat, Orla's clear playing area.
        art('book_shelf',16,8);art('study_desk',64,64)
        art('playing_table',256,64);art('snack_stool',288,144)
        art('playing_table',160,144)
        for npc in data['npcs']:
            npc['idle']={'ilse':'read','sunny':'arrange','orla':'play'}[npc['id']]
            if npc['id']=='ilse':npc['tile']=[6,7]
    elif name=='academy_class':
        art('demonstration',112,0);art('book_shelf',16,16)
        for x,y in [(32,80),(176,80),(32,128),(176,128)]:art('student_desk',x,y)
        for npc in data['npcs']:
            npc['idle']='arrange' if npc['id']=='hana' else 'wipe'
            if npc['id']=='nadia':npc['tile']=[5,5]
    elif name=='academy_dorm':
        art('bed',16,64);art('coat_rack',16,16)
        art('study_desk',128,72);art('laundry_basket',72,96)
    elif name=='bondszaal':
        for x in [32,96,192]:art('tall_window',x,0)
        for y in [80,160,240]:art('tall_window',0,y)
        for row,y in enumerate([80,144,208,272]):
            for col,x in enumerate([48,112,176]):
                art('playing_table',x,y)
                art('board_number_%d'%(row*3+col+1),x+17,y-6)
        art('reception',16,304);art('coat_rack',208,304)
        art('tea_station',208,336);art('long_bench',192,64)
        data['npcs'][0]['tile']=[2,22]
    data['ground']=[''.join(row) for row in ground]
    data['solid']=[''.join(row) for row in solid]
    return data

SIGN_TEXTS={
'attic':{(9,4):'__DESK__A board and a bowl of stones. The drawer underneath holds blank paper and a pencil.',
(2,5):'__BED__Your bed, tucked under the low roof.',(5,2):'Rain taps the skylight. Beyond the tram wires, a crane turns over the quay.'},
'ketelsteeg':{(3,9):'CUP ENTRIES: Bondszaal. Take Tram 4 south. Register at the entrance desk.',
(4,8):'The stationer is closed. Your stairs are through the door beside the shutters.',
(15,8):'DE KETEL. Go, tea and a place out of the rain. Beginners welcome. Ask for Wren.',
(21,8):'WASSALON. Washing, drying and a folding counter. Please leave a machine free for work clothes.',
(25,8):'The snack window. A tray of chips waits beside a stack of paper bags.',
(29,8):'UNDERBRIDGE. Keep the loading lane clear. Someone has drawn a Go board below the notice.'},
'de_ketel':{(9,2):'Coats on brass hooks. A spare umbrella has a note: BORROW IT. BRING IT BACK.',
(18,4):'A coal stove. A pair of wet gloves dries on the guard.',
(1,5):'Please bring empty cups back to the counter. Tomás has left a cloth beside the kettle.',
(1,4):'DE KETEL. Ask Wren to learn the rules or play a practice game. Kesh plays rated games by the window.',
(15,5):"Wren's teaching board. Spare stones are kept in the drawer."},
'onderbrug':{(5,6):'A board on an upturned crate. A strip of felt stops it rocking.',
(11,8):'A tin of spare stones and a cloth, kept clear of the damp wall.',
(2,4):'A lamp wired under the arch. Joos has fixed a sheet above the board to catch the drips.'},
'quay':{(12,4):'A bench facing the water. The middle slats are dry.',(5,6):'Rope has worn a groove in the mooring post.'},
'academy_hall':{(1,4):'ESSENVELD INSTITUUT. Registration here. Study hall west. Classroom east. Dormitory upstairs.'},
'academy_study':{(1,6):'Tea and biscuits. Please wash your cup and leave some biscuits for the next person.',
(10,2):'LOWER LEAGUE. Ask a student for a league game. Results and standings are on the board in the hall.',
(5,5):"Ilse's notes. Several pages are tucked into the back of her book.",
(11,5):'A clear table and two spare bowls. Please put the stones away when you finish.'},
'academy_dorm':{(9,6):'__DESK__A study board beside a stack of exercise paper.',(2,6):'__BED__A made bed. Your bag fits underneath.'},
'bondszaal':{(1,20):'VERHAVEN GO FEDERATION. Register with Marguerite beside the entrance. Draws and results are at the far end.',
(16,3):'Bound tournament records. The oldest pages are patched along the binding.'}}

def rewrite_signs(name,data):
    for sign in data['signs']:
        text=SIGN_TEXTS.get(name,{}).get(tuple(sign['tile']))
        if text:sign['text']=text

# Pixel bounds become physical furniture footprints. Art overhangs toward the
# back wall; collision stays at the base, where a standing person's feet reach it.
FOOTPRINTS={
'washer_bank':(128,40,0,24,128,16),'folding_counter':(64,32,0,16,64,16),
'bar_counter':(64,32,0,16,64,16),'playing_table':(48,32,0,16,48,16),
'long_bench':(48,24,0,8,48,16),'study_desk':(48,40,0,16,48,24),
'bed':(32,48,0,0,32,48),'reception':(64,40,0,16,64,24),
'student_desk':(48,24,0,0,48,16),'tea_station':(48,32,0,16,48,16),
'laundry_basket':(24,24,0,8,24,16),'dry_corner':(80,48,8,32,48,16),
'port_cargo':(64,32,0,16,64,16),'review_board':(48,40,0,24,48,16)}

def finish(name,data):
    ground=[list(r) for r in data['ground']];solid=[list(r) for r in data['solid']]
    floor=',' if name.startswith('academy') or name=='wassalon' else '1'
    if data.get('indoors'):
        for y,row in enumerate(ground):
            for x,ch in enumerate(row):
                if x in [0,len(row)-1] and ch in ['i','I'] and y>2:ground[y][x]='}'
                if ch=='N':ground[y][x]='I'
        # Retire miniature furniture only where its larger replacement defines
        # the same activity. Keep every readable sign solid and reachable.
        signs={tuple(s['tile']) for s in data['signs']}
        for y,row in enumerate(ground):
            if y<3:continue
            for x,ch in enumerate(row):
                if ch in 'GEXVZ' and (x,y) not in signs:
                    ground[y][x]=floor;solid[y][x]='0'
    for prop in data.get('art_props',[]):
        spec=FOOTPRINTS.get(prop['art'])
        if not spec:continue
        w,h,bx,by,bw,bh=spec;x,y=prop['position']
        # Clear the old tiny drawing from beneath the new asset.
        for ty in range(max(3,y//16),min(len(ground),(y+h+15)//16)):
            for tx in range(max(1,x//16),min(len(ground[ty])-1,(x+w+15)//16)):
                if ground[ty][tx] in 'GEXOVZbk':ground[ty][tx]=floor;solid[ty][tx]='0'
        for ty in range((y+by)//16,(y+by+bh-1)//16+1):
            for tx in range((x+bx)//16,(x+bx+bw-1)//16+1):
                if 0<=ty<len(solid) and 0<=tx<len(solid[ty]):solid[ty][tx]='1'
    for sign in data['signs']:
        x,y=sign['tile'];solid[y][x]='1'
    data['ground']=[''.join(r) for r in ground];data['solid']=[''.join(r) for r in solid]
