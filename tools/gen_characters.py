"""Draws every character's overworld sprite sheet and dialogue portrait.

Sprite sheet: 3 frames (idle, step A, step B) x 4 directions (down,left,right,up)
              at 16x24 -> 48x96 per character.
Portrait:     7 expressions at 64x64 -> 448x64, in the order of EXPRESSIONS below.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from png import Img
from palette import rgb, skin
from characters import CHARACTERS

W, H = 16, 24
DIRS = ["down", "left", "right", "up"]

# The portrait strip's column order. `src/rpg/npc/portrait_moods.gd` holds the
# same list for the game side, and tests/test_data.gd measures a real strip
# against it, because the only thing that goes wrong here goes wrong silently:
# an unknown mood name resolves to column 0 and the face simply never changes.
EXPRESSIONS = ["neutral", "happy", "annoyed", "working",
               "thinking", "worried", "pleased"]


# Walking proportions are independent of the portrait faces and approved shoulders.
from art_people import sprite_frame, sprite_sheet, action_sheet


# ==================================================================== portrait
# Head geometry, shared by every character so faces line up across the cast.
HEAD_X, HEAD_W = 17, 30      # 17..46
HEAD_TOP, HEAD_BOT = 11, 45
EYE_Y, BROW_Y, NOSE_Y, MOUTH_Y = 27, 22, 32, 37


def _head_mask(im, colour_mid, colour_light, colour_dark, shape="round"):
    """The bare head and neck: a rounded skull, jaw, and ears."""
    cx = HEAD_X + HEAD_W // 2
    im.rect(HEAD_X, HEAD_TOP + 5, HEAD_W, 27, colour_mid)
    im.disc(cx, HEAD_TOP + 12, 15, colour_mid)
    if shape == "square":
        im.rect(HEAD_X+2,HEAD_BOT-20,HEAD_W-4,18,colour_mid)
    else:
        im.disc(cx, HEAD_BOT - 10, 11 if shape == "narrow" else 14, colour_mid)
    # light from the upper left
    im.disc(cx - 5, HEAD_TOP + 11, 10, colour_light)
    im.rect(HEAD_X + 2, HEAD_TOP + 8, 10, 12, colour_light)
    # shade down the right cheek and under the jaw
    im.rect(HEAD_X + HEAD_W - 4, HEAD_TOP + 8, 4, 24, colour_dark)
    im.rect(HEAD_X + 4, HEAD_BOT - 5, HEAD_W - 8, 3, colour_dark)
    # ears
    im.rect(HEAD_X - 2, EYE_Y, 3, 6, colour_mid)
    im.rect(HEAD_X + HEAD_W - 1, EYE_Y, 3, 6, colour_dark)


def portrait(c, expression="neutral"):
    im = Img(64, 64)
    sk_d, sk_m, sk_l = skin(c["skin"])
    hair_d, hair_l = rgb(c["hair_col"][0]), rgb(c["hair_col"][1])
    top_d, top_l = rgb(c["top"][0]), rgb(c["top"][1])
    accent = rgb(c.get("accent", c["top"][1]))
    ink = rgb("ink0")
    acc = c.get("accessory", "none")

    # 1. background
    from palette import mix
    im.rect(0, 0, 64, 64, mix("paper1", c["top"][1], 0.18))
    im.rect(0, 0, 64, 30, mix("paper0", c["top"][1], 0.12))

    # 2. hair behind the head
    _hair_back(im, c, hair_d, hair_l)

    # 3. shoulders
    # Broad shoulders used to start five rows higher, joining Tomás's neck to
    # his shirt. The owner chose the same floating neckline as the slim cast;
    # scarves keep their deliberate connection between neck and clothing.
    shoulder_drop = 5 if c["build"] == "broad" and acc != "scarf" else 0
    im.disc(32, 78 + shoulder_drop, 29 if c["build"] == "broad" else 24, top_d)
    im.disc(30, 80 + shoulder_drop, 27 if c["build"] == "broad" else 22, top_l)
    im.rect(0, 62, 64, 2, top_d)
    if acc == "scarf":
        im.rect(16, 50, 32, 6, accent)
        im.rect(19, 55, 7, 9, accent)
    elif acc == "apron":
        im.rect(23, 54, 18, 10, accent)
    elif acc == "blazer":
        im.rect(17, 52, 6, 12, accent)
        im.rect(41, 52, 6, 12, accent)
    elif acc == "cardigan":
        im.rect(29, 52, 6, 12, accent)

    # 4. neck, then the head over everything behind it
    im.rect(27, HEAD_BOT - 6, 10, 12, sk_d)
    _head_mask(im, sk_m, sk_l, sk_d, c.get("face_shape","round"))

    # 5. fringe and side hair, over the forehead only
    _hair_front(im, c, hair_d, hair_l)

    # 6. face
    #
    # Seven expressions, from three features and the same geometry every
    # character shares, so identity survives the change. `annoyed` and `happy`
    # were the whole vocabulary until the opponent's portrait started reacting
    # to the board: one face had to carry losing a group, being cut, and being
    # asked a question, and it read as sulking. `worried` is `angled` inverted
    # -- inner brow ends UP, which is the one shape a scowl cannot be mistaken
    # for -- `thinking` narrows the lids without moving the mouth, and
    # `pleased` is the quiet version of `happy`, whose closed-eye grin is far
    # too much for taking four stones off.
    brow = c["brow"]
    if expression == "annoyed":
        brow = "angled"
    elif expression == "worried":
        brow = "worried"
    elif expression in ("happy", "pleased") and brow != "angled":
        brow = "raised"

    for i, ex in enumerate((23, 36)):
        if expression == "happy":
            im.hline(ex, EYE_Y + 2, 5, ink)
            im.set(ex, EYE_Y + 1, ink)
            im.set(ex + 4, EYE_Y + 1, ink)
        elif expression == "thinking":
            # Eyes off the board, up and to one side. A half-closed lid was the
            # first attempt and it is invisible at 64px: one pixel of eyelid on
            # a four-pixel eye is not an expression. Where somebody is looking
            # is legible at any size.
            im.rect(ex, EYE_Y + 1, 5, 4, rgb("paper0"))
            im.rect(ex + 2, EYE_Y + 1, 3, 2, ink)
            im.hline(ex, EYE_Y, 5, sk_d)
        else:
            im.rect(ex, EYE_Y + 1, 5, 4, rgb("paper0"))
            im.rect(ex + 1, EYE_Y + 2, 3, 2, ink)
            im.set(ex + 1, EYE_Y + 2, rgb("ink3"))
            im.hline(ex, EYE_Y, 5, sk_d)

        by = BROW_Y
        if brow == "raised":
            by -= 2
        for k in range(5):
            yy = by
            if brow == "angled":
                yy = by + (k if i == 0 else 4 - k) // 2
            elif brow == "worried":
                yy = by - (k if i == 0 else 4 - k) // 2 + 1
            im.rect(ex + k, yy, 1, 2, hair_d)

    im.rect(31, NOSE_Y, 2, 4, sk_d)
    im.set(30, NOSE_Y + 3, sk_d)

    mouth = c["mouth"]
    if expression == "happy":
        mouth = "grin"
    elif expression == "pleased":
        mouth = "smile"
    elif expression == "annoyed":
        mouth = "frown"
    elif expression == "worried":
        mouth = "small"
    elif expression == "thinking":
        mouth = "flat"
    if mouth == "flat":
        im.rect(28, MOUTH_Y, 8, 1, rgb("ink2"))
    elif mouth == "small":
        im.rect(30, MOUTH_Y, 4, 1, rgb("ink2"))
    elif mouth == "smile":
        im.rect(28, MOUTH_Y, 8, 1, rgb("ink2"))
        im.set(27, MOUTH_Y - 1, rgb("ink2"))
        im.set(36, MOUTH_Y - 1, rgb("ink2"))
    elif mouth == "frown":
        im.rect(28, MOUTH_Y, 8, 1, rgb("ink2"))
        im.set(27, MOUTH_Y + 1, rgb("ink2"))
        im.set(36, MOUTH_Y + 1, rgb("ink2"))
    else:   # grin
        im.rect(27, MOUTH_Y - 1, 10, 4, rgb("ink1"))
        im.rect(28, MOUTH_Y, 8, 2, rgb("paper0"))

    if c.get("beard"):
        im.rect(21, MOUTH_Y - 4, 22, 11, hair_d)
        im.rect(26, MOUTH_Y - 3, 12, 5, sk_d)
        im.rect(28, MOUTH_Y, 8, 1, rgb("ink2"))
        im.rect(24, MOUTH_Y - 5, 16, 2, hair_d)

    # 7. glasses last, so they sit on the face
    if acc == "glasses":
        im.frame(21, EYE_Y, 9, 7, rgb("ink1"))
        im.frame(34, EYE_Y, 9, 7, rgb("ink1"))
        im.hline(30, EYE_Y + 2, 4, rgb("ink1"))
        im.hline(16, EYE_Y + 1, 5, rgb("ink1"))
        im.hline(43, EYE_Y + 1, 5, rgb("ink1"))

    # A scene-specific object and hand make the working expression readable.
    if expression == "working":
        pose=c.get("activity","read")
        if pose == "read":
            im.rect(11,49,42,14,rgb("teal0"));im.rect(14,50,36,10,rgb("paper1"))
            im.vline(32,50,11,rgb("wood1"))
        elif pose == "fold":
            im.rect(10,52,43,11,rgb("paper1"));im.hline(11,57,41,rgb("blue1"))
        elif pose == "wipe":
            im.rect(30,53,25,9,rgb("paper0"))
        else:
            im.disc(39,54,5,rgb("ink0"))
        im.rect(10,51,7,5,sk_m);im.rect(47,51,7,5,sk_m)
    im.frame(0, 0, 64, 64, rgb("ink1"))
    return im


def _hair_back(im, c, hair_d, hair_l):
    """The mass of hair that sits behind the head silhouette."""
    style = c["hair"]
    if style == "long":
        im.rect(12, 16, 40, 44, hair_d)
        im.rect(12, 18, 6, 34, hair_l)
    elif style == "bob":
        im.rect(13, 16, 38, 30, hair_d)
        im.rect(13, 18, 6, 22, hair_l)
    elif style == "curls":
        for cx, cy in ((17, 20), (24, 12), (33, 11), (42, 15), (47, 24), (15, 30), (49, 31)):
            im.disc(cx, cy, 7, hair_d)
            im.disc(cx - 2, cy - 2, 4, hair_l)
    elif style == "bun":
        im.disc(32, 9, 8, hair_d)
        im.disc(30, 7, 5, hair_l)
        im.rect(16, 14, 32, 16, hair_d)
    elif style == "tiedback":
        im.rect(28, 3, 9, 12, hair_d)
        im.rect(30, 1, 4, 8, hair_l)
        im.rect(15, 14, 34, 26, hair_d)
    elif style in ("crop", "short"):
        im.rect(15, 13, 34, 20, hair_d)
    elif style == "cap":
        im.rect(15, 16, 34, 18, hair_l)


def _hair_front(im, c, hair_d, hair_l):
    """Fringe and sideburns. Shaped, never erased -- erasing punches holes."""
    style = c["hair"]
    top = HEAD_TOP
    if style == "cap":
        im.rect(13, top - 1, 38, 9, rgb(c.get("accent", "#7a6a58")))
        im.rect(13, top - 1, 19, 5, rgb("path2"))
        im.rect(11, top + 8, 42, 4, rgb("path0"))
        im.hline(11, top + 12, 42, rgb("ink2"))
        im.rect(15, top + 13, 5, 9, hair_l)
        im.rect(44, top + 13, 5, 9, hair_l)
        return

    # A cap of hair with a rounded top and a fringe line above the brows.
    fringe = top + 8
    for x in range(14, 50):
        d = abs(x - 32)
        if d > 17:
            continue
        crown = top - 3 + (0 if d <= 11 else (d - 11))
        hem = fringe if d <= 12 else fringe + 4      # longer at the temples
        if style in ("long", "bob", "tiedback", "bun"):
            hem = fringe if d <= 10 else fringe + 6
        im.rect(x, crown, 1, hem - crown + 1, hair_d)
    # highlight, upper left
    for x in range(19, 31):
        d = abs(x - 32)
        crown = top - 3 + (0 if d <= 11 else (d - 11))
        im.rect(x, crown + 1, 1, 4, hair_l)

    if style == "short":
        im.rect(15, top + 2, 4, 12, hair_d)
        im.rect(45, top + 2, 4, 12, hair_d)
    elif style == "bob":
        im.rect(13, top + 2, 6, 28, hair_d)
        im.rect(45, top + 2, 6, 28, hair_d)
        im.rect(13, top + 4, 3, 16, hair_l)
    elif style == "long":
        im.rect(12, top + 2, 6, 38, hair_d)
        im.rect(46, top + 2, 6, 38, hair_d)
        im.rect(12, top + 4, 3, 22, hair_l)
    elif style == "curls":
        for cx, cy in ((17, top + 5), (25, top - 2), (39, top - 2), (47, top + 5),
                       (14, top + 14), (50, top + 14)):
            im.disc(cx, cy, 6, hair_d)
            im.disc(cx - 1, cy - 1, 3, hair_l)
    elif style == "bun":
        im.rect(15, top + 1, 4, 10, hair_d)
        im.rect(45, top + 1, 4, 10, hair_d)
    elif style == "tiedback":
        im.rect(14, top + 1, 5, 14, hair_d)
        im.rect(45, top + 1, 5, 14, hair_d)



def build(out_sprites, out_portraits, *, sprites=True, portraits=True):
    if sprites: os.makedirs(out_sprites, exist_ok=True)
    if portraits: os.makedirs(out_portraits, exist_ok=True)
    for c in CHARACTERS:
        if sprites:
            sprite_sheet(c).save(os.path.join(out_sprites, "%s.png" % c["id"]))
            action_sheet(c).save(os.path.join(out_sprites, "%s_actions.png" % c["id"]))
        # Passers-by never reach a dialogue box, so they get no portrait: a
        # portrait strip of somebody with no name is dead weight in the repo.
        if c.get("extra") or not portraits:
            continue
        strip = Img(64 * len(EXPRESSIONS), 64)
        for i, expr in enumerate(EXPRESSIONS):
            strip.blit(portrait(c, expr), i * 64, 0)
        strip.save(os.path.join(out_portraits, "%s.png" % c["id"]))
    return len(CHARACTERS)


if __name__ == "__main__":
    here = os.path.dirname(__file__)
    print(build(os.path.join(here, "..", "art", "sprites"),
                os.path.join(here, "..", "art", "portraits")))
