# Ninepoint — what is left to do

Everything below is outstanding as of the current build. It is ordered by what
would most improve the game, not by what is easiest. `MILESTONES.md` records what
was built and how it was verified; this file records what has not been.

The build is green: `tools/test.sh` runs 5481 checks, `tools/check_lessons.py`
reports no problems, and the game is playable from the cold open to the exam and
the Cup.

---

## 0. A decision, before anything else

**The term is six weeks and there are about four days of content in it.**

Counting only what consumes a day's hours: three of Hana's classes and a first
game against each of about eight reachable opponents. That is eleven slots,
call it four days at three slots a day. Lessons and puzzles are free and finite.
The Cup is on day 42.

The calendar did not create this. Before it there was no clock, so nothing felt
empty; adding one revealed the thinness and then put a "Sleep until the Cup (41
days)" button on it. That button is a plaster, not a feature.

Two ways out, and they are different sizes:

- **Rescale the term.** "Six weeks" is written in four places — Wren's line, the
  `first_stones` quest summary, the Ketelsteeg noticeboard, and Marguerite. Two
  weeks would match the content that exists today. Small, and it stops the game
  overstating its own scale.
- **Fill the term.** Items 1–4 below, and then some. The better game, and much
  more work.

These are not exclusive: rescale now, widen later. But the fiction is the
strongest thing in the project and "six weeks" is a written line, so this is a
call for the author rather than something to quietly adjust.

**Still open, and the term now has a second fixed date in it.** The exam is day
`GameState.EXAM_DAY` (38) and the Cup is day `CUP_DAY` (42), so the last week of
term holds the exam's three rounds and then the Cup's four. That is seven days of
content at the end of a forty-two day term against roughly four days spread
through the rest of it. The exam gives the middle of the term something to aim
at that it did not have -- your league position is now a thing that decides
something -- but it does not fill it, and "Sleep until the exam" sits beside
"Sleep until the Cup" as the same plaster over the same gap. Moving either event
is one constant each.

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

- **NPC schedules.** Designed in GAME_DESIGN §4 and never wired. `idle` behaviour
  works; time-of-day movement does not, so the hours change the light and nothing
  else. Now that days pass, this is what makes one day differ from another.
- **More to do per day.** More puzzles, more classes, repeatable teaching games,
  reasons to visit the quay and Onderbrug.
- **Quests with meaning.** GAME_DESIGN §7 wants ladder quests, fetch-with-meaning
  quests and tournament arcs. Two quests ship; the Cup is the third.

## 4. The thin places

The quay is two signs and a bench. Onderbrug has Joos and a crowd it cannot have
(walled at both ends, so `gen_maps.validate()` rejects every route). Ketelsteeg
is the largest map in the game and the wassalon is a facade with a door, a sign,
neon and no warp.

## 5. Beyond 9×9

Every board in the game is 9×9, except Pip's 7×7 Capture Go. The title refers to
the nine star points of a 19×19 — *the shape you grow into* — and there is
nothing to grow into. 13×13 is the real next step, and it is also where the
heuristic starts to run out.

GAME_DESIGN §9 sketches chapters 2–6 and a rank arc from 22k to 6k. None of it
is built.

## 6. The review

Owned by a parallel effort; listed here for completeness.

- Ten of fifteen characters have no review voice and fall back to
  `data/reviews/default.json`, so a nine-year-old and the top of the lower league
  post-mortem in the same words. `abel`, `dov` and `moss` are the highest value:
  they are who a 22k plays four games running in the Cup.
- Only `wren` and `default` have an `unqualified` block.
- The review has rules and no judgement. It can say a group had one liberty and
  died; it cannot say a move was worth four points rather than nine. That needs
  an engine, and at kyu strength it is the right trade.

## 7. Technical debt

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
- **`play_music` has the fade race** that `play_ambience` was fixed for. Stopping
  and starting a track in the same frame leaves the stop's tween running over the
  new one. Not yet hit in play because no map pair does it; `Audio._fade_ambience`
  shows the fix.
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

## 8. The engine question

Declined on 3 September 2026 and worth leaving declined for now: ~235 MB of
binary and weights against a 7.6 MB game whose entire asset pipeline is generated
Python, a build per platform, and a blocking GTP adapter. The heuristic's
legibility is a teaching feature and a ladder that does not work is content Pip is
built out of.

The condition that would change the answer has not changed: an opponent ladder
that runs past about 8 kyu, which means Act 3.
