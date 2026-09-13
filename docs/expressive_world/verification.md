# ART-13 / M58 — campaign style rollout

Implemented in `/home/user/Code/ninepoint-style-rollout`, branch `codex/style-rollout`.
Freshly fetched `origin/main` and detached HEAD both resolved to
`f90a39ecce39214de32f974eafdd29f51e99d391` before branching. The approved local
match/adoption/Kettle/refinement chain was then cherry-picked. Other checkouts and
normal campaign saves were preserved. This is a local rollout, not a main-branch merge.

## Technical acceptance

- `XDG_DATA_HOME=/home/user/.cache/ninepoint-world-gate-final tools/test.sh`:
  19,407 passed / 0 failed, 380 resource loads (M57 predecessor: 19,407 and 361).
- 13 Python art tests, 21 match-asset contracts, 119 live-world asset checks.
- Full-body build: 3,640 deformed-pose assertions across 26 identities. Required exports
  include the approved continuous motion plus seated and counter-height activity clips.
  The new activity poses were inspected in actual campaign rooms.
- Pure review, worker, teaching, Capture Go, KataGo smoke/service/review gates remain serial.
- Existing shutdown ObjectDB/resource diagnostics remain in some harness runs; they are
  not new parse failures and are not represented as a warning-free baseline.

[Complete technical gate log](technical-gate.log).

## Rendered routes, run serially with disposable user data

| Route | Inspected evidence / purpose |
|---|---|
| `rendered_doors` | All 22 connections; live-camera projection agrees with every logical tile centre within 0.1 px; right/diagonal input remains equal-speed. |
| `saves` | New-game confirmation, three slots, selected slot identity, save/overwrite, delete confirmation and return to title. |
| `mouse_capture` | New Game/Hana/name/attic, Pip demonstration, illegal lesson move, 7×7 mouse placement/reply, resignation and world reaction. |
| `mouse_lessons` | Wren's ko lesson, hover/capture, rejected immediate recapture and blocked second click during feedback. |
| `mouse_puzzle` | Desk puzzle, reset, target selection, solution and world return. |
| `mouse_count` | 19×19 fallback fixture, whole/close views, keyboard navigation, mouse group toggles, restored group, result and review refusal. |
| `rendered_match` | Real Wren 9×9, nigiri, eight player moves followed by passes, counting/result, engine review graph/cards and walking after return. This is a UI route, not a strength test. |
| `rendered_tram` | Actual passing tram interrupted and held at the platform; original boarding logic remains authoritative. |
| `expressive_league`, `expressive_cup`, `expressive_exam` | Existing saved fixtures open their real competition panels; no fabricated match results. |
| `rendered_polish_motion` | Sixteen actual walking frames and sixteen running frames, with unchanged movement controls. |
| `expressive_showcase` | Actual campaign scenes in all twelve areas, menu, street/room walking and Wren conversation. |

Screenshots live in the corresponding folders here. [Six selected views](six-screenshots.jpg),
[room overview](rooms-overview.jpg), [cast overview](cast-overview.jpg).

Inspection caught and fixed cropped SubViewport textures, inherited nearest filtering on
outline text, long location-name wrapping, an introduction camera aimed before tree entry,
standing poses on chairs, counter hand height and legacy faceted teaching stone art.
The ko harness now chooses the actual current dialogue options by text. Keyboard fixture
navigation waits for initial layout/hover before sampling its starting intersection.

## Recorded evidence

The [61.65-second review cut](showcase.mp4) comes from Godot Movie Maker captures at
1536×864 / 30 fps, with the engine's game audio. The [90.6-second full campaign tour](full-tour.mp4)
remains available. Frame ranges are recorded in [movie-cuts.json](movie-cuts.json);
encoding uses H.264, ordinary-range yuv420p and stereo AAC. The cut removes travel/test
pauses and selects normal-speed intervals; it does not accelerate animation.
Raw AVI files remain under `/home/user/.cache/ninepoint-world-*.avi`.

The full tour and final cut were opened in the app browser and inspected at 1× with
sound enabled. Screenshots were opened at readable size, including the new opening,
seated cast, long room label, teaching/counting boards and review graph. Movie audio
was also measured at −25.5 dB mean / −2.4 dB peak; see [stream metadata](media-info.json) and [audio levels](audio-levels.txt). The localhost preview server supports byte
ranges so playback and seeking work reliably in the app browser.

## Scope and remaining review

The complete campaign uses this presentation, including the original 20 NPCs, player,
five passer identities, all twelve areas and the tram. Logical map data, collisions,
warps, dialogue content, progression, rank labels, opponent profiles, rules and save
schema are unchanged. Preview saves persist separately so the owner can play normally.

This is the first campaign-wide visual pass. Room-specific composition, individual
acting and live-rendering performance on other hardware remain suitable subjects for
owner review. Automated acceptance is not independent beginner playtesting and does not
close PROG-01's human strength/learning gate. Historical raster assets remain available
for fallback/development routes and their existing contracts.
