# NINEPOINT — Game Design

> A top-down RPG about learning to play Go, set in **Verhaven**, a rainy port city.
> There are no combat statistics. The only thing that gets stronger is the person holding the controller.

---

## 0. Structure

Three acts, borrowed deliberately.

```
OPENING              ACT 1 -- Steenbeek            ACT 2 -- Essenveld Instituut
Hana addresses you   You do not know what Go is.   Enrolled at the bottom of the
directly, then asks  A board is left in your       lower league.
your name.           room. Pip drags you into a      - classes (openings, and on)
   (Pokemon)         game. Wren teaches the          - the study hall: play anyone
                     rules. Kesh challenges you      - the league board: your record
                     and hands you a rank. Tram 4    - the qualifying exam (the goal)
                     north, to the Instituut.
                          (Hikaru no Go)                  (Tag Force / insei)
```

- **The opening** is the Pokemon position: somebody speaks to the player before the
  world exists and asks what to call them. Hana takes it, which means she is a
  familiar face by the time you meet her at the Instituut.
- **Act 1** starts from genuine zero. The intro narration no longer implies the player
  knows the rules -- there is a board in the room and no instructions. Pip in the park
  assumes you play, and teaches you **Capture Go** before anybody explains anything.
  Target length: fifteen minutes.
- **Act 2** is the *insei* programme -- an institution with classes, an internal league
  ranked on results, and an exam most students will not pass
  ([Insei](https://gomagic.org/go-term/insei/)) -- arrived at the way Tag Force does it:
  as a new student, placed at the bottom, free to spend your time as you like
  ([Yugipedia](https://yugipedia.com/wiki/Yu-Gi-Oh!_GX_Tag_Force)).

**There is no relationship or affection system.** What the game tracks instead is your
**record** against each person, which is what actually matters between two Go players and
is what the rival dialogue reads from.

**The league board is the progression.** Your position on it is your results and nothing
else -- no experience, no allowance for effort. It is the honest form of the pillar in
section 2: the only way up is to win, and the only way to win is for the human to get
better. `LeagueTable` computes it from `GameState.match_records` and has no other input.

**There is no clock.** There was one from M19 to M36 — hours, days, a weekday, weather and
schedules that moved people between rooms — and M37 cut all of it, because none of it was
Go and all of it was complexity the player had to carry: a quest step could hide behind an
hour, a room could be empty, and the after-game line could be about a game from last week.
Everyone stands where they live. A game costs nothing but the game. The exam and the Cup
start when you tell Marguerite you are ready.

## 1. Premise

You have just moved into an attic over a shuttered stationer's on Ketelsteeg, in
**Steenbeek** -- an inner district of the port city of **Verhaven**, on the wrong side of a
canal. Three steps below the pavement next door is **De Ketel**, a bar whose back room has
had a Go board in it for sixty years. At the end of the street the viaduct crosses, and under
the arches men play for coins in the dark.

That is why an unusual number of people here play Go: it is a port, they always have, and
nobody ever stopped. Two stops north there is an institute that will certify you. Nobody
under the arches has ever been near it.

You know how the stones move. That is all you know.

*Ninepoint* is the story of one season in Steenbeek: the people you meet over a board, the
rival who keeps finding you, and the slow, real business of getting better.

### The two Go cultures

The city is built on one opposition, and the player lives between its halves. Above ground,
in daylight, the **Essenveld Instituut**: glass, timetables, a league board on the wall, an
exam that culls you, and everything recorded. Below, **De Ketel** and **Onderbrug**: an
hourly rate chalked on a slate, cash on the crate, and nobody asking to see your papers.

The Instituut says a rank is a document. Joos under the arches says a rank is what happens at
the table. Both are telling the truth, which is what makes it a setting rather than a
backdrop. Nothing supernatural, and no statistics -- this is simply what Go culture is.

The title refers to the nine star points of a full 19×19 board — the shape you grow into.
You begin on 9×9.

## 2. Design pillars

### P1 — The player is the character sheet
The protagonist has no Reading stat, no Tesuji skill, no equipment that adds +2 to fights.
When the player wins a game it is because the human understood the position better than before.
Anything that would let a weaker human beat a stronger opponent by grinding is forbidden.

**Allowed forms of progression**
| Progression | What it actually is |
|---|---|
| Rank | A record of results, like a real club rank. Never a modifier. |
| Handicap | Fewer stones needed against an opponent = evidence of improvement. |
| Unlocked opponents/locations | Access gating, not power. |
| Relationships | Changes dialogue, lessons offered, and who will play you. |
| Key items | A rank certificate, a tournament entry slip, a borrowed book. Narrative keys. |
| Knowledge | Lessons, puzzles, proverbs. Lives in the human's head. |

**Forbidden**
Stat buffs, "critical reads", luck rolls that change the board, AI that secretly plays worse
because you levelled up, consumables that undo mistakes in rated games.

### P2 — Difficulty is expressed in Go's own vocabulary
Opponents are never *Easy/Medium/Hard*. They are **20 kyu**, **12 kyu**, **4 kyu**, **1 dan**.
Difficulty rises along four honest axes:

1. **Board size** — 9×9 → 13×13 → 19×19
2. **Handicap** — how many stones you need, or give
3. **Engine strength** — from a legal-move-picker to a real engine over GTP
4. **Concepts in play** — the game surfaces ideas in a teaching order: liberties and capture →
   two eyes → connection and cutting → the value of corners → ladders and nets → simple endgame.

### P3 — Every opponent is a person first
Each NPC plays the way they talk. Bertie in the park plays fast and territorially and will tell
you a proverb whether or not it applies. Pip attempts ladders that do not work. Kesh cuts.
A match should read as a conversation, and the post-game dialogue should refer to what happened.

### P4 — Compact and alive over large and empty
One town, eleven rooms, fifteen people who are always where they live.
Better a café whose owner remembers your last game than a continent of silent villagers.

### P5 — Losing is content
This is a game about a beginner. The rival will beat you, probably several times.
Defeat advances the story and never blocks progress. There is no game-over screen.

## 3. Core loop

```
        ┌──────────────────────────────────────────────────┐
        │                                                  │
   Explore Steenbeek  ──► Talk to NPCs ──► Discover challenges,
        ▲                                    lessons, quests
        │                                          │
        │                                          ▼
  Unlock locations,                          Play Go  ◄──── the actual game
  new opponents,                                  │
  new concepts                                    ▼
        │                              Result changes rank,
        │                              relationships, story
        │                                          │
        └────────── Enter tournaments ◄────────────┘
```

The loop tightens: early games are 9×9 against people who explain what they are doing;
later games are 19×19 against people who expect you to already know.

## 4. Steenbeek

Compact, walkable, vertical: a street with rooms above it and rooms below it. Nine locations:

| Location | Role | Regulars |
|---|---|---|
| **The attic** (player's home) | The study desk (puzzles) | — |
| **De Ketel** | Informal lessons, practice games, then the rival | Tomás, Wren, Kesh |
| **Onderbrug** (the arches) | Nine stones from a man with no card | Joos |
| **Molenpark** | Fast outdoor games, the stone tables | Bertie, Pip |
| **Ketelsteeg** | The street: the tram stop, noticeboard, snack window, the stationer's | — |
| **The wassalon** | The laundrette. The city's third register: nothing at all is written down | Abel, Dov, Moss |
| **The quay** | Grey water and one bench. Where you go after losing; the noticeboard holds the last game you asked somebody to go over | — |
| **Essenveld Instituut** | Classes, the internal league, the study hall | Hana, Marguerite, the students |
| **Bondszaal** | The federation hall: tournaments and the exam | Marguerite |

**Built:** all nine, plus the attic — Ketelsteeg (street + park end), the wassalon, De Ketel,
Onderbrug, the quay, the Bondszaal and the four Instituut rooms. Eleven maps.

The wassalon (M36) is the one location that is neither half of section 1's opposition. The
Instituut records you and De Ketel remembers you; at street level, in the warm, nobody does
either. Two of the three games played there are unrated for that reason, and the third is
rated because the one person who wants a record is the one who has spent three years managing
his.

### Schedules

**Cut (M37).** From M26 to M36 a map's NPC entry could carry hours, weekdays and weather,
and the same person stood in different rooms at different times. It was the largest source
of complexity in the game and it decided nothing a player could act on: a quest step could
hide behind an hour, and the tests needed a 56-combination cover just to prove nobody had
been scheduled out of existence. Everyone now stands on one map, always. The one design
consequence worth keeping: Hana cannot be both at De Ketel for Act 1 and in the classroom
for Act 2, so Kesh hands out the first rank and the tram, and Hana meets you at the
Instituut.

Locations can still remember progress. After lessons, matches, enrolment and events, a map
may change its conversation pair, clutter, notices or overheard remarks. These **presence
states** are persistent, legible on revisits and never make a person or service unavailable;
they give Verhaven social movement without putting a clock back in the player's pocket.

## 5. Cast

The nine below are the original prototype cast and the table is kept at that size, because
these are the nine the design was reasoned from. **Fifteen `NpcData` files ship and all
fifteen stand on a map** -- the six added since are Ilse, Sunny and Orla in the study hall
and Abel, Dov and Moss in the wassalon. The last three stood nowhere until M36 and were
reached only by the Cup draw interpolating their ids, so the tournament that ends Act 2 was
introducing three strangers at the board. `CLAUDE.md` carries the complete list with ranks
and locations; that is the one to read for who exists.

Ranks are real ranks; the ladder from 20k to 5d is the game's difficulty curve made human.

| # | Name | Rank | Role | Personality | Style at the board |
|---|---|---|---|---|---|
| 1 | **Wren Calloway** | 20k | Beginner friend | Warm, anxious, over-apologises, genuinely delighted by other people's good moves | Plays contact moves everywhere; no plan, no malice |
| 2 | **Kesh Idowu** | 12k | Recurring rival | Sharp, impatient, competitive in a way she is slightly embarrassed by; keeps score of your meetings | Cuts first, counts never. Fast. Punishes loose shapes |
| 3 | **Pip Arnesen** | 18k | Enthusiastic weaker player | Boundless, loud, wants to play *right now*, loses cheerfully | Attempts ladders. The ladders do not work. Attempts them again |
| 4 | **Bertie Vale** | 4k | Older park player | Gruff, dry, generous underneath; deals in proverbs of variable relevance | Territorial, fast, solid. Will not fight you; will out-count you |
| 5 | **Nadia Ferreira** | 2k | Senior student | Methodical, polite, a little tired; sits in on the beginners' classes | Opens by the book. Struggles when you leave the book |
| 6 | **Hana Oyelaran** | 5d | Club teacher | Patient, unhurried, asks questions instead of answering them | Teaching games at handicap; will not crush you, will not let you off |
| 7 | **Tomás Beir** | 8k | Bar owner | Gruff, practical, counts | Loose, instinctive, surprisingly good endgame |
| 8 | **Marguerite Sable** | 1d | Tournament organiser | Brisk, fair, allergic to slow pairing | Precise, orthodox, low-risk |
| 9 | **Joos** | `?` | The man at the arches | Laconic, unimpressed, will not discuss himself. No surname offered | Territorial and patient. Three dan behind a label he refuses to fill in |

### Player rank
Starts **unranked**. After the first rated game Kesh gives you 22 kyu. After that the rank
is a step ladder (`GoRankLadder`): beat somebody at or above your rank and it goes up one;
lose to somebody at or below it and it goes down one; anything else changes nothing.
Handicap is priced in at what the board says a stone is worth. Park and arch games are
unrated and move nothing, which is itself a piece of Go culture worth teaching. It replaced
a rolling performance rating under which three losses from 22 kyu were a promotion.

### The rival: Kesh Idowu
Kesh is 12k and knows it. She meets you at the club the day you arrive, plays you at 9×9,
and — win or lose — files the result away. She reappears at every milestone: the park,
the Beginner Cup, and eventually across a 19×19 board as an equal. Her dialogue tracks the
head-to-head score. She is never a villain; she is the reason you study.

## 6. Go as the combat system

### Match flow
```
RPG world ──► challenge accepted ──► MatchConfig built from opponent data
   ▲                                          │
   │                                          ▼
   │                              Go board scene (independent of the world)
   │                                          │
   │                              play ──► two passes ──► mark dead ──► score
   │                                          │
   └──────── MatchResult ◄────────────────────┘
      (winner, margin, resigned?, board size, handicap, komi, move count)
```
`MatchResult` is the *only* thing the RPG learns from a game. Dialogue, quests and rank
all read from it. The Go board knows nothing about NPCs, quests or the town.

### The review

**Cut (M37), rebuilt on the engine (M40).** From M25 to M36 a match did not end at the
result card: fifteen detectors, an evaluator that priced each finding in points, and a
voice file per character replayed the game at the player. It could say a group had one
liberty and died but never what a move was worth — rules without judgement — and it went.

What replaced it is what every real Go app shows. After the result card, the person you
played asks whether to go over the game. Say yes and KataGo replays every position; the
card says how far it has got and you may walk off, in which case the review waits on the
quay noticeboard. What you get starts with what went right, because the point of the game
is learning to play: how many of your moves were the best move on the board, which ones by
number, and how many more gave nothing away. Then at most three positions: the move that
cost the most, a second loss about a different idea, and, when the engine agreed with you at
a moment that mattered, one strength. Each card is the board before the move, your move filled,
the better move ringed, the cost in points, and one plain sentence about what the better
move does. Under three quarters of a point is noise and is never called a lesson; a game
with nothing to say gets one honest "steady" card. Nobody teaches in it, nobody is named
who has not been met, and nothing in it touches the result or the rank.

### Rules implemented (milestone 1)
9×9; stone placement; liberties; capture; suicide illegal; ko (simple ko, with positional
superko available); passing; two passes ends the game; dead-stone marking; Japanese
(territory + prisoners) and Chinese (area) scoring; configurable komi; handicap placement.

### Teaching order
Concepts are introduced by opponents and puzzles in this sequence, and the game does not
present an opponent whose style requires a concept the player has not been shown:

1. Liberties, capture, self-capture (Wren, capture puzzle)
2. Two eyes, life and death basics (Hana)
3. A first full game: corner starts, first-line caution and urgent stones (Wren)
4. Connection and cutting (Kesh)
5. Corners, sides, influence and whole-board priorities (Hana)
5. Ladders and nets (Pip's ladders, taught properly by Bertie)
6. Simple endgame and counting (Tomás, Bertie)
7. Whole-board judgment at 19×19 (Marguerite, Hana)

### Deciding the colours
Every match opens with the ceremony a real game opens with. In an **even game** the
opponent takes a handful of stones and the player calls odd or even; a correct call wins the
choice of colour. In a **handicap game** there is no nigiri at all -- the weaker player takes
Black with the stones already placed, and komi drops to 0.5. The player is always told, in
one sentence, why they ended up the colour they did. `GoMatchSetup` decides this from the
two ranks; no opponent hard-codes a colour except a scripted story match.

### The tutorial
Ninepoint is a game about learning Go, so it teaches Go. The order is Yasuda Yasutoshi's,
which is how the game is taught in clubs everywhere. Thirteen lessons and, in the middle of
them, a real game -- with a teacher for each, because who teaches a thing is part of what
the thing means here. The last two were added in M30 to stop Hana's course repeating its
final class for the rest of the term, and both are deliberately things the *rules* can
settle, because `tools/check_lessons.py` can only guard a claim it can decide:

| # | Lesson | Where |
|---|---|---|
| 1 | **Liberties** -- a stone's breathing room; edges and corners have fewer; chains share them | Wren, `data/lessons/liberties.json` |
| 2 | **Capture** -- fill the last liberty; chains die whole | Wren, `data/lessons/capture.json` |
| 3 | **Capture Go** -- a real 7x7 game, first capture wins, no territory and no counting | Pip, in the park |
| 4 | **No self-capture** -- and the exception that captures create | Wren, `data/lessons/self_capture.json` |
| 5 | **Ko** -- you may not take it straight back | Wren, once the rulebook has settled |
| 6 | **Escape** -- a group on one liberty is not dead yet | Kesh, after she has cut you apart |
| 7 | **Connection** -- the cut, and not being on the wrong end of one | Kesh, after `escape` |
| 8 | **Ladders** -- the one that works, and the ten seconds of counting that tells you which you have | Bertie, Molenpark |
| 9 | **Openings** -- a usable first-game plan, then the corner/side/centre count | Wren before the first full game; Hana applies it later |
| 10 | **Two eyes** -- what alive actually means | Hana, the class board |
| 11 | **Life and death** -- the vital point | Hana, the class board |
| 12 | **Counting** -- passing, territory, what a captured stone is worth | Tomas, behind his counter |
| 13 | **The capturing race** -- your liberties, their liberties, whose move it is | Hana, the class board |
| 14 | **False eyes** -- the way "two eyes is life" goes wrong | Hana, the class board |

One entry point, and it is a person: Wren asks, the first time you meet her, whether you
have played before, and "never" runs the rulebook -- 1, 2 and 4 -- back to back. There is
no menu item, because being taught by somebody is the point. Everything after the rulebook
is offered by whoever it belongs to, at the moment in the fiction that earns it, and all of
it is optional so a player who already knows Go is never detained. Capture Go is a real
match against a real opponent, not a scripted set piece -- `GoGame.capture_goal` is a rule
of the engine, not a special case in the UI.

**The teaching path was repaired in M27** (ROADMAP §6, now closed). Three of those faults
changed what a player was actually taught: `self_capture` hung off a single dialogue
choice, `knows_the_rules` meant "has had any lesson" rather than "knows the rules", and
four of the eleven lessons ended without their teacher saying anything. Entering the
rulebook anywhere now teaches the rest of it; the flag distinguishes what you were taught
from what you said; and every lesson closes on `taught_<lesson>` or `taught`, so a teacher
with two lessons can end each in its own words. The rulebook can also be asked for again,
and it is asked for from Wren rather than from a menu, for the reason in the paragraph
above.

### Puzzles and lessons
Puzzles are small board positions with a goal (*capture the marked group*, *make two eyes*,
*save your stones*) and a set of accepted solution moves, plus a hint and a written
explanation shown on success. They live in `data/puzzles/*.json` and use the same board
renderer as real matches. The study desk at home replays any puzzle already unlocked.

## 7. Quests

Quests are data. **Four ship**: `first_stones` (below), `enrolment` ("The Lower League"),
`qualifying_exam` and `beginner_cup`. The first is the one worth reading in full, because it
is the shape the others follow:

**"First Stones"**
1. Find De Ketel, further along Ketelsteeg.
2. Learn Wren's rules and a short opening plan.
3. Play Wren's unrated 9×9 first full game. (Either result advances.)
4. Play Kesh's rated 9×9 game. (Either result advances.)
→ Kesh gives you 22 kyu and starts `enrolment`: the tram north, Hana's capture problem,
Marguerite's register, the league board, a class, a league win.

Tournament arcs are built -- the Cup and the exam are both quests. Two more shipped and were
cut in M37: `the_hooks`, a second progression at De Ketel that disagreed with the league on
purpose, and `page_forty`, a borrowed book in a game with no inventory screen. One
progression is enough for a player to read, and it is the league board.

## 8. Tournaments (post-slice design)

The Steenbeek Cup: 4 rounds in a hired room at the Bondszaal, run round after round once
you tell Marguerite you are ready. Placing changes your rank the way every other result
does -- through the record.

**Two sections, and the difference between them is the argument.** The beginners' section
has a **ceiling** -- fifteen kyu and below -- and therefore no handicap: everybody in it is
within a few stones of everybody else, and the entry requirement does the work. The open
section has **no ceiling** and hands out stones instead. Those are the two ways Go deals
with a gap in strength, and the Cup runs one of each. Nine lines below the ceiling,
thirteen above it.

Which one you are in is decided by the rank on your card, at the registrar's desk, which is
how a real event does it. The one exception is deliberate: a player still under the ceiling
who has won three rated games may choose to **play up** into the open section. Marguerite
will enter them, and will say first that it is four games against people who will beat you.

The open field is the only place in Verhaven where the two Go cultures sit down at the same
table with a result form on it: Kesh, Ilse, Tomás, Sunny and Orla, the Instituut and De
Ketel in one column, because the Bondszaal is the federation and therefore neutral ground.
Joos is not in it and cannot be -- the federation needs a rank written down, and he has
never had one.

## 9. Progression map (full game sketch)

| Chapter | Board | Player rank arc | Gate |
|---|---|---|---|
| 1 Arrival | 9×9 | unranked → 22k | Vertical slice |
| 2 The back table | 9×9 → 13×13 | 22k → 17k | Win 3 rated games — **built (M28)** |
| 3 Beginner Cup | 13×13 | 17k → 14k | Enter tournament |
| 4 The Park Crowd | 13×13 | 14k → 10k | Beat Bertie at 4 stones |
| 5 Kesh, Even | 19×19 | 10k → 8k | Rival match, no handicap |
| 6 Teaching Game | 19×19 | 8k → 6k | Hana at 9 stones, then 6 |

Each rank step is gated on the human actually winning games at the appropriate handicap.
The game will not hand out a rank for time served.

**Chapter 2's gate is real.** Three rated games won opens a 13×13 -- Tomás's back table at
De Ketel, which Kesh will also play you on -- through the `rated_wins_at_least` condition,
counted off the record rather than kept in a flag.

**Chapter 3's board is real too.** §8's open section is built (M33) and is played on
thirteen lines, so the Cup is no longer a 9×9 event with a bigger board promised beside it.
The same `rated_wins_at_least` gate that opens the club's 13×13 also opens the option of
playing up into it, which is the two chapters meeting where the design always had them
meet. What chapters 4 and up still are is a sketch: the rank arcs above 14k need an
opponent ladder that runs past about 8 kyu, which is §9 of ROADMAP and the engine question.

## 10. Tone and content

Gentle, adult, unhurried. No violence — the town's stakes are pride, friendship and a
trophy that is mostly a shelf ornament. Humour is dry and character-driven. Text should be
short enough to read on a dialogue box in three breaths.

## 11. Accessibility & quality-of-life

- Coordinates and move numbers toggleable on the board.
- Last-move marker and capture count always visible.
- Confirm-before-place option for touch/controller.
- Undo in unrated and teaching games only; never in rated games or tournaments.
- Colour-blind-safe last-move and territory markers (shape, not only colour).
- Text speed and instant-complete on button press.

## 12. Out of scope for v1

Online play, real-time clocks, SGF import/export UI (games are recorded, but there is no
kifu browser), a second town, romance systems, crafting.
