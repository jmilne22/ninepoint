## Shared UI construction, so the panels agree with each other and with the font.
##
## The three board scenes each hand-rolled a _label() helper and hard-coded card
## sizes, which is how prose ended up running off the bottom of a card. Cards
## are now measured against the text they hold.
class_name UiKit
extends RefCounted

const FONT: Font = preload("res://art/fonts/DejaVuSans.ttf")
## Logical text size; outline glyphs render at the window's native resolution.
const FONT_SIZE := 9
const LINE_H := 11
const PAD := 10

const VIEW := Vector2(384, 216)

const INK := Color("#243b33")
const INK_SOFT := Color("#526b5e")
const INK_FAINT := Color("#718477")
const GOLD := Color("#926b36")
const PAPER := Color("#f4eddf")
const TEAL := Color("#477c6b")
const RUST := Color("#a5624d")


static func label(parent: Node, pos: Vector2, width: int, colour: Color,
        height: int = 0) -> Label:
    var l := Label.new()
    l.position = pos
    l.size = Vector2(width, height if height > 0 else LINE_H)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_override("font", FONT)
    l.add_theme_font_size_override("font_size", FONT_SIZE)
    l.add_theme_color_override("font_color", colour)
    parent.add_child(l)
    return l


## Compatibility helper for artwork labels; clear outline type needs no pixel shadow.
static func shadow_label(parent: Node, pos: Vector2, width: int, colour: Color,
        size: int = FONT_SIZE, _offset: int = 1) -> Label:
    var l := Label.new()
    l.position = pos
    l.size = Vector2(width, LINE_H * (size / FONT_SIZE))
    l.add_theme_font_override("font", FONT)
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", colour)
    l.add_theme_color_override("font_shadow_color", INK)
    l.add_theme_constant_override("shadow_offset_x", 0)
    l.add_theme_constant_override("shadow_offset_y", 0)
    parent.add_child(l)
    return l


static func panel(parent: Node, rect: Rect2, dark: bool = false) -> NinePatchRect:
    var p := SurfacePanel.new()
    p.dark = dark
    for m in ["left", "top", "right", "bottom"]:
        p.set("patch_margin_%s" % m, 6)
    p.position = rect.position
    p.size = rect.size
    p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    parent.add_child(p)
    return p


## How tall `text` is when wrapped to `width`.
static func text_height(text: String, width: int) -> int:
    var size := FONT.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT,
        float(width), FONT_SIZE)
    return int(ceil(size.y))


## Grows or shrinks a card so its text fits, and re-centres it. Long prose is
## the normal case in a teaching game, so this must never clip.
static func fit_card(card: Control, body: Label, text: String,
        max_width: int = 300) -> void:
    var inner := max_width - PAD * 2
    body.text = text
    # A Label's own wrapping does not always agree with get_multiline_string_size
    # to the pixel, so carry a line of slack. Being a line too tall is invisible;
    # being a line too short pushes the last line outside the card.
    var h := text_height(text, inner) + LINE_H
    var card_h: int = mini(int(VIEW.y) - 16, h + PAD * 2)
    card.size = Vector2(max_width, card_h)
    card.position = Vector2(floor((VIEW.x - max_width) * 0.5),
        floor((VIEW.y - card_h) * 0.5))
    body.position = Vector2(PAD, PAD)
    body.size = Vector2(inner, card_h - PAD * 2)


## Wraps text to a width, splitting into as many cards as it takes. Used where a
## single explanation is longer than one screen.
static func paginate(text: String, width: int, max_height: int) -> PackedStringArray:
    var pages := PackedStringArray()
    var current := ""
    for paragraph in text.split("\n\n"):
        for word in paragraph.split(" "):
            var candidate := word if current == "" else current + " " + word
            if current != "" and text_height(candidate, width) > max_height:
                pages.append(current.strip_edges())
                current = word
            else:
                current = candidate
        if current != "":
            current += "\n\n"
    if current.strip_edges() != "":
        pages.append(current.strip_edges())
    return pages
