"""Environment-only colors. Never change the shared cast, board or UI ramps."""
from palette import PALETTE, rgb

COLORS = {
    'sela_plaster': '#e6d8bb', 'sela_light': '#f5e8ca',
    'sela_stone': '#b9af96', 'sela_paving': '#c5b99e',
    'sela_joint': '#b3a98f', 'sela_shadow': '#536366',
    'sela_deep': '#33494e', 'sela_teal': '#548c83',
    'sela_teal_light': '#85aba0', 'sela_coral': '#bb795f',
    'sela_coral_light': '#d7a080', 'sela_leaf': '#71825a',
    'sela_leaf_light': '#95a06b', 'sela_leaf_dark': '#455f49',
    'sela_sea': '#568b92', 'sela_sea_light': '#75a3a1',
    'sela_sky': '#a4c3c5', 'sela_road': '#898e86',
    'sela_wood': '#98795b',
}
PALETTE.update(COLORS)


def color(name):
    return rgb('sela_' + name)
