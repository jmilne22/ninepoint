# ART-15 campaign presentation verification

The complete campaign preview is isolated on `codex/campaign-next` in `/home/user/Code/ninepoint-campaign-next`. Production adoption remains an owner visual-review decision. Implementation and played acceptance are complete; the packaged preview is ready for owner visual review.

## Provenance and scope

Freshly fetched HEAD and origin/main both matched `2c0ca2da44c429d10720c1247432912d81355f43` before branching on 2026-09-13. The owner-approved Kettle prototype `fa8cc25` was incorporated as `3d761d5`. Original checkouts and user saves were preserved.

The profile selects twelve separate room exports, 26 shared character models/facial atlases, the refined table/tram, and embedded lesson/review surfaces. Original faces retain all 156 expression images pixel for pixel. The final asset gate passes 964 contracts, 444,054 authored deformation checks and 1,320,735 batch-equivalence vertices. Runtime actors retain movement, collision, interaction, rules, ranks, engine strength, dialogue, progression and save authority. No migration or production-default switch is included.

## Played gates

| Gate | Recorded result |
|---|---|
| Full technical gate | Two full technical runs: 19,434 passed / 0 failed. Final compile/load and unit run: 402 files all load; 19,435 passed / 0 failed. M59 predecessor: 19,418. |
| Pure review / teaching | 130 pure review checks, 31 worker checks, 43 teaching scene checks; capture, real KataGo smoke/service/review gates passed. |
| Board projection | 1,162 checks / 0 failures with the doubled viewport. |
| Board interactions | `table_adoption`: 98 / 0, covering 7, 9, 13 and 19 lines, edge inputs, keyboard/mouse, zoom, hover, count and result return. |
| Nigiri | Mouse call/colour choice, keyboard ceremony focus, real move, resignation and world return. |
| Locomotion | Real physics-driven player at 30, 60 and 144 fps: no unwanted idle frames or clip changes; walk/run foot travel 0.466–0.470 / 0.660–0.664. Stops, wall contact and modal locks passed. |
| Connections | All 22 doorway connections plus tram interruption/boarding/return passed. |
| Wren | Final filmed run: 33 legal real-engine replies, no fallback; complete 69/69-position review in 44.1 seconds; exactly one record and world return. |
| 13×13 | `campaign_thirteen`: actual opponent with two legal engine replies, no fallback; handicap setup, input, reaction and return. |
| Capture/lessons/events | `capture_practice`, `mouse_lessons`, `expressive_cup`, `expressive_league` passed. |
| Launchers | Both `play_campaign_next.sh` and `--baseline` passed their actual launch route; disposable save path, profile and starting fixture asserted. |
| Counter work | Tomás's cloth remained on the counter throughout five sampled poses; no contact failures. |

The full technical gate was run twice. Expected negative engine/corrupt-save tests and existing integration shutdown resource warnings are recorded in the logs; neither substitutes for played acceptance. The final unit run reports 15 ObjectDB instances and five resources at shutdown; the standalone capture/contact harnesses exit cleanly. Final cosmetic changes passed a fresh compile/load/unit gate and refreshed doors, tram, board, Capture Go, mouse lessons, nigiri and full Wren routes. The load gate covers src/tests/data/art; tools-only review scenes were exercised by the capture routes.

## Visual inspection and corrections

The front/side/rear sheets cover all 26 identities. Five posed views per group cover walking, jogging, greeting, thinking and sitting. Seven portrait and seven match-camera pages cover all 21 named/player identities, with gesture variants. The inspection found and corrected long collar strips, coat overlap, a palm-offset held stone, and chair occupants standing through their seats after activity changes. Chair ownership now comes from the original map manifests; seated presentation faces the actual table and keeps hands resting beside the thighs at the seat rather than reaching across an impossible gap. Kesh and Sunny were inspected close up after the correction.

All twelve environments were toured at identical baseline/preview arrival points. Room-specific furniture, washer/cloth details, personal desk items, planting, window fills, afternoon palette and uncluttered approaches were inspected. Title/opening/travel use the corresponding live assets and shared board rather than a separate inconsistent depiction.

Shadow diagnosis exposed two separate issues: the earlier custom light pass produced broad bands, and a camera depth range far beyond the fixed-angle rooms reduced useful directional-shadow precision. Standard diffuse materials, a 4096-pixel 32-bit orthogonal shadow atlas and a 12–55 metre camera depth range remove the striped/sawtooth artifacts. Camera angle, size, logical projection and map geometry are unchanged. Ground receives shadows without casting coplanar sun shadows.

The board uses explicit logical/pixel conversions. Quiet grain and softer highlights extend to the embedded 2D lesson/review boards. The ceremony panel keeps the reveal visible and separates the call from its controls. The movie capture route holds readable result/review cards while the scene continues at its normal simulation speed.

## Performance investigation

Same workstation: AMD Radeon RX 6900 XT, Mesa 26.2.1, Godot 4.7.2 Compatibility, 1536×864 output, vsync disabled. The harness measures actual movement in Kettle and Market Lane, then a populated 19×19 board; screenshots and movie encoding are excluded from timed sections. Moving-frame counts prove the actor actually moved.

The first short measurements varied with unseeded street traffic. One run reported Market Lane at 0.935 ms versus 0.783 ms for the Kettle profile (+19.35%, +0.152 ms). Investigation found more separate skinned draw primitives despite fewer triangles. Compatible meshes now join by material; Pip drops from 51 primitives to 12. A three-pose vertex-equivalence gate verifies the optimization preserves deformation. Final measurements seed the traffic and record draw calls, object and primitive counts as well as mean/p95 frame time. The optimized campaign has no additional regression above 10% in these routes.

| Scene | Main mean / p95 ms | Kettle profile mean / p95 ms | Campaign mean / p95 ms | Change vs Kettle | Campaign draw calls |
|---|---:|---:|---:|---:|---:|
| Kettle, moving | 0.963 / 1.341 | 1.156 / 1.389 | 0.664 / 0.828 | -42.6% | 208 |
| Market Lane, moving | 0.813 / 1.103 | 0.889 / 1.312 | 0.670 / 0.815 | -24.6% | 213 |
| 19×19 populated board | 0.763 / 0.973 | 0.777 / 0.997 | 0.770 / 0.950 | -1.0% | 478 |

Campaign moving samples contain 6,019 and 5,959 moving frames. This measures complete application frame intervals, not isolated GPU time. No Blender build, encoder or video playback ran during these serial samples. Raw JSON for all three profiles is retained beside this record.

## Evidence and limits

The local review page contains normal-speed environment, full-cast, locomotion and complete match films, matched map comparisons, and cast comparison/inspection sheets. Videos preserve the recorded 30 fps timebase. Cast and movement trim only 0.1 seconds of terminal cleanup. The complete chaptered film is 1280×720; individual chapters retain 1536×864. Wren is 294.467 seconds, including the full review wait and readable card holds. Raw AVI recordings remain in `/home/user/.cache/ninepoint-campaign-next`.

This is a stylized articulated preview, without lip sync, cloth simulation or terrain IK. Measurements describe this workstation and these routes; they are not a low-end hardware guarantee. Beginner engine-strength human validation remains the separate PROG-01 gate. Owner approval of the completed campaign in motion is still required before production adoption.

Lighting references: official [Godot lights and shadows](https://docs.godotengine.org/en/latest/tutorials/3d/lights_and_shadows.html) and [RenderingServer API](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html). Actual rendered inspections determined the final settings.
