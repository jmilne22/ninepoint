"""The cast, as data.

Both the 16x24 overworld sprite and the 64x64 portrait are drawn from these
records, so a character cannot drift between the two. Change a colour here and
every image of that person changes with it. See ART_DIRECTION.md section 4.
"""

# hair styles: crop, short, bob, long, curls, bun, cap, tiedback
# accessories: none, scarf, glasses, apron, cap, blazer, cardigan
CHARACTERS = [
    dict(id="player", name="Ro", rank="unranked", skin="skinD",
         hair="crop", hair_col=("#3b2a1f", "#5c4230"),
         top=("#3a5a7d", "#6d9ac0"), bottom="#2a2633",
         accessory="none", build="slim", brow="flat", mouth="flat"),

    dict(id="wren", name="Wren Calloway", rank="20k", skin="skinD",
         hair="long", hair_col=("#8a6023", "#c08f3a"),
         top=("#c08f3a", "#e0b25c"), bottom="#5c4230",
         accessory="scarf", accent="#f2d791", build="slim", brow="raised", mouth="smile"),

    dict(id="kesh", name="Kesh Idowu", rank="12k", skin="skinB",
         hair="curls", hair_col=("#3a2340", "#63406b"),
         top=("#8c4034", "#b8624a"), bottom="#2a2633",
         accessory="none", build="slim", brow="angled", mouth="flat"),

    dict(id="pip", name="Pip Arnesen", rank="18k", skin="skinA",
         hair="crop", hair_col=("#8c4034", "#d99070"),
         top=("#47693c", "#6b8f4a"), bottom="#5c4230",
         accessory="none", build="slim", brow="raised", mouth="grin"),

    dict(id="bertie", name="Bertie Vale", rank="4k", skin="skinD",
         hair="cap", hair_col=("#6b6577", "#bda98c"),
         top=("#5c4230", "#8a6440"), bottom="#45404f",
         accessory="cap", accent="#7a6a58", build="broad", brow="flat", mouth="flat"),

    dict(id="nadia", name="Nadia Ferreira", rank="2k", skin="skinA",
         hair="bun", hair_col=("#14121a", "#45404f"),
         top=("#23324e", "#3a5a7d"), bottom="#2a2633",
         accessory="glasses", build="slim", brow="flat", mouth="small"),

    dict(id="hana", name="Hana Oyelaran", rank="5d", skin="skinB",
         hair="tiedback", hair_col=("#14121a", "#3a2340"),
         top=("#3a2340", "#63406b"), bottom="#2a2633",
         accessory="cardigan", accent="#96699e", build="slim", brow="flat", mouth="smile"),

    dict(id="tomas", name="Tomas Beir", rank="8k", skin="skinA",
         hair="short", hair_col=("#3b2a1f", "#5c4230"),
         top=("#1f4a45", "#367f72"), bottom="#45404f",
         accessory="apron", accent="#f2e9d8", build="broad", brow="flat", mouth="smile",
         beard=True),

    dict(id="marguerite", name="Marguerite Sable", rank="1d", skin="skinD",
         hair="bob", hair_col=("#6b6577", "#ddd0b8"),
         top=("#2a2633", "#45404f"), bottom="#2a2633",
         accessory="blazer", accent="#c08f3a", build="slim", brow="angled", mouth="flat"),

    # Joos has been under the arches long enough to dress for it: dock coat,
    # grey, and one rust-red scarf so he reads at night under sodium light.
    dict(id="joos", name="Joos", rank="?", skin="skinC",
         hair="short", hair_col=("#45404f", "#6b6577"),
         top=("#2a2633", "#45404f"), bottom="#14121a",
         accessory="scarf", accent="#8c4034", build="broad", brow="flat",
         mouth="flat", beard=True),

    # --- Essenveld Instituut students, added with the academy arc
    dict(id="ilse", name="Ilse Brandt", rank="9k", skin="skinD",
         hair="bob", hair_col=("#3b2a1f", "#8a6440"),
         top=("#367f72", "#63b3a0"), bottom="#2a2633",
         accessory="glasses", build="slim", brow="flat", mouth="small"),

    dict(id="sunny", name="Sunny Achebe", rank="6k", skin="skinC",
         hair="bun", hair_col=("#14121a", "#45404f"),
         top=("#c08f3a", "#f2d791"), bottom="#8c4034",
         accessory="none", build="slim", brow="raised", mouth="grin"),

    dict(id="orla", name="Orla Finn", rank="4k", skin="skinD",
         hair="tiedback", hair_col=("#8c4034", "#d99070"),
         top=("#23324e", "#3a5a7d"), bottom="#14121a",
         accessory="blazer", accent="#6d9ac0", build="slim", brow="angled",
         mouth="flat"),

    # --- passers-by -----------------------------------------------------
    # Traffic, not cast. They cross the street and leave: no name, no rank, no
    # dialogue, nothing to talk to. GAME_DESIGN P4 wants eight people who have
    # somewhere to be rather than a continent of villagers -- so these are not
    # villagers, they are the city those eight people live in.
    #
    # extra=True means no portrait is drawn: nothing ever puts them in a
    # dialogue box. gen_content.py has its own CAST list and never sees them,
    # and gen_nigiri_art.py names its crowd explicitly, so neither picks these
    # up by accident.
    dict(id="extra_commuter", name="a commuter", rank="", skin="skinA",
         hair="crop", hair_col=("#2a2633", "#45404f"),
         top=("#26232c", "#3a3644"), bottom="#2a2633",
         accessory="none", build="slim", brow="flat", mouth="flat", extra=True),

    dict(id="extra_shopper", name="a woman with shopping", rank="", skin="skinD",
         hair="bob", hair_col=("#5c4230", "#8a6440"),
         top=("#1f4a45", "#367f72"), bottom="#3b2a1f",
         accessory="scarf", accent="#63b3a0", build="broad", brow="flat",
         mouth="flat", extra=True),

    dict(id="extra_docker", name="a dockworker", rank="", skin="skinB",
         hair="cap", hair_col=("#3b2a1f", "#5c4230"),
         top=("#5e2a2a", "#8c4034"), bottom="#26232c",
         accessory="cap", build="broad", brow="angled", mouth="flat", extra=True),

    dict(id="extra_student", name="a student", rank="", skin="skinA",
         hair="tiedback", hair_col=("#3b2a1f", "#5c4230"),
         top=("#23324e", "#3a5a7d"), bottom="#2a2633",
         accessory="blazer", accent="#6d9ac0", build="slim", brow="flat",
         mouth="flat", extra=True),

    dict(id="extra_kid", name="a kid", rank="", skin="skinC",
         hair="curls", hair_col=("#14121a", "#2a2633"),
         top=("#8a6023", "#c08f3a"), bottom="#23324e",
         accessory="none", build="slim", brow="raised", mouth="smile", extra=True),

    # --- the Beginner Cup field. Fifteen kyu and below brings in people from the
    # rest of Verhaven who have never been down the steps at De Ketel, which is
    # the point of a city tournament: the first strangers the player ever plays.
    dict(id="abel", name="Abel Roos", rank="21k", skin="skinA",
         hair="short", hair_col=("#5c4230", "#8a6440"),
         top=("#367f72", "#5aa79a"), bottom="#45404f",
         accessory="none", build="broad", brow="raised", mouth="small"),

    dict(id="dov", name="Dov Halevi", rank="19k", skin="skinB",
         hair="curls", hair_col=("#14121a", "#3b2a1f"),
         top=("#8a6023", "#c08f3a"), bottom="#2a2633",
         accessory="glasses", build="slim", brow="flat", mouth="flat"),

    dict(id="moss", name="Moss Lindqvist", rank="16k", skin="skinD",
         hair="tiedback", hair_col=("#6b6577", "#bda98c"),
         top=("#45404f", "#6b6577"), bottom="#2a2633",
         accessory="scarf", accent="#8c4034", build="slim", brow="angled", mouth="flat"),
]

BY_ID = {c["id"]: c for c in CHARACTERS}

## The named cast, in the sense that matters: everybody who can be drawn in a
## dialogue box. Passers-by are excluded.
CAST_IDS = [c["id"] for c in CHARACTERS if not c.get("extra")]
