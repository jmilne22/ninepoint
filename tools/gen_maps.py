"""Authors the city maps as data.

Maps are plain JSON grids (see data/maps/*.json) built here from placement
instructions, because hand-counting 30-character rows is how off-by-one bugs get
into a tileset. The engine side is src/rpg/maps/map_builder.gd.
"""
import json
import os
import sys
from venue_layouts import dress, rewrite_signs, finish
from venue_presence import states as activity_states

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.join(here, "..")


class Grid:
    def __init__(self, w, h, fill="."):
        self.w, self.h = w, h
        self.rows = [[fill] * w for _ in range(h)]

    def set(self, x, y, ch):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.rows[y][x] = ch

    def fill(self, x, y, w, h, ch):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, ch)

    def row(self, y, x, text):
        for i, ch in enumerate(text):
            self.set(x + i, y, ch)

    def out(self):
        return ["".join(r) for r in self.rows]


# tile name for every legend character, shared by both maps
LEGEND = {
    "}": "wall_side",
    "^": "roof_ridge", "#": "roof_slate", "R": "roof_rust", "~": "roof_eave",
    "C": "chimney", "W": "wall_plaster", "w": "wall_plaster_win", "B": "wall_base",
    "D": "door_wood", "d": "door_club", "F": "door_glass", "S": "sign_hanging",
    "A": "awning", "P": "pavement", "K": "kerb", "c": "cobble_a", "v": "cobble_b",
    "g": "grass_a", "h": "grass_b", "j": "grass_c", "f": "grass_flowers",
    "T": "tree_tl", "t": "tree_tr", "U": "tree_bl", "u": "tree_br",
    "H": "hedge", "-": "fence_h", "|": "fence_post", "b": "bench",
    "s": "stone_table", "n": "noticeboard", "L": "lamp_post", "p": "planter",
    "o": "post_box", "x": "void", "e": "bush", "r": "gravel", "z": "drain",
    # the city
    "a": "asphalt", "=": "tram_rail_h", "!": "tram_rail_v", "q": "puddle",
    "%": "cobble_wet", ":": "canal", ";": "quay_edge", "J": "bollard",
    "y": "bike_rack", "l": "tram_pole", "m": "wall_brick", "0": "wall_brick_win",
    "_": "wall_brick_base", "&": "graffiti", "5": "shutter", "6": "shutter_sign",
    "(": "arch_left", ")": "arch_right", "7": "arch_shade", "8": "neon_sign",
    "9": "snack_window", "<": "stairs_down", "+": "concrete", "*": "glass_curtain",
    # interior
    "$": "stove", "?": "hooks", ",": "floor_concrete", "k": "washer",
    "1": "floor_wood_a", "2": "floor_wood_b", "3": "floor_mat", "4": "rug",
    "I": "wall_int", "i": "wall_int_base", "N": "wall_int_win", "V": "shelf_books",
    "O": "counter", "G": "go_table", "E": "go_table_empty", "X": "chair",
    "Y": "kifu_board", "Q": "plant_int", "Z": "kettle_table", "M": "door_int",
}

# Solidity is a whitelist and not a blacklist: solid_mask() calls a tile
# walkable if and only if its legend character is in here (or the caller passed
# the tile in extra_walkable, which is how doors work). Everything else --
# walls, roofs, furniture, the canal, the quay lip, every piece of street
# furniture -- is solid by default, which is the safe direction: a new tile
# nobody classified blocks the player rather than letting them walk into the
# sea.
#
# There was a SOLID set above this line until M36 and it was read by NOTHING.
# One definition, no references, in a file whose whole job is classifying
# tiles -- so it looked exactly like the source of truth and was not one. It
# was found by breaking it on purpose: adding a new tile to it and taking it
# out again changed nothing either way. Do not reintroduce it; the list that
# decides is the one below.
WALKABLE_OVERRIDE = set("PKcvghjfrz1234" "a=!q%7<,")


def ketelsteeg():
    """The street. Brick, tram rails, the salon steps, the arch, the park.

    Layered on purpose: rooms above (your attic), rooms below (De Ketel), the
    viaduct at the east end and the water past the park at the south.
    """
    W, H = 34, 20
    ground = Grid(W, H, "a")
    decor = Grid(W, H, " ")

    # --- the north side: three buildings, then the flank of the viaduct
    # home is the shuttered stationer's with your stairs behind it; De Ketel is
    # the bar whose back room you actually want; the wassalon never closes.
    buildings = [(1, 8, "home"), (10, 8, "ketel"), (19, 8, "wassalon")]
    for bx, bw, kind in buildings:
        ground.row(0, bx, "^" * bw)
        ground.row(1, bx, "#" * bw)
        ground.set(bx + bw // 2, 1, "C")
        for y in (2, 3):
            ground.row(y, bx, ("R" if kind == "wassalon" else "#") * bw)
        ground.row(4, bx, "~" * bw)
        for y in (5, 6, 7):
            ground.row(y, bx, "m" * bw)
        ground.row(8, bx, "_" * bw)
        for wx in (bx + 1, bx + bw - 2):
            ground.set(wx, 5, "0")
            ground.set(wx, 7, "0")
    for x in (0, 9, 18, 27):                   # the gaps between are dark alleys
        for y in range(0, 9):
            ground.set(x, y, "x")

    # doors, at the one row a standing player can face
    home_door, ketel_steps, wash_door = 4, 13, 22
    ground.set(home_door, 8, "5")              # the shutter, never once raised
    ground.set(home_door, 7, "6")              # the stationer's dead sign
    ground.set(home_door + 1, 8, "D")          # your street door, beside it
    ground.set(ketel_steps, 8, "<")            # three steps down, and a double
    ground.set(ketel_steps + 1, 8, "<")        # width so it is not mean to aim at
    ground.set(ketel_steps, 7, "S")            # the hanging sign with the kettle
    # Two tiles wide, for the reason the salon steps are: a door you have to
    # stand on exactly one tile to find is a door most players never open.
    ground.set(wash_door, 8, "F")
    ground.set(wash_door + 1, 8, "F")
    ground.set(wash_door + 3, 7, "9")          # the snack window
    ground.set(wash_door + 4, 7, "8")          # and the only neon on the street

    # --- the viaduct closes the east end, and you can walk under it
    for y in range(0, 8):
        for x in range(28, W):
            ground.set(x, y, "m")
    ground.row(8, 28, "_" * (W - 28))
    ground.set(29, 6, "&")
    arch_x = 30
    ground.set(arch_x, 7, "(")
    ground.set(arch_x + 1, 7, ")")
    ground.set(arch_x, 8, "7")
    ground.set(arch_x + 1, 8, "7")

    # --- pavement, road, kerb
    for y in (9, 10):
        ground.row(y, 0, "P" * W)
    ground.row(11, 0, "a" * W)
    ground.row(12, 0, "=" * W)
    ground.row(13, 0, "a" * W)
    ground.row(14, 0, "K" * W)
    ground.set(6, 11, "q")
    ground.set(24, 13, "q")
    ground.set(16, 13, "z")

    # street furniture. All of it solid, all of it on the upper pavement row so
    # the lower row stays a clear walk from one end of the street to the other.
    ground.set(1, 9, "l")                      # the tram pole, at the stop
    ground.set(3, 9, "n")                      # the noticeboard
    ground.set(8, 9, "y")                      # bike racks nobody uses properly
    ground.set(20, 9, "o")
    ground.set(26, 9, "L")
    ground.set(12, 9, "p")

    # --- Molenpark, below the road
    park = ["gghjgghgjgghggjhggjgghjgghggjhggjg",
            "ghgjgghjggjhgghgjgghggjhgghggjhggg",
            "gjhggjgghgjgghjggjhgghgjgghggjhggg",
            "hggjgghjgghgggjhggjgghjgghjggjhggg"]
    for i, line in enumerate(park):
        ground.row(15 + i, 0, (line + "g" * W)[:W])
    ground.row(19, 0, "-" * W)
    for px in range(0, W, 6):
        ground.set(px, 19, "|")
    quay_steps = 16
    ground.set(quay_steps, 19, "<")            # the gap in the railing
    ground.set(quay_steps + 1, 19, "<")

    for tx, ty in ((4, 15), (12, 15), (25, 15)):
        ground.set(tx, ty, "T")
        ground.set(tx + 1, ty, "t")
        ground.set(tx, ty + 1, "U")
        ground.set(tx + 1, ty + 1, "u")
    ground.set(8, 17, "b")
    ground.set(21, 17, "b")
    ground.set(18, 16, "s")                    # the stone tables, in daylight
    ground.set(2, 17, "e")
    ground.set(30, 16, "e")

    walkable = {(ketel_steps, 8), (ketel_steps + 1, 8), (home_door + 1, 8),
                (wash_door, 8), (wash_door + 1, 8),
                (quay_steps, 19), (quay_steps + 1, 19)}
    solid = solid_mask(ground, extra_walkable=walkable)

    return {
        "name": "Ketelsteeg",
        "size": [W, H],
        "tile_size": 16,
        "legend": LEGEND,
        "ground": ground.out(),
        "decor": decor.out(),
        "solid": solid,
        "spawns": {
            "start": [home_door + 1, 9],
            "from_home": [home_door + 1, 9],
            "from_ketel": [ketel_steps, 9],
            "from_arch": [arch_x, 9],
            # Coming back off the southbound tram from Essenveld.
            "from_tram": [1, 10],
            "from_quay": [quay_steps, 18],
            "from_wassalon": [wash_door, 9],
            "park": [18, 17],
        },
        "warps": [
            {"tile": [ketel_steps, 8], "map": "de_ketel", "spawn": "from_street",
             "prompt": "De Ketel"},
            {"tile": [ketel_steps + 1, 8], "map": "de_ketel", "spawn": "from_street",
             "prompt": "De Ketel"},
            {"tile": [home_door + 1, 8], "map": "attic", "spawn": "from_street",
             "prompt": "Up to your room"},
            # The wassalon was a facade with a door, a sign, neon and no warp
            # for thirty-five milestones -- the sign describing the room was
            # standing on the tile that should have been the way into it, and
            # a sign has to be solid where a warp has to be walkable, so the
            # two could never have been the same tile. Ungated: the room is
            # open from day one and asks nothing of anybody.
            {"tile": [wash_door, 8], "map": "wassalon", "spawn": "from_street",
             "prompt": "Wassalon"},
            {"tile": [wash_door + 1, 8], "map": "wassalon", "spawn": "from_street",
             "prompt": "Wassalon"},
            {"tile": [arch_x, 8], "map": "onderbrug", "spawn": "from_street",
             "prompt": "Onderbrug"},
            {"tile": [arch_x + 1, 8], "map": "onderbrug", "spawn": "from_street",
             "prompt": "Onderbrug"},
            {"tile": [quay_steps, 19], "map": "quay", "spawn": "from_park",
             "prompt": "Down to the water"},
            {"tile": [quay_steps + 1, 19], "map": "quay", "spawn": "from_park",
             "prompt": "Down to the water"},
        ],
        "signs": [
            # The tram stop, at the pole. A sign with a prompt rather than a
            # walk-on warp at the map's edge: you press [Space] and choose a
            # direction, and the tram that passes is the tram you board.
            {"tile": [1, 9], "prompt": "Tram 4", "text": "__TRAM__" + json.dumps({"routes": [
                {"label": "North, to Essenveld.", "map": "academy_hall", "spawn": "from_tram",
                 "flag": "invited_to_institute",
                 "refused": "Tram 4 goes north to the Instituut. Nobody up there is expecting you yet."},
                {"label": "South, to the Bondszaal.", "map": "bondszaal", "spawn": "from_tram",
                 "flag": "ranked_by_club",
                 "refused": "Tram 4 goes south to the federation hall. Nothing down there for somebody with no rank."},
            ]})},
            {"tile": [3, 9], "text": "STEENBEEK BEGINNER CUP -- entries at the Bondszaal, by tram. All ranks 15k and below."},
            {"tile": [home_door, 8], "text": "A stationer's, shuttered since before you came. Your stairs are the door beside it, and the landlord's cat owns the landing."},
            {"tile": [ketel_steps + 2, 8], "text": "DE KETEL. Three steps down. The bar is Tomas's and so is the back room, which has had a board in it for sixty years."},
            {"tile": [wash_door - 1, 8], "text": "WASSALON -- open till two. The warmest room on Ketelsteeg, and nobody minds if you only sit."},
            {"tile": [wash_door + 3, 8], "text": "A hatch in the wall with a fryer behind it and no name over it. Open when the wassalon is, which is to say later than anything else on this street."},
            {"tile": [29, 8], "text": "Under the viaduct the brick is black with a century of smoke. Somebody has chalked a 3-4 point on it, and somebody else has chalked the answer."},
        ],
        "npcs": [
            {"id": "pip", "tile": [10, 16], "dir": "down", "idle": "wander"},
            # "Four kyu, forty years, one park bench." He sits at the stone table.
            {"id": "bertie", "tile": [17, 16], "dir": "right", "idle": "tend"},
        ],
        # Two pavements, and nobody walks the tram tracks between them. The
        # ends sit off the grid on purpose: a pedestrian who pops into being
        # at x=0 is a pedestrian you notice appearing.
        "routes": [
            {"path": [[-2, 10], [35, 10]], "rate": 9.0},
            {"path": [[-2, 14], [35, 14]], "rate": 13.0},
        ],
        "music": "theme_street",
        "indoors": False,
    }


def attic():
    """Your room, over the shuttered stationer's. One dormer, one board."""
    W, H = 12, 9
    ground = Grid(W, H, "1")
    decor = Grid(W, H, " ")

    ground.row(0, 0, "I" * W)
    ground.row(1, 0, "I" * W)
    ground.row(2, 0, "i" * W)
    for y in range(3, H):
        ground.set(0, y, "i")
        ground.set(W - 1, y, "i")
    ground.row(H - 1, 0, "i" * W)
    for y in range(3, H - 1):
        for x in range(1, W - 1):
            ground.set(x, y, "1" if (x + y) % 3 else "2")

    # The dormer is the whole character of the room: it looks at the tram wires.
    ground.set(5, 1, "N")
    ground.set(6, 1, "N")
    ground.set(1, 3, "V")
    ground.set(2, 3, "Q")
    ground.set(9, 4, "G")                      # the previous tenant's board
    ground.set(9, 3, "X")
    ground.set(2, 5, "Z")                      # the bed, near enough
    ground.set(2, 6, "Z")
    ground.set(W - 2, 6, "Z")                  # a table with a kettle on it

    door_x = 6
    ground.set(door_x, H - 1, "M")
    solid = solid_mask(ground, extra_walkable={(door_x, H - 1)})

    return {
        "name": "Your attic",
        "size": [W, H], "tile_size": 16, "legend": LEGEND,
        "ground": ground.out(), "decor": decor.out(), "solid": solid,
        # "start" is where a new game begins: standing at the desk, looking
        # at a board somebody else left behind.
        "spawns": {"start": [8, 4], "from_street": [door_x, H - 2], "desk": [8, 4]},
        "warps": [{"tile": [door_x, H - 1], "map": "ketelsteeg", "spawn": "from_home",
                   "prompt": "Down to Ketelsteeg"}],
        "signs": [
            {"tile": [9, 4], "text": "__DESK__The board the last tenant left, on a desk exactly the right size for it. You have turned it over twice looking for instructions."},
            {"tile": [2, 5], "text": "__BED__A bed under the slope of the roof. You have hit your head on that roof twice."},
            {"tile": [5, 2], "text": "Under the dormer, which looks out at the tram wires and, past them, the crane on the far quay. It rains against that window most nights."},
        ],
        "npcs": [],
        "music": "",
        "indoors": True,
    }


def wassalon():
    """Machines, folding and a game share the room without sharing a doorway."""
    W,H=20,13
    ground=Grid(W,H,",");decor=Grid(W,H," ")
    for y in (0,1): ground.row(y,0,"I"*W)
    ground.row(2,0,"i"*W)
    for y in range(3,H):
        ground.set(0,y,"i");ground.set(W-1,y,"i")
    ground.row(H-1,0,"i"*W)
    ground.set(7,H-1,"M")
    ground.row(H-2,6,"33")
    ground.set(17,2,"n")
    for x in range(2,10):ground.set(x,4,"k")
    for x in range(2,6):ground.set(x,7,"O")
    for x in range(10,13):ground.set(x,6,"G")
    for x in range(15,18):ground.set(x,9,"b")
    return {
        "name":"Wassalon", "size":[W,H],"tile_size":16,"legend":LEGEND,
        "ground":ground.out(),"decor":decor.out(),"solid":solid_mask(ground,extra_walkable={(7,H-1)}),
        "art_props":[
            {"art":"washer_bank","position":[32,40]},
            {"art":"folding_counter","position":[32,96]},
            {"art":"playing_table","position":[160,80]},
            {"art":"long_bench","position":[240,136]},
            {"art":"coat_rack","position":[240,24]}],
        "spawns":{"from_street":[7,H-2],"bench":[14,10]},
        "warps":[{"tile":[7,H-1],"map":"ketelsteeg","spawn":"from_wassalon","prompt":"Out to Ketelsteeg"}],
        "signs":[
            {"tile":[4,4],"text":"Please empty your pockets. Lost buttons are in the jar by the folding counter."},
            {"tile":[17,2],"text":"ROOM TO LET. Ask at the snack window. Below it: Cup entries at the Bondszaal."},
            {"tile":[11,6],"text":"A Go board between two bowls. Someone has put felt under the table legs."}],
        "npcs":[
            {"id":"abel","tile":[6,7],"dir":"left","idle":"study"},
            {"id":"dov","tile":[11,7],"dir":"up","idle":"study"},
            {"id":"moss","tile":[11,4],"dir":"down","idle":"study"}],
        "music":"","indoors":True}


def onderbrug():
    """Under the viaduct: three arches, crates for tables, and no papers."""
    W, H = 24, 12
    ground = Grid(W, H, "7")
    decor = Grid(W, H, " ")

    for y in (0, 1, 2):
        ground.row(y, 0, "m" * W)
    ground.row(3, 0, "_" * W)
    ground.row(H - 2, 0, "_" * W)
    ground.row(H - 1, 0, "m" * W)
    for y in range(4, H - 2):
        ground.set(0, y, "m")
        ground.set(W - 1, y, "m")

    # the three arches along the north side, and daylight in none of them
    for ax in (3, 10, 17):
        ground.set(ax, 2, "(")
        ground.set(ax + 1, 2, ")")
        ground.set(ax, 3, "7")
        ground.set(ax + 1, 3, "7")
    ground.set(7, 1, "&")
    ground.set(14, 2, "&")

    # standing water, because it is always standing under a viaduct
    for qx, qy in ((5, 8), (12, 6), (20, 9)):
        ground.set(qx, qy, "q")
    for cx in range(2, W - 2, 3):
        ground.set(cx, 10, "%")

    # crates with boards on them. The last one is Joos's and it is furthest in.
    for tx, ty in ((5, 6), (11, 8), (19, 6)):
        ground.set(tx, ty, "G")
    ground.set(15, 5, "E")                     # one empty board, waiting
    # One lamp per arch, and not one more. They are the reason anybody can see
    # to play at all, and at night they are the whole of the lighting design.
    for lx in (2, 9, 16):
        ground.set(lx, 4, "L")

    exit_y = 7
    ground.set(0, exit_y, "7")
    ground.set(0, exit_y + 1, "7")
    solid = solid_mask(ground, extra_walkable={(0, exit_y), (0, exit_y + 1)})

    return {
        "name": "Onderbrug",
        "size": [W, H], "tile_size": 16, "legend": LEGEND,
        "ground": ground.out(), "decor": decor.out(), "solid": solid,
        "spawns": {"from_street": [1, exit_y], "arch": [18, 7]},
        "warps": [
            {"tile": [0, exit_y], "map": "ketelsteeg", "spawn": "from_arch",
             "prompt": "Out to Ketelsteeg"},
            {"tile": [0, exit_y + 1], "map": "ketelsteeg", "spawn": "from_arch",
             "prompt": "Out to Ketelsteeg"},
        ],
        "signs": [
            {"tile": [5, 6], "text": "A board on an upturned crate, the lines worn pale in the middle where sixty years of hands have rested."},
            {"tile": [11, 8], "text": "Coins on the corner of the crate, held down by a stone. Nobody counts them until the game is over."},
            {"tile": [2, 4], "text": "One lamp per arch, and the furthest one has been out for years. Everybody sits where they can see; the man at the far end sits where he cannot be seen."},
        ],
        # The arches are the other half of the city: a man with no card and no
        # papers, under a viaduct, and nobody else.
        "npcs": [
            {"id": "joos", "tile": [19, 7], "dir": "up", "idle": "watch"},
        ],
        # No crowd route: validate() rejected every one tried here, because the
        # arches are walled at both ends and there is nowhere for a passer-by
        # to have come from or be going to. Which is the correct answer -- it
        # is a dead end under a viaduct, and nobody official comes down here.
        "music": "theme_arches",
        "indoors": False,
    }


def quay():
    """Grey water, one bench, and the crane on the far side."""
    W, H = 26, 14
    ground = Grid(W, H, "P")
    decor = Grid(W, H, " ")

    ground.row(0, 0, "-" * W)
    for px in range(0, W, 6):
        ground.set(px, 0, "|")
    for y in (1, 2, 3, 4, 5, 6):
        ground.row(y, 0, ("%" if y == 6 else "P") * W)
    ground.row(7, 0, ";" * W)
    for y in range(8, H):
        ground.row(y, 0, ":" * W)

    # Standing water on the flags. The puddle tile has a when_wet animation and
    # has done since M16; it just never ran, because nothing in the game ever
    # made it rain. Ketelsteeg and Onderbrug already had five between them, and
    # the quay -- the map you come to after losing, in a port that drizzles --
    # had none.
    ground.set(8, 5, "q")
    # A weathered noticeboard is the quay's only deliberate interaction: it
    # holds a later look at a finished rated game, not another person to meet.
    ground.set(17, 3, "n")

    ground.set(5, 6, "J")                      # mooring bollards
    ground.set(19, 6, "J")
    ground.set(12, 4, "b")                     # the bench
    ground.set(2, 3, "L")
    ground.set(22, 3, "e")
    ground.set(9, 2, "y")

    steps_x = 12
    ground.set(steps_x, 0, "<")
    ground.set(steps_x + 1, 0, "<")
    solid = solid_mask(ground, extra_walkable={(steps_x, 0), (steps_x + 1, 0)})

    return {
        "name": "The quay",
        "size": [W, H], "tile_size": 16, "legend": LEGEND,
        "ground": ground.out(), "decor": decor.out(), "solid": solid,
        "spawns": {"from_park": [steps_x, 1], "bench": [12, 5]},
        "warps": [
            {"tile": [steps_x, 0], "map": "ketelsteeg", "spawn": "from_quay",
             "prompt": "Up to Molenpark"},
            {"tile": [steps_x + 1, 0], "map": "ketelsteeg", "spawn": "from_quay",
             "prompt": "Up to Molenpark"},
        ],
        "signs": [
            {"tile": [12, 4], "text": "A bench facing the water. It is the only place in Steenbeek where nobody will ask you how the game went."},
            {"tile": [5, 6], "text": "A mooring bollard, worn smooth. The water is the colour of the sky, which today is the colour of the water."},
            {"tile": [17, 3], "text": "__QUAY_REVIEW__"},
        ],
        "npcs": [],
        "music": "theme_quay",
        "indoors": False,
    }


def de_ketel():
    W, H = 20, 14
    ground = Grid(W, H, "1")
    decor = Grid(W, H, " ")

    # walls
    ground.row(0, 0, "I" * W)
    ground.row(1, 0, "I" * W)
    ground.row(2, 0, "i" * W)
    for y in range(3, H):
        ground.set(0, y, "i")
        ground.set(W - 1, y, "i")
    ground.row(H - 1, 0, "i" * W)

    # floor
    for y in range(3, H - 1):
        for x in range(1, W - 1):
            ground.set(x, y, "1" if (x + y) % 3 else "2")

    # windows and fittings along the back wall
    for wx in (3, 6, 13, 16):
        ground.set(wx, 1, "N")
    # The hooks hang on the wall base -- the row a standing player can face.
    # On row 1 they were two tiles up and the interaction probe never saw them,
    # which is the same bug the league board had.
    ground.set(9, 2, "?")
    ground.set(10, 2, "?")
    for vx in range(1, 3):
        ground.set(vx, 2, "V")
    for vx in range(17, 19):
        ground.set(vx, 2, "V")

    # the counter with the kettle the room is named after, and a plant
    # nobody waters
    ground.set(1, 4, "O")
    ground.set(1, 5, "Z")
    ground.set(18, 4, "$")                     # the stove, and the only warmth
    ground.set(18, 11, "Q")

    # the rug and the playing tables. The two columns in front of the door are
    # left clear so nobody spawns inside a chair.
    ground.fill(7, 6, 6, 4, "4")
    door_x = 9
    tables = [(4, 5), (4, 10), (15, 5), (15, 10)]
    for i, (tx, ty) in enumerate(tables):
        ground.set(tx, ty, "G" if i % 2 == 0 else "E")
        ground.set(tx, ty - 1, "X")
        ground.set(tx, ty + 1, "X")

    # the double door back up the steps onto Ketelsteeg
    ground.set(door_x, H - 1, "M")
    ground.set(door_x + 1, H - 1, "M")

    solid = solid_mask(ground, extra_walkable={(door_x, H - 1), (door_x + 1, H - 1)})


    return {
        "name": "De Ketel",
        "size": [W, H],
        "tile_size": 16,
        "legend": LEGEND,
        "ground": ground.out(),
        "decor": decor.out(),
        "solid": solid,
        "spawns": {
            "from_street": [door_x, H - 3],
            "middle": [10, 8],
        },
        "warps": [
            {"tile": [door_x, H - 1], "map": "ketelsteeg", "spawn": "from_ketel",
             "prompt": "Ketelsteeg"},
            {"tile": [door_x + 1, H - 1], "map": "ketelsteeg", "spawn": "from_ketel",
             "prompt": "Ketelsteeg"},
        ],
        "signs": [
            {"tile": [9, 2], "text": "A row of brass hooks on the back wall. Coats, mostly, and one umbrella nobody has claimed."},
            {"tile": [18, 4], "text": "A coal stove, lit from October to April whatever the weather does. The chair nearest it is not yours and everybody knows whose it is."},
            {"tile": [1, 5], "text": "The rate is chalked on a slate: two-fifty an hour, board and stones included. Under it a kettle, a tin of biscuits, and an honesty box. The biscuits are gone."},
            {"tile": [1, 4], "text": "Pinned to the counter, in Tomas's handwriting: ALL COMERS. ASK. Underneath, smaller: the board is free, the tea is not."},
            {"tile": [15, 5], "text": "Wren's teaching table. A chalk note says: RULES, FIRST GAME, THEN KESH. Someone has underlined FIRST GAME twice."},
        ],
        # Kesh and Hana are the two people the setting says cross between the
        # Instituut and the salon, and until M26 that was expressed by placing
        # two permanent copies of each. Now it is one person with an evening.
        # Both keep the afternoon on both maps, because Act 1 meets them here on
        # day one at that hour and a schedule may not break the opening.
        #
        # Wren is deliberately unscheduled: she is the anchor that keeps De
        # Ketel staffed at every hour, and Act 1's rules lessons hang off her.
        "npcs": [
            {"id": "wren", "tile": [6, 8], "dir": "right", "idle": "study"},
            # Kesh does not sit still anywhere, which is most of what she is.
            {"id": "kesh", "tile": [14, 7], "dir": "left", "idle": "wander"},
            # Tomas owns this room and the bar above it.
            {"id": "tomas", "tile": [2, 6], "dir": "right", "idle": "tend"},
        ],
        "music": "theme_club",
        "indoors": True,
    }


def bondszaal():
    """The federation hall: where a result becomes a record.

    Neither De Ketel nor the Instituut. The salon is warm and unofficial and the
    Instituut is cold and official; the Bondszaal is a hired room in a civic
    building -- wood floor, plaster, too many chairs, and a board at the front
    with the draw pinned to it. It is only ever full four times a year.
    """
    W, H = 18, 24
    ground = Grid(W, H, "1")
    decor = Grid(W, H, " ")

    ground.row(0, 0, "I" * W)
    ground.row(1, 0, "I" * W)
    ground.row(2, 0, "i" * W)
    for y in range(3, H - 1):
        ground.set(0, y, "i")
        ground.set(W - 1, y, "i")
    ground.row(H - 1, 0, "i" * W)
    for y in range(3, H - 1):
        for x in range(1, W - 1):
            ground.set(x, y, "1" if (x + y) % 2 else "2")

    # Tall windows on the street side, because a civic hall has them and because
    # the light is the only thing here that is not municipal.
    for wx in (3, 6, 12, 15):
        ground.set(wx, 1, "N")

    # The draw is pinned at the front, on the wall base where it can be faced.
    ground.set(9, 2, "Y")
    ground.set(10, 2, "Y")
    # And the exam list beside it, because the Instituut hires this room too and
    # pins its own paper up next to the federation's.
    ground.set(13, 2, "Y")
    ground.set(14, 2, "Y")
    ground.set(1, 20, "O")                      # the entry desk
    ground.set(W - 2, 3, "V")                  # the federation's own shelf
    ground.set(W - 2, 11, "Q")

    # Rows of hired tables. Two occupied at the front, the rest waiting, which is
    # what a tournament room looks like an hour before it fills.
    for ty in (7, 11, 15, 19):
        for tx in (4, 8, 12):
            ground.set(tx, ty, "G" if ty == 6 and tx in (4, 8) else "E")
            ground.set(tx, ty - 1, "X")
            ground.set(tx, ty + 1, "X")

    ground.set(9, H - 1, "M")                  # out to the tram
    ground.set(10, H - 1, "M")
    solid = solid_mask(ground, extra_walkable={(9, H - 1), (10, H - 1)})

    return {
        "name": "The Bondszaal",
        "size": [W, H], "tile_size": 16, "legend": LEGEND,
        "ground": ground.out(), "decor": decor.out(), "solid": solid,
        "spawns": {"from_tram": [9, H - 2], "front": [9, 3]},
        "warps": [
            {"tile": [9, H - 1], "map": "ketelsteeg", "spawn": "from_tram",
             "prompt": "Tram 4, back to Steenbeek"},
            {"tile": [10, H - 1], "map": "ketelsteeg", "spawn": "from_tram",
             "prompt": "Tram 4, back to Steenbeek"},
        ],
        "signs": [
            {"tile": [9, 2], "text": "__CUP_BOARD__"},
            {"tile": [10, 2], "text": "__CUP_BOARD__"},
            {"tile": [13, 2], "text": "__EXAM_BOARD__"},
            {"tile": [14, 2], "text": "__EXAM_BOARD__"},
            {"tile": [1, 20], "text": "THE VERHAVEN GO FEDERATION. A hired room, four times a year, and a cupboard the rest of it. The urn is municipal and so is the tea."},
            {"tile": [W - 2, 3], "text": "Bound volumes of every result the federation has recorded since 1954. Somebody's first game is in here and they are dead now."},
        ],
        "npcs": [
            {"id": "marguerite", "tile": [2, 20], "dir": "right", "idle": "tend"},
        ],
        "music": "theme_institute",
        "indoors": True,
    }


def academy_hall():
    """The entrance hall: glass, concrete, and the league board.

    Deliberately the coldest room in the game -- it is the half of the city
    that writes things down, and it should not look like De Ketel.
    """
    W, H = 22, 14
    ground = Grid(W, H, "1")
    decor = Grid(W, H, " ")

    ground.row(0, 0, "+" * W)
    ground.row(1, 0, "*" * W)                  # a glass curtain wall, floor to
    ground.row(2, 0, "+" * W)                  # ceiling, and no way to see in
    for y in range(3, H):
        ground.set(0, y, "+")
        ground.set(W - 1, y, "+")
    ground.row(H - 1, 0, "+" * W)
    for y in range(3, H - 1):
        for x in range(1, W - 1):
            # poured concrete, with one rug where people stand to read the board
            ground.set(x, y, "4" if 8 <= x <= 13 and 4 <= y <= 6 else ",")

    for wx in (3, 6, 15, 18):
        ground.set(wx, 1, "*")
    # The league board hangs on the wall base, which is the row the player can
    # actually stand next to and face. On row 1 it was two tiles up and
    # unreachable by the interaction probe.
    ground.set(10, 2, "Y")
    ground.set(11, 2, "Y")
    ground.set(1, 2, "V")
    ground.set(20, 2, "V")
    ground.set(1, 4, "O")            # the register desk
    ground.set(20, 4, "Q")
    ground.set(20, 11, "Q")

    # doors: south to the tram, west to the study hall, east to the classroom,
    # north-east stair to the dormitory
    ground.set(10, H - 1, "M")
    ground.set(11, H - 1, "M")
    ground.set(0, 7, "M")
    ground.set(W - 1, 7, "M")
    ground.set(W - 2, 3, "P")        # the stair up, drawn as pavement stone

    solid = solid_mask(ground, extra_walkable={
        (10, H - 1), (11, H - 1), (0, 7), (W - 1, 7), (W - 2, 3)})

    return {
        "name": "Essenveld Instituut -- Hall",
        "size": [W, H], "tile_size": 16, "legend": LEGEND,
        "ground": ground.out(), "decor": decor.out(), "solid": solid,
        "spawns": {"from_tram": [10, H - 2], "from_study": [1, 7],
                   "from_class": [W - 2, 7], "from_dorm": [W - 3, 3]},
        "warps": [
            {"tile": [10, H - 1], "map": "ketelsteeg", "spawn": "from_tram",
             "prompt": "Back to Steenbeek"},
            {"tile": [11, H - 1], "map": "ketelsteeg", "spawn": "from_tram",
             "prompt": "Back to Steenbeek"},
            {"tile": [0, 7], "map": "academy_study", "spawn": "from_hall",
             "prompt": "Study hall"},
            {"tile": [W - 1, 7], "map": "academy_class", "spawn": "from_hall",
             "prompt": "Classroom"},
            {"tile": [W - 2, 3], "map": "academy_dorm", "spawn": "from_hall",
             "prompt": "Up to the dormitory"},
        ],
        "signs": [
            {"tile": [10, 2], "text": "__LEAGUE_BOARD__"},
            {"tile": [11, 2], "text": "__LEAGUE_BOARD__"},
            {"tile": [1, 4], "text": "THE ESSENVELD INSTITUUT. Founded so that people who were going to spend their lives on this anyway could do it somewhere warm."},
        ],
        "npcs": [{"id": "marguerite", "tile": [2, 4], "dir": "down", "idle": "tend"}],
        # Students crossing the hall between the study hall and the classroom,
        # door to door along row 7 -- an interior has no map edge to arrive
        # from, so the doorways are the only honest place to appear. And only
        # students: the street's dockworker would be wearing the wrong thing
        # entirely. (Warps mask the player's layer alone, so a passer walking
        # over one does not change the scene.)
        "routes": [
            {"path": [[0, 7], [21, 7]], "rate": 11.0, "sheets": ["extra_student"]},
        ],
        "music": "theme_institute",
        "indoors": True,
    }


def academy_study():
    """A clean, numbered competitive workspace: tables, pairings, and study
    records make its purpose legible before anyone explains the league."""
    W, H = 24, 14
    ground = Grid(W, H, "1")
    decor = Grid(W, H, " ")

    ground.row(0, 0, "I" * W)
    ground.row(1, 0, "I" * W)
    ground.row(2, 0, "i" * W)
    for y in range(3, H):
        ground.set(0, y, "i")
        ground.set(W - 1, y, "i")
    ground.row(H - 1, 0, "i" * W)
    for y in range(3, H - 1):
        for x in range(1, W - 1):
            ground.set(x, y, ",")

    for wx in (3, 7, 16, 20):
        ground.set(wx, 1, "N")
    for vx in (1, 2, 21, 22):
        ground.set(vx, 2, "V")
    ground.set(10, 2, "Y")
    ground.set(11, 2, "Y")

    # four playing tables in two rows, chairs above and below
    for tx, ty in ((5, 5), (11, 5), (17, 5), (5, 10), (11, 10), (17, 10)):
        ground.set(tx, ty, "G" if (tx + ty) % 2 == 0 else "E")
        ground.set(tx, ty - 1, "X")
        ground.set(tx, ty + 1, "X")
    ground.set(1, 6, "Z")
    ground.set(22, 6, "Q")

    door_x = W - 1
    ground.set(door_x, 7, "M")
    solid = solid_mask(ground, extra_walkable={(door_x, 7)})

    return {
        "name": "Essenveld Instituut -- Study Hall",
        "size": [W, H], "tile_size": 16, "legend": LEGEND,
        "ground": ground.out(), "decor": decor.out(), "solid": solid,
        "spawns": {"from_hall": [door_x - 1, 7], "middle": [12, 7]},
        "warps": [{"tile": [door_x, 7], "map": "academy_hall", "spawn": "from_study",
                   "prompt": "Back to the hall"}],
        "signs": [
            {"tile": [1, 6], "text": "A kettle, a tin, and a handwritten note: THE BISCUITS ARE FOR EVERYONE WHICH MEANS THEY ARE NOT ALL FOR YOU."},
            {"tile": [10, 2], "text": "LOWER LEAGUE — PAIRINGS / RESULTS. Tables 1–6 are numbered in pencil. Play here when a result is meant to count."},
            {"tile": [5, 5], "text": "Table 1. A neat card: PRACTICE / REVIEW."},
            {"tile": [11, 5], "text": "Table 2. A neat card: LEAGUE GAMES."},
        ],
        # The three students you can play any time. Kesh is at De Ketel.
        "npcs": [
            {"id": "ilse", "tile": [6, 6], "dir": "right", "idle": "study"},
            {"id": "sunny", "tile": [18, 6], "dir": "left", "idle": "wander"},
            {"id": "orla", "tile": [12, 11], "dir": "up", "idle": "watch"},
        ],
        "music": "theme_institute",
        "indoors": True,
    }


def academy_class():
    """Where the openings get taught."""
    W, H = 18, 12
    ground = Grid(W, H, "1")
    decor = Grid(W, H, " ")

    ground.row(0, 0, "I" * W)
    ground.row(1, 0, "I" * W)
    ground.row(2, 0, "i" * W)
    for y in range(3, H):
        ground.set(0, y, "i")
        ground.set(W - 1, y, "i")
    ground.row(H - 1, 0, "i" * W)
    for y in range(3, H - 1):
        for x in range(1, W - 1):
            ground.set(x, y, "2" if (x + y) % 4 else "1")

    # The demonstration board, on the wall base for the same reason.
    for bx in range(7, 11):
        ground.set(bx, 2, "Y")
    for row_y in (6, 9):
        for dx in range(3, 15, 3):
            ground.set(dx, row_y, "E")
            ground.set(dx, row_y - 1, "X")
    ground.set(1, 4, "V")
    ground.set(W - 2, 4, "Q")

    door_x = 0
    ground.set(door_x, 7, "M")
    solid = solid_mask(ground, extra_walkable={(door_x, 7)})

    return {
        "name": "Essenveld Instituut -- Classroom",
        "size": [W, H], "tile_size": 16, "legend": LEGEND,
        "ground": ground.out(), "decor": decor.out(), "solid": solid,
        "spawns": {"from_hall": [1, 7], "front": [9, 4]},
        "warps": [{"tile": [door_x, 7], "map": "academy_hall", "spawn": "from_class",
                   "prompt": "Back to the hall"}],
        "signs": [
            {"tile": [8, 2], "text": "__CLASS_BOARD__"},
            {"tile": [9, 2], "text": "__CLASS_BOARD__"},
        ],
        "npcs": [
            {"id": "hana", "tile": [12, 3], "dir": "down", "idle": "watch"},
            {"id": "nadia", "tile": [4, 5], "dir": "right", "idle": "study"},
        ],
        "music": "theme_institute",
        "indoors": True,
    }


def academy_dorm():
    """Your room. Small, and yours."""
    W, H = 12, 10
    ground = Grid(W, H, "1")
    decor = Grid(W, H, " ")

    ground.row(0, 0, "I" * W)
    ground.row(1, 0, "I" * W)
    ground.row(2, 0, "i" * W)
    for y in range(3, H):
        ground.set(0, y, "i")
        ground.set(W - 1, y, "i")
    ground.row(H - 1, 0, "i" * W)
    for y in range(3, H - 1):
        for x in range(1, W - 1):
            ground.set(x, y, "1")

    ground.set(4, 1, "N")
    ground.set(7, 1, "N")
    ground.set(1, 3, "V")            # your shelf
    ground.set(2, 3, "V")
    ground.set(W - 2, 3, "Q")
    ground.set(9, 6, "G")            # the board you brought with you
    ground.set(9, 5, "X")
    ground.set(2, 6, "Z")            # a bed, near enough
    ground.set(2, 7, "Z")

    door_x = 5
    ground.set(door_x, H - 1, "M")
    solid = solid_mask(ground, extra_walkable={(door_x, H - 1)})

    return {
        "name": "Essenveld Instituut -- Your Room",
        "size": [W, H], "tile_size": 16, "legend": LEGEND,
        "ground": ground.out(), "decor": decor.out(), "solid": solid,
        "spawns": {"from_hall": [door_x, H - 2], "bed": [3, 6]},
        "warps": [{"tile": [door_x, H - 1], "map": "academy_hall", "spawn": "from_dorm",
                   "prompt": "Down to the hall"}],
        "signs": [
            {"tile": [9, 6], "text": "__DESK__The board from your old room, on a desk that is exactly the right size for it. Somebody has put it there deliberately."},
            {"tile": [2, 6], "text": "__BED__A bed. Institute issue. You will be glad of it."},
        ],
        "npcs": [],
        "music": "",
        "indoors": True,
    }


def solid_mask(grid, extra_walkable=frozenset()):
    rows = []
    for y in range(grid.h):
        line = ""
        for x in range(grid.w):
            ch = grid.rows[y][x]
            walkable = ch in WALKABLE_OVERRIDE or (x, y) in extra_walkable
            line += "0" if walkable else "1"
        rows.append(line)
    return rows


def validate(name, data):
    """Every place a person can stand must actually be standable."""
    solid = data["solid"]
    problems = []

    def walkable(x, y):
        return 0 <= y < len(solid) and 0 <= x < len(solid[y]) and solid[y][x] == "0"

    for spawn, (x, y) in data["spawns"].items():
        if not walkable(x, y):
            problems.append("%s: spawn '%s' at %d,%d is solid" % (name, spawn, x, y))
    for npc in data["npcs"]:
        x, y = npc["tile"]
        if not walkable(x, y):
            problems.append("%s: npc '%s' at %d,%d is solid" % (name, npc["id"], x, y))
    # Furniture can leave a perfectly walkable service in an isolated pocket.
    # Check reachability as well as the tile under each object.
    occupied = {tuple(npc["tile"]) for npc in data["npcs"]}
    start = tuple(next(iter(data["spawns"].values())))
    reached, pending = {start}, [start]
    while pending:
        x, y = pending.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            point = (x + dx, y + dy)
            if point not in reached and point not in occupied and walkable(*point):
                reached.add(point)
                pending.append(point)
    for kind, objects in (("NPC", data["npcs"]), ("sign", data["signs"])):
        for obj in objects:
            x, y = obj["tile"]
            if not any((x + dx, y + dy) in reached for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                problems.append("%s: %s at %d,%d cannot be approached from the entrance" % (name, kind, x, y))
    for warp in data["warps"]:
        if tuple(warp["tile"]) not in reached:
            problems.append("%s: exit to %s cannot be reached" % (name, warp["map"]))
    # Presence states are event-driven map variants, never a schedule. They
    # may replace the visible cast, but every placement is still held to the
    # same walkability rule as the base map.
    for state in data.get("presence_states", []):
        for npc in state.get("npcs", []):
            x, y = npc["tile"]
            if not walkable(x, y):
                problems.append("%s: presence '%s' npc '%s' at %d,%d is solid"
                                % (name, state.get("id", ""), npc["id"], x, y))
        for prop in state.get("tiles", []):
            x, y = prop["tile"]
            if not (0 <= y < len(solid) and 0 <= x < len(solid[y])):
                problems.append("%s: presence '%s' prop at %d,%d is off-map"
                                % (name, state.get("id", ""), x, y))
    for w in data["warps"]:
        x, y = w["tile"]
        if solid[y][x] != "0":
            problems.append("%s: warp to %s at %d,%d is solid" % (name, w["map"], x, y))
    for s_ in data["signs"]:
        x, y = s_["tile"]
        if walkable(x, y):
            problems.append("%s: sign at %d,%d is on a walkable tile (unreadable)" % (name, x, y))
        # ...and solid is only half of readable. The interaction probe is a
        # 14x14 box thrown PROBE_REACH=12 px from the player's feet, so it
        # reaches exactly one tile: a sign with no walkable orthogonal
        # neighbour is a sign nobody can ever stand in front of. It is solid,
        # it passes the check above, it builds an Interactable, and the probe
        # never once overlaps it.
        #
        # Written because M36 wrote two of them in an afternoon -- and found a
        # third that had been there since the attic was built in M14. The
        # dormer sign sat on the upper wall course with the wall base below it
        # and the floor below that, two tiles from anywhere a player can stand,
        # which is the same "interactables go on the base row" fact the hooks
        # at De Ketel had to learn separately.
        elif not any(walkable(x + dx, y + dy)
                     for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            problems.append("%s: sign at %d,%d has nowhere to stand and read it"
                            % (name, x, y))

    # Crowd routes. A passer-by is launched down these with no pathfinding at
    # all, so the whole segment has to be clear, not just its ends -- two
    # walkable endpoints with a wall between them is the bug this catches.
    #
    # Off-grid waypoints are deliberate and legal: routes start and end past
    # the edge of the map so people come from somewhere rather than blinking
    # into being on the pavement. There is nothing out there to collide with.
    def on_grid(x, y):
        return 0 <= y < len(solid) and 0 <= x < len(solid[y])

    for i, r in enumerate(data.get("routes", [])):
        path = r.get("path", [])
        if len(path) < 2:
            problems.append("%s: route %d has fewer than two waypoints" % (name, i))
            continue
        for (x0, y0), (x1, y1) in zip(path, path[1:]):
            if x0 != x1 and y0 != y1:
                problems.append("%s: route %d segment %d,%d -> %d,%d is not "
                                "axis-aligned" % (name, i, x0, y0, x1, y1))
                continue
            step = 1 if (x1 + y1) >= (x0 + y0) else -1
            if x0 == x1:
                cells = [(x0, y) for y in range(y0, y1 + step, step)]
            else:
                cells = [(x, y0) for x in range(x0, x1 + step, step)]
            for x, y in cells:
                if on_grid(x, y) and not walkable(x, y):
                    problems.append("%s: route %d crosses a solid tile at %d,%d"
                                    % (name, i, x, y))
    return problems


def build():
    out_dir = os.path.join(root, "data", "maps")
    os.makedirs(out_dir, exist_ok=True)
    written = []
    maps = (("ketelsteeg", ketelsteeg), ("de_ketel", de_ketel),
            ("attic", attic), ("wassalon", wassalon),
            ("onderbrug", onderbrug), ("quay", quay),
            ("academy_hall", academy_hall), ("academy_study", academy_study),
            ("academy_class", academy_class), ("academy_dorm", academy_dorm),
            ("bondszaal", bondszaal))
    for name, fn in maps:
        data = dress(name, fn())
        rewrite_signs(name,data)
        finish(name,data)
        data["presence_states"] = activity_states(name, data)
        problems = validate(name, data)
        if problems:
            raise SystemExit("Map validation failed:\n  " + "\n  ".join(problems))
        path = os.path.join(out_dir, name + ".json")
        json.dump(data, open(path, "w"), indent=1)
        written.append((name, data["size"]))
    return written


if __name__ == "__main__":
    print(build())
