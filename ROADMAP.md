# Ninepoint — what is left to do

Everything below is outstanding as of the current build. It is ordered by what
would most improve the game, not by what is easiest. `MILESTONES.md` records what
was built and how it was verified; this file records what has not been.

The build is green: `tools/test.sh` runs 6725 checks, `tools/check_lessons.py`
reports no problems, and the game is playable from the cold open to the exam and
the Cup.

---

## 0. ~~A decision, before anything else~~ — decided (M26)

**The term was six weeks and there were about four days of content in it.**

Decided by rescaling rather than filling: `CUP_DAY` 42 -> 14, `EXAM_DAY` 38 -> 10. Nine
open days, the exam's three rounds on 10-12, a clear day, then the Cup. "Six weeks" was
written in three places, not the four this file claimed -- Wren, Hana, and the
`first_stones` quest summary; the Ketelsteeg noticeboard carries no duration at all and
never did.

The two "Sleep until..." options stay, and are now a convenience rather than a cover-up:
a dozen keypresses is still a dozen keypresses. Filling the term is item 3 below and is
still worth doing; rescaling was the honest thing to do first, because the fiction is the
strongest thing in the project and a game that says six weeks and means four days is
overstating itself in the one register it cannot afford to.

**One thing this dragged out that is worth keeping.** `tools/make_test_save.py` carried
literal day numbers -- 42, 41, 40, 39, 38, 36 -- across seven presets. None of them would
have errored after the rescale; `exam_ready` at day 36 against `EXAM_DAY = 10` is simply a
save twenty-six days past the exam, and a screenshot taken from the wrong starting state
looks exactly as confident as one taken from the right one. The presets now derive their
days from the constants, so the next rescale is one line rather than eight.

---

## 1. ~~The exam~~ — built (M24)

Act 2 has an ending. Top four of the lower league sit it, three rounds, a round
robin, even games, top two pass -- Marguerite's problem paper first, the list on
the wall at the Bondszaal, and both outcomes written, because failing is an
ending too. `src/academy/exam.gd` is pure and stores nothing, like `CupDraw` and
`LeagueTable` before it, so a save and a reload is the same exam.

What it dragged into the light on the way, which is the part worth keeping:

- **`LeagueTable.player_position()` was read by a footer string**, so nobody had
  noticed that the table counted *every* rated game the player had played while
  the students played a round robin of five, against a sort that leads on wins.
  Twenty games and eight wins finished above a student who went 5-0. That is
  grinding past a stronger player, and Pillar 1 forbids it. The table now counts
  the player's first game against each person, which is what a league is;
  rematches still move rank through `GoRating`, which is where volume belongs.
- **Two graphs had a `start_match` exit and no `post_match` node** -- `tomas.json`
  since M21 and `pip.json` since the prologue -- so `resolve()` returned `""`,
  the box never opened, and the after-game beat was skipped in silence.
- **A player not in the exam field was told they finished fourth of four.**
  Nothing stops the simulation when the player has no game in it, so it ran to
  the end and `placing()` fell through to the bottom of the table. Found by
  looking at the screenshot, not by a test; there is a test now.

## 2. ~~Five opponents nobody can play~~ — built (M24)

All five are reachable. **Wren** offers a game at De Ketel once she has taught
you the rules, so a beginner's first rated game is no longer against a 12 kyu;
**Bertie** plays an unrated game on his bench, on the park's own terms;
**Hana** offers `hana_teaching` once the course is finished and `hana_9x9` at
8 kyu; **Marguerite** plays her own league fixture, having been on the board
without being an opponent in it since M13.

The reason it went unnoticed for so long is now a test. `tests/test_data.gd`
never looked at an `exit` at all -- only at `goto` -- so a wrong profile, lesson
or puzzle id passed every check in the project and failed silently at run time.
It now validates every exit, and asserts the reverse direction too: a profile
named by no dialogue must appear on a written allow-list of the ones an event
draws by string interpolation. `hana_teaching` had been orphaned since the day it
was written and `check_load.gd` loaded it faithfully every time.

## 3. ~~Fill the term~~ — closed (M35)

**DONE.** The term has a shape now: an hour axis (M26), a day axis (M34), a weather axis
(M35), and three recurring things that differ in kind rather than in degree.

| | |
|---|---|
| **Done** — NPC schedules, the hour axis | M26 |
| **Done** — the ladder quest (`the_hooks`) | M30 |
| **Done** — the fetch quest (`page_forty`) | M32 |
| **Done** — more classes and puzzles (3→5 classes, 8→12 puzzles, the quay at dusk) | M30 |
| **Done** — the day axis: `"days"`, `MapData.is_present()`, `World` rebuilding on `day_changed` | M34 |
| **Done** — one instance of a day that differs: club night at De Ketel | M34 |
| **Done** — **more days that differ**: the weather axis, rain, and market day | M35 |

**What closed it, against the four criteria set before the work started.**

1. **Three kinds of differing day ship.** *Rain*, which varies every day and changes the whole
   outdoor city; *club night* at De Ketel, one evening a week; *market day* on Ketelsteeg, one
   morning a week. One continuous axis and two recurring occasions, on different weekdays and
   at opposite ends of the day.
2. **Each is visible without reading the source.** The Ketelsteeg noticeboard carries both
   occasions on the one sign; the HUD has an occasion slot; Tomás has a wet-market voice and a
   dry one. Confirmed from screenshots, not from the diff.
3. **Each is expressed by a real condition.** `"weather"` beside `"blocks"` and `"days"` on a
   map entry, and `club_night` / `market_day` / `weather_is` / `weekday_is` / `block_is` /
   `day_at_least` in `DialogueGraph` — which had **no** environmental condition but `on_map`
   before this. Club night's own dialogue no longer rests on a coincidence.
4. **No occasion satisfies a safety guarantee, and removal is now safe.** See below.

**The two findings worth carrying forward.**

**The fortnight had one usable club night, not two.** Day 1 is a Monday, so Wednesday fell on
day 3 and day 10 — and `EXAM_DAY` is 10. The term's second club night was the exam, with Nadia
and Orla scheduled into De Ketel while both sat in the exam field. Nothing errored; it was
arithmetic nobody had done. Club night is **Tuesday** now: days 2 and 9, the second of them the
eve of the exam.

**The old guard made a schedule that *removes* somebody impossible to write.** `_test_schedules`
built its tables from the entries carrying no `"days"` key, on the sound reasoning that one day
in seven cannot satisfy a guarantee — and the cost, which nobody had priced, was that *any*
conditional entry was discounted, so taking a person out of a room on a condition failed the
findability check by construction. The day axis could only ever add. It is an **exhaustive
cover** now: all 4 × 7 × 2 combinations of hour, weekday and sky, asking at each who is
somewhere and which rooms are staffed. Strictly stronger, and a *pair* of entries that between
them cover every combination now keeps a guarantee — which is what Pip and Bertie's
dry-park/wet-arches pair is, and it is the first schedule in the game that moves somebody
rather than adding them.

**One correction to what this file said.** §1.4 of the M35 audit recorded that no map used the
`when_wet` tile key. Wrong: Ketelsteeg and Onderbrug have five puddle tiles between them and
have had since M16. The animation was never seen because **nothing in the game ever made it
rain** — `raining` had three readers and exactly one writer, the Autopilot test hook. It rains
now, and the quay has two puddles of its own.

## 4. The thin places

~~The quay is two signs and a bench.~~ **Half fixed (M30).** It was 364 tiles, two signs and
nobody -- the map GAME_DESIGN says you come to after losing, with no one there to have lost
to. Orla walks home that way at dusk, is a different person off the premises, and will play
one on the bench that goes on no board and no card. She was already on the "off at some hour"
list and still is: this gave her a third hour without giving her a fourth.

Ketelsteeg is still the largest map in the game and the wassalon is still a facade with a
door, a sign, neon and no warp.

Onderbrug is **half fixed**: it still cannot have a crowd (walled at both ends, so
`gen_maps.validate()` rejects every route, which is the correct answer for a dead end under
a viaduct) but it is no longer one man alone. Pip and Bertie come down from the park after
dark, so the map has three people in it at the hours anybody would be there and nobody at
the hours they would not -- population from the schedule rather than from a route it can
never have.

## 5. Beyond 9×9 — 13×13 built (M28), 19×19 still promised

**13×13 exists and two people will sit down over one.** Tomás opens the back table at De
Ketel and Kesh the board in the study hall, both on the chapter-2 gate GAME_DESIGN §9 always
specified — three rated games won — read off the record by a `rated_wins_at_least` condition
rather than stored behind a flag. `tomas_13x13` and `kesh_13x13` are generated profiles; the
board, the handicap (three stones on 13×13 where the same gap gives two on 9×9), the star
points, the coordinates and the review all work at the new size, and were looked at rather
than reasoned about.

**The hazard this section recorded was not waiting at a new board size. It was already
happening.** `GoRating._effective_strength()` priced a handicap stone at one rank — the 19×19
convention — while `GoRank.ranks_per_stone()` handed the stones out at three a stone on 9×9.
So a 22 kyu who beat a 4 kyu on the five stones the game itself dealt them was credited with
having beaten a 9 kyu, and had been since handicap games existed. Pillar 5 says the table is
honest; it was not, and it was not honest about 9×9. Fixed, with the failing assertions
watched to go red first. The lesson is the one M27 wrote down: **verify documented debt
rather than repeating it** — this file was confident and wrong about which tense the bug was
in.

**Still open, and deliberately:**

- ~~**The Cup has no 13×13 section.**~~ **Built (M33).** The open section: no ceiling,
  thirteen lines, handicap by the gap, and a field that is the club and the Instituut in one
  column -- Kesh, Ilse, Tomás, Sunny, Orla. Which section you are in is decided by the rank
  on your card, except that a player still under the ceiling with three rated wins may
  choose to play up, and Marguerite has an opinion about it.

  The plumbing was ready exactly as this file said, and the round needed the one argument
  the comment in `world.gd` had been predicting since M24. What was **not** ready was the
  thing that made it worth doing: `marguerite.json`'s `cup_outgrown` told a player past
  fifteen kyu that they were too strong for the Cup and offered them nothing, so improving
  locked you out of the only ending Act 2 has. That is Pillar 5 upside down and it had been
  shipping since M24.
- **19×19, which the fiction has promised twice** and still does: the board in `intro.json`
  is "nineteen one way, nineteen the other", and Hana's `exam_word_passed` closes the act by
  naming it. Screen space is the reason it is not next. At the 192-px match panel a 19×19
  gets 8-px cells against a 9-px font, where 13×13 gets 13. The board is meant to be the one
  saturated object on screen and at 19 it stops being legible before it stops working.
- ~~**The AI's endgame is worse on a bigger board, and now measured.**~~ **Fixed (M29).**
  It was worse there because it was wrong everywhere: the opponent only ever passed in reply
  to a pass, so it filled the dame, then its own territory, then invaded settled ground until
  no legal move was left. 13×13 self-play went from 1.76 moves a point to 0.92 and from three
  games in twenty-four that never ended to none. Move time was never the problem and still is
  not — worst 4.4 ms at 13×13, against 4.1 before.
- **`MISTAKE_BREADTH` makes a profile mean something different on a bigger board.** It turns
  `mistake_rate` into a rank window over a candidate list that is 169 long instead of 81, so
  the same numbers describe a different player at 13×13. `resign_threshold` had the same
  shape and was fixed — it is scaled by area in `gen_content.py` — but the shortlist width
  was left alone, because unlike resignation nobody has measured what it should be.

## 6. ~~The tutorial~~ — built (M27)

Eleven lessons existed and the machinery around them was written when there were three.
M21 grew the curriculum and did not revisit it; M27 did. All seven items below are closed.

- ~~**`self_capture` is reachable from one dialogue choice.**~~ Both rulebook entries now
  carry `"track": true`, so asking Wren to remind you of the capturing rule teaches the
  rest of the rulebook after it, which is what her closing line always claimed. The guard
  is general rather than specific: `tests/test_data.gd` requires *any* `start_lesson` exit
  naming a lesson in `MatchBridge.TUTORIAL_TRACK` to carry the track, because entering the
  rulebook part-way and not finishing it is the bug rather than that one node being wrong.
- ~~**`knows_the_rules` is doing two jobs and doing neither.**~~ Split. `finish_lesson` sets
  it only when every lesson in `TUTORIAL_TRACK` has its `lesson_<id>_done` flag, or when
  `said_knows_the_rules` is set -- the player telling Wren they know how the stones move,
  which is now taken at their word instead of setting a flag nothing read. The old
  behaviour was worse than this file recorded: `kesh.json`'s `offer_escape` is not gated on
  the flag, so one lesson from Kesh retroactively unlocked the study desk, Joos, Bertie and
  Tomas at once. `wren_knows_you_can_play` is retired; it had zero readers and was set by
  the `cup` node on every path through it, including paths where the player said nothing.
- ~~**Four of the eleven lessons end in silence.**~~ `World._post_lesson()` now enters
  `taught_<lesson>` and falls back to `taught`. Kesh has a close for each of her two
  lessons; Bertie and Tomas needed one line each, because **the writing already existed**
  in nodes called `after_lesson`, reachable from `start` and therefore playing one
  conversation late. `tests/test_data.gd` now requires every lesson's teacher to have one
  of the two nodes -- the `start_match`/`post_match` rule one seam over.
- ~~**The ko lesson replays the pre-Kesh Cup speech.**~~ The per-lesson node is what fixes
  this: ko ends on `taught_ko` and stops there. `taught` also branches on
  `wren_told_about_cup` now, so a *refresher* does not replay a speech about a tournament
  the player entered days ago either.
- ~~**A lesson cannot be re-taken.**~~ Wren offers the rulebook again, from `repeat` and
  from both game offers, so it is reachable at every stage of a save. Deliberately on her
  and not at the study desk: GAME_DESIGN is explicit that there is no menu item because
  being taught by somebody is the point, and the desk keeps handing out problems.
- ~~**`tools/autopilot/tutorial.json` drives a menu item deleted in M12.**~~ Deleted, and
  the CLAUDE.md line that advertised it with it.

  **And its replacement had the same disease.** `lessons.json` -- written to replace it --
  moved the board cursor three squares left and never moved it vertically at all, so it
  could not reach the answer on step 1 of the ko lesson. It sat on step 1 for the life of
  the file while writing screenshots called `ko_taken`, `step_two_intro` and `refused`,
  exiting 0 with no script errors every time. Found by opening the PNGs, which is the only
  way any of these are ever found. It now navigates by clamping into the corner and
  counting out, so it cannot drift no matter where the cursor starts.
- ~~**Nothing asserts a lesson or a puzzle is reachable.**~~ `tests/test_data.gd` now checks
  both directions for lessons and puzzles, with the same written allow-list idiom as
  `REACHED_BY_EVENT`, and reads the three GDScript tracks off the script rather than naming
  them (an autoload is not resolvable as a plain identifier in a `--script` run). A fourth
  check closes the asymmetry §8 recorded: every dialogue node must be reachable from an
  entry point. `pip.json`'s `capture_go` is on that allow-list rather than fixed -- see §8.

**Verification.** 5525 -> 5824 checks, 0 failed. Every new guard was confirmed to *fail*
when the thing it guards was broken on purpose -- Bertie's `taught` node deleted, an id in
`PUZZLE_TRACK` typo'd, an orphan node added to `joos.json`, `pip.json` dropped from the
orphan allow-list, `self_capture` dropped from the track allow-list, and the `track` flag
removed from Wren's capture choice. Two autopilot runs screenshotted and looked at: Wren
closing ko in her own words, and Bertie closing ladders with a paragraph that had never
once played at the moment it was written for.

## 7. The review

Owned by a parallel effort; listed here for completeness.

- **Eight of fifteen characters have no review voice** and fall back to
  `data/reviews/default.json`, so a nine-year-old and the top of the lower league
  post-mortem in the same words. `abel`, `dov` and `moss` -- previously named here as
  the highest value, being who a 22k plays four games running in the Cup -- have since
  been written, along with `hana`, `joos`, `kesh` and `wren`. What is left is the
  students: `ilse`, `sunny`, `orla`, `nadia`, plus `pip`, `bertie`, `tomas` and
  `marguerite`.
- ~~Only `wren` and `default` have an `unqualified` block.~~ All eight files have one.
- The review has rules and no judgement. It can say a group had one liberty and
  died; it cannot say a move was worth four points rather than nine. That needs
  an engine, and at kyu strength it is the right trade.

## 8. Technical debt

- **`slice_full` had not been playing its match, three runs in five, since M16.**
  Fixed, and worth reading before trusting any autopilot result again. Every NPC
  gained an idle behaviour in M16 and several wander on a leash of about a tile
  and a half. `Autopilot._talk_to` took the tile beside the NPC **once**, before
  walking, then pressed [Space] at where they had been; if they had drifted, the
  interaction probe found nothing. It printed a warning and *carried on*, so the
  rest of the script ran against a world in which the conversation had never
  happened — the run walked its whole arc, wrote nineteen screenshots, and exited
  0 with no script errors, having never played the game it exists to play. It was
  measured, not guessed: pristine `HEAD` missed 3 of 5, and `_talk_to` now
  retries from where the person actually is and tests the dialogue box rather
  than the probe. 0 of 5 after.

  Two lessons, both of which cost real time today. A green autopilot run is not
  evidence that the script did what it says; only the screenshots are, and only
  if somebody looks at them. And a flaky harness will fake a clean bisect —
  four single-sample runs pointed convincingly at three different files of mine
  before the rate was measured and the answer turned out to be "neither, and it
  predates you".

- **A tournament could not tell you it had ended.** `SceneRouter.go_to()` uses
  `change_scene_to_file()`, so the World is *freed* for the length of a match --
  and `World` was listening for `EventBus.match_finished` to notice that a Cup or
  an exam had finished its last round. There is no World in the tree when
  `finish_match()` emits, so that handler had never run, not once. The Cup limped
  because `_start_cup_round()` also sets `cup_finished` when you come back and ask
  for a round that is not there, so the flag arrived a conversation late and only
  if you asked. The exam made it visible: the standings on the wall said "you
  finished 3 of 4" while the journal still said "play your three rounds". The
  check now runs in `_after_load()`, where the world already picks up
  `MatchBridge.last_result`. Both events are fixed by the one move.
- **The journal never noticed a quest finishing.** `Hud` refreshed on
  `quest_advanced` and not on `quest_completed`, and `QuestTracker` emits the
  latter for the last step -- so a completed quest kept displaying its final
  objective until a rank, a day or an hour happened to change. Every quest in the
  game ended that way since M6.
- ~~**`src/rpg/world.gd` is 700 lines**~~ **-- half paid (M30).** It was **745** by the
  time anybody re-measured it, which is the ordinary way a line in this file goes stale.
  `SignDesk` (`src/rpg/sign_desk.gd`) now owns everything you *read* or *sit at* -- the
  three boards, the study desk, the hooks and the bed -- and `world.gd` came out at **577**. The
  seam is "reading versus starting a match", which is where the two halves actually fall:
  `_start_cup_round`, `_start_exam_round` and the problem paper stay in the World because
  they route through MatchBridge and spend an hour. The class board is reached from the
  desk through an injected callable for the same reason.

  One thing worth copying: `SignDesk` does **not** keep its own "a box is open" flag. It is
  handed `set_talking` and the World's `_talking` stays the only copy, because two flags
  meaning the same thing is how `knows_the_rules` went wrong in M27.
- **Three things M30 left behind**, written down here rather than discovered later:
  - `world.gd` is **591** lines against a convention of ~300 (577 when M30 wrote this
    line, 588 by the time M33 re-measured it, and three lines more for the section). `SignDesk` took the reading
    and the sitting-down; what is left is the tournament routing (`_start_cup_round`,
    `_start_exam_round`, the problem paper), which is a second component and was out of
    scope for a milestone whose subject was the term.
  - **`LESSONS_REACHED_BY_TRACK` and `PUZZLES_REACHED_BY_TRACK` in `tests/test_data.gd` are
    hand-kept copies of the tracks they guard.** Adding a class now means remembering two
    places, and the copy in the test is the one that would go on passing. The same problem
    for puzzle *kinds* was fixed in M30 -- `GoPuzzleData.KINDS` is read by the test rather
    than retyped in it -- so the fix shape is known and simply was not applied here.
  - **`GameState._note_hooks()` writes three flags** (`took_a_hook`, `hooks_top_three`,
    `hooks_top`) so the journal has an event to advance on, since `QuestTracker` advances on
    events and not on derived numbers. The order itself stays derived and stored nowhere,
    and this is the same pattern as `won_a_league_game` -- but it is still state that could
    disagree with `HooksLadder` if the roster ever changed underneath it.

- **`src/rpg/sign_desk.gd` is 299 lines** against a convention of ~300 -- M32's, and the only
  thing it left behind. It was 273 and the borrowed book took the rest of the room. The next
  thing added to the desk splits the file, and the seam is already visible: the boards on
  walls (`__LEAGUE_BOARD__`, `__CUP_BOARD__`, `__EXAM_BOARD__`, `__CLASS_BOARD__`,
  `__HOOKS__`) against the furniture you sit at (the desk and the bed).

- **Nothing relates a quest's steps to the hours the people in them are standing somewhere**,
  and this is **older than it first looked** -- the first draft of this bullet said M32 had
  introduced it, which is the tense mistake section 5 above already records this file making.

  It has been true since schedules landed in M26. `first_stones` step 3 -- *"Hana, who
  teaches at the Instituut, was watching. Speak to her"* -- advances on a flag set by talking
  to Hana **at De Ketel**, and she is not at De Ketel in the morning. That is Act 1 and it is
  mandatory. `page_forty` is only the second instance and the milder one: Nadia is in the
  classroom for three hours of four, and the quest is optional.

  `tests/test_data.gd` asserts that every character is findable at *some* hour and that De
  Ketel and the study hall are staffed at all four. It does not ask where a quest step
  expects to find somebody, so a step that needs a particular person in a particular room is
  checked by nothing. Neither case deadlocks today. The guard that would keep it that way is
  the one that does not exist.

  ~~Related, and found while checking the above: `World._start_class` is gated on `can_act()`
  rather than on Hana being in the room.~~ **Fixed.** A class could be taken at dusk, when
  Hana is at De Ketel and the classroom has only Nadia in it: the lesson ran, cost an hour,
  and `_post_lesson` then looked for the teacher, found an empty room and returned -- the M27
  silent close, reached through the clock instead of through a missing node, and present since
  M26. `_start_class` now checks the lesson's own `teacher` is in the room. The refusal string
  was the joke of it: *"Hana has gone home"* was already written and already correct, and was
  wired to whether the day had hours left rather than to whether she was standing there.

- **`LeagueTable.current_rows()` reads `GameState`.** `standings()` is still pure
  and takes everything it needs; the convenience exists because the board, the
  exam and the `league_position_at_most` dialogue condition must not build the
  roster three slightly different ways. It is the first impure thing in
  `src/academy/` and the file says so.
- **`pip.json`'s `capture_go` node is orphaned.** Nothing points at it, so the
  paragraph where Pip works out that you have been getting the rules off Wren is
  written and unreachable. It predates this pass (it is orphaned at HEAD too) and
  the intended entry condition is not obvious from the file, so it wants whoever
  wrote the prologue rather than a guess. `tests/test_data.gd` checks that every
  `goto` resolves but not that every node is reachable, which is the asymmetry
  that let it sit there.
- **The exam list and the Cup draw look identical.** This entry used to say they were "the
  same tile" and that was never true: `gen_maps.py:573-578` puts the draw at (9,2),(10,2)
  and the list at (13,2),(14,2), split in the very commit (M24) that wrote the complaint.
  What is true is that both use the `kifu_board` art the league board uses, so there is
  nothing but the panel header to tell them apart once you press [Space]. Left here in the
  corrected form rather than deleted, because "a documented bug that was fixed before it was
  written down" is a thing this file has now produced twice.
- ~~**The AI's endgame is weak.**~~ **Fixed (M29)** — `GoEndgame` decides which ground is
  finished, the pass rule is the absence of a contested point rather than a score under a
  threshold, and the mercy rule stops a decided game instead of a cheap one. What is left is
  the *middlegame*: it still plays every point on the board at roughly the same strength and
  cannot tell a ten-point move from a two-point one, which is judgement, which is §7's engine
  question. A human who passes early is now played out rather than passed back at, and the
  margin means what it says.
- ~~**Three save slots, and no way to see any of them.**~~ **Fixed (M31).** `SaveSystem` had
  taken a slot since M9 -- `SLOT_COUNT := 3`, `save_game(slot)`, `load_game(slot)`, and a
  `delete_save(slot)` with no caller anywhere in the project -- and the two places the game
  used it collapsed all three back onto one: the pause menu wrote the literal `save_game(1)`
  and the title screen read `newest_slot()`. A second playthrough destroyed the first,
  silently, and nothing could be thrown away. Now a shared `SaveSlots` panel lists who is in
  each slot and where they are, reached from **Load Game** on the title and **Save to slot**
  in the pause menu, with deleting behind a card that answers only to [Del] and never to the
  accept key. New Game still takes an empty slot without asking and asks only when all three
  are full: the cold open is the point of the cold open.
- ~~**A bare autoload name in a test typed the singleton as `Node` for the whole run.**~~
  **Fixed (M31).** `test_data.gd` said `GameState.BLOCKS`, which the analyser resolves before
  the autoload's script is in the global cache, so it settled on plain `Node` and kept that
  answer for everything compiled after it -- including `save_system.gd`, whose
  `GameState.to_dict()` then failed at run time inside the suite while working perfectly in
  the game. It had been quietly killing `_test_dialogue_branches` since that test was written:
  thirteen assertions that had never once executed, and a green report. Fetch the autoload
  (`root.get_node("GameState")`) into an **untyped** local instead; a `: Node` annotation is
  the same bug by hand.
- **A panel that touches an autoload cannot be tested at all, and this is the third shape
  of the same bug.** `CupBoard` is a `CanvasLayer` that reads `GameState` and `Audio`, so in
  a `--script` run -- which is how the whole suite runs -- it fails to compile, `CupBoard`
  resolves to a bare `GDScript`, and **every static on it silently returns null**. M33 put
  the two Cup sections on it first; the new assertions did not fail, they did not run, and
  the suite went green with a `t.eq()` count eight higher than the assertions written.

  Found because the same commit's `test_data.gd` guard failed loudly for an unrelated
  reason and the investigation went one layer down. Fixed by moving the section vocabulary,
  `PLAYER_ID` and `summary()` onto `CupDraw`, which is pure -- and that is the architectural
  rule already (`LeagueTable` pure + `LeagueBoard` panel; `HooksLadder` pure + `HooksBoard`),
  so the fix was to obey a boundary rather than to invent one.

  **What is still open is the general case.** Nothing detects it. `ExamBoard.summary()`
  below is the same disease diagnosed a milestone earlier and still untreated, and the
  `GameState`-typed-as-`Node` entry two bullets down is the same disease again. Three
  instances is a pattern, and the guard that would catch all three -- a suite that fails on
  `SCRIPT ERROR: Invalid call` rather than counting the assertions that did run -- does not
  exist. Until it does: **if a test names a class, check the class compiles without
  autoloads.**
- **`ExamBoard.summary()` is called on the class in `test_exam.gd:135`** and it is not static,
  so that one assertion has never run -- the same shape of dead test the bullet above
  describes, found while chasing it and left for whoever touches the exam next.
- **`check_load.gd` never opens a `.json` file.** Its `EXTS` is `gd/tscn/tres/fnt`, so the
  load gate walks `res://data` and skips every dialogue graph, lesson, puzzle, banter file
  and review voice in it. Those are validated only where a specific test happens to walk
  them -- `test_data.gd` covers dialogue, lessons, puzzles and maps, and nothing at all
  covers `data/reviews/`, where three of the eight voice files are named by no test. A
  malformed one surfaces as a `push_error` at run time, in front of the player.
- **Three test hooks ship in production code**: the `Autopilot` autoload,
  `GoMatch.THINK_DELAY_FAST`, and `GameState.weather_override` (M35 -- `""` derives the sky from
  the day, `"wet"`/`"dry"` forces it, and it is deliberately not saved, because a forced sky must
  not survive into somebody's real playthrough). Autopilot grew a `day` step in M34 beside its
  `time` step, and its `rain` step now writes the override rather than a flag nothing else read.
- **Two things M34 left behind:**
  - **`world.gd` cannot be reached by any test**, and this is the §8 bug above wearing its
    fourth costume. The M34 bug *was* in `world.gd` -- it never connected `day_changed`, so a
    day could turn with yesterday's people still in the room -- and no test in this project
    could have caught it, because `world.gd` reads autoloads and does not compile in a
    `--script` run. It was found by reading the wiring and confirmed by opening screenshots.
    The schedule *rule* was deliberately moved to `MapData.is_present()` so at least that half
    is guarded; the connection itself is not, and nothing detects the class of problem.
  - **`CLUB_NIGHT_GUESTS` in `tests/test_data.gd` is a hand-kept copy** of who is actually in
    `de_ketel.json` on club night, and **M35 added a second, `MARKET_GUESTS`**. This is the
    `LESSONS_REACHED_BY_TRACK` shape that this file already records the cost of, and the copy in
    the test is the one that would go on passing. M33 showed the fix -- derive it -- but there is
    no pure module to derive it *from* here, so it wants one, or it wants the assertion inverted.
    Two copies is where this stops being a note and starts being a pattern.

    What M35 *did* close is the same disease one file over: a dialogue graph could have said
    `["weekday_is", "tuesday"]` and held its own copy of which night it is, and would have gone
    on passing after the night moved. `club_night` and `market_day` take no argument and ask
    `GameState`, so no dialogue file names a weekday at all.
  - ~~The day axis has exactly one user.~~ **Moved to §3, where it belongs.** It is content
    rather than debt -- the unfinished half of "More to do per day" -- and recording it here
    would have let a closed-looking §3 hide it from whoever reads this file to pick the next
    thing to build.
- **`GtpOpponent` is unwired**, with four known bugs between it and an engine -- the count
  said three and then listed four:
  handicap stones never enter `game.moves`, `choose_move` issues `clear_board`
  every turn, `set_position` never reaches GTP, and `_command` blocks on
  `get_line()` with no timeout.
- **Dead-stone estimation is a heuristic** and will misjudge seki and complicated
  life and death. The player can override every call.
- **The UI is positioned by hand**, in literal coordinates rather than containers.
- Audio has never been *heard*. What is machine-checked: that each track renders
  as written, reaches the master bus, and exists where a map names it. Whether it
  is any good needs a person and headphones.

## 9. The engine question

Declined on 3 September 2026 and worth leaving declined for now: ~235 MB of
binary and weights against a 7.6 MB game whose entire asset pipeline is generated
Python, a build per platform, and a blocking GTP adapter. The heuristic's
legibility is a teaching feature and a ladder that does not work is content Pip is
built out of.

The condition that would change the answer has not changed: an opponent ladder
that runs past about 8 kyu, which means Act 3.
