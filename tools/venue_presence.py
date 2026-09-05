"""Persistent activities and ordered conversations. No time or social scores."""
from copy import deepcopy

ROUTINES={'wren':'arrange','kesh':'play','tomas':'wipe','pip':'arrange','bertie':'play',
'joos':'arrange','abel':'fold','dov':'arrange','moss':'read','marguerite':'read',
'ilse':'read','sunny':'play','orla':'play','hana':'arrange','nadia':'wipe'}
VARIATIONS={'wren':'wipe','kesh':'arrange','tomas':'arrange','pip':'play','bertie':'read',
'joos':'wipe','abel':'arrange','dov':'fold','moss':'play','marguerite':'arrange',
'ilse':'arrange','sunny':'read','orla':'read','hana':'read','nadia':'arrange'}
EXCHANGES={
'ketelsteeg':[[('pip','Bertie, can I use the spare bowl?'),('bertie','The lid is under the bench.')]],
'de_ketel':[[('wren','Tomás, have you got a dry cloth?'),('tomas','Hanging by the counter.')],
            [('kesh','Is this table ready?'),('wren','Just let me move the cups.')]],
'wassalon':[[('abel','Is this your towel?'),('moss',"The blue one's mine. Thanks.")],
            [('dov','Who has the spare lid?'),('abel','Under the folded shirts.')]],
'academy_study':[[('sunny','Ilse, can I borrow your pencil?'),('ilse','The short one. Keep the eraser with it.')],
                 [('orla','Anyone using this board?'),('sunny',"I'm finished with it!")]],
'academy_class':[[('hana','Are the small boards ready?'),('nadia','All but this one.')]],
}
RETURNS={
'ketelsteeg':('match_pip_capture_done',[[('pip','I found the missing stones!'),('bertie','Put them back in the bowl this time.')]]),
'de_ketel':('kesh_match_done',[[('kesh','Another game, Wren?'),('wren',"Yes. I'll bring my cup over.")]]),
'wassalon':('abel_match_done',[[('abel',"Your shirt's folded, Dov."),('dov',"Thanks. Mine never stay flat.")]]),
'academy_study':('won_a_league_game',[[('ilse','Sunny, your pencil.'),('sunny','Thanks! Did you keep the eraser?')]]),
'academy_class':('lesson_two_eyes_done',[[('nadia','Leave that position up?'),('hana','Yes, someone may want to try it again.')]]),
}

def groups(raw):return [[{'npc':who,'text':text} for who,text in exchange] for exchange in raw]

def states(name,data):
    for npc in data['npcs']:
        who=npc['id'];npc['idle']=ROUTINES[who]
        flag='enrolled' if who=='marguerite' else who+'_match_done'
        npc['activity_variations']=[{'flag':flag,'idle':VARIATIONS[who]}]
    out=[]
    if name in RETURNS:
        flag,lines=RETURNS[name]
        out.append({'id':'return','when':{'all':[flag]},'exchanges':groups(lines)})
    if name in ['de_ketel','ketelsteeg','wassalon']:
        who={'de_ketel':'wren','ketelsteeg':'pip','wassalon':'abel'}[name]
        out.insert(0,{'id':'cup-finished','when':{'all':['cup_finished']},'exchanges':groups([[(who,{'wren':'How did the Cup go? Sit down.','pip':'You played in the Cup! Come over!','abel':'The Cup results are up. Did you see?'}[who])]])})
    out.append({'id':'routine','exchanges':groups(EXCHANGES.get(name,[]))})
    if name=='attic':out.insert(0,{'id':'study','when':{'all':['knows_the_rules']},'tiles':[{'tile':[9,4],'name':'prop_papers'}]})
    if name=='bondszaal':out.insert(0,{'id':'event','when':{'all':['cup_finished']},'tiles':[{'tile':[8,7],'name':'prop_papers'}]})
    return out
