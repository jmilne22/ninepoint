# ART-09: movement, daylight and coastal architecture polish

Verified locally on `codex/ps1-ketel-prototype`, 2026-09-12. Before this follow-up,
a fresh fetch proved HEAD and origin/main both `f459336`. Earlier ART-07/08 work remains
on this branch. This report supplements, rather than replaces, M49's full-game evidence.

## Changes

- All 26 production identities have rebuilt walk cells with fixed shoulder attachment,
  continuous upper/forearm swing, sealed joints and a shallower passing pose. Idle,
  activity and portrait cells remain intact. Run playback uses the same improved poses.
- All twelve maps were rebuilt with visible entrances, neutral exterior daylight and
  continuous surrounding geometry. Door centres/widths follow existing warp groups.
- Five White City facade types replace cloned buildings: curved balconies, a recessed
  loggia, stairwell glazing, a roof terrace and a taller curved variant. Main shop
  identities and neighboring heights/widths differ. See the [photo study](references.md).
- Sea Walk has warm stone storehouses, true arches, stepped roofs, a low harbor shed,
  fishing boats, moorings and an angular breakwater inspired by inspected Jaffa photos.
  The Arcade uses the same stone arch construction. Title/opening/arrival frames were rebuilt.
- Map data, collision, gameplay routes, progression and Go rules are unchanged.

## Technical checks

`logs/ninepoint-polish-tests.log`: **17,239 passed, zero failed**, unchanged from M49;
13 Python art tests; 310 files load; all three real KataGo integration gates pass,
including complete 9×9/19×19 reviews and the stalled-engine watchdog.
The full gate ran before the last coastal renders completed. A final editor import
and 310-file load pass verified the final exports afterward; there were no script,
compile or parse errors. All twelve scenery PNGs have alpha 255 across the canvas.

All map exports, all 26 locomotion atlases, the coastal refinement and presentation
stills completed through the Python/Blender production commands. Editable `.blend`
snapshots accompany the Python sources. `git diff --check` is clean.

## Play and visual inspection

Every route used `tools/run_rendered.sh` and disposable user data, leaving real saves alone.
All six routes exited 0 with zero script errors: **116 captured frames**.

| Route / capture directory | Frames | What was checked |
|---|---:|---|
| `rendered_doors` / `doors` | 22 | Every connection; GPU color/occlusion probe; equal screen-right/diagonal speed |
| `rendered_polish_motion` / `motion` | 32 | Actual physics-driven walk and run frame sequences |
| `portrait_sprites` / `people` | 19 | Run 1.750×, release/collision/menu lock; activities, portraits and conversation return |
| `art_arrivals` / `arrivals` | 14 | New title; boarding and both updated destination images; hall entry |
| `rendered_coastal` | 11 | All three main facades, arcade entrance, garden, west/central/east harbor and stair approaches |
| `art_tour` | 18 | All twelve final maps; room edges, washer poses, novice aisle and park |

Opened the contact sheets for all route groups, the eight-direction gait sheet and
actual motion sequence crops. Opened native coastal frames and exact 3× nearest-neighbor
enlargements (`white_city_3x.png`, `harbor_3x.png`). Inspected full street and harbor render
canvases too. The three shop silhouettes are distinct, doors remain aligned, the harbor
promenade and review-board approach are clear, and exterior scene corners contain scenery.
`walk.gif` and `run.gif` retain the captured playback sequences for manual review.

The door route ran during the architecture build and includes intermediate facade art;
its entrance geometry and logical routes were already final. The coastal route and final
all-map tour use freshly imported final scenery. An early motion preview also exposed
stale Godot imports; its images were replaced after an editor import. The harbor inspection
caught a water-height seam at the old tile boundary. A single continuous sea mesh removed
it; the corrected render and final in-game harbor frames were opened again.

Known Godot process-exit ObjectDB/resource cleanup warnings remain in route logs, as in
M49; there were no runtime script errors or failed route assertions. This is visual and
navigation verification, not a new independent assessment of Go strength or game balance.


## Final interior exposure correction

The owner identified overexposed pale rooms before PR preparation. The attic benchmark
was rebuilt and played first: floor seams/grain, the blue-white bed cover and plaster
remain distinct with reduced indoor sky strength (0.38 → 0.26) and area-light powers
(1100/650 → 500/230). The other seven non-bar interiors use that same correction.
Outdoor sun/sky and the bar's separate warmer lighting remain unchanged.

`rendered_interior` captures the actual attic after import; `interior_tour` is a fresh
`art_tour` run after all eight corrected exports are imported. These supersede the earlier
bright interior frames above. Historical test and route evidence is retained.

Both final exposure routes passed at exit 0 with zero script errors: one attic benchmark
and eighteen final tour frames, bringing this polish pass to **135 frames across eight
runs**. Opened `attic_balanced_3x.png` and `interior_tour_contact.png`; checked all eight
corrected interiors alongside the unchanged bar and outdoors. Pale surfaces retain texture
and color without the broad clipped-white floor patches in the owner's report.


## PR source-tree check

The staged Git tree was exported into a new directory with no `.godot` cache. After
import, all 310 resources load. With the required pinned KataGo package supplied from
the verified local installation, the final unit run passes **17,239 / 0**. The initial
model-free run failed only the 33 model-presence contracts; README now states that the
full gate requires `tools/setup_katago.sh`. The first cold editor startup reported the
project theme before its bitmap font had been imported; import completed, the subsequent
editor pass was clean, and resource loading succeeded. No generated game asset is missing
from the staged tree. Local tooling directories and unrelated old screenshot imports
are excluded from the PR.

The clean source export also passes all **13 Python art contracts**. Root and PS1
documentation links resolve, and the staged diff has no whitespace errors.
