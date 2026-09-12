"""Physical furniture vocabulary. Inputs are footprint units, not image rectangles."""
import math,random
import bpy
from common import box, cylinder, sphere, limb


def table(x,y,w,d,m,kind='playing_table'):
    z=.76
    box('table top',(x,y,z),(w*.93,d*.91,.12),m['wood'],.035)
    for dx in [-w*.38,w*.38]:
        for dy in [-d*.34,d*.34]: box('table leg',(x+dx,y+dy,.35),(.10,.10,.7),m['wood'],.01)
    if kind in ['study_desk','student_desk']:
        box('open book',(x-.12,y,z+.09),(.4,.3,.035),m['cream'])
        cylinder('pencil pot',(x+w*.32,y+.18,z+.18),.07,.2,m['metal'])
    else:
        bw=min(w*.53,.73); bd=min(d*.71,.72)
        box('goban',(x,y,z+.095),(bw,bd,.065),m['board'],.014)
        for i in range(9):
            box('grid',(x-bw*.4+i*bw*.1,y,z+.131),(.007,bd*.8,.001),m['ink'])
            box('grid',(x,y-bd*.4+i*bd*.1,z+.132),(bw*.8,.007,.001),m['ink'])
        for i in range(7):
            sphere('stone',(x-bw*.3+(i%4)*bw*.1,y-bd*.3+(i//3)*bd*.1,z+.15),(.025,.025,.014),m['white' if i%2 else 'ink'])
        for dx in [-w*.34,w*.34]: sphere('bowl',(x+dx,y,z+.12),(.10,.10,.08),m['wood'])


def plant(x,y,m,tree=False):
    cylinder('terracotta planter',(x,y,.20),.28,.4,m['terra'])
    limb('trunk',(x,y,.3),(x+.03,y,1.65 if tree else .8),.045 if tree else .025,m['wood'])
    rng=random.Random(round(x*77+y*99))
    for i in range(12 if tree else 7):
        a=i*2.4;r=.5 if tree else .22; z=(1.2 if tree else .48)+rng.random()*.5
        sphere('leaves',(x+math.cos(a)*r,y+math.sin(a)*r,z),(.44,.31,.25) if tree else (.21,.15,.19),m['leaf_light' if i%3==0 else 'leaf'])


def bench(x,y,w,d,m):
    for j in range(3):box('bench slat',(x,y-d*.3+j*d*.3,.40),(w,.12,.075),m['wood'],.01)
    for dx in [-w*.4,w*.4]:
        box('bench foot',(x+dx,y,.20),(.10,d,.4),m['metal'])
        box('bench back post',(x+dx,y+d*.38,.62),(.06,.06,.75),m['metal'])
    for z in [.66,.85]:box('back slat',(x,y+d*.38,z),(w,.07,.12),m['wood'])


def cabinet(x,y,w,d,m,kind):
    box(kind,(x,y,.48),(w*.96,d*.93,.96),m['cream' if kind=='washer_bank' else 'wood'],.03)
    if kind=='washer_bank':
        for i in range(max(1,round(w/.7))):
            cx=x-w*.5+(i+.5)*w/max(1,round(w/.7))
            ring=cylinder('washer rim',(cx,y-d*.48,.51),.22,.04,m['metal']);ring.rotation_euler.x=math.pi/2
            disk=cylinder('washer glass',(cx,y-d*.5,.51),.17,.05,m['glass']);disk.rotation_euler.x=math.pi/2
            box('controls',(cx,y-d*.5,.83),(.26,.02,.06),m['ink'])
    else:
        box('counter stone',(x,y,1.0),(w,d,.08),m['stone'],.015)
        for i in range(max(1,round(w/.6))):
            cx=x-w*.45+(i+.5)*w*.9/max(1,round(w/.6))
            box('panel',(cx,y-d*.475,.47),(w*.8/max(1,round(w/.6)),.02,.71),m['wood'],.015)
        if kind in ['bar_counter','tea_station']:
            for dx in [-.25,.2]:cylinder('cup',(x+dx,y,1.12),.07,.16,m['cream'])


def prop(kind,x,y,w,d,m):
    if 'table' in kind or 'desk' in kind or kind.startswith('novice_'):
        table(x,y,w,d,m,kind)
    elif kind=='bed':
        box('bedframe',(x,y,.24),(w*.95,d*.98,.35),m['wood'],.03)
        box('mattress',(x,y,.46),(w*.90,d*.95,.2),m['cream'],.06)
        box('blanket',(x,y-d*.15,.58),(w*.91,d*.57,.05),m['cloth'],.02)
        box('pillow',(x,y+d*.32,.61),(w*.7,d*.17,.10),m['cream'],.05)
        box('headboard',(x,y+d*.47,.63),(w,.08,.65),m['wood'],.02)
    elif 'bench' in kind:bench(x,y,w,d,m)
    elif kind in ['bar_counter','folding_counter','washer_bank','tea_station','reception']:
        cabinet(x,y,w,d,m,kind)
    elif kind in ['sela_tree','sela_garden','plant_int','planter','bush']:
        plant(x,y,m,kind=='sela_tree')
    elif kind in ['review_board','noticeboard','tram_stop','demonstration','school_directions']:
        for dx in [-w*.36,w*.36]:box('notice leg',(x+dx,y,.72),(.06,.08,1.44),m['wood'])
        box('notice frame',(x,y,1.35),(w,.10,.73),m['wood'],.025)
        box('slate',(x,y-.06,1.35),(w-.09,.01,.64),m['ink'])
        for i in range(4):box('chalk',(x-.1,y-.073,1.56-i*.12),(w*.55,.008,.012),m['cream'])
    elif kind in ['laundry_basket','port_cargo','dry_corner']:
        box('crate',(x,y,.25),(w*.85,d*.85,.5),m['wood'],.03)
        for i in range(4):box('crate strip',(x,y-d*.435,.06+i*.12),(w*.9,.035,.025),m['amber'])
        if kind=='laundry_basket':sphere('folded washing',(x,y,.56),(w*.4,d*.4,.14),m['cream'])
    elif kind=='coat_rack':
        for dx in [-w*.35,w*.35]:box('rack post',(x+dx,y,.88),(.06,.06,1.76),m['wood'])
        box('hatrail',(x,y,1.7),(w,.08,.09),m['wood'])
        for i in range(3):box('coat',(x-w*.28+i*w*.28,y-.08,1.22),(.25,.15,.71),m['cloth' if i%2 else 'blue'],.04)
    elif kind=='book_shelf':
        box('shelf back',(x,y,1),(w,.10,1.9),m['wood'])
        for z in [.3,.8,1.3,1.8]:
            box('shelf',(x,y-.15,z),(w,.38,.07),m['wood'])
            for i in range(max(1,int(w/.13))):box('book',(x-w*.46+i*.13,y-.12,z+.20),(.09,.2,.32),m[['red','cream','blue','amber'][i%4]])
    elif kind in ['lamp_post','tram_pole']:
        cylinder('lamp post',(x,y,1),.045,2,m['metal'])
        box('lamp hood',(x,y,2.05),(.30,.28,.10),m['metal'])
        box('lamp glass',(x,y,1.91),(.19,.18,.23),m['amber'])
    elif kind=='sela_kiosk':
        cabinet(x,y,w,d,m,'tea_station')
        for dx in [-w*.46,w*.46]:box('awning pole',(x+dx,y,1.25),(.06,.06,2.5),m['metal'])
        box('kiosk canopy',(x,y,2.15),(w*1.2,d*1.2,.08),m['red'])
    elif kind in ['bollard','post_box','snack_stool']:
        cylinder(kind,(x,y,.3),.14,.6,m['metal'])
    elif kind=='bike_rack':
        for i in range(3):
            limb('cycle rack',(x-.25+i*.25,y-.2,.02),(x-.25+i*.25,y+.2,.48),.025,m['metal'])
    else:
        raise ValueError('Unimplemented physical prop '+kind)
