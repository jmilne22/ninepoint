# NINEPOINT — Art Direction

## 0. Tooling note (read this first)

All art remains deterministic Python-generated pixel art. Use `tools/build_assets.py` to
rebuild assets through the pure-Python PNG writer. Shared records in `tools/characters.py`
drive walking sprites, action sheets and portraits. This pipeline is an intentional part of
Ninepoint's visual identity.

---

## 1. Visual identity in one paragraph

A working port city in the wet: brick, tram rails set into cobbles, grey stucco, slate and
rust roofs, a canal the colour of the sky, one damp green park. Top-down 3/4 perspective at
16×16 tiles, chunky readable pixels, no anti-aliasing, no dithering except in large flat
areas. Colour is muted everywhere **except the Go board**, which is warm honey wood with pure
black and off-white stones — the one saturated, high-contrast object in the world. The eye
should always be able to find a board. The city is where you live; the board is where you
*are*.

The city is drawn at one hour: the muted daylight register above. It had four hours and
rain from M16 to M36 (`Ambient`, a `CanvasModulate` and a glow per lit tile), cut in M37
with the calendar. The tiles still carry their lit windows, the neon still faults and the
snack window still glows in its own pixels; nothing tints the world over them.

## 2. Palette

The foundation is a set of hand-picked colour ramps for the town, people and board.
Quiet floor details may mix neighbouring tones within these ramps. `tools/palette.py` is the source of
truth and this section mirrors it.

### Ink & neutrals
| Name | Hex | Use |
|---|---|---|
| `ink0` | `#14121a` | Outlines, black stones, text |
| `ink1` | `#2a2633` | Deep shadow, UI frame |
| `ink2` | `#45404f` | Mid shadow, stone shadow |
| `ink3` | `#6b6577` | Soft shadow, disabled text |
| `paper0` | `#f2e9d8` | Walls, white stones, UI panel |
| `paper1` | `#ddd0b8` | Wall shade, panel shade |
| `paper2` | `#bda98c` | Wall deep shade, plaster |

### Greens — park, hedges, moss
| `grass0` `#2f4a30` | `grass1` `#47693c` | `grass2` `#6b8f4a` | `grass3` `#92ad5c` |

### Browns — wood, paths, earth
| `wood0` `#3b2a1f` | `wood1` `#5c4230` | `wood2` `#8a6440` | `wood3` `#b08a5c` |
| `path0` `#7a6a58` | `path1` `#9c8a72` | `path2` `#bda98c` | `path3` `#d6c4a8` |

### Blues — water, sky, glass, night
| `blue0` `#23324e` | `blue1` `#3a5a7d` | `blue2` `#6d9ac0` | `blue3` `#a8cbe0` |

### Warm accents — roofs, signage, autumn
| `rust0` `#5e2a2a` | `rust1` `#8c4034` | `rust2` `#b8624a` | `rust3` `#d99070` |
| `gold0` `#8a6023` | `gold1` `#c08f3a` | `gold2` `#e0b25c` | `gold3` `#f2d791` |

### The city — wet brick, wet road, one cold tube
| `brick0` `#43292b` | `brick1` `#63403c` | `brick2` `#85574c` | `brick3` `#a57263` |
| `asphalt0` `#26232c` | `asphalt1` `#3a3644` | `asphalt2` `#524d5e` | |
| `neon0` `#4fb8c8` | `neon1` `#9fe4ec` | | |

Brick is deliberately browner and greyer than `rust`, which stays a roof-and-signage red.
There is **no sodium ramp**: a Verhaven street lamp is exactly `gold1`/`gold2`, which is why
the town's warm accents were already the right colour for night. The neon is cold and
deliberately dimmer than `board1` — nothing in the city may out-saturate the board, so the
one tube on Ketelsteeg is a cyan and not a pink.

### Cool accents — plum (club/teacher), teal (café)
| `plum0` `#3a2340` | `plum1` `#63406b` | `plum2` `#96699e` |
| `teal0` `#1f4a45` | `teal1` `#367f72` | `teal2` `#63b3a0` |

### Go board (deliberately outside the town's muted range)
| `board0` `#a97b3c` | `board1` `#d9ac66` | `board2` `#eccd96` | `line` `#3a2a18` |
| `stoneB0` `#0d0b10` | `stoneB1` `#2e2a35` | `stoneW0` `#cfc6b4` | `stoneW1` `#f7f2e6` |

### Skin ramps (4 tones × 3 steps) — used by both sprites and portraits
| Tone | shadow | base | light |
|---|---|---|---|
| `skinA` | `#8a5a44` | `#b2795c` | `#d6a183` |
| `skinB` | `#5e3a2c` | `#84543c` | `#a8735a` |
| `skinC` | `#3d2620` | `#5c3a2e` | `#7d5240` |
| `skinD` | `#a87a5e` | `#d6a583` | `#f0c9a8` |

## 3. Tiles

- **16×16**, single atlas `art/tiles/town_tileset.png`, 16 columns wide.
- One coherent set, drawn by one generator, sharing one light direction: **top-left**.
- Terrain uses 3-value shading only (dark / base / light). No gradients.
- Walkability, not decoration, decides tile identity: every solid tile is visibly solid
  (a wall has a top face and a shaded side; a fence has posts).
- Everyday traces live on the decor layer: cups, papers, satchels, chalk and laundry
  make a room or route feel used without changing collision, hiding a doorway, or
  competing with an interactable. Reuse generated prop tiles rather than placing one-off pixels.
- Interiors reuse the same atlas plus an interior strip (floorboards, mats, shelving, tables,
  De Ketel's board tables).
- **Nothing in code refers to an atlas index.** `TileAtlas.at(name)` resolves every tile
  through `art/tiles/tileset_manifest.json`, so the atlas can grow a row without touching
  GDScript. The manifest is the truth; the table below is a summary of it.

Atlas families, 16 tiles per row (`python3 tools/gen_tiles.py` prints the current shape)
```
 0  ground: grass ×4, cobble ×2, pavement, gravel, dirt, kerb, water, plank, step, drain, void
 1  buildings: plaster, brick, wall base, doors, roofs, chimney, awning, signs, lamp post
 2  outdoor props: fence, hedge, tree 2×2, bush, bench, planter, stone table, board, barrel
 3  interiors: floorboards, mat, rug, wall, window, shelf, counter, go tables, chair, kettle
 4  the city: asphalt, puddle, tram rails, wet cobble, canal, quay, bollard, bike rack,
    tram pole, brick window, wet brick base, graffiti, shutter, dead sign, arch
 5  the city: arch, arch shade, neon, snack window, steps down, concrete, glass curtain,
    the stove and the coat hooks at De Ketel, poured floor
 6  the wassalon: the washing machine, two frames. Enamel and a control panel, and a
    porthole that is the only warm thing in the tile -- it is a light source as well as
    an animation, because that room has no stove and no music and the machines have to
    be what says it is warm
```

**Whenever the atlas gains a row, `town_tileset.tres` must be regenerated and the PNG
reimported.** A tile outside the resource is drawn as nothing, in silence: that is exactly how
the city's first build came out with black holes where its windows and road should have been.
`tools/build_assets.py` now runs `gen_tileset_resource.py` for this reason, and `tools/test.sh`
does the reimport pass.

## 4. Characters

**One template, many people.** Every character is drawn by the same routine from a record:

```python
Character(
  id="kesh", name="Kesh Idowu", skin="skinB",
  hair="short_curl", hair_col=("#3a2340","#63406b"),   # dyed plum — hers alone
  top=("#8c4034","#b8624a"), bottom=("#2a2633",),
  build="slim", accessory="scarf", brow="angled", mouth="flat",
)
```

- **Overworld sprite:** 16×24 (feet at bottom of a 16×16 grid cell, head overhangs upward).
  4 directions × 3 frames (idle, step-left, step-right). Silhouette first: hair shape and
  top colour must identify the character at 100% zoom from across the street.
- **Portrait:** 64×64 bust for dialogue, same skin ramp, same hair colours, same garment
  colours, same accessory. Because both come from one record, the portrait *is* the sprite,
  scaled and detailed — the classic consistency failure is structurally impossible.
- Faces are minimal: eyes are 2×2 blocks, brows carry the whole expression, mouths are 1–3px.
  Expression variants (`neutral`, `happy`, `annoyed`, `working`) retain the same identity;
  the working pose adds the character’s activity and hand position.

Character colour signatures (never reused between characters):
| Wren `gold` · Kesh `plum+rust` · Pip `grass` · Bertie `wood+path` · Nadia `blue` ·
Hana `plum0 deep` · Tomás `teal` · Marguerite `ink+gold` · Player `paper+blue` |

## 4b. Type

Text is set in a **generated 5x7 bitmap font** (`tools/font5x7.py`, rendered by
`tools/gen_font.py` to a PNG page plus a BMFont `.fnt` that Godot imports as a `FontFile`).

Godot's default face is a vector font: at 9px it anti-aliased every glyph and put **157
distinct colours** into one small patch of the match panel, which at 384x216 reads as fuzz.
The bitmap font uses exactly two colours -- paper and ink -- and lands on whole pixels. The
same patch now measures 2 colours.

Rules that follow from using a bitmap font:
- **Native size is 9, and only integer multiples of it are allowed** (9, 18, 27). Anything
  else scales the bitmap and undoes the point of it.
- The project sets `window/stretch/scale_mode = "integer"`, so the 384x216 framebuffer is
  never fractionally upscaled.
- Cards that hold prose are measured against their text (`UiKit.fit_card`) and paginated if
  they overflow (`UiKit.paginate`). Nothing is allowed to run off the bottom of a panel.

## 4c. The nigiri ceremony

Deciding the colours is a set piece, and its structure is borrowed from **HammerLock
Wrestling** (SNES, 1994) -- a game with indifferent play and one genuinely good idea:
the screen split into three horizontal windows showing the crowd, the ring, and a close-up
of the action all at once, animated broadly and slowly.

| Window | Height | Holds |
|---|---|---|
| Crowd | 34px | The club, watching. Heads drawn from the cast's own hair and garment colours (`crowd.png`) |
| Ring | 104px | The bowl and the hand, at **2x**, plus the stones as they land and the running count |
| Close-up | 70px | The opponent's portrait, the prompt, and the call in gold |

Animation follows the era: anticipation before every movement (the hand rises and *hangs*
before it dives), squash and stretch on the dive, a held pose that breathes while you decide,
the call slamming in at 3x scale with an overshoot and a screen kick, and stones that bounce
as they land. The windows wipe in from alternating sides.

The ceremony is presentation only. `GoMatchSetup` decides the outcome; the animation is told
what happened and performs it. It runs at full speed even under the autopilot, because a
screenshot of a sped-up set piece is not a screenshot of the set piece.

Art added for it: `bowl.png`, `hands.png` (4 skin tones x 3 poses, drawn as explicit pixel
art -- stacked circles read as a potato), `crowd.png`.

## 5. UI

- Panels: `paper0` fill, `ink1` 1px border, `ink2` 1px drop shadow, 4px corner cut (no rounding).
- Dialogue box: bottom-anchored, 64×64 portrait at left, name plate above the frame in `gold2`.
- Font: the generated Ninepoint bitmap font at native size 9 and integer multiples only. Text `ink0` on paper, `paper0` on ink.
- Everything snaps to the pixel grid; the camera is pixel-snapped; no rotation, no scaling
  that is not an integer multiple.
- Icons 16×16, single-colour silhouettes plus one accent (stone, book, ticket, key, cup).

## 6. The Go board

The board renders into a fixed square area, computing an integer cell size so lines
land on exact pixels. 19×19 has a whole-board overview with alternate coordinate labels
and a V-toggled close view. The close view starts at nine visible lines (a starting value
checked on crowded positions), keeps global coordinates and star points, and follows the
cursor within the true board bounds. Short continuation ticks cross cropped grid edges;
true board edges have none. The targeted coordinate is written below the board while a point is selected.
Mouse hover uses corner brackets and a translucent stone on empty points during the
player's turn. The preview conveys targeting, not legality; rejected clicks retain their
existing explanation. Counting uses teal outlines on the hovered chain. Reviews use the
brackets without a placement preview. Review offer choices sit inside the measured card
and highlight in warm paper on hover; their visible rows are the click targets.
Coordinates and compact paper buttons sit below
the board; hover never pans the close view. The seven-line layout reserves its larger
wood margin so it stays clear of the opponent panel. Other sizes retain their spacing. Review positions use the same transform. Star points on 9×9 at (3,3),(3,7),(7,3),(7,7),(5,5) in
1-indexed coordinates. Stones are circles with a 1px `ink0` rim, a 2px highlight at upper-left
(`stoneW1`/`stoneB1`), and a soft `ink2` shadow offset down-right by 1px. The last move carries
a small ring in the *opposite* stone colour; territory in scoring mode is shown as small squares
**and** a diagonal hatch so it reads without colour.

## 7. Screen and camera

- Base resolution **384×216** (16:9, exactly 24×13.5 tiles), integer-scaled to the window.
  `viewport` stretch, `keep` aspect, integer scale mode. At 1280×720 it lands on 3×
  with letterboxing; the normal 1152×648 play window is exactly 3×.
- Camera follows the player with a 1-frame deadzone, clamped to map bounds, pixel-snapped.
  A map **smaller** than the screen is centred, not pinned to the top-left: the limits are
  widened equally on both sides, and `World._build_backdrop()` paints `ink0` behind the tiles
  so the frame around a small room — and an unlit alley — reads as shadow rather than as a
  missing tile.

## 7c. Tiles that move

`src/rpg/maps/tile_animator.gd`. Water, the canal, the neon, the stove, the washers and the go
tables cycle through frames.

Godot's TileSet animates a tile natively, but it wants the frames in **consecutive atlas cells**,
and `gen_tiles.py` packs strictly `i % 16` with no way to control adjacency. Taking the native
route therefore means rewriting the packer and hand-editing the generated `.tres` — the exact
file §3 warns is silently fatal to get wrong. Cycling cells by **tile name** instead costs a few
hundred `set_cell` calls a second, touches neither, and lets a frame live anywhere in the atlas:
frames are ordinary tiles called `water_f1`, `canal_f2`, and frame 0 *is* the base tile, so
parking an animation is a no-op.

Two rules the look depends on:

- **Phase per cell.** The canal is 156 tiles on the quay. Animated in lockstep it reads as a
  screensaver; offset along the diagonal by `(x + y)`, it reads as water travelling.
- **Holds are per frame, not a frame rate.** The interesting ones are uneven. The neon sits lit
  for 4.5 seconds and dark for 0.16 — an even blink is a decoration, an uneven one is a fault.

The go table is the one that earns the most: its three frames are the *same game with more
stones on it*, so a table in the corner of De Ketel is a game getting longer while you talk to
somebody. Paired with the `stone_place` emitter in `Soundscape`, that is the whole of "somebody
is playing over there", and it costs one row in a table.

## 8. Venue composition and activity

The eleven maps have different dominant objects. The attic has a sloping roof and skylight;
De Ketel has a counter, teaching table and recessed back table; the wassalon has a machine
bank, folding counter and bench; Onderbrug has sheltered arches and Joos's dry equipment
corner. The quay keeps open water and a clearly labelled review board.

The Instituut is a broad glass-and-concrete reception room with branching corridors.
The Bondszaal is a long civic hall with tall windows, twelve numbered tournament tables,
coats and tea, with registration beside the entrance. Distinct generated exterior views
appear during tram travel and can be skipped with Space or Esc.

`gen_venue_props.py` and `gen_venue_scenes.py` draw larger readable furniture. Their base
footprints live in `venue_layouts.py`; foreground faces remain clear of interaction paths.
`gen_arrivals.py` draws the destination views. Grass, brick, water and floor patterns are
restrained so people, doors and boards carry more contrast. Wear belongs near chairs,
thresholds and working surfaces.

Walking sheets retain their 3-by-4 frame contract. Optional action sheets contain two
frames in each facing direction for seated play, reading, folding, wiping and arranging. Heights, head shapes,
shoulders and props distinguish characters; portraits have a fourth working pose. Activities
pause immediately for conversation, then resume. Match backgrounds borrow quiet venue
colours while preserving the board and text contrast; standalone matches use a neutral room.
