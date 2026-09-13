# Kettle prototype verification

Base: `2c0ca2d`, freshly fetched and matched to HEAD before creating
`codex/kettle-next` in `/home/user/Code/ninepoint-kettle-next`. All game and fixture
runs used disposable or explicitly isolated user data, serially.

## Scope and review

The optional profile changes Ro, Wren, Kesh, Tomás, the Kettle room and match materials.
Original facial pixels, hair designs and outfit palette remain. Normal campaign launch
uses the baseline. Rules, engine profiles, dialogue, progression, map coordinates and
save schema are unchanged. This is an implemented prototype awaiting owner visual
review, not approval to roll the work out across the campaign.

Open [the review page](index.html), or run `python3 tools/kettle_next/serve.py` and visit
`http://127.0.0.1:8781`. Movies are normal-speed, 30-fps captures from Godot:

- [Complete review film: cast, movement, Kettle and match](review-film.mp4).
  [Room-only film](kettle-film.mp4) shows conversations, placement, result and return.
  This shorter filming route resigns after a reply; the counted full game is separate below.
- [Prototype cast turntable and motion](prototype-cast.mp4) / [current main](baseline-cast.mp4).
- [Prototype gameplay movement, turning and stopping](prototype-motion.mp4) /
  [current main](baseline-motion.mp4). Only these isolated films omit the passing tram
  to keep Ro's feet visible; normal play and the frame-rate gate retain it.
- [Matched front views](cast_0-comparison.jpg), [side views](cast_90-comparison.jpg),
  [jogging](run_3-comparison.jpg) and [room views](room-comparison.jpg).

## Technical and gameplay evidence

- Full technical gate: **19,418 passed, zero failed**, predecessor 19,407. Eleven new
  checks exercise gait phase, one-shot expiry, cancellation and opt-in asset selection.
  **387 resource loads** pass. [Full technical log](technical-gate.log).
  Python art, teaching/capture scenes, real-engine service and review gates pass.
- **164 asset contracts**, **64,032 deformed-pose checks**, four 40-bone rigs and 18 clips
  each. All 24 central-gaze facial expressions exactly match the approved painted pixels.
  Selectively rebuilding Tomás preserves the other three identities' pose reports.
- Actual physics-driven walking and running pass at **30, 60 and 144 fps**: zero idle
  interruptions or gait changes while moving. Input release, wall contact with run held,
  and modal locks pass. [Motion log](motion.log).
- Four-board-size route: **98 passed, zero failed** in both profiles. Mouse placement,
  hover/count group changes, 19-line zoom and keyboard controls, result dismissal,
  record-once return and canvas restoration were exercised. [Prototype log](board-sizes.log).
- Full Wren route: **36 legal real-engine replies, no fallback**, counting and result,
  post-match reaction, complete **76/76-position review in 43.4 seconds**, exactly one
  saved match, and resumed walking. [Full log](full-game.log),
  [ready board](screenshots/11_match_ready.png), [count](screenshots/12_counting.png),
  [result](screenshots/13_result.png), [reaction](screenshots/14_reaction_before_review.png),
  [review](screenshots/19_review_2_page_1.png), [return](screenshots/23_walking_after_review.png).
- Tomás's wiping reach is checked against the actual worktop. The cloth centre remains
  over its footprint, within the authored contact-height band, and within 15 degrees of
  horizontal across sampled working poses. [Contact log](contact.log).
- Both actual launchers are exercised through `kettle_next_launch.json`, checking that
  they enter the Kettle using a disposable save and select the intended profile.

## Same-hardware performance

AMD Radeon RX 6900 XT, Mesa 26.2.1, Godot 4.7.2 compatibility renderer, 1536×864 window,
VSync disabled, identical static Kettle camera/cast, two-second warmup and five seconds
of samples each. No screenshot stalls occur in the sampling interval.

| Profile | Frames | Mean frame time | 95th percentile |
| --- | ---: | ---: | ---: |
| Current main | 5,624 | 0.889 ms | 1.161 ms |
| Prototype | 4,736 | 1.056 ms | 1.389 ms |

The prototype costs about 19% more in this static sample while increasing its world
viewport from 768×432 to 1536×864. These are frame-loop timings on this machine, not
isolated GPU timings, engine-turn latency or a guarantee for other hardware.
[Raw measurements](performance/prototype-performance.json).

## What was inspected and corrected

Opened all four characters from front, side and rear, plus shoulder/hand/knee poses and
normal-speed cast playback. Inspection caught wrist gaps, a trouser/hem overlap and a
lost cream shirt under Tomás's jacket; their sources were corrected and rebuilt.
Opened actual conversations with all three NPCs, room/counter views, match placement,
count, reaction, review and return. The counter close-up exposed a cloth reaching in
front of the worktop; the authored torso lean/reach and cloth orientation were corrected.
Steam uses exported cup positions. Continuous plaster replaces segmented shadow edges.

The first full run lacked the checkout's untracked engine package and used fallback;
it was excluded from real-engine acceptance. The existing local package was copied,
checksummed and smoke-tested before the successful full runs. One initial board-size
run reported a transient hover miss during counting; the baseline and repeated prototype
route passed with the same input assertions. The cause of that transient is unconfirmed.

## Remaining limits

- Visual approval belongs to the owner. The technical gates and this inspection do not
  establish that the prototype meets the desired final art quality.
- Clothing, cloth and hair use authored geometry/poses rather than physical simulation.
  Foot contact is authored for the game's flat floor; there is no terrain IK.
- Faces retain the existing painted expression system. Eye-direction variants and blinks
  add attention; there is no lip-sync or replacement facial topology.
- Coverage is four people and one room. Other cast models, rooms and general campaign
  lighting remain separate rollout work. The prototype also raises Ro's presentation
  resolution when walking into another area within that same preview process.
- Existing ObjectDB/resource cleanup warnings remain in some Godot test exits. They are
  recorded in logs; no script/parse failures were accepted as passing gameplay runs.

Documentation sweep: WORKBOARD, ROADMAP, MILESTONES, AGENTS, README and ARCHITECTURE
were reconciled. GAME_DESIGN required no change: its pillars, cast and teaching order
are preserved. No external publication or campaign rollout is part of this prototype.
