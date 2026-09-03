"""UI frame, icons, and the application icon."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from png import Img, Rand
from palette import rgb


def panel():
    """24x24 nine-patch: 6px margins, hard corners, one-pixel drop shadow."""
    im = Img(24, 24)
    im.rect(0, 0, 23, 23, rgb("ink1"))
    im.rect(1, 1, 21, 21, rgb("paper0"))
    im.rect(2, 2, 20, 20, rgb("paper0"))
    im.frame(1, 1, 22, 22, rgb("ink1"))
    im.frame(2, 2, 20, 20, rgb("paper1"))
    # drop shadow along the bottom and right
    im.rect(1, 23, 23, 1, rgb("ink0"))
    im.rect(23, 1, 1, 23, rgb("ink0"))
    # corner cuts
    for c in ((1, 1), (22, 1), (1, 22), (22, 22)):
        im.set(c[0], c[1], (0, 0, 0, 0))
    return im


def dark_panel():
    im = Img(24, 24)
    im.rect(0, 0, 23, 23, rgb("ink0"))
    im.rect(1, 1, 21, 21, rgb("ink1"))
    im.frame(2, 2, 20, 20, rgb("ink2"))
    im.rect(1, 23, 23, 1, rgb("ink0"))
    im.rect(23, 1, 1, 23, rgb("ink0"))
    return im


ICONS = []


def icon(name):
    def deco(fn):
        ICONS.append((name, fn))
        return fn
    return deco


@icon("stone_black")
def _(im):
    im.disc(8, 8, 6, rgb("stoneB0"))
    im.disc(6, 6, 2, rgb("stoneB1"))
    im.disc(8, 9, 6.4, None)


@icon("stone_white")
def _(im):
    im.disc(8, 8, 6, rgb("stoneW1"))
    im.disc(9, 9, 5, rgb("stoneW0"))
    im.disc(6, 6, 2, rgb("stoneW1"))


@icon("board")
def _(im):
    im.rect(1, 2, 14, 12, rgb("board1"))
    im.frame(1, 2, 14, 12, rgb("line"))
    for i in (4, 7, 10):
        im.vline(i, 3, 10, rgb("line"))
        im.hline(2, i - 1, 12, rgb("line"))
    im.disc(4, 3, 1.5, rgb("stoneB0"))
    im.disc(10, 9, 1.5, rgb("stoneW1"))


@icon("book")
def _(im):
    im.rect(2, 2, 12, 12, rgb("rust1"))
    im.rect(2, 2, 3, 12, rgb("rust0"))
    im.rect(6, 4, 7, 8, rgb("paper0"))
    im.hline(7, 6, 5, rgb("ink3"))
    im.hline(7, 8, 5, rgb("ink3"))


@icon("ticket")
def _(im):
    im.rect(1, 4, 14, 8, rgb("gold2"))
    im.frame(1, 4, 14, 8, rgb("gold0"))
    im.set(5, 4, (0, 0, 0, 0))
    im.set(5, 11, (0, 0, 0, 0))
    im.hline(7, 7, 6, rgb("gold0"))
    im.hline(7, 9, 4, rgb("gold0"))


@icon("key")
def _(im):
    im.disc(5, 6, 3, rgb("gold1"))
    im.disc(5, 6, 1.2, None)
    im.rect(7, 6, 7, 2, rgb("gold1"))
    im.rect(12, 8, 2, 2, rgb("gold1"))
    im.rect(9, 8, 2, 2, rgb("gold1"))


@icon("cup")
def _(im):
    im.rect(3, 5, 9, 7, rgb("paper0"))
    im.rect(3, 5, 9, 2, rgb("paper1"))
    im.hline(3, 12, 9, rgb("ink2"))
    im.rect(12, 7, 2, 3, rgb("paper1"))
    im.set(6, 3, rgb("ink3"))
    im.set(9, 2, rgb("ink3"))


@icon("rank")
def _(im):
    for dx, dy in ((0, -5), (5, -1), (3, 5), (-3, 5), (-5, -1)):
        im.disc(8 + dx * 0.6, 8 + dy * 0.6, 3, rgb("gold2"))
    im.disc(8, 8, 4, rgb("gold3"))
    im.disc(8, 8, 2, rgb("gold1"))


def icons_sheet():
    sheet = Img(16 * len(ICONS), 16)
    names = {}
    for i, (name, fn) in enumerate(ICONS):
        t = Img(16, 16)
        fn(t)
        sheet.blit(t, i * 16, 0)
        names[name] = i
    return sheet, names


def app_icon():
    im = Img(64, 64)
    im.rect(0, 0, 64, 64, rgb("board1"))
    im.frame(0, 0, 64, 64, rgb("line"))
    for i in range(1, 8):
        im.vline(i * 8, 4, 56, rgb("line"))
        im.hline(4, i * 8, 56, rgb("line"))
    im.disc(24, 24, 7, rgb("stoneB0"))
    im.disc(21, 21, 3, rgb("stoneB1"))
    im.disc(40, 40, 7, rgb("stoneW1"))
    im.disc(42, 42, 5, rgb("stoneW0"))
    im.disc(38, 38, 2, rgb("stoneW1"))
    return im


def build(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    panel().save(os.path.join(out_dir, "panel.png"))
    dark_panel().save(os.path.join(out_dir, "panel_dark.png"))
    sheet, names = icons_sheet()
    sheet.save(os.path.join(out_dir, "icons.png"))
    app_icon().save(os.path.join(out_dir, "icon.png"))
    return names


if __name__ == "__main__":
    print(build(os.path.join(os.path.dirname(__file__), "..", "art", "ui")))
