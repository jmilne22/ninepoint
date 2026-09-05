"""Rebuilds every generated asset -- art and audio -- deterministically."""
import os
import sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
root = os.path.join(here, "..")

import gen_tiles, gen_characters, gen_ui, gen_title, gen_audio
import gen_venue_props, gen_venue_scenes, gen_arrivals
import gen_font, gen_nigiri_art, gen_tileset_resource, gen_props

print("tiles     ", gen_tiles.build(os.path.join(root, "art", "tiles")))
# The TileSet resource lists one entry per atlas cell, so it MUST be rebuilt
# whenever the atlas gains a row -- a tile outside it is drawn as a hole, in
# silence. That is exactly how the city's windows and road came out black.
print("tileset   ", gen_tileset_resource.build()[1], "cells")
print("characters", gen_characters.build(os.path.join(root, "art", "sprites"),
                                         os.path.join(root, "art", "portraits")))
print("props     ", len(gen_props.build(os.path.join(root, "art", "props"))))
print("venues    ", gen_venue_props.build(os.path.join(root, "art", "props")))
print("landmarks ", gen_venue_scenes.build(os.path.join(root, "art", "props")))
print("arrivals  ", gen_arrivals.build(os.path.join(root,"art","props")))
print("ui        ", gen_ui.build(os.path.join(root, "art", "ui")))
print("title     ", gen_title.build(os.path.join(root, "art", "title")))
print("font      ", gen_font.build(os.path.join(root, "art", "ui")))
print("ceremony  ", gen_nigiri_art.build(os.path.join(root, "art", "ui"))["hands"])
print("audio     ", len(gen_audio.build(os.path.join(root, "audio"))), "sounds")
