## The column order of a character's portrait strip, in one place.
##
## `tools/gen_characters.py` draws the strip and holds the same list; it was
## duplicated in `dialogue_box.gd` and again, as bare column numbers, in
## `nigiri_ceremony.gd`, and the failure mode is silent: an unknown mood name
## resolves to column 0 and the face simply never changes. `tests/test_data.gd`
## measures a real portrait against this list so the two cannot drift.
class_name PortraitMoods
extends RefCounted

const SIZE := 64

const COLUMNS := ["neutral", "happy", "annoyed", "working",
    "thinking", "worried", "pleased"]


static func column(mood: String) -> int:
    var i := COLUMNS.find(mood)
    return i if i >= 0 else 0


## The slice of a portrait strip for one mood.
static func region(mood: String) -> Rect2:
    return Rect2(column(mood) * SIZE, 0, SIZE, SIZE)


## The strip for `texture`, cut to one mood. Null in, null out, so a speaker
## with no portrait costs the caller no branch.
static func slice(texture: Texture2D, mood: String) -> AtlasTexture:
    if texture == null:
        return null
    var at := AtlasTexture.new()
    at.atlas = texture
    at.region = region(mood)
    return at
