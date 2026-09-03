# Ninepoint — what is left to do

Everything below is outstanding as of the current build. It is ordered by what
would most improve the game, not by what is easiest. `MILESTONES.md` records what
was built and how it was verified; this file records what has not been.

The build is green: `tools/test.sh` runs 5075 checks, `tools/check_lessons.py`
reports no problems, and the game is playable from the cold open to the Cup.

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

---

## 1. The exam — Act 2 has no ending

Marguerite says entry is by league position. The league board prints it. Nothing
happens. `LeagueTable.player_position()` is computed and read by exactly one
thing: the footer string underneath it.

Everything it needs now exists — a calendar, a term that ends, a tested pure
draw module (`CupDraw`), a results panel (`CupBoard`), and a rank that responds
to results. This is a content job rather than a systems one, and it is the
single most valuable thing left.

The Bondszaal is built and is where it should happen.

## 2. Five opponents nobody can play

No dialogue starts a match with any of these:

| profile | who | why it matters |
|---|---|---|
| `wren_9x9` | Wren, 20k | The right first opponent for a beginner. She teaches you the rules and then never sits down with you, so your first rated game is against a 12k. |
| `hana_teaching` | Hana, 5d at nine stones | Generated with the comment "the honest way to make a 5 dan playable for a beginner", and unreachable since the day it was written. Now that counting and life and death are taught, this is the obvious next step up. |
| `hana_9x9` | Hana, 5d even | The mentor. Endgame material. |
| `bertie_9x9` | Bertie, 4k | He teaches ladders in the park and will not play you. |
| `marguerite_9x9` | Marguerite, 1d | She runs the league and is on its board, but is not an opponent in it. |

Wren is the urgent one: it is an early-game hole, not a late-game one.

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
