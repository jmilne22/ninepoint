"""Explicit tailoring and acting choices; original colours and faces remain authoritative."""
# width, depth, height, garment, gesture amplitude, idle duration multiplier
STYLE={
 'player':(.235,.145,1.,'plain',1.,1.),'wren':(.225,.150,.98,'scarf',1.,1.),
 'kesh':(.235,.140,1.04,'plain',1.,1.),'tomas':(.285,.185,1.02,'apron',1.,1.),
 'pip':(.218,.139,.98,'overshirt',1.18,.89),'bertie':(.277,.181,.98,'jacket',.64,1.25),
 'hana':(.232,.157,1.05,'cardigan',.62,1.18),'marguerite':(.225,.150,1.04,'blazer',.57,1.28),
 'nadia':(.226,.143,1.03,'overshirt',.72,1.12),'joos':(.283,.184,1.04,'coat',.55,1.30),
 'ilse':(.213,.137,1.00,'overshirt',.67,1.15),'sunny':(.225,.155,.98,'child',1.13,.91),
 'orla':(.245,.151,1.06,'blazer',.73,1.07),'abel':(.281,.185,.98,'overshirt',.78,1.21),
 'dov':(.225,.150,1.02,'plain',.92,1.10),'moss':(.250,.171,1.03,'cardigan',.58,1.31),
 'noor':(.220,.145,1.00,'cardigan',.86,1.04),'ivo':(.235,.141,1.07,'jacket',1.06,.96),
 'lea':(.236,.157,1.00,'overshirt',.81,1.13),'emil':(.263,.176,1.03,'jacket',.77,1.19),
 'sora':(.228,.154,.99,'cardigan',.65,1.24),
 'extra_commuter':(.237,.154,1.04,'jacket',.7,1.12),
 'extra_shopper':(.275,.181,1.,'coat',.8,1.17),
 'extra_docker':(.293,.194,1.06,'overshirt',.8,1.22),
 'extra_student':(.221,.141,1.03,'blazer',.9,1.07),
 'extra_kid':(.221,.152,.97,'child',1.15,.94),
}

def tailor(spec,rig,width,depth,style):
    from mesh import material,ribbon,rigid,loft,tube
    trim=material('Cloth tailored trim',spec['top'][1])
    main=material('Cloth tailored panels',spec['top'][0])
    accent=material('Cloth accessory',spec.get('accent',spec['top'][1]))
    garment=style[3]
    if spec['id'] in ['player','wren','kesh','tomas']:return
    if garment in ['overshirt','jacket','blazer','cardigan','coat']:
        if garment in ['blazer','jacket','coat']:
            for s in [-1,1]:
                x=s*width*.39
                obj=ribbon('Constructed lapel',[((x*.70,-depth*.75,1.71),.018,.003),
                    ((x*1.14,-depth*1.035,1.56),.024,.004),((x*.47,-depth*1.035,1.43),.007,.003)],trim)
                rigid(obj,rig,'spine')
        else:
            # Small collar points read as clothing rather than long decorative straps.
            for s in [-1,1]:
                obj=ribbon('Folded collar',[((s*.072,-depth*.74,1.72),.034,.004),
                    ((s*.092,-depth*.96,1.62),.025,.004),((s*.082,-depth*1.06,1.58),.002,.002)],trim)
                rigid(obj,rig,'spine')
        for z in [1.23,1.37,1.51]:
            obj=tube('Covered button',[(0,-depth*1.06,z),(0,-depth*1.06-.012,z)],[.012,.012],accent,12)
            rigid(obj,rig,'spine')
        if garment in ['jacket','overshirt','coat']:
            obj=ribbon('Shaped pocket',[((width*.45,-depth*1.06,1.40),.048,.009),
                ((width*.45,-depth*1.09,1.28),.042,.007)],trim)
            rigid(obj,rig,'spine')
    if garment=='coat':
        obj=loft('Coat skirt',[(.76,width*.99,depth*1.14,0),(.90,width*.98,depth*1.13,0),(1.02,width*.96,depth*1.12,0)],main,32)
        rigid(obj,rig,'spine')
    if spec.get('accessory')=='scarf':
        rigid(loft('Scarf wrap',[(1.73,.117,.093,0),(1.82,.109,.090,0)],accent),rig,'neck')
        rigid(ribbon('Scarf tail',[((-.06,-.117,1.78),.041,.011),((-.07,-depth*1.10,1.48),.043,.012)],accent),rig,'spine')
    for s in [-1,1]:
        rigid(tube('Sleeve seam',[(s*(width+.088),-.072,1.43),(s*(width+.117),-.073,1.20)],[.003,.003],trim,6),rig,'lower_'+('R' if s>0 else 'L'))
