# Inspected trial evidence — 2026-09-13

Base: freshly fetched `origin/main` and checkout HEAD both
`f90a39ecce39214de32f974eafdd29f51e99d391`, before creating
`codex/table-scene-restart` in `/home/user/Code/ninepoint-table-scene`.

The first expressive prototype was rejected by the owner. This revised trial is ready
for visual review; technical acceptance does not establish approval of the art style.

## Play and watch

- [39.2-second actual Godot recording, with sound](showcase.mp4)
- [Six full-resolution screenshots together](six-screenshots.jpg)
- [Six-second capture-reaction animation](reaction.gif)
- [Live engine match](screenshots/live_wren.png) and [live resignation result](screenshots/live_result.png)
- Launch: `/home/user/Code/ninepoint-table-scene/tools/play_table_scene.sh`

The MP4 was played in the in-app browser at normal speed and visually checked through
the result. Timed inspection sheets sample the encoded MP4 every 0.25 seconds:
[motion 1](motion-01.jpg), [2](motion-02.jpg), [3](motion-03.jpg), [4](motion-04.jpg),
[5](motion-05.jpg), [6](motion-06.jpg), [7](motion-07.jpg).

## What was opened and judged

| Beat | Evidence | Inspection |
|---|---|---|
| Opening | [01](screenshots/01_table_for_two.png) | All intersections clear; board thickness, grain, bowls and coordinates visible; names fit. |
| Placement | [02](screenshots/02_placing_a_stone.png) | Continuous arm reach, attached hands, correctly centred stone and its highlight/shadow. |
| Thinking | [03](screenshots/03_thinking.png) | Wren's hand reaches the chin, with a smaller mouth and lowered brows; facial features are painted flat. |
| Player capture | [04](screenshots/04_wren_surprised.png) | Wren opens her eyes/mouth and lifts both hands; the captured corner stone is removed. |
| Wren capture | [05](screenshots/05_wren_relief.png) | Ro reacts with surprise while Wren settles into a smile after placing; the opposite corner stone is removed. |
| Counting/result | [06](screenshots/06_counting_together.png), movie 33–39 s | Group markers and totals align; controls fit; the narrower result card keeps both faces visible. |

Iterations corrected inward-facing head polygons, colour-space import values, a head
resizing operation accidentally affecting hand bind geometry, shoulder/forearm weighting,
chin-gesture height, hidden coordinates, reaction interruption and result-card width.
The final movie and stills contain the revised assets and layout.

The hands perform authored gestures beside the board; they do not physically touch an
arbitrary selected intersection. The fixed camera and two transparent character viewports
are deliberate composition choices for this match-only trial. Other opponents and the
walking world have not been converted.

## Technical acceptance

All engine/game runs used this separate checkout and absolute disposable user data under
`/home/user/.cache/`. Acceptance routes ran serially.

| Check | Result |
|---|---|
| `tools/test.sh` | Exit 0: 18,239 checks, 0 failed; 340 files loaded; 13 Python art tests. |
| Remaining full-gate routes | Pure review 130/0; teaching worker 31/0 and scene 43/0; capture and KataGo smoke/service/review gates passed. |
| Rendered `--verify-table_scene` | 97 passed, 0 failed: all 81 projected hovers, click placement, occupied/outside rejection, keyboard, modal blocking, counting groups and Help. |
| Rendered `--live-check` | 9 passed, 0 failed: two real legal Wren replies, GTP active, no fallback, cancel/resign/result, zero match records. |
| `check_assets.py` | Both casts: seven continuous clips, outward-facing UV head, original hand/wrist bind position. |
| Movie capture | Godot MovieWriter: 1,175 frames at 30 fps, 768×432; normal animation timing. |
| Encoded media | H.264 MP4, 39.166667 seconds; AAC, stereo, 48 kHz. |
| Decoded audio level | Mean −26.7 dB, maximum −1.3 dB; actual recorded music/effects, with modest encoding headroom. |

The full gate still reports teardown resource warnings in the existing teaching,
capture and review integration processes. Its suites and gates complete successfully.
The dedicated trial input, live-match and movie logs contain no script/runtime errors.

Raw logs: [technical gate](evidence/technical-gate.log), [input](evidence/input.log),
[live Wren](evidence/live-wren.log), [movie](evidence/movie.log),
[media streams](evidence/media.json), [audio measurement](evidence/audio.log).

## Document sweep

Updated WORKBOARD, README, ARCHITECTURE, ROADMAP, ART_DIRECTION and AGENTS with the
isolated launcher, presentation boundary and evidence. MILESTONES remains shipped history;
this unmerged visual trial is recorded on the workboard. GAME_DESIGN remains accurate:
no cast, teaching-order, scoring, progression or campaign pillar changed.
