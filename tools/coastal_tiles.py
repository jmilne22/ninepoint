"""Sela tile materials retain named atlas identities and collision semantics."""
from coastal_palette import color as c
from palette import rgb
from png import Img
from pixel_art import remap


def paving(im, shade=False):
    im.rect(0, 0, 16, 16, c('stone' if shade else 'paving'))
    im.hline(0, 15, 16, c('joint'))
    im.vline(7, 0, 15, c('joint'))
    im.hline(0, 0, 16, c('plaster'))


def paint(name, original):
    im = Img(16, 16)
    base = name.split('_f')[0]
    if base in ('canal', 'canal_b', 'canal_c', 'water', 'water_edge'):
        frame = int(name.rsplit('_f', 1)[1]) if '_f' in name else 0
        im.rect(0, 0, 16, 16, c('sea'))
        offset = (frame * 2 + (3 if base == 'canal_b' else 0)) % 16
        if base!='canal_b':im.hline(offset, 4, 4, c('sea_light'))
        return im
    if base in ('pavement', 'cobble_a', 'cobble_b', 'cobble_wet', 'gravel'):
        paving(im, base == 'cobble_b')
        return im
    if base in ('asphalt', 'puddle', 'arch_shade'):
        im.rect(0, 0, 16, 16, c('shadow' if base == 'arch_shade' else 'road'))
        return im
    if name in ('wall_brick', 'wall_plaster', 'wall_int', 'concrete'):
        im.rect(0, 0, 16, 16, c('plaster'))
        return im
    if name in ('wall_brick_base', 'wall_base', 'wall_int_base', 'wall_side'):
        im.rect(0, 0, 16, 16, c('stone'))
        im.hline(0, 0, 16, c('light'));im.hline(0, 15, 16, c('shadow'))
        return im
    if name in ('roof_slate', 'roof_rust', 'roof_ridge', 'roof_eave'):
        im.rect(0, 0, 16, 16, c('plaster'))
        im.hline(0, 1, 16, c('light'));im.hline(0, 15, 16, c('stone'))
        return im
    if name == 'floor_concrete':
        im.rect(0, 0, 16, 16, c('paving'))
        for x,y in ((2,5),(11,13),(13,2)):im.set(x,y,c('stone'))
        return im
    if name in ('floor_wood_a', 'floor_wood_b'):
        im.rect(0, 0, 16, 16, c('wood'))
        for y in (0, 8):im.hline(0,y,16,rgb('wood2'))
        im.vline(3 if name.endswith('a') else 11,1,7,rgb('wood2'))
        return im
    if name.startswith(('grass', 'tree', 'bush', 'hedge')):
        return remap(original, {'grass0':'sela_leaf_dark','grass1':'sela_leaf',
                               'grass2':'sela_leaf_light','grass3':'sela_plaster'})
    if name == 'quay_edge':
        paving(im)
        im.rect(0,8,16,8,c('stone'));im.hline(0,8,16,c('light'))
        im.hline(0,15,16,c('deep'))
        return im
    if name == 'coast_sky':
        im.rect(0,0,16,16,c('sky'));return im
    return original
