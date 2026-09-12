# ART-08 verification — 2026-09-12

This is local implementation and play evidence on `codex/ps1-ketel-prototype`, based on
freshly fetched `f459336`. Nothing here asserts a merge or a release. The normal title
launch now uses the rendered presentation. ART-07 remains a separate session-only scene.
Later daylight, architecture, movement and interior exposure changes are recorded in the
[ART-09 verification report](../polish/verification.md).

## Technical gate

- Final editor pass: no script parse/compile errors; **310 scripts/scenes/resources load**.
- Final unit suite: **17,239 passed, zero failed**. Predecessor M48/SELA-07: 16,922.
  ART-07 adds 53 checks; production projection, coverage and tram exports add 264.
- **13 Python art tests pass.** The original generated fallback assets remain intact.
- The full `tools/test.sh` run passed at 17,232 checks before the final tram refinement.
  It includes real KataGo smoke/fallback, service and review gates: all 79 positions in
  a 9×9 and all 241 positions in a 19×19 were analysed; a wedged engine hit the watchdog.
  The final seven checks cover the tram's independently sorted export sections.
  Editor/load/unit/art checks were repeated after the tram and small presentation fixes.
- Real audio driver: **18 tracks audible**, all four intro stings hand over correctly.
  An explicit logical-player listener keeps world sound distances correct under projection.
- Pure Go rules, dialogue graphs, opponent profiles and authored map JSONs have no diff.
- [Full gate](logs/full-gate.log), [final unit](logs/final-unit.log),
  [final load](logs/final-load.log), [art](logs/final-art.log), [audio](logs/audio.log).

The unit suite deliberately submits malformed saves and prints their errors. Some
Godot shutdowns also retain the pre-existing audio resource cleanup warnings; these
are not described as zero-warning runs. The successful gameplay routes have no script
errors or failed navigation.

## Played and inspected

All routes use `tools/run_rendered.sh`, normal entry scenes and disposable user data.
They drive actual keyboard/mouse movement and choices. `experience.visit` in art routes
sets up a location; it does not prove the walk there. The generated doorway route and
the fresh journey provide that separate evidence.

| Route / captures | What it proves |
|---|---|
| `rendered_doors` / 22 | Every distinct doorway connection; live GPU colour/occlusion probes; actual right and diagonal input travel 17.40005 / 17.39998 screen pixels |
| `portrait_sprites` / 19 | Running at 1.750×, collision/pause lock, far-seat overlap, working poses, conversation and resumed activities |
| `mouse_capture` / 8 | Fresh 7×7 Capture Go through real board input and room return |
| `art_tour` / 18 | All twelve rendered maps; washer highlights, park approach and novice aisle; opened [contact sheet](tour.png) |
| `kesh_skip` / 80 | Fresh opening, Pip, Wren lessons/practice, Kesh's card without a game, actual tram, Hana/class/enrolment, novice board, save/reload |
| `novice_losses` / 88 | Five novice losses complete the attempt; four Cup rounds reach the ending; a repeated novice attempt starts at zero |
| `rendered_match` / 19 | Wren rematch through the current named choices, real game to the count, loss reaction, requested engine review, all review pages and walking after return |
| `mouse_nigiri` / 7 | Nigiri choices, stone placement, occupied feedback and turn ownership |
| `thirteen` / 11 | Kesh's 13×13 offer, actual handicap/komi, pointer placement, reaction and return |
| `mouse_nineteen` / 11 | Overhead 19×19, zoom/pan, pointer input, result and return |
| `mouse_count` / 7 | Counting group hover, changing/restoring dead marks, score/result and return |
| `art_arrivals` / 14 | Title, both destination illustrations and federation room |
| `sela_legacy` / 5 | Legacy safe arrival and exact current saved position through real load menus |
| `art_tram` / 93 | Both passing directions, cab/sections/shadows, real boarding and both destinations |
| `rendered_tram` / 1 | A passing tween interrupted by boarding; the vehicle remains held at the stop |

Opened the [fresh journey/Cup/save frames](journey_verification.png),
[review pages](review.png), [nigiri/input](nigiri.png), [nineteen-line views](nineteen.png),
[counting](count.png), [7×7 Capture Go](capture.png), [13×13](thirteen.png), [activities/portraits](people.png), and all twelve map frames. Room/dialogue composition was inspected
before full cast animation; the production room and tram were also opened at nearest-neighbor
3× window size. [Tram at normal window size](tram_3x.png),
[held at the platform](rendered_tram/01_tram_held_at_platform.png).

The isolated prototype separately verifies an actual unrated Wren game/review, cancelled
setup, synthetic win/loss reaction branches, long text/choices and save byte preservation.
Those synthetic result checks are not claimed as games won by the autopilot.
[Prototype evidence](../README.md).

## Corrections made from play

- Actor fragments were multiplying the texture twice; the live GPU probe now checks
  that unoccluded RGBA stays exact and a foreground mask actually clips the actor.
- Autopilot's former 3.5-pixel waypoint tolerance clipped a narrow classroom door after
  projection. Projected waypoints now settle within 0.8 logical pixels; all 22 connections pass.
- Hiding the whole HUD also hid the rank card. Conversation visibility now suppresses
  only base status/prompt panels, keeping modal cards visible and operable.
- Ambient speech from offscreen people was clamped onto the view edge. It now starts only
  for visible speakers and remains inside the reserved play area.
- The older running probe assumed screen-right meant logical east and measured logical
  distances. It now projects the physical lane and measures screen travel; the live
  1.750× run ratio, release, collision and pause/resume checks pass.
- The tram is split into five sorting sections. Boarding cancels old travel/bell tweens
  before taking control, so an in-flight pass cannot drag it away from the platform.
- Blender now purges orphan geometry between poses; a fresh complete cast build and
  activity export completed after an early batch had slowed and an overlapping export raced it.

Initial obsolete `novice_journey` and `review_world_wren_loss` routes did not follow the
current lesson/rematch menu. Their incomplete captures are excluded. The maintained
`kesh_skip` route and new `rendered_match` route supply the successful evidence. An early
handwritten door target was replaced by a route generated from actual warp data. A type
inference error introduced while adding the tram test was corrected before the final
compile/load/unit and replay pass. Intermediate failed/old-colour screenshots were removed.

## Scope and remaining limits

All twelve maps and all twenty NPC identities, player and five passer types have exported
models/sprites; required map activities and seven portrait expressions are covered by
asset checks. The camera has a fixed angle but follows large maps. Go intersections and
rules remain overhead and unchanged. No AI illustration assets are present.

This is an art implementation and scripted play pass. Independent beginner wayfinding,
opponent strength calibration and the existing ENG-09/PROG-01 human acceptance gates
remain separate. Full-size town 19×19 teaching is not introduced by the art conversion.
