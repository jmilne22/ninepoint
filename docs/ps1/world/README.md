# Ninepoint: the rendered game

ART-08 carries the approved De Ketel experiment into the normal game. Sela's current
places and progression remain: twelve maps, twenty opponents, the player, five kinds
of passer, the novice league/Cup and the optional Academy league/exam.

Run `tools/play.sh`. The viewport is still 384×216 with integer window scaling.
Directions are screen-relative. The camera keeps its 45° azimuth / 30° elevation;
it follows the player across large rooms and streets. Dialogue uses a measured bottom
card and a 108-pixel model-rendered bust. No AI illustration assets are used.

The Go surface stays overhead. The slab, slate/shell stones, bowls, nigiri hands and
table are rendered assets. Intersections, coordinates, selection, counting, teaching
marks and 19×19 zoom still use the existing board geometry and controls.

## Build

Blender and Pillow are development dependencies. Players need only Godot and the
checked-in exported PNGs. On this NixOS machine:

```bash
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_world_art.py --maps'
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_world_art.py --people --actions --board'
# Complete game assets, including existing audio, font and legacy grid fallback:
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_assets.py'
```

`--motion` rebuilds locomotion for all 26 identities; `--motion player wren` selects identities.
It preserves idle, activity and portrait cells. `--stills` rebuilds only title/opening/travel
frames. `--tram` rebuilds only the light-rail vehicle. `--maps attic de_ketel` selects individual rooms. `BLENDER=/path/to/blender` selects
the executable. `build_assets.py --groups rendered --output <project-shaped-root>`
builds the new presentation into an isolated output tree. Sources are the Python files
in `tools/ps1/`; editable `.blend` snapshots live in `source/`. Blender's orphan data
is purged between character poses so long batches do not accumulate unused meshes.

`tools/characters.py` remains the identity record. `people.py` models faces, hair,
garments and accessories; `actions_render.py` derives required activities from all
map states. Sprites have eight facings and walking/idle frames; separate action
atlases provide play, read, fold, wipe and arrange where the data calls for them.
Dialogue expressions and the compact board portraits share the same geometry.

## Coordinates and occlusion

The simulation still uses the original 16-pixel logical grid. Collision, doors,
interaction priority, far seats, sound sources and save positions keep those units.
`RoomProjection` transforms only presentation coordinates. Player input is inverse
projected, so right moves right on screen and diagonal movement has the same speed.
Autopilot converts its logical targets to analog screen input through the same transform.

One tile is 0.8 model units, rendered at 32 pixels per unit. A map exports `scene.png`,
`depth.png`, and `layout.json`. The manifest includes the source map SHA-256; tests reject stale
geometry after map edits. The depth pass comes from the *same meshes and camera*:
red stores the visible surface's ground depth, green identifies water, blue identifies
washer glass. Floors and back walls have zero occlusion depth. Character shaders clip
pixels behind a surface whose ground depth is farther forward than their feet. People
sort against one another by projected foot position. This resolves table tops and legs
without assigning an entire large table one approximate sorting point.

The other two mask channels allow restrained water/drum highlights without moving
collisions or applying screen wobble. The tram remains a live moving object, with a
five-section [TLV-inspired vehicle](tram.md) following its existing route. Each section
has an independent ground contact and shadow. An explicit listener follows the logical
player because the presentation camera now occupies different coordinates.

Maps without a rendered resource retain the existing grid renderer. The opt-in ART-07
room remains available through `tools/play_ps1.sh`, with its isolated session and original
four-character source snapshots. Production art is under `art/rendered/`, so legacy
assets remain reproducible and do not silently become the source for new art.

## Daylight, architecture and motion polish

`world/white_city.py` owns the five facade types, including curved balcony meshes,
recessed loggias and stairwell glazing. `world/harbor.py` owns original stone arches,
storehouses and fishing boats. [Photographic study and source links](../polish/references.md).
`world/entrances.py` derives door centres and widths from existing warp groups.
`world/surroundings.py` continues real ground, sea and buildings outside the logical map,
uses neutral sun/sky illumination outdoors, and aims interior fills at the room centre.
Pale interiors use reduced sky fill (0.26) and area-light powers (500/230) to preserve
floor, bedding and plaster detail. The bar retains its separate warmer 0.20/500/240 setup.
Context never expands collision or creates additional playable doors. The orthographic
camera sits far enough away to avoid clipping through foreground context buildings.

Locomotion uses fixed shoulder attachment and upper/forearm lengths, with sealed elbow
joints and a shallow passing pose. The walk loop and faster run playback share those
poses. `motion_render.py` and `production_motion.py` provide the selective export.

## Verification

See `verification.md` for the final checks and inspected captures. `tools/run_rendered.sh`
uses the normal entry scene and disposable user data for any existing autopilot route.

ART-09 follow-up: [polish verification](../polish/verification.md).
