# Verhaven overhaul: observed play

Branch: `codex/verhaven-overhaul`, started from verified `origin/main` `277b51d`.
All play used a separate `XDG_DATA_HOME`; the player's save slots were not used.

## Newcomer journey

Played the opening and name exchange, took the board from the attic and followed the note
to Pip in the park. Played Capture Go, then followed Pip's directions to Wren under the
kettle sign. Read and played the liberties, capture and self-capture positions, including
an incorrect move and the explanation. Played the optional corner/side/centre comparison.
The empty-board Capture Go and practice reminders were read as two controlled pages.

Wren's full game reached counting after 38 automated player moves. The displayed result
was a Black win by 24.5; Wren said “You won! Well played.” Declined that review. Followed
the objective to Kesh, used nigiri, played a move and resigned. Accepted the review, read
the loading card, left it and returned to the club while analysis finished. Followed the
tram directions to the Instituut, solved Hana's capture problem, registered, read the
league board and played the first classroom lesson, Two Eyes.

Inputs were chosen from the displayed scene during the first pass. Repeatable scripts
then replayed those observed choices. Autoplay completed longer games; that proves a route
through results, not that a human beginner can beat these opponents. Engine calibration
was outside this overhaul.

## Problems found by looking at play

- The old return wait saw the world before the fade and return conversation had settled.
  Routes now wait for the transition and dialogue; a script cannot silently miss a result.
- An automation batch used an unsupported command and photographed the same lesson six
  times. Those frames are excluded from evidence. The lesson was replayed through real
  cursor input and its explanations were read.
- An attempted class-board interaction was beside its edge; moving to its centre reached
  the lesson. The visible board and the classroom direction made the destination clear.
- The first-rank flag fired before the rank action, so the new card could read “unranked”.
  Rank is now assigned first, and the card receives a higher canvas layer and modal input.
- Nigiri retained an unsupported estimate of Black's advantage. Its instructions now
  explain the guess and colour choice without a numerical claim.
- Joos still had a numerical promise in a choice after the spoken offer was rewritten.
  The choice now simply accepts the game.
- Large furniture initially left miniature objects underneath it and inconsistent
  collision. The generator now clears superseded tiles and supplies physical footprints.
- The league board repeated rank rules and crowded its purpose. Those rules remain on the
  player card; the board explains standing, exam eligibility and the next action.

Additional branch and visual evidence is recorded below as verification completes.

## Final journeys and branch coverage

| Session | Observed result |
|---|---|
| `overhaul_fresh` / `slice_full` | A fresh save through Pip, all Wren rules and optional openings, a full game to counting, Kesh's nigiri/rank, tram, Hana's problem, registration, league board, Two Eyes and Ilse's first handicap. The final replay reaches the intended scenes without live correction. |
| `overhaul_shortcuts` | Knowing the rules, skipping openings and postponing practice gives a practice objective. Kesh directs the player back to Wren. Completing practice and Kesh then gives the correct 22k card. |
| Fresh Ilse game and `overhaul_white` | Receiving four stones through ordinary progression and giving five as White in an isolated stronger-player fixture. Read both teaching stages and the rank-gap explanation. Help rejects a pass and a board activation; an engine reply waits behind the explanation. Position, next player and move count are unchanged by help. |
| `overhaul_joos` / `joos` | Unknown published rank, an agreed five-stone head start, casual label, actual loss reaction and all three player-card pages. No promise of nine stones. |
| `overhaul_review_return` | Played a short game, requested analysis, left while it ran, then opened the completed review from the quay noticeboard and read its cards. |
| `overhaul_review_failure` | A deliberately unresponsive analysis fixture reaches a direct failure message and lets the player return. The result remains recorded. |
| `overhaul_art`, `overhaul_returns` | All eleven maps inspected at their entrances and useful interior views. Return fixtures exercise completed lessons, matches, enrolment and Cup flags. Both tram exteriors also inspected through actual travel. |
| `overhaul_activities` | Invalid old return position falls back to the laundry entrance. Abel's towel question precedes Moss's answer; opening is suspended in the menu and resumes before the answer. Talking interrupts folding; it resumes afterwards. |
| `overhaul_cup`, `overhaul_cup_open` | Entered and completed all four rounds of both sections by resignation. Beginners' games have empty nine-line boards and nigiri; open rounds use thirteen lines and the resolved handicap. Actual completion acknowledgement and final placing read. |
| `overhaul_exam_fail` | Left both distinct paper positions, then completed all three rounds by resignation. Read the actual unsuccessful outcome and standings. The paper remains explicitly unscored. |
| `overhaul_exam_pass` | Continued a fixture with two prior wins and completed the last round by resignation. The resulting placing qualifies; the certificate and congratulation were observed. |
| `overhaul_hana_passed`, `overhaul_hana_failed` | Optional classroom acknowledgements from the two completed-exam fixtures, followed by normal return conversation. |
| `overhaul_returns` | Champion acknowledgement and tea invitation from a completed winning Cup fixture; results display and an optional acknowledgement back at the laundry. |
| `overhaul_arcs_3`, `overhaul_arcs_6` | Existing record thresholds for Ilse, Sunny, Orla and Moss, followed by accessible game offers. These are saved-record fixtures, not new relationship systems. |
| `nineteen` | Existing M42 development route: overview, cursor-following zoom, two legal replies, outside-view information, modal input, resignation cancellation and return. No town access or new nineteen-line lesson was added. |

The winning Cup and qualifying-exam preparation are explicitly saved-outcome fixtures.
They establish that those branches display and continue correctly; they do not represent
an assistant winning an entire tournament. The newcomer route and both completed Cup
sections were played through the actual world and match scenes. Longer counting games
used autoplay for moves after their introductions were read. This pass does not calibrate
opponent strength or establish how quickly a first-time human learns Go.

## Further issues found and fixed

- Returning to Wren after skipping openings offered the same lesson again. The opening
  gate now honours both completed and explicitly skipped lessons.
- Shortcut reconciliation changed the saved quest but failed to notify the HUD. It now
  emits the same quest update used by ordinary progress.
- An oversized reception counter covered a numbered Bondszaal table. The table rows and
  counter were separated; the entrance and registration approach were replayed.
- The Instituut reception sign had a standable tile but no approach around its counter.
  The sign moved; map validation now checks reachability, including named NPCs and exits.
- The exam emitted puzzle completion before the World listener existed. It now returns
  to the world first, so its two positions progress instead of repeating the first forever.
- Finishing an event after postponing its draw/list reading left an obsolete objective.
  Durable completion now supersedes those preparation steps.
- NPCs watched the nearby player indefinitely and therefore never resumed their routine.
  They now give a brief glance and resume, while interaction still interrupts immediately.
- The league footer's “as it stands” wording was a writing problem. Its replacement was
  inspected in both ineligible and eligible states; all lines fit.
- Generic fallback table talk retained unsupported score claims. It now contains only
  observable event reactions, like each named character's bank.
- A review tally could say “1 moves”. Its singular and plural forms now agree.

## Supporting verification and limits

Final compile/import, loading of 236 scripts/scenes/resources and the complete suite are
recorded in M43. All dialogue graphs are exercised for last-win and last-loss branches.
The new checks cover unknown ranks, measured teaching stages, durable quest repair,
handicap teaching saves, record-based conversations, walking/action sheet dimensions,
valid exchange speakers and short bubble layout. All eleven generated maps validate;
`tools/check_lessons.py` reports zero problems.

The full script was printed with `tools/check_dialogue.py` and read as connected
conversations, including repeat visits and event outcomes. Punctuation searches were a
supplement to that read. Screenshots were opened at 384×216 and selected images at 3×
nearest-neighbour scale. The gallery retains the native captures.

`tools/check_audio.sh` measured all 18 tracks through PulseAudio, with peaks from -24.2 to
-13.2 dB; all four intro stings handed over to their loops. Existing sounds were reused.
This is measured audibility, not a subjective listening assessment. Positional emitter
coverage remains the separate TECH-03 ticket.

The headless engine gates exercised legal replies, fallbacks, warm setup and completed
9×9/19×19 reviews, including the stalled-analysis watchdog. Exit-time resource warnings
remain from the existing test/runtime teardown; they did not produce script errors or
prevent the observed returns. Engine calibration, dead-stone adjudication and a town
introduction to nineteen lines remain outside this overhaul.
