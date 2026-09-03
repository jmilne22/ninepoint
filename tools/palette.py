"""The Ninepoint palette. Single source of truth -- see ART_DIRECTION.md section 2."""

PALETTE = {
    # ink and neutrals
    "ink0": "#14121a", "ink1": "#2a2633", "ink2": "#45404f", "ink3": "#6b6577",
    "paper0": "#f2e9d8", "paper1": "#ddd0b8", "paper2": "#bda98c",
    # greens
    "grass0": "#2f4a30", "grass1": "#47693c", "grass2": "#6b8f4a", "grass3": "#92ad5c",
    # browns / paths
    "wood0": "#3b2a1f", "wood1": "#5c4230", "wood2": "#8a6440", "wood3": "#b08a5c",
    "path0": "#7a6a58", "path1": "#9c8a72", "path2": "#bda98c", "path3": "#d6c4a8",
    # blues
    "blue0": "#23324e", "blue1": "#3a5a7d", "blue2": "#6d9ac0", "blue3": "#a8cbe0",
    # warm accents
    "rust0": "#5e2a2a", "rust1": "#8c4034", "rust2": "#b8624a", "rust3": "#d99070",
    "gold0": "#8a6023", "gold1": "#c08f3a", "gold2": "#e0b25c", "gold3": "#f2d791",
    # cool accents
    "plum0": "#3a2340", "plum1": "#63406b", "plum2": "#96699e",
    "teal0": "#1f4a45", "teal1": "#367f72", "teal2": "#63b3a0",
    # the city: wet brick, wet road, and one cold neon tube. The gold ramp above
    # doubles as sodium street light -- a Verhaven lamp is exactly gold1/gold2.
    "brick0": "#43292b", "brick1": "#63403c", "brick2": "#85574c", "brick3": "#a57263",
    "asphalt0": "#26232c", "asphalt1": "#3a3644", "asphalt2": "#524d5e",
    # Deliberately cool, and deliberately dimmer than board1: nothing may
    # out-saturate the board, so the only neon in the city is a cold one.
    "neon0": "#4fb8c8", "neon1": "#9fe4ec",
    # the go board -- deliberately warmer and brighter than the town
    "board0": "#a97b3c", "board1": "#d9ac66", "board2": "#eccd96", "line": "#3a2a18",
    "stoneB0": "#0d0b10", "stoneB1": "#2e2a35",
    "stoneW0": "#cfc6b4", "stoneW1": "#f7f2e6",
}

SKIN = {
    "skinA": ("#8a5a44", "#b2795c", "#d6a183"),
    "skinB": ("#5e3a2c", "#84543c", "#a8735a"),
    "skinC": ("#3d2620", "#5c3a2e", "#7d5240"),
    "skinD": ("#a87a5e", "#d6a583", "#f0c9a8"),
}


def rgb(name_or_hex, alpha=255):
    h = PALETTE.get(name_or_hex, name_or_hex)
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def skin(tone):
    return tuple(rgb(c) for c in SKIN[tone])


def mix(a, b, t):
    ca, cb = rgb(a), rgb(b)
    return tuple(int(ca[i] + (cb[i] - ca[i]) * t) for i in range(4))
