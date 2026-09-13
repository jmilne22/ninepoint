# Expressive Kettle — inspected acceptance

Separate checkout `codex/expressive-kettle-poc` started from freshly fetched
`f90a39ecce39214de32f974eafdd29f51e99d391`, with HEAD/origin-main hashes printed equal.
The approved match trial and ART-11 adoption were then brought into this checkout.
All game tests used disposable absolute data paths under `/home/user/.cache`.

## Technical and rendered results

- Full technical gate: **19,407 passed, 0 failed**; 13 Python art tests; 21 match cast
  contracts; pure review, teaching, capture and KataGo integration gates completed.
- Gate-time resource load: 357 files. Final load after the player-card addition:
  **358 files, all load**. Final rendered route imports and exercises the latest scripts.
- **28 rendered checks passed**, with actual input-driven movement and dialogue,
  real Wren GTP replies, cancellation/resignation/result, exactly one disposable record,
  return to the same player position, all three conversations, Kesh's 30k novice card,
  player card, review loading/dismissal, counter collision, room boundaries and modal blocks.
- Final rendered log contains no script errors or shutdown resource warnings. The full
  headless integration gate retains its existing synthetic failure-path and teardown warnings.

Logs: [technical gate](evidence/technical-gate.log), [rendered route](evidence/rendered.log),
[final resource load](evidence/load.log), [video metadata](evidence/media.json).

## What was opened and judged

[Overview](overview.jpg), [six locomotion frames](walk-frames.jpg), arrival, Wren
conversation/game/result/return, Tomás conversation, Kesh conversation, novice card,
player card and review loading. Text fits the cards, cast identities match the table
view, feet track the floor through the stride, and dialogue blocks movement.
Kesh stands by the window as her existing referral dialogue describes.

[Viewing cut](showcase.mp4): 43 seconds, 768×432, 30 fps H.264; stereo AAC at 48 kHz.
Captured with Godot MovieWriter; original animation speed is retained. Watched in
the in-app browser at 1× through the ending, unmuted; inspected movement frame by frame.
Delivery audio peak is −5.5 dB. The edit retains original intervals 0–8, 54–64, 72–87
and 95–105 seconds from [the full route](full-tour.mp4), removing startup and check pauses.
The final player-card/review sizing checks were added after recording; their screenshots
and final rendered log cover those additions.

## Scope

Playable one-area POC, ready for owner review. Other areas, lessons, puzzles and review
card art retain their existing presentation. No production-world migration is claimed.
See [the launch and source guide](README.md).
