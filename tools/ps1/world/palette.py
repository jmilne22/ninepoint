"""Sela's worn coastal materials, with the prototype's restrained texture density."""
from common import material

def make(indoor=False, club=False):
    palette = {k: material(k,c,n) for k,c,n in [
        ('wood',(.22,.12,.066) if club else (.39,.26,.14),18),
        ('floor',(.29,.20,.13) if club else (.52,.42,.29),28),
        ('plaster',(.44,.39,.31) if club else (.69,.64,.49),12),
        ('stone',(.48,.48,.40),32),('paving',(.57,.54,.43),40),
        ('asphalt',(.25,.28,.27),40),('water',(.16,.34,.38),8),
        ('grass',(.28,.36,.19),20),('leaf',(.13,.26,.14),9),
        ('leaf_light',(.29,.40,.18),12),('terra',(.49,.24,.13),20),
        ('metal',(.16,.20,.20),18),('glass',(.27,.45,.50),6),
        ('cream',(.78,.73,.59),40),('amber',(.79,.48,.17),18),
        ('board',(.66,.45,.22),22),('ink',(.045,.055,.054),0),
        ('white',(.86,.84,.74),0),('cloth',(.40,.49,.47),30),
        ('blue',(.17,.32,.42),20),('red',(.48,.20,.13),20)]}

    # Continuous sea detail must use world coordinates across the tile and context meshes.
    mat=palette['water'];nodes=mat.node_tree.nodes;geom=nodes.new('ShaderNodeNewGeometry')
    for node in nodes:
        if node.type=='TEX_NOISE':mat.node_tree.links.new(geom.outputs['Position'],node.inputs['Vector'])
    return palette
