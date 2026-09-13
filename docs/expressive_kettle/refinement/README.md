# Kettle refinement — second visual review

The same one-area prototype, revised after feedback on awkward stances and the art direction.
The clarified reference is **Hikaru no Go 3 on GameCube**. Its readable character acting
informed this pass; Ninepoint's own identities, clothing and painted faces are retained.
The [reference match screenshot](https://gamesandkanji.com/wp-content/uploads/2021/10/screenshot-55-e1634760580559.png?w=1024)
was inspected for resting hands and staging. No reference assets were incorporated.

[Watch the 36.1-second review cut](showcase.mp4) · [Before/after](before-after.jpg) ·
[Stance study](poses/stance_00.png) · [Room and conversations](overview.jpg) ·
[Uncut 114.97-second route](full-tour.mp4)

## Play

```bash
/home/user/Code/ninepoint-kettle-refinement/tools/play_expressive_kettle.sh
```

WASD/arrows walk, Shift runs, Space talks, Tab opens the player card, V opens the last
review and Esc offers exit. Wren offers the existing practice match. The launcher uses
disposable saves. The window is titled **Ninepoint - Kettle refinement**.

## What changed

- Longer legs and slightly smaller heads; lowered, relaxed arms and small weight shifts.
- Wren holds one wrist, Kesh settles into one hip, and Tomás works with a cloth at the counter.
- Correct bone roll through elbows and knees, planted resting feet and a stride tied to travel speed.
- Conversation portraits use these same revised bodies and a closer camera.
- Warm directional shadows, restrained wood/plaster grain and individual ficus leaves.

The room remains 768×432 at 30 fps. The approved match exports, original dialogue graphs,
engine profiles, rules, scoring and record/return logic are unchanged. This is one fixed-camera
area awaiting another visual review; it does not adopt the renderer across the campaign.
The cast is still deliberately simplified, and seated world interactions are not implemented.

## Verification and inspection

- Full `tools/test.sh`: **19,407 passed, 0 failed**, **361 resources loaded**. Pure review,
  worker, teaching, Capture Go, KataGo service and KataGo review gates pass.
- Serial rendered Kettle route: **28 passed**, including real Wren engine replies,
  cancellation/result/record-once/return, all three conversations, cards, review and modals.
- Generator checks: **560 deformed-pose assertions** over four characters, protecting
  knee width and idle foot contact. Blender errors now fail the build.
- Opened final arrival, conversation portraits, before/after, front and three-quarter
  stance captures, and six actual walking frames. Inspected the normal-speed review film.
- The technical gate retains the same shutdown resource-leak diagnostics as the first POC;
  all assertions pass. The dedicated rendered visit and pose film have no error diagnostics.

Evidence: [technical gate](evidence/technical-gate.log), [rendered route](evidence/rendered.log),
[pose contracts](evidence/pose-contracts.log), [movie metadata](evidence/media.json),
[audio measurement](evidence/audio.log), [edit timings](evidence/edit.json).

The review film starts with the actual Godot pose scene, then shows walking, Wren's
conversation, a real match excerpt, return, Tomás and Kesh. Every retained segment is
normal speed with Godot-recorded sound; loading and verification pauses are cut. MP4
encoding applies -3 dB to the source soundtrack. The uncut route remains available.

## Reproduce

From the checkout above:

```bash
nix-shell -p blender 'python3.withPackages (p: [p.pillow])' --run 'python3 tools/build_expressive_kettle.py'
DISPLAY_NUM=0 OUT=docs/expressive_kettle/refinement/screenshots LOG=/home/user/.cache/kettle-refine.log MOVIE=/home/user/.cache/kettle-refine.avi tools/run_expressive_kettle.sh --tour
DISPLAY_NUM=0 OUT=docs/expressive_kettle/refinement/poses LOG=/home/user/.cache/kettle-poses.log MOVIE=/home/user/.cache/kettle-poses.avi tools/run_expressive_kettle.sh --poses
XDG_DATA_HOME=/home/user/.cache/ninepoint-refine-gate tools/test.sh
```

Encode the two AVIs as `full-tour.mp4` and `poses.mp4` with H.264, yuv420p, AAC and
`-af volume=-3dB`, then run `tools/expressive_kettle/review_media.py` with ffmpeg on PATH.
Sources and generated assets remain isolated in their `expressive_kettle` directories.

Branch `codex/kettle-refinement` was created from freshly fetched `origin/main`, with
both hashes verified as `f90a39ecce39214de32f974eafdd29f51e99d391` before bringing in
approved local match work and the first area POC. The first POC's evidence is preserved
in the parent directory for comparison.
