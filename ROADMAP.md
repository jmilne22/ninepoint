# Ninepoint — what is left to do

Everything below is outstanding as of the current build. It is ordered by what
would most improve the game, not by what is easiest. `MILESTONES.md` records what
was built and how it was verified; this file records what has not been.

The build is green: `tools/test.sh` runs 5864 checks, `tools/check_lessons.py`
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

## 3. Fill the term

- ~~**NPC schedules.**~~ **Built (M26).** An NPC entry may carry `"blocks"`, the same key
  and the same "absent means always" reading `TileAnimator` and `Soundscape` already used;
  `MapBuilder.build_npcs()` filters on the hour and `World._repopulate()` rebuilds when the
  hour turns with the world still standing. Hana teaches by day and is at De Ketel after
  dark, Kesh the same, Pip and Bertie move from the park to the arches, the bar is shut in
  the morning and the study hall empties as the day goes on. The clock was previously read
  by the light, the sound, the crowd and the music and by nothing that decided where a
  person stood, which made the most atmospheric system in the project decorative.

  The guard rail is the part worth remembering: a schedule that can hide somebody can hide
  a quest step. `tests/test_data.gd` asserts every character is findable at every hour
  unless they are on a written list of the five who are deliberately not, and that De Ketel
  and the study hall -- the two rooms Act 1 and Act 2 run through -- are staffed at every
  hour, because a room that empties is an hour the player cannot spend and therefore an
  hour they cannot get past.
- **More to do per day.** More puzzles, more classes, repeatable teaching games,
  reasons to visit the quay and Onderbrug.
- **Quests with meaning.** GAME_DESIGN §7 wants ladder quests, fetch-with-meaning
  quests and tournament arcs. Two quests ship; the Cup is the third.

## 4. The thin places

The quay is two signs and a bench. Ketelsteeg is the largest map in the game and the
wassalon is a facade with a door, a sign, neon and no warp.

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

- **The Cup has no 13×13 section.** GAME_DESIGN §8 wants one. The plumbing is ready --
  `OpponentProfile.path_for(id, board, variant)` is where the Cup round chooses its profile
  and takes a board argument it currently always passes 9 to -- but the Cup is Act 2's
  ending and a second field and draw is its own piece of work.
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
- **`src/rpg/world.gd` is 700 lines** against a convention of ~300. It was over
  before the exam and the exam added a hundred: `_start_cup_round`,
  `_start_exam_round`, the paper, the sleep menu and six sign sentinels are five
  jobs in one file. It wants an event-desk component that both tournaments and
  the exam route through -- the shape is already there in triplicate.
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
- **The exam list and the Cup draw are the same tile** -- two pairs of paper
  pinned to the same wall of the Bondszaal, with nothing but the panel header to
  tell them apart once you press [Space].
- ~~**The AI's endgame is weak.**~~ **Fixed (M29)** — `GoEndgame` decides which ground is
  finished, the pass rule is the absence of a contested point rather than a score under a
  threshold, and the mercy rule stops a decided game instead of a cheap one. What is left is
  the *middlegame*: it still plays every point on the board at roughly the same strength and
  cannot tell a ten-point move from a two-point one, which is judgement, which is §7's engine
  question. A human who passes early is now played out rather than passed back at, and the
  margin means what it says.
- **`check_load.gd` never opens a `.json` file.** Its `EXTS` is `gd/tscn/tres/fnt`, so the
  load gate walks `res://data` and skips every dialogue graph, lesson, puzzle, banter file
  and review voice in it. Those are validated only where a specific test happens to walk
  them -- `test_data.gd` covers dialogue, lessons, puzzles and maps, and nothing at all
  covers `data/reviews/`, where three of the eight voice files are named by no test. A
  malformed one surfaces as a `push_error` at run time, in front of the player.
- **Two test hooks ship in production code**: the `Autopilot` autoload and
  `GoMatch.THINK_DELAY_FAST`.
- **`GtpOpponent` is unwired**, with three known bugs between it and an engine:
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
