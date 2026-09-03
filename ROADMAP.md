# Ninepoint — what is left to do

Everything below is outstanding as of the current build. It is ordered by what
would most improve the game, not by what is easiest. `MILESTONES.md` records what
was built and how it was verified; this file records what has not been.

The build is green: `tools/test.sh` runs 5525 checks, `tools/check_lessons.py`
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

## 5. Beyond 9×9

Every board in the game is 9×9, except Pip's 7×7 Capture Go. The title refers to
the nine star points of a 19×19 — *the shape you grow into* — and there is
nothing to grow into. 13×13 is the real next step, and it is also where the
heuristic starts to run out.

GAME_DESIGN §8 and §9 already say what should happen: the Cup "played on 9×9 or
13×13 depending on the section entered", placing unlocks the 13×13 section of the
club, and the chapter table moves 9→13 at chapter 2 and 13→19 at chapter 5. The
intent is written. What is missing is the work, and what is in the way has never
been written down.

**The fiction has promised 19×19 twice already**, which is what makes this a gap
rather than a preference. The board the last tenant left is described in
`intro.json` as "a grid of lines cut into the top -- nineteen one way, nineteen the
other": the player owns a 19×19 board from the first minute of the game and never
plays a game on one. And the closing line of Act 2, Hana's `exam_word_passed`, is
"Nineteen by nineteen is a different game and you know almost nothing about it.
Isn't that good?" -- the game ends by naming the board it does not have.

**What already exists**, so nobody rebuilds it: the rules layer is size-generic
throughout and simply never called above 9. `GoGame.handicap_points()` switches the
star points at 13 (`e = 2 if size < 13 else 3`) and places up to nine stones;
`default_komi()` returns 6.5 at ≥19; `GoRank.ranks_per_stone()` returns 3, 2 or 1
by board and `max_handicap()` goes 5 → 9; `handicap_between()` *defaults* to
`board_size = 19`. `tests/test_go_rules.gd` already asserts nine stones on a 19×19
at the 4-4 points, and `HeuristicOpponent._book_move()` takes its corner book from
`handicap_points(game.size(), 4)`, so the opening book scales on its own.

**What is in the way**, in the order it would bite:

- **Profile filenames encode the board size, and the tournaments interpolate them.**
  `world.gd` builds `"res://data/opponents/%s_9x9.tres" % opponent_id` for both Cup
  and exam rounds, and `go_match.gd` falls back to `kesh_9x9.tres`. A 13×13 section
  means a second profile per person and a convention in which `_9x9` stops meaning
  "the profile for this person" -- and `tests/test_data.gd`'s `REACHED_BY_EVENT`
  allow-list is written in those same names.
- **Rank arithmetic does not know the board.** `GoRating.performance()` reads
  `handicap` and `handicap_taken` off each record and never `board_size`, though the
  field is stored on every one. Three stones is three ranks on 9×9 and nine ranks on
  19×19 by `ranks_per_stone`, so the first record at a new size mis-rates the player
  with no error and no failing test. Pillar 5 is that the table is honest; this is
  the line it stops being honest at. Along with the profile names above, it is one
  of the two places a bigger board goes quietly wrong rather than merely missing.
- **Screen space, which is why 13 comes before 19.** The viewport is 384×216 and
  `GoBoardView` derives its cell size from the panel it is handed
  (`_cell = floorf((span - 30.0) / float(n - 1))`). At 19×19 that is about 8 px a
  cell and a stone roughly 7 px across, against an art direction of a 9 px native
  font and integer scaling only; 13×13 is about 12 px. The board is meant to be the
  one saturated object on screen, and at 19×19 it stops being legible well before it
  stops working.
- **The AI and the review have never been run at either size.** `_score_move()`
  flood-fills chains per candidate and probes a worst reply, over 361 points instead
  of 81 and across a game four or five times as long, with weights tuned at 81
  points (`CAPTURE_WEIGHT`, `PASS_THRESHOLD`, the territory limit
  `maxi(8, cells / 4)`); `GoReview` replays every move through fourteen detectors.
  That is a measurement nobody has taken, not a known failure -- and it is the sort
  of thing this project has twice found out about by running it rather than by
  reasoning about it.

## 6. The tutorial

Eleven lessons exist and the machinery around them was written when there were
three. M21 grew the curriculum and did not revisit the rulebook track, the
`knows_the_rules` flag or the post-lesson beat, and none of what that left behind
was written down until now.

- **`self_capture` is reachable from one dialogue choice.** In Wren's
  `ask_experience`, only "Never. I don't know the rules at all." carries
  `"track": true`, which queues `MatchBridge.TUTORIAL_TRACK` -- liberties, capture,
  self-capture. "A bit. Remind me of the capturing rule." starts `capture` alone,
  and `finish_lesson` sets `knows_the_rules` anyway, and Wren's `taught` node still
  says "liberties, capture, and no filling in your own last one" to a player who was
  never shown the third one. `start` never returns to `ask_experience`, so it is
  skipped for the life of that save.
- **`knows_the_rules` is doing two jobs and doing neither.**
  `MatchBridge.finish_lesson` sets it whenever any lesson completes with an empty
  queue, so Bertie's ladders or Tomas's counting or a class at the Institute all
  count as having been taught the rules. Meanwhile "I know how the stones move" --
  a player stating outright that they know them -- sets only
  `wren_knows_you_can_play`, which nothing reads. That player finds the study desk
  refusing them in their own attic ("You still do not know what any of it is for"),
  Joos on his `no_rules` branch, Bertie and Tomas both locked, and the ko lesson
  never offered, until an unrelated lesson from Kesh retroactively unlocks all four.
  The flag wants splitting: what you have been taught, and what you have said.
- **Four of the eleven lessons end in silence.** `World._post_lesson()` exists so a
  lesson "does not end in mid-air" -- it looks up `lesson.teacher` and opens that
  person's `taught` node. Only `wren.json` and `hana.json` have one. Kesh (`escape`,
  `connection`), Bertie (`ladders`) and Tomas (`counting`) do not, so
  `resolve("taught")` returns `""`, `DialogueBox.run` emits `end` without showing a
  box, and the teacher says nothing about what she has just taught you. This is the
  rule 6 failure shape one seam over, and `tests/test_data.gd` refuses a
  `start_match` with no `post_match` while having no lesson equivalent.
- **The ko lesson replays the pre-Kesh Cup speech.** Wren's `taught` ends
  `"goto": "cup"`, which runs on into `point_at_kesh` -- "That's Kesh over there, by
  the window. Twelve kyu. She'll play anyone." `offer_ko` is gated on
  `kesh_match_done`, so ko is only ever taught after that game has been played. One
  `taught` node is being asked to close two different lessons.
- **A lesson cannot be re-taken.** The study desk repeats puzzles once all eight are
  solved and the class board repeats its last class; the rulebook repeats never,
  because `wren_asked_experience` closes `ask_experience` permanently. A beginner who
  has forgotten what a liberty is has nowhere to go, and the desk -- the one place in
  the game built for revision -- hands out problems only.
- **`tools/autopilot/tutorial.json` drives a menu item deleted in M12.** It opens
  `move_down` + `interact` under the note "select Learn to play", against a title
  screen whose items are New Game / Continue / Quit. It now selects **Continue**,
  loading whatever is in slot 1, then spends twelve more `interact` taps writing
  twelve screenshots named `lesson_intro`, `step1_liberties`, `step2_corner` of the
  overworld -- or, with no save at all, of the title screen with a disabled item
  under the cursor. Exit 0, no script errors: section 8's lesson, sitting inside the
  harness that exists to catch it. It is also the only script that needs a save and
  declares none. `lessons.json` is the working replacement, and CLAUDE.md still
  advertises `tutorial` as a script you can run.
- **Nothing asserts a lesson or a puzzle is reachable.** `tests/test_data.gd`
  checks that every `exit` names a real lesson and a real puzzle, and has the reverse
  check -- with a written allow-list -- for opponent profiles only. Four lessons
  (`self_capture`, `openings`, `two_eyes`, `life_and_death`) and all eight puzzles
  are named nowhere but a GDScript constant: `MatchBridge.TUTORIAL_TRACK`,
  `World.CLASS_TRACK`, `World.PUZZLE_TRACK`. A typo in one of those is silent at run
  time, which is the failure section 2 has already paid for once with
  `hana_teaching`.

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
- **The AI's endgame is weak.** It stops playing once only first-line points
  remain, so a human who passes wins by a margin that means nothing. It wants a
  mercy rule and a better endgame before it is a satisfying opponent above ~15k.
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
