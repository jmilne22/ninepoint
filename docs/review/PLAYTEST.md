# REV-01 verification (in progress)

## Step 1

Base HEAD and freshly fetched origin/main both `37d007c`; work is on
`codex/rev-01-review-facts`. Existing untracked files were preserved.

The first 9×9 measurement exceeded the approved budget: pass 1 14.661 s, pass 2
50.377 s, nine queries at 200 visits. Work stopped and the owner approved reducing
only pass branches to 50 visits. Actual and best branches remain at 200.

The first full gate with that adjustment passed 18,055 unit checks, 317 file loads,
13 art tests and all integration gates. 9×9 timings were 14.922 / 33.382 s;
19×19 timings were 61.275 / 46.460 s. Saved review bytes were unchanged at
4,640 and 13,932 respectively. The existing 19×19 fixture had reached its move cap
without ending; it now passes to finish, and final whole-game measurements follow.

`rendered_match` ran with isolated user data at
`/home/user/.cache/ninepoint-rev01/play-step1`, producing 18 frames, exit 0 and no
script errors. This is an eight-player-move regression route, **not** the final
abandoned-group acceptance. It used Wren's normal profile, player White, no handicap.
The loading label, legacy mistake text and return to the room were opened and inspected.

![Phase-aware loading](screenshots/step1-loading.png)
![Legacy mistake card retained](screenshots/step1-legacy-card.png)
![Return to the room](screenshots/step1-return.png)

Final Step 1 full gate after fixing the ending: **18,055 / 0**, 317 loads, 13 art
checks and all engine gates pass. The finished 9×9 has 78 moves, pass 1 **14.846 s**,
pass 2 **31.850 s**, saved review **4,639 bytes**. The finished 19×19 has 242 moves,
pass 1 **61.661 s**, pass 2 **45.597 s**, saved review **13,946 bytes**. Both sizes
return all nine detail branches. Detail rejection preserves the exact legacy payload;
detail cancellation terminates its pipe; the stalled engine fails within 6.1 seconds.
The 45-second acceptance budget applies to 9×9 pass 2. Shutdown resource-leak warnings
remain visible in logs; no script or parse errors occurred.

## Remaining acceptance

Steps 2–4, full Black/White abandoned-group games, the new mistake card and lesson
action, ownership comparison inspection, save-size deltas and legacy regression
remain unverified. No completion or shipped milestone is claimed yet.
