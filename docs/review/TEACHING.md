# REV-02 — Optional teaching practice

Technical implementation of REV-01 Step 5, 2026-09-12, on
`codex/rev-01-teaching-game`, based on freshly fetched main `6ab343a`.
Steps 1–4 remain shipped as M51. Independent beginner learning and interruption-fatigue
acceptance is **pending**; automated play below does not establish either. The local LLM
narrator remains deferred until this flow has been evaluated.

## Implemented behavior

The per-game choice defaults to **With teaching**. **Play normally** starts no teaching
process. Eligibility is limited to unrated, ordinary 9×9 practice: Wren's `wren_first`,
or Kesh's `kesh_first` / `practice_kesh` when the resolved setup has handicap stones.
Rated games, rematches outside those contexts, Capture Go and other sizes are excluded.

After a legal placement, the opponent waits for a bounded actual/best comparison. At
least four estimated points lost and a supported group-loss, missed-capture or four-point
region fact may produce one question. The panel shows the preceding position, rings the
relevant stones/region, and dots the attempted intersection. Arrows/Space and mouse work;
Escape chooses **Play it anyway**. **Undo** restores all rules and visual state, including
prisoners, passes, ko, move history and repetition history. The opponent and table talk see
only committed moves. Questions are separated by five committed player turns, and retrying
an undone decision cannot produce another question there.

Ordinary opponent moves remain quiet. A note requires the real move to match the legal
actual-branch continuation and an observed capture or current one-liberty group. Ownership
predictions never become claims of forced capture. Help offers current-position guidance,
the latest explanation, handicap guidance when applicable, and **Turn teaching off**.
An older explanation reopens on its own saved board and returns to the current game.
All teaching state is transient; match records, SGFs and save format are unchanged.

## Worker and factual boundary

`KataGoTeaching` owns one optional persistent analysis process, separate from the opponent's
GTP process. It warms asynchronously during the practice introduction; play does not wait
for readiness. Two analysis workers use up to four search threads each, capped from the
available CPU count to reserve capacity for the game. The normal opponent configuration and
post-match analysis budgets are unchanged.

The current position is cached while the player thinks at 30 visits. Its identity includes
the full initial position and retained move history, rules, komi, ko and side to move.
Actual and preferred branches each use 30 visits, ownership enabled and policy disabled,
with **one shared profile deadline** (currently two seconds). Missing, identical or illegal
preferences skip the comparison. Deadline misses cancel both branches and continue play.
Session generations and position keys reject obsolete replies, including partial responses
to terminated queries. A malformed response, failed startup or dead worker disables it for
that match. Disabling teaching, finishing or leaving the scene closes the process.
Cancellation and reply handling follow the [pinned KataGo 1.15 protocol](https://github.com/lightvector/KataGo/blob/v1.15.0/docs/Analysis_Engine.md#terminate).

The production games use simple ko and Japanese rules. Live teaching skips other ko modes
rather than submitting a mismatched engine ruleset. Pure history/undo and continuation tests
also cover superko. `ReviewFacts` accepts two branches without `lead_pass`, omitting
pass-dependent `slow_move`; existing three-branch review fixtures are unchanged. Live PVs
replay against an exact `GoGame.fork()`, with no post-match illustrative capture extension.

## Real-engine measurement

The bundled CPU engine was measured serially, before UI integration and again after final
worker changes. Initial six-position run: 1.61–1.85 seconds, six comparisons completed and
no timeouts. Recorded run: asynchronous startup **3.292 seconds**, four search threads per
analysis worker, **six completed comparisons, zero timeouts and zero failures**.

| Position | Pair latency | Teaching process tree RSS |
|---|---:|---:|
| Recorded Wren position 25, Black | 1.663 s | 599.9 MiB |
| Recorded Wren position 29, Black | 1.745 s | 605.6 MiB |
| Position 25 mirrored as White | 1.786 s | 605.8 MiB |
| Position 29 mirrored as White | 1.897 s | 611.4 MiB |
| Kesh, five handicap stones | 1.821 s | 611.8 MiB |
| Kesh, developing handicap position | 1.808 s | 611.9 MiB |

All four Wren samples produced the F2 group-loss fact. Quiet Kesh samples did not invent a
group-loss question even when score loss alone exceeded four points. The rendered Kesh
prepared threat did produce a supported region question. These are a small sample on this
PC, not a general latency guarantee. RSS includes descendants of the steam-run wrapper,
excludes the game's normal GTP engine and game process, and is sampled after each pair;
it is not a peak-memory measurement. [Raw final measurements](teaching/benchmark.txt).

A final repeat after strengthening the benchmark's coverage assertions completed all six
pairs in **1.752–1.918 seconds**, startup **3.278 seconds**, sampled RSS **605–615 MiB**,
and zero timeouts/failures. All four Wren positions again produced group-loss facts.
[Repeat measurements](teaching/benchmark-repeat.txt). The two recorded runs therefore
completed twelve pairs without a timeout; the small timing margin remains a reason to
retain silent fallback and evaluate on the player's actual machine.

Reproduce with the installed Godot wrapper and isolated user data:

```bash
XDG_DATA_HOME=/home/user/.cache/ninepoint-teaching-tests /home/user/.local/bin/godot --headless --path . --script res://tools/teaching_benchmark.gd
XDG_DATA_HOME=/home/user/.cache/ninepoint-teaching-tests tools/test.sh
```

## Verification and inspected play

`tools/test.sh` passed: **18,229 checks / 0 failures** (M51 predecessor: 18,200),
331 files loaded, 13 art tests, isolated pure gate **130 / 0**, teaching protocol gate
**31 / 0**, teaching scene gate **43 / 0**, and all existing capture/KataGo gates.
The existing real whole-game 9×9/19×19 review, failure and cancellation gate passed.
[Full gate log](teaching/test-gate.txt). After that run, the two teaching fixtures were
strengthened and rerun: the protocol gate grew from 27 to 31 checks by adding in-progress
responses, and scene-exit cleanup now relies on destroying the scene itself.
[Final targeted gate log](teaching/extra-gates.txt). Production code was unchanged.

The pure gate tests threshold boundaries, supported/quiet facts, optional pass data, colour
orientation, exact history, illegal ko continuations, cooldown and repeated undo decisions.
The protocol fixture tests deadline, stale/partial/malformed output, unavailable/dead engines,
disable and shutdown. The scene fixture asserts input locking and that GTP receives a kept
move exactly once and never receives an undone move; it also checks historical Help boards.
Protocol and scene fixtures are deliberately synthetic and are not Go-strength evidence.

All six rendered routes passed with real teaching analysis and normal opponents: Wren and
Kesh's `teaching_*`, `*_keep` and `*_normal`. They use explicitly prepared positions and real
keyboard/mouse events, not independent whole games. They cover the default choice, opting
out with zero teaching queries, the question, Undo/retry, keep, real opponent reply, Help,
handicap guidance, disable, resignation, post-match reaction and return. Observed in-game
comparison pairs were 1.666–1.867 seconds. Each output log was checked for script errors.

The separate `teaching_note` route uses real analysis but deliberately scripts the first PV
reply, so the supported note and its Help replay can be inspected reliably. It does **not**
claim Wren independently selected that move. Actual normal opponents can differ from the
PV; the other routes and fixture assert that such replies produce no speculative note.

Representative final screenshots were opened and inspected at game resolution:

| View | Evidence |
|---|---|
| Wren question, F2 rings and attempted-move dot | [Question](teaching/wren-question.png) |
| Undo restores the board and permits retry | [Undo](teaching/wren-undo.png) |
| Kesh question grounded in a lost region | [Region](teaching/kesh-question.png) |
| Existing handicap guidance through Help | [Handicap Help](teaching/kesh-handicap-help.png) |
| Real opponent reply after keeping the move | [Keep](teaching/wren-keep.png) |
| Supported note, scripted PV reply | [Note](teaching/opponent-note.png) |
| Explanation reopened on its own board | [Reopened note](teaching/reopened-note.png) |
| Play normally retains the existing practice UI | [Normal practice](teaching/normal-practice.png) |

Run each route serially, with distinct outputs:

```bash
OUT=/home/user/.cache/ninepoint-teaching-wren LOG=/home/user/.cache/ninepoint-teaching-wren.log tools/run_rendered.sh tools/autopilot/teaching_wren.json
```

Other routes: `teaching_kesh`, `teaching_wren_keep`, `teaching_kesh_keep`,
`teaching_wren_normal`, `teaching_kesh_normal`, and the labelled `teaching_note` fixture.
The normal `rendered_match` route covers the existing count/review/world-return regression.
It passed, and its [rated review](teaching/rated-review.png) and room-return screenshots
were inspected. Existing `kesh_practice` and `early_skips` routes also passed through the
normal dialogue entry points: [Kesh's five-stone practice](teaching/kesh-dialogue-practice.png)
retained 30k after the game, and [Wren's original Help](teaching/wren-original-help.png)
still worked with teaching declined. School access and save/reload assertions passed.

Some scene exits retain the existing Godot ObjectDB/resource-at-exit diagnostics, including
the normal-practice routes without a teaching worker. They are recorded separately from
script errors; teaching worker shutdown and process cleanup have explicit passing checks.

## Independent beginner evaluation — not yet observed

Use an ordinary eligible game with teaching on. When a question occurs, let the player
inspect the board and decide without the facilitator supplying the answer. Ask the player
to identify the threatened group or region, explain what they reconsidered, and describe
whether the question helped. Later offer a similar position without a prompt. Let them try
Play normally and Help's off action too. Record the player's own words, not an inferred pass.

| Observation | Result |
|---|---|
| Participant's prior Go experience and game/context | Pending |
| Can identify the named stones/region and attempted move | Pending |
| Describes the relevant liberties or capture opportunity | Pending |
| Explains their reconsidered move without being told the answer | Pending |
| Applies the idea in a later unprompted position | Pending |
| Confusion about board rewind, Undo, keep or the note | Pending |
| Number/timing of interruptions and reported fatigue | Pending |
| Preference for teaching, normal play or turning it off | Pending |

Keep comprehension and fatigue separate from engine latency and correctness. REV-02 stays
open for these observations; do not mark the learning goal shipped or start the optional
LLM narrator on the strength of automated evidence alone.
