# Independent beginner playtest

Prepared 12 September 2026 for the CAP-01 / DESIGN-01 implementation candidate.
**No participants have been recruited or tested by this work.** The owner authorized
implementation while away; that does not supply independent observations. This packet
makes the remaining validation runnable without inventing results.

## Session setup

Recruit 5–8 newcomers: at least five who cannot yet explain capture, plus a few who have
played several games. Record the groups separately. An experienced player can check
skips and repeat visits, but cannot stand in for a newcomer. Obtain consent for any
recording and use participant IDs in retained notes. This is formative design work,
not certification of the novice ranks.

Record the exact git commit/dirty diff, Godot version, engine package/config and whether
fallback occurred. Start a fresh save in an isolated XDG directory. Play on the real
display with `tools/play.sh`. Do not use an autopilot route for participants. Keep the
same build and settings for the first five complete sessions; retain dropouts separately.
Collect active play time separately from breaks. Let the player stop whenever they want.

## Opening prompt

“Play as you normally would. Say what you're trying to do when you feel comfortable.
You can use anything the game offers. I'm interested in what the game explains.”

Do not tell them the intended club premise, suggest the right move, supply the controls,
or rescue a loss. If they ask for outside help, first record the request and the point of
confusion. Mark any subsequent coached action as assisted. Do not count it as independent
success. The game's H help and demonstration are permitted; record when they use them.

## Observe, then ask

1. Begin at New Game. Record the first action, time to Pip and time to an actual capture.
   Ask after the result: “What happened to that stone?” Capture in the guided position
   and understanding why it disappeared are separate observations.
2. Before Wren's rules lessons, offer the separate transfer board in
   [transfer-position.sgf](transfer-position.sgf), using a board/editor or physical board.
   Ask: “Black to play. Can you capture a white stone now? Show me, then explain.”
   The facilitator-only answer is C4, capturing C3. F6 does not capture F5, which has
   another liberty at G5. The setup is validated by the rules mirror in
   `tools/check_lessons.py`; see [position data](transfer-position.json).
3. Let them try empty-board practice. Record Help use, capture threats, illegal attempts,
   long chases, resignation and neutral endings. After an ending ask what they would do
   to retry or go on. Do not require them to lose or pass just to satisfy a checklist.
   Use a separate explicit usability exercise for an ending they never encounter.
4. Continue toward Wren, Kesh and the club rooms. Ask without supplying the answer:
   “Who are these people to each other?” “Why are you heading there?” “What would you
   like to do next?” “Is there anyone you'd like to see again, and why?”
5. Observe Wren's supported first game, then Noor/Ivo if the participant chooses to go on.
   Retain SGFs, colours, handicap, result, Help use, move/pass timing and final dead marks.
   Ask what made a selected move useful, what a threatened group could do, why they
   passed and what they think the count means. Record “don't know” as useful evidence.
6. Ask whether they want another game and record what they actually choose. Mechanical
   Cup access after losses is already tested; do not require a novice to sit through
   nine discouraging games to prove that access again.

Use a separate follow-up session for the league/Cup payoff if the learner wants it.
Do not show a fabricated result as their own. A loaded completion fixture can test the
wording, but must be explained as such and cannot measure earned narrative satisfaction.

## Decision criteria

Initial targets from the approved audit, agreed before gathering results:

| Question | Formative target / decision |
|---|---|
| First capture | At least 4 of the first 5 complete zero-knowledge sessions make and explain a capture within five active minutes at Pip, without facilitator coaching |
| Transfer | Record every answer on the different board; guided success alone never closes CAP-01 |
| Recovery | Every observed tester can find Help, retry and onward access; report each failure and whether the game or facilitator resolved it |
| Fiction | At least 4 of 5 describe a local group in an ordinary city and a reason to meet the novices beyond obeying directions |
| Full game | Investigate each helpless loss, unexplained count or opaque continuation using its actual position and the learner's words |
| Motivation | Record voluntary continuation, refusal and reasons; do not convert courtesy comments into a success score |

A failed criterion triggers a focused revision and fresh participants. Do not lower a
threshold after seeing results. Distinguish a failure to notice a legal move, an opponent
that is too strong, an unexplained pass, and an incorrect dead-group proposal. They call
for different fixes.

CONTENT-05 compares supported Wren with Noor/Ivo before deciding on a separate teaching
profile or a route to a novice peer. ENG-09 owns stopping behavior; ENG-05 owns dead-group
adjudication. PROG-01 retains independent novice strength validation. This small round
can expose problems and guide those decisions; it cannot establish calibrated kyu ranks.

## Notes template

Copy one row/session into [sessions.csv](sessions.csv). Leave results blank until observed.
Attach short quotations and timestamps, an anonymized save/SGF where consented, and the
exact build. Use separate fields for an action witnessed, the player's explanation and
the facilitator's interpretation. Do not fill missing observations with assumptions.
