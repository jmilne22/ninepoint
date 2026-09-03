# NINEPOINT — Art Direction

## 0. Tooling note (read this first)

This environment has **no image-generation tool available** (no image MCP, no diffusion model,
no PIL/numpy). Rather than hand-place pixels ad hoc — which drifts, and drift is exactly what
kills character consistency — all art is produced by **deterministic Python generators** in
`tools/`, writing PNGs through a small pure-Python encoder (`tools/png.py`).

That makes this document *executable*: the palette and the character template below are the
literal contents of `tools/palette.py` and `tools/gen_characters.py`. Regenerate everything with:

```bash
python3 tools/build_art.py        # rebuilds art/ from scratch, deterministically
```

Consistency is therefore structural, not a matter of discipline: **a character's overworld
sprite and their portrait are drawn from the same feature record** (`CHARACTERS` in
`tools/characters.py`). Change Kesh's hair colour once and both update.

If a generative image tool becomes available later, it should be used to *replace* title art,
portraits and illustrations — never the tileset — and it must be fed the palette below and the
existing portraits as reference. See §8.

---

## 1. Visual identity in one paragraph

A working port city in the wet: brick, tram rails set into cobbles, grey stucco, slate and
rust roofs, a canal the colour of the sky, one damp green park. Top-down 3/4 perspective at
16×16 tiles, chunky readable pixels, no anti-aliasing, no dithering except in large flat
areas. Colour is muted everywhere **except the Go board**, which is warm honey wood with pure
black and off-white stones — the one saturated, high-contrast object in the world. The eye
should always be able to find a board. The city is where you live; the board is where you
*are*.

The city is **vertical and layered by hour**. Daylight is the muted register above. Dusk is
sodium gold on wet asphalt with the windows coming on. Night is ink and deep blue with neon
at the snack window and the tram wires sparking. Rain can fall on any of them, desaturating
everything and adding sheen. The board does not change: it is the one object that looks the
same at two in the afternoon and two in the morning, and that is the point of it.

## 2. Palette

54 colours, hand-picked ramps of 3–4 steps: 37 for the town, 9 added for the city, 8 for the
board. Nothing outside this list appears in the game. `tools/palette.py` is the source of
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
- Interiors reuse the same atlas plus an interior strip (floorboards, mats, shelving, tables,
  De Ketel's board tables).
- **Nothing in code refers to an atlas index.** `TileAtlas.at(name)` resolves every tile
  through `art/tiles/tileset_manifest.json`, so the atlas can grow a row without touching
  GDScript. The manifest is the truth; the table below is a summary of it.

Atlas rows, 16 per row, 90 tiles (`python3 tools/gen_tiles.py` prints the shape)
```
 0  ground: grass ×4, cobble ×2, pavement, gravel, dirt, kerb, water, plank, step, drain, void
 1  buildings: plaster, brick, wall base, doors, roofs, chimney, awning, signs, lamp post
 2  outdoor props: fence, hedge, tree 2×2, bush, bench, planter, stone table, board, barrel
 3  interiors: floorboards, mat, rug, wall, window, shelf, counter, go tables, chair, kettle
 4  the city: asphalt, puddle, tram rails, wet cobble, canal, quay, bollard, bike rack,
    tram pole, brick window, wet brick base, graffiti, shutter, dead sign, arch
 5  the city: arch, arch shade, neon, snack window, steps down, concrete, glass curtain,
    the stove and the hooks at De Ketel, poured floor
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
  Expression variants (`neutral`, `happy`, `annoyed`, `thinking`) alter brow/mouth only.

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
- Font: Godot's default UI font at integer scale only. Text `ink0` on paper, `paper0` on ink.
- Everything snaps to the pixel grid; the camera is pixel-snapped; no rotation, no scaling
  that is not an integer multiple.
- Icons 16×16, single-colour silhouettes plus one accent (stone, book, ticket, key, cup).

## 6. The Go board

The board renders at any size (9/13/19) into a fixed square area, computing an integer cell
size so lines land on exact pixels. Star points on 9×9 at (3,3),(3,7),(7,3),(7,7),(5,5) in
1-indexed coordinates. Stones are circles with a 1px `ink0` rim, a 2px highlight at upper-left
(`stoneW1`/`stoneB1`), and a soft `ink2` shadow offset down-right by 1px. The last move carries
a small ring in the *opposite* stone colour; territory in scoring mode is shown as small squares
**and** a diagonal hatch so it reads without colour.

## 7. Screen and camera

- Base resolution **384×216** (16:9, exactly 24×13.5 tiles), integer-scaled to the window.
  `canvas_items` stretch, `keep` aspect. At 1280×720 that is a clean 3.33× — the project uses
  `viewport` scaling with integer snap so it lands on 3× with letterboxing rather than blurring.
- Camera follows the player with a 1-frame deadzone, clamped to map bounds, pixel-snapped.
  A map **smaller** than the screen is centred, not pinned to the top-left: the limits are
  widened equally on both sides, and `World._build_backdrop()` paints `ink0` behind the tiles
  so the frame around a small room — and an unlit alley — reads as shadow rather than as a
  missing tile.

## 7b. The hours

`src/rpg/ambient.gd` owns the register. Two mechanisms, and no shaders:

- A **`CanvasModulate`** takes the whole world down to the colour of the hour, from
  `GameState.time_block`. Afternoon is pure white, so the city at the hour the game has
  always been set in looks exactly as it did before there were hours at all.
- One **additive glow** sits on every tile that lights itself — lamp posts, lit windows, the
  snack window, the neon, De Ketel's stove, the Instituut's glass. Additive is the whole
  trick: the modulate still multiplies the glow, so a lamp counts for nothing at noon and for
  everything at night, and there is no second canvas to keep in step with the camera. Reach
  is per source (`GLOW_SCALE`): a street lamp lights a junction, a window lights its own sill.
- **Indoors takes the hour far more gently** (`MapData.indoors`, `INDOOR_TINTS`) and never
  gets rained on. Inside a room the lights are simply on: De Ketel at eleven at night must
  not be as blue as the street above it.
- Rain is a `GPUParticles2D` drizzle on its own canvas layer, so it falls across the screen
  rather than across the map. A second, sparser emitter throws splash back up at ground level:
  rain you only ever see *falling* reads as a filter laid over the picture rather than as
  weather landing on the street the player is standing in.
- **Lights are not steady.** Each glow carries a phase and a small amplitude (`Ambient.FLICKER`):
  street lamps hum at ±5%, the stove breathes harder, the windows do nothing at all. The neon
  *faults* — mostly lit, occasionally not — and its timing is read from
  `TileAnimator.ANIMATIONS["neon_sign"]["hold"]` so the tube and the light it throws go out
  together. A lit blob over a dark tube is worse than neither. `apply()` still owns the base
  strength and the animation only multiplies it, so a lamp counts for nothing at noon whatever
  it is doing.

## 7c. Tiles that move

`src/rpg/maps/tile_animator.gd`. Water, the canal, puddles in the rain, the neon, the stove and
the go tables cycle through frames.

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

Ambient **reads** `time_block` and never writes it, and listens to
`EventBus.time_block_changed` / `weather_changed`. The day counter, when it exists, will be
what emits them.

## 8. If a generative image tool becomes available

Allowed: title illustration, character portraits (as *upgrades* to the generated ones), shop
signage, key-item icons, tournament certificate, book covers.
Forbidden: environment tiles (they must tile and share one light direction), UI frames.
Any generated portrait must (a) use only the palette above, (b) match the character record's
hair/garment/skin values, (c) be pinned in `art/portraits/REFERENCE.md` with the exact prompt
and seed so it can be reproduced when a second expression is needed.

## 9. Files

```
art/tiles/town_tileset.png      16×16 atlas, all terrain + interiors + animation frames
art/props/tram.png, bubble.png  things that cross the frame or float over it
art/sprites/<id>.png            16×24 × (4 dirs × 3 frames) per character
art/portraits/<id>.png          64×64 bust, expression strip
art/ui/panel.png, icons.png     9-slice frame, 16×16 icon sheet
art/title/title.png             384×216 title illustration
tools/palette.py                the palette above, as code — single source of truth
tools/characters.py             the character records
tools/gen_props.py              the tram and the "..." bubble
tools/gen_*.py, tools/build_art.py
```
