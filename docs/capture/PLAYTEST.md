# CAP-01: first capture implementation and evidence

12 September 2026. Base `89e1a35`; branch `codex/cap-01-first-capture`.
The owner approved the [design audit](../design-audit/PLAN.md) and then completion of
its implementation plan. Technical implementation is verified locally. **Independent
beginner learning/transfer acceptance remains pending.**

## What changed

Pip first offers a clearly labelled prepared demonstration on 7×7: fill the last liberty
at D3 and watch White D4 disappear. It is an example, not a win against an 18k opponent.
The player can skip it, practise from an empty board, repeat it or get Wren's directions.
Completing the example or asking directions gives onward access; a win is never required.

Optional Capture Go uses a dedicated one-ply practice policy: immediate captures first,
otherwise legal nearby moves, with legal self-atari allowed. It accepts the player's pass
as an offer to end practice. The board explains this policy openly; it neither changes
Pip's ordinary 18k profile nor claims to reproduce 18k competitive strength. There is no
adaptive difficulty or forced illegal sequence. The 7×7 board remains a candidate pending
human observation of chase length and comprehension.

H inspects a selected group's liberties and identifies a legal immediate capture or a
threatened own group. A capture wins, resignation loses, and two passes end neutrally:
**no counting, komi winner, loss counter or rank movement**. Capture mode survives in the
record even after resignation/neutral endings, so none requests ordinary territory review.
After returning, Pip offers retry, directions and the exact final capture before/after.
The replay is saved, checks its payload and creates no game, result or engine request.
Old records are preserved; old capture attempts retain onward access.

## Verification

The final shared gate is recorded in [the baseline report](../baseline/PLAYTEST.md).
The dedicated suite checks both colours winning, occupied refusal, ko-aware help, empty
and occupied two-pass endings, attempts to overwrite a terminal result, resignation,
undo, policy legality across twelve seeded games, neutral counters/rank/dialogue,
legacy review exclusion, and JSON save/replay reconstruction. Seeded games check legality
and termination only; they do not establish a human win rate.

`tools/capture_scene_probe.gd` instantiates the actual match with a GTP-labelled profile
and installed/missing engine paths. Both open CaptureOpponent immediately with no KataGo
lease, then reach the real neutral result card. The test deliberately tears down its
waiting result scenes; Godot reports resource cleanup warnings at process exit. No script
error is accepted as a passing integration gate.

Isolated played routes:

- `capture_practice`: fresh opening, demonstration/feedback, H help, neutral pass ending,
  retry/resignation, retry/capture, save/reload, exact replay and Wren. Initial and final repeat runs: 30
  captures each, exit 0, no script errors. [Final log](final-capture.log). Representative images were opened, not merely counted.
- `capture_skip`: abort the demonstration, take directions, save/reload and reach Wren's
  short rules exercises without playing practice. Nine captures, exit 0; leave/directions/
  Wren images opened. Wren now acknowledges Pip's referral without claiming a skipped
  demonstration was completed.
- `club_journey` and `beginner_full_games` also traverse the demonstration and real practice
  through the new club fiction. See the shared report for subsequent full-game evidence.

Retained representative frames:

| Moment | Image |
|---|---|
| Explicit example | [Demonstration](demonstration.png) |
| Why the stone disappeared | [Capture feedback](capture-explained.png) |
| Open practice policy / neutral exit | [Practice terms](practice-terms.png) |
| Neutral ending | [No winner or count](neutral-result.png) |
| Factual help | [Help](help.png) |
| Exact final liberty | [Before](replay-before.png) |
| Actual captured stones removed | [After](replay-after.png) |
| Onward access after leaving | [Wren](skip-to-wren.png) |

Isolated logs live under `/home/user/.cache/ninepoint-cap01`; the baseline report retains
final logs and selected newer frames. No user save was used or overwritten.

## Remaining design evidence

There were no independent human participants. Completing the prepared move is not proof
of transfer; a bot's easy capture is not proof a novice can see it. Use the separate
[playtest packet](../baseline/BEGINNER-PLAYTEST.md), including a validated different
position, before closing CAP-01's learning gate. Wren/novice strength is separately owned
by CONTENT-05 and PROG-01; the first-capture fix does not settle those questions.
