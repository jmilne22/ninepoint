"""De Ketel's fixed-camera set. All exported points use the render's projection."""
import json
import random
from pathlib import Path
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector
from common import box, cylinder, sphere, material, light, camera, render, reset


def build(output):
    random.seed(7)
    scene = reset()
    wood = material('smoked walnut', (.11, .058, .032), 9)
    edge = material('worn walnut edges', (.21, .125, .063), 14)
    plaster = material('stained olive plaster', (.24, .255, .23), 20)
    metal = material('blackened iron', (.055, .061, .064), 16)
    brass = material('aged brass', (.47, .30, .105), 12)
    cloth = material('oxblood upholstery', (.27, .067, .048), 25)
    paper = material('cream paper', (.72, .64, .44), 35)
    glass = material('cold window panes', (.13, .26, .35), 8, .35)
    tea = material('ochre glaze', (.52, .33, .14), 8)
    white = material('white stones', (.86, .82, .70))
    green = material('bottle glass', (.08, .18, .13), 5)
    cam = camera((10, -10, 8.16497), (0, 0, .6), 11.6)
    # Exact 30 degree elevation independent of the room's framing offset.
    cam.location.z += .6
    light('amber pendant', (0, -.3, 4.7), (1, .70, .39), 380, 4)
    light('window light', (-2, 1.6, 3.3), (.48, .69, 1), 170, 2)
    light('soft front fill', (4, -6, 5), (.77, .80, 1), 100, 5)
    for row in range(20):
        y = -2.5 + row * .25
        for col in range(5):
            x = -3.5 + col * 1.4
            mat = material('plank', (.11 + random.random()*.045, .065 + random.random()*.025, .039), 17)
            box('floor plank', (x+.69, y+.12, -.045), (1.37, .237, .09), mat)
    box('left back wall', (-3.56, 0, 1.05), (.12, 5.12, 2.1), plaster)
    box('right back wall', (0, 2.56, 1.05), (7.2, .12, 2.1), plaster)
    for y in [-2.5, 2.5]:
        box('floor trim', (0, y, -.05), (7.18, .11, .20), edge)
    for x in [-3.5, 3.5]:
        box('floor trim', (x, 0, -.05), (.11, 5.1, .20), edge)
    for z in [.10, .72, 2.05]:
        box('wall rail', (-3.47, 0, z), (.09, 5, .08), edge)
        box('wall rail', (0, 2.47, z), (7, .09, .08), edge)
    for i in range(14):
        box('wainscot panel', (-3.47, -2.32+i*.36, .4), (.065, .32, .53), wood)
    for i in range(20):
        box('wainscot panel', (-3.32+i*.35, 2.47, .4), (.31, .065, .53), wood)
    for y in [-1.15, .25]:
        box('window frame', (-3.42, y, 1.4), (.14, 1.18, 1.05), edge)
        box('cold glazing', (-3.33, y, 1.4), (.025, 1.01, .89), glass)
        for dy in [-.52, 0, .52]:
            box('mullion', (-3.30, y+dy, 1.4), (.06, .035, .94), metal)
        box('crossbar', (-3.30, y, 1.4), (.06, 1.06, .035), metal)
        box('window sill', (-3.25, y, .87), (.40, 1.3, .08), edge)
    # Back-wall shelf and still life establish this as a working salon.
    for z in [1.03, 1.57]:
        box('shelf', (.65, 2.26, z), (3.4, .36, .065), edge)
        for i in range(9):
            x = -.82+i*.37
            cylinder('bottle', (x, 2.25, z+.17), .065, .27, green)
            cylinder('bottle neck', (x, 2.25, z+.33), .027, .10, green)
    box('slate frame', (-2.55, 2.41, 1.42), (1.10, .1, .96), edge)
    box('slate', (-2.55, 2.34, 1.42), (.96, .045, .81), metal)
    for x in [-2.84, -2.55, -2.26]:
        for z in [1.18, 1.4, 1.62]:
            sphere('chalk mark', (x, 2.308, z), (.025, .006, .025), paper)
    box('door lintel', (3, 2.38, 1.9), (.75, .15, .1), edge)
    box('door', (3, 2.43, .93), (.72, .10, 1.82), wood)
    cylinder('ceiling rose', (0, .15, 2.85), .14, .07, metal)
    cylinder('lamp cable', (0, .15, 2.49), .016, .70, metal)
    cylinder('lamp shade', (0, .15, 2.15), .35, .16, brass)
    sphere('lamp bulb', (0, .15, 2.03), (.12, .12, .075), material('glow', (1, .64, .24), emission=2))
    groups, collision = [], []

    def project(p):
        q = world_to_camera_view(scene, cam, Vector(p))
        return [round(q.x*384, 2), round((1-q.y)*216, 2)]

    def group(name, x, y, w, d, make):
        before = set(bpy.data.objects)
        make()
        objects = list(set(bpy.data.objects)-before)
        groups.append((name, project((x, y, 0)), objects))
        collision.append([project((x+dx*w/2, y+dy*d/2, 0)) for dx,dy in [(-1,-1),(1,-1),(1,1),(-1,1)]])

    def table(x, y, size=1.0):
        box('table top', (x, y, .70), (size, .84, .09), edge, .025)
        for dx in [-1, 1]:
            for dy in [-1, 1]:
                box('table leg', (x+dx*(size/2-.09), y+dy*.32, .33), (.09,.09,.66), wood)
        box('goban', (x, y, .78), (.59, .59, .07), tea, .012)
        for n in range(9):
            o = (n-4)*.058
            box('board line', (x+o, y, .818), (.007,.47,.002), metal)
            box('board line', (x, y+o, .818), (.47,.007,.002), metal)
        for i in range(10):
            sx, sy = random.randrange(-4,5)*.058, random.randrange(-4,5)*.058
            sphere('stone', (x+sx,y+sy,.832), (.025,.025,.012), metal if i%2 else white)
        for dx, mat in [(-1,metal),(1,white)]:
            sphere('stone bowl', (x+dx*.40,y,.78), (.085,.085,.055), wood)
            sphere('stones in bowl', (x+dx*.40,y,.816), (.07,.07,.02), mat)

    def chair(x, y):
        box('chair cushion', (x,y,.37), (.40,.4,.1), cloth, .025)
        box('chair back', (x,y+.16,.64), (.40,.08,.53), wood, .02)
        for dx in [-.15,.15]:
            for dy in [-.15,.15]:
                box('chair leg',(x+dx,y+dy,.17),(.06,.06,.34),wood)

    group('wren_table', -1.55, -.35, 1.05, .88, lambda: table(-1.55,-.35))
    group('kesh_table', -2.0, 1.22, 1.05, .88, lambda: table(-2.0,1.22))
    group('back_table', 1.7, -1.2, 1.2, .88, lambda: table(1.7,-1.2,1.16))
    for name,x,y in [('wren_chair',-1.55,.30),('guest_chair',-1.55,-1.08),('kesh_chair',-2,1.96),('back_chair',1.7,-.45)]:
        group(name,x,y,.43,.44,lambda x=x,y=y: chair(x,y))
    for i in range(3):
        x = -.1+i*.85
        def bar(x=x):
            box('bar panel',(x,1.30,.47),(.85,.66,.94),wood)
            box('bar inlay',(x,.956,.48),(.68,.025,.66),edge)
            box('bar countertop',(x,1.3,.98),(.89,.83,.11),edge,.02)
            cylinder('cup',(x,1.27,1.09),.065,.13,paper)
            sphere('cup handle',(x+.073,1.27,1.10),(.035,.021,.037),paper)
        group('bar_%d'%i,x,1.30,.86,.72,bar)
    def stove():
        cylinder('coal stove',(2.97,.03,.40),.30,.8,metal)
        cylinder('stovepipe',(2.97,.03,1.43),.09,1.25,metal)
        box('stove glow',(2.97,-.263,.38),(.22,.015,.17),material('embers',(.73,.20,.025),emission=1))
    group('stove',2.97,.03,.65,.65,stove)
    static = [o for o in bpy.data.objects if o.type=='MESH' and all(o not in g[2] for g in groups)]
    output.mkdir(parents=True, exist_ok=True)
    all_meshes = [o for o in bpy.data.objects if o.type=='MESH']
    for _,_,objs in groups:
        for obj in objs: obj.visible_camera = False
    render(output/'background.png')
    for obj in static: obj.visible_camera = False
    layers = []
    for name, foot, objs in groups:
        for obj in objs: obj.visible_camera = True
        render(output/(name+'.png'))
        layers.append(dict(image=name+'.png', foot=foot))
        for obj in objs: obj.visible_camera = False
    for obj in all_meshes: obj.visible_camera = True
    render(output/'composition.png')
    bpy.ops.wm.save_as_mainfile(filepath=str(output/'room.blend'))
    layout = dict(background='background.png', layers=layers,
        bounds=[project((x,y,0)) for x,y in [(-3.35,-2.35),(3.35,-2.35),(3.35,2.30),(-3.35,2.30)]],
        collision=collision, spawn=project((.1,-1.9,0)), camera=[192,108],
        people=[dict(id='wren',foot=project((-2.30,-.05,0)),activity='arrange',seat=project((-1.55,-1.7,0))),
                dict(id='kesh',foot=project((-2,1.94,0)),activity='play',seat=project((-2.72,.70,0))),
                dict(id='tomas',foot=project((.78,2.0,0)),activity='wipe',seat=project((.78,.55,0)))],
        door=project((2.75,1.65,0)), review=project((2.3,-1.95,0)))
    (output/'layout.json').write_text(json.dumps(layout,indent=2)+'\n')
