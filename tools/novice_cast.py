"""Novice playtest cohort. Rank targets need independent human validation.

Temperatures are fixed per opponent and never read player progress. The underlying
Human-SL profile is 20k; these are deliberately separate from the town's configs.
"""

NOVICES = [
    dict(id="noor", name="Noor Dekker", rank="30k", temperature=4.0,
         blurb="Keeps a postcard under her bowl. Has just learned to play.",
         skin="skinB", hair="bob", top=("#63406b", "#96699e"), accessory="scarf"),
    dict(id="ivo", name="Ivo Maas", rank="27k", temperature=2.75,
         blurb="A bicycle courier with a pencil behind his ear.",
         skin="skinD", hair="crop", top=("#5e2a2a", "#b8624a"), accessory="none"),
    dict(id="lea", name="Lea Vos", rank="25k", temperature=2.0,
         blurb="Brings scrap paper from the print shop for game records.",
         skin="skinA", hair="curls", top=("#47693c", "#92ad5c"), accessory="glasses"),
    dict(id="emil", name="Emil Bakker", rank="23k", temperature=1.5,
         blurb="Repairs bicycle lamps. Likes to put a position back and try again.",
         skin="skinD", hair="short", top=("#3a5a7d", "#a8cbe0"), accessory="cardigan"),
    dict(id="sora", name="Sora Meijer", rank="20k", temperature=1.0,
         blurb="Leaves a spare cushion on the chair across her board.",
         skin="skinC", hair="tiedback", top=("#8a6440", "#d6c4a8"), accessory="none"),
]


def opponents():
    return [dict(c, mistake=0.5, depth=0, aggr=1.0, terr=1.0, resign=0.0,
                 style="balanced", novice=True) for c in NOVICES]


def characters():
    return [dict(c, hair_col=("#3b2a1f", "#8a6440"), bottom="#2a2633",
                 accent=c["top"][1], build="broad" if c["id"] == "emil" else "slim",
                 brow="raised" if c["id"] == "ivo" else "flat", mouth="smile")
            for c in NOVICES]
