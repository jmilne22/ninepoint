# NINEPOINT — Game Design

> A PS1-inspired 2.5D RPG about learning to play Go, set in **Sela**, a warm, leafy coastal city.
> There are no combat statistics. The only thing that gets stronger is the person holding the controller.

---

## 0. Structure

The beginner journey is **opening lessons → provisional 30k → five novice fixtures
→ Beginner Cup ending**. Afterwards the player may register for the Academy League
and try its qualifying exam. The academy atmosphere was inspired by competitive
student leagues, but an aspiring-professional exam is an optional advanced goal.

- Hana introduces herself and asks the player's name before the world appears.
- In Sela, Pip teaches Capture Go, Wren teaches rules and finishing before a supported unrated
  first full game. Kesh issues the novice card and invitation, then offers optional
  unrated handicap practice. This supersedes the original required even game (PROG-02).
- At the Institute, Hana welcomes the player and offers Two Eyes before registration.
  Marguerite points to the back-wall board and lower west novice room. Noor wants company
  through her first league and toward the Cup; five classmates share that goal in different ways.
- Completing all five fixtures earns the main Cup invitation, regardless of wins.
  Earlier Cup entry remains available. Completing four Cup rounds at any placing is
  the beginner ending; Academy competition and its even-game exam follow by choice.

**There is no relationship or affection system.** What the game tracks instead is your
**record** against each person, which is what actually matters between two Go players and
is what the rival dialogue reads from.

**The league board is the progression.** Each division has recorded, repeatable attempts.
Wins decide standings; ties use stronger entry rank, frozen when the attempt begins,
then name. Everyone begins at zero. A fixed round robin schedules every pair once,
with byes in the seven-player Academy field. Each player round settles its scheduled
NPC games once, using deterministic simulated results. The board says they are simulated.
Practice never changes a fixture, and a rematch cannot replace a loss. Completed attempts
remain browsable while a new attempt starts from zero. Player outcomes reference the
append-only match history; NPC outcomes are saved on fixtures. No hidden effort score exists.

**There is no clock.** There was one from M19 to M36 — hours, days, a weekday, weather and
schedules that moved people between rooms — and M37 cut all of it, because none of it was
Go and all of it was complexity the player had to carry: a quest step could hide behind an
hour, a room could be empty, and the after-game line could be about a game from last week.
Everyone stands where they live. A game costs nothing but the game. The exam and the Cup
start when you tell Marguerite you are ready.

## 1. Premise

You have just moved into a rooftop room above a closed stationer's on **Market Lane**,
in the fictional coastal city of **Sela**. The last tenant left a Go board and no instructions.
Outside, shutters open over shop awnings and a shaded boulevard garden. Pip and Bertie
keep a table there. Three steps below the pavement, **The Kettle** is Tomás's neighborhood
bar; Wren makes room for beginners and Kesh wants another opponent.

Tram 4 links the neighborhood to the **Sela Go Institute** and **Assembly Hall**. The
institute occupies a modernist building with a planted court; the hall hosts the Cup.
Go belongs to the city's ordinary shared spaces. You begin knowing nothing about it.

### Three ways to belong

The bar provides familiar opponents and patient practice. The institute offers a group
of fellow learners and organized competition. The laundry provides casual company while
people finish everyday chores. These are equally valid ways to enjoy Go. Joos keeps his
own quiet alcove in the Arcade, off the public passage to Sea Walk.

This replaces the former above-ground institution / underground authenticity opposition.
Hana and Marguerite are welcoming people; their setting should support their established
voices. The neighborhood remains useful after enrolment and after the Cup.

The title refers to the nine star points of a full 19×19 board. The player's first game
is Capture Go on 7×7; the first full game is 9×9. Nineteen-line town teaching remains future work.

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
| Head-to-head record | Results inform greetings and repeat conversations; no affection score. |
| Key items | A rank certificate and a tournament entry slip. Narrative keys. |
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
Their face reacts while you play: seven expressions per portrait, chosen from what just
happened on the board and how the game is going. Reactions are to **outcomes** — a capture
landed, a group is in atari, a ko started, they are behind — never to whether your move was
a good one. Judgement belongs to the review, after the game.

### P4 — Compact and alive over large and empty
One town, twelve rooms, twenty people who are always where they live.
Better a café whose owner remembers your last game than a continent of silent villagers.

### P5 — Losing is content
This is a game about a beginner. The rival will beat you, probably several times.
Defeat advances the story and never blocks progress. There is no game-over screen.

## 3. Core loop

```
        ┌──────────────────────────────────────────────────┐
        │                                                  │
   Explore Sela  ──► Talk to NPCs ──► Discover challenges,
        ▲                                    lessons, quests
        │                                          │
        │                                          ▼
  Unlock locations,                          Play Go  ◄──── the actual game
  new opponents,                                  │
  new concepts                                    ▼
        │                              Result changes rank,
        │                              head-to-head records, story
        │                                          │
        └────────── Enter tournaments ◄────────────┘
```

The loop tightens: early games are 9×9 against people who explain what they are doing;
the planned later games are 19×19 against people who expect you to already know.
The UI supports nineteen lines through a development route; town access and the teaching
bridge from thirteen remain unbuilt. Interface inspection is available to every learner
using that board and never depends on rank or an earned ability.

## 4. Sela

Compact and walkable: Market Lane, Sea Walk and the Arcade form a loop. The park remains part of Market Lane; twelve maps retain their internal IDs:

| Location | Role | Regulars |
|---|---|---|
| **Rooftop Room** (player's home) | The study desk (puzzles) | — |
| **The Kettle** | Informal lessons, practice games, then the rival | Tomás, Wren, Kesh |
| **The Arcade** (the arches) | Nine stones from a man with no card | Joos |
| **Boulevard Garden** | Fast outdoor games, the stone tables | Bertie, Pip |
| **Market Lane** | The street: the tram stop, noticeboard, snack window, the stationer's | — |
| **The Laundry** | The laundrette. The city's third register: nothing at all is written down | Abel, Dov, Moss |
| **Sea Walk** | Sea water and one bench. Where you go after losing; the noticeboard holds the last game you asked somebody to go over | — |
| **Sela Go Institute** | Classes, the internal league, the study hall | Hana, Marguerite, the students |
| **Assembly Hall** | The federation hall: tournaments and the exam | Marguerite |

**Built:** Rooftop Room, Market Lane (street + garden), The Laundry, The Kettle,
The Arcade, Sea Walk, Assembly Hall and the five institute rooms. Twelve maps.

The laundry provides everyday company alongside the bar and institute. Two residents
prefer unrated games; Moss wants a record. Two of the three games played there are unrated for that reason, and the third is
rated because the one person who wants a record is the one who has spent three years managing
his.

### Schedules

**Cut (M37).** From M26 to M36 a map's NPC entry could carry hours, weekdays and weather,
and the same person stood in different rooms at different times. It was the largest source
of complexity in the game and it decided nothing a player could act on: a quest step could
hide behind an hour, and the tests needed a 56-combination cover just to prove nobody had
been scheduled out of existence. Everyone now stands on one map, always. The one design
consequence worth keeping: Hana cannot be both at The Kettle for Act 1 and in the classroom
for Act 2, so Kesh hands out the first rank and the tram, and Hana meets you at the
Institute.

Locations can still remember progress. After lessons, matches, enrolment and events, a map
may change its conversation pair, clutter, notices or overheard remarks. These **presence
states** are persistent, legible on revisits and never make a person or service unavailable;
they give Sela social movement without putting a clock back in the player's pocket.

## 5. Cast

The original fifteen characters keep their ranks, identities and venues. Five novice
classmates now live permanently in `academy_novice`, through the hall's lower west door:

| Classmate | Target rank | Detail |
|---|---|---|
| Noor Dekker | 30k | Keeps a postcard under the bowl |
| Ivo Maas | 27k | Bicycle courier with a tiny pencil |
| Lea Vos | 25k | Brings scrap paper from the print shop |
| Emil Bakker | 23k | Repairs lamps and lays out the stones |
| Sora Meijer | 20k | Keeps a spare cushion for a visitor |

These ranks are calibration targets, not measured Human-SL profiles. Each has a separate,
fixed engine configuration. Content release remains blocked on independent beginner
playtesting; bot results alone cannot establish plausible human peers. See WORKBOARD PROG-01.
The original prototype cast is retained below; CLAUDE.md carries the full cast list.

| # | Name | Rank | Role | Personality | Style at the board |
|---|---|---|---|---|---|
| 1 | **Wren Calloway** | 20k | Beginner friend | Considerate host; prepares the table and offers help while uncertain about her own Go | Plays contact moves everywhere; no plan, no malice |
| 2 | **Kesh Idowu** | 12k | Recurring rival | Sharp, impatient, competitive in a way she is slightly embarrassed by; keeps score of your meetings | Cuts first, counts never. Fast. Punishes loose shapes |
| 3 | **Pip Arnesen** | 18k | Enthusiastic weaker player | Boundless, loud, wants to play *right now*, loses cheerfully | Attempts ladders. The ladders do not work. Attempts them again |
| 4 | **Bertie Vale** | 4k | Older park player | Established park regular; brushes leaves from his usual bench and offers a seat | Territorial, fast, solid. Will not fight you; will out-count you |
| 5 | **Nadia Ferreira** | 2k | Senior student | Methodical, polite, a little tired; sits in on the beginners' classes | Opens by the book. Struggles when you leave the book |
| 6 | **Hana Oyelaran** | 5d | Club teacher | Patient, attentive; asks answerable questions beside demonstrated positions | Teaching games at handicap; will not crush you, will not let you off |
| 7 | **Tomás Beir** | 8k | Bar owner | Gruff, practical, counts | Loose, instinctive, surprisingly good endgame |
| 8 | **Marguerite Sable** | 1d | Tournament organiser | Prepared, competent and welcoming; keeps registration and results clear | Precise, orthodox, low-risk |
| 9 | **Joos** | `?` | The man at the arches | Private and practical; maintains a dry corner beneath the arches | Territorial and patient. Three dan behind a label he refuses to fill in |

### Player rank
Starts **unranked**. Kesh gives you provisional 30 kyu before offering optional practice, a starting club estimate. After that the rank
is a step ladder (`GoRankLadder`): beat somebody at or above your rank and it goes up one;
lose to somebody at or below it and it goes down one; anything else changes nothing.
Handicap is priced in at what the board says a stone is worth. Park and arch games are
unrated and move nothing, which is itself a piece of Go culture worth teaching. It replaced
a rolling performance rating under which three losses from 22 kyu were a promotion.

### The rival: Kesh Idowu
Kesh is 12k and knows it. She meets you at the club the day you arrive, plays you at 9×9,
and — win or lose — files the result away. She remains available at The Kettle throughout the journey, including for her scheduled league fixture. Her dialogue tracks the
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

The accepted score produces one recorded result. The player returns to the world for the
opponent’s win/loss reaction, or the Cup/exam completion announcement, before the optional
review offer. Rematches belong to the next normal interaction. Analysis may continue after
Escape; its result waits at the quay, south past the park. Starting another match or loading
another session cancels unfinished analysis without changing any result.

The review starts with the engine tally, then a best move and at most two costly positions.
Move numbers include both players; the tally counts placements and is not a beginner grade.
C compares the original position, the played move and the engine preference, each applied
independently. Only immediate captures, distinct connected groups and liberties are explained
as board facts. The engine’s score includes later play that these comparisons do not show.
Extra liberties never prove survival, contact alone never proves a useful attack, and the
first line is not prohibited. Recommendations stay together across measured pages.

### Rules implemented (milestone 1)
9×9; stone placement; liberties; capture; suicide illegal; ko (simple ko, with positional
superko available); passing; two passes ends the game; dead-stone marking; Japanese
(territory + prisoners) and Chinese (area) scoring; configurable komi; handicap placement.

### Teaching order
The default early route is:

1. Pip’s real Capture Go encounter.
2. Wren: extend a group, identify a capture, try a refused self-capture, then the capture exception.
3. Wren: inspect a demonstrably living/dead position, choose a final boundary move, pass twice, inspect and confirm the count.
4. Optional opening comparisons, then a supported unrated full 9×9. Help follows the actual position.
5. Kesh’s provisional card and invitation to meet beginners; optional handicap practice.
6. Hana’s welcome and first class applying survival knowledge, registration and the league board.
7. Noor, Ivo and the remaining novice fixtures; the Cup becomes a shared ambition.

Longer rules, territory shapes, ko, escape, connection, ladders and Tomás’s deeper score
inspection remain optional. Later school classes cover life and death, capture races and
false eyes. Whole-board judgement and a nineteen-line teaching transition remain separate
work; this sequence does not certify beginner readiness or opponent ranks.

### Deciding the colours
Every match opens with the ceremony a real game opens with. In an **even game** the
opponent takes a handful of stones and the player calls odd or even; a correct call wins the
choice of colour. In a **handicap game** there is no nigiri at all -- the weaker player takes
Black with the stones already placed, and komi drops to 0.5. The player is always told, in
one sentence, why they ended up the colour they did. `GoMatchSetup` decides this from the
two ranks; no opponent hard-codes a colour except a scripted story match.

### The tutorial
Teaching belongs to people and demonstrated positions. Wren’s default beginner track queues
`first_game_rules` then `finishing`; the optional `openings` lesson has two comparisons.
All result explanations remain beside the board. Scripted proofs use real legal moves or
real refusals, and the count uses territory, prisoners, komi and manual group marks.

Sixteen lesson files are available. The older `liberties`, `capture` and `self_capture`
track remains a refresher; `territory_shapes` preserves the longer enclosure examples.
Tomás’s `counting` inspects score components rather than repeating wall construction.
Hana’s `two_eyes` class compares secure eyes with a boundary stone that can be captured.
The remaining files are `ko`, `escape`, `connection`, `ladders`, `life_and_death`,
`capture_race` and `false_eyes`.

Wren acknowledges Pip, or offers a route for someone who has not met him. Explicit
experienced-player choices skip rules, finishing and opening advice without requiring a win.
Leaving a lesson keeps completed lessons and permits a return. Old saves reconcile the
changed school journal from durable facts; finished quests, ranks and fixture records remain.
The M27 repair remains historical: teaching completion and an explicit claim of knowing the
rules are separate facts, and lesson returns use `taught_<lesson>` or `taught`.

### Puzzles and lessons
Puzzles are small board positions with a goal (*capture the marked group*, *make two eyes*,
*save your stones*) and a set of accepted solution moves, plus a hint and a written
explanation shown on success. They live in `data/puzzles/*.json` and use the same board
renderer as real matches. The study desk at home replays any puzzle already unlocked.

## 7. Quests

Quests are data. **Four ship**: `first_stones` (below), `enrolment` ("The Novice League"),
`qualifying_exam` and `beginner_cup`. The first is the one worth reading in full, because it
is the shape the others follow:

**"First Stones"**
1. Find The Kettle, further along Market Lane.
2. Learn Wren’s rules and finishing lesson, or explicitly skip teaching. Opening advice is optional.
3. Play Wren's unrated 9×9 first full game. (Either result advances.)
4. Ask Kesh for your novice card. Her handicap 9×9 practice is optional and unrated.
→ Kesh gives provisional 30 kyu and starts `enrolment`: tram north, Hana’s welcome/class,
Marguerite’s register, league board and five novice fixtures. The arrival capture puzzle is optional.

Tournament arcs are built -- the Cup and the exam are both quests. Two more shipped and were
cut in M37: `the_hooks`, a second progression at The Kettle that disagreed with the league on
purpose, and `page_forty`, a borrowed book in a game with no inventory screen. One
progression is enough for a player to read, and it is the league board.

## 8. Tournaments (post-slice design)

The Sela Cup: 4 rounds in a hired room at the Assembly Hall, run round after round once
you tell Marguerite you are ready. Placing changes your rank the way every other result
does -- through the record.

**Two sections.** Beginners are 15k and weaker on 9×9 with rank-based handicap.
Open has no ceiling and uses 13×13 with handicap. A player under the beginner ceiling
with three rated wins may play up. The town opponents remain Wren, Pip, Abel, Dov and
Moss in beginners; Kesh, Ilse, Tomás, Sunny and Orla in open. Joos remains ineligible.
Old Cups already entered retain their original rules through their remaining rounds.

After the Cup, Marguerite offers the **Academy League**: Kesh 12k, Ilse 9k, Sunny 6k,
Orla 4k, Nadia 2k and Marguerite 1d. Complete six fixtures; the top four eligible entrants,
excluding the registrar, enter the exam. Board, dialogue and exam use one qualification
calculation. A failed league attempt permits another complete attempt, without replacing
individual losses. Legacy leagues retain their old baseline and qualification route;
novice enrolment is offered explicitly without resetting ranks, records or certificates.

New Cup entries also save the player's entry rank for the draw. Rated results may change
handicap at the next board, but cannot reconstruct earlier Cup pairings from a different
rank. The Cup retains its existing score-based pairing rule, including an occasional
rematch when the six-player draw cannot pair the remaining players afresh. Legacy active
Cups retain their original policy. This is separate from leagues, where every scheduled
pair appears exactly once per attempt.

## 9. Progression map (full game sketch)

| Chapter | Board | Player rank arc | Gate |
|---|---|---|---|
| 1 Arrival | 9×9 | unranked → 30k | Vertical slice |
| 2 The back table | 9×9 → 13×13 | 30k onward | Win 3 rated games — **built (M28)** |
| 3 Beginner Cup | 13×13 | 17k → 14k | Enter tournament |
| 4 The Park Crowd | 13×13 | 14k → 10k | Beat Bertie at 4 stones |
| 5 Kesh, Even | 19×19 | 10k → 8k | Rival match, no handicap |
| 6 Teaching Game | 19×19 | 8k → 6k | Hana at 9 stones, then 6 |

Each rank step is gated on the human actually winning games at the appropriate handicap.
The game will not hand out a rank for time served.

**Chapter 2's gate is real.** Three rated games won opens a 13×13 -- Tomás's back table at
The Kettle, which Kesh will also play you on -- through the `rated_wins_at_least` condition,
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

## 10b. What the town has to say for itself

A place the player cannot read is a place they get lost in, and none of it is dialogue.
Four rules, all of them levels and art rather than systems:

- **The playable boundary is closed unless it is a door.** Scenery continues beyond it:
  paving, neighboring buildings and sea fill the camera view. Existing collision defines
  where walking ends; background buildings do not imply additional playable entrances.
- **Every threshold is drawn.** A door has a frame and daylight under it, a mat inside it,
  and a line at the bottom of the screen naming where it goes. A tram stop has a shelter
  and a boarding slab. The steps to the water have a path worn to them.
- **The person is the ruler.** Furniture is drawn at the size it would be beside a person.
  A goban is a person's shoulders wide; a table may be bigger, a board may not.
- **You can sit down on the other side of a board.** A board is two tiles deep, so the far
  chair is a real place to stand and the person across it answers from there.

## 11. Accessibility & quality-of-life

- Hold Shift to run throughout the town; running is unlimited and carries no character stat.
- Coordinates and move numbers toggleable on the board.
- Last-move marker and capture count always visible.
- Confirm-before-place option for touch/controller.
- Undo in unrated and teaching games only; never in rated games or tournaments.
- Colour-blind-safe last-move and territory markers (shape, not only colour).
- Text speed and instant-complete on button press.

## 12. Out of scope for v1

Online play, real-time clocks, SGF import/export UI (games are recorded, but there is no
kifu browser), a second town, romance systems, crafting.

## Sela presentation and teaching

Dialogue is written around a person's immediate situation: clearing cups, finding a chair,
preparing for the Cup or marking a book. Short exchanges may stay ordinary. Repeat visits
reach game offers quickly; further conversation and the existing three/six-game reactions
add familiarity without another progression system. Post-match speech acknowledges the
actual result. Detailed move judgement belongs to the engine review, with positive findings
first and at most two costly positions. Table talk describes observable events only.

Pip's Capture Go and Wren's first practice use empty boards. Kesh issues the novice card
before offering optional unrated practice, which now uses rank-based handicap. At 30k
against her 12k, the existing 9×9 cap gives five stones. Her engine strength is unchanged.
Handicap is introduced after a rank exists, with two player-controlled explanation stages beside the real board, an explicit
skip and H to reopen. The explanation handles receiving and giving stones, White moving
first, ordinary capturable stones, actual komi, rank consequences and optional rank-gap math.
Joos has no published rank; his head start is an agreement shown by the setup.

Venue identity comes from architecture and useful objects, with restrained floor detail.
Persistent activities and ordered conversations use existing lesson, match, enrolment and
event flags. Exam and Cup conclusions state the outcome and allow warm acknowledgements
at familiar places. No schedules, affection, errands, character statistics or new currencies
are introduced. Actual observed play is the acceptance test for this presentation.

## Sela journey and setting revision

Tel Aviv's recessed balconies, planted setbacks, shaded kiosks and stepped waterfronts
inform original model-rendered architecture. They are references for the fictional city, not literal
geography or a new identity for any character. One fixed mild afternoon replaces perpetual
drizzle; no clock, weather simulation, heat meter or shop economy is introduced.

The complete teaching/league/Cup sequence stays intact. Home and Pip are close together;
the kettle sign identifies Wren's venue; the institute court shows the league board,
registration and labeled room entrances. The same named people stay in the same internal
venues. After lessons and the Cup, existing progress-based exchanges and details supply
return-visit changes without schedules.

Market Lane connects to Sea Walk through the garden steps and to the Arcade through its
east entrance. Sea Walk's east steps join the Arcade's east exit. The reverse connections
are always available. Tram 4 remains at Market Lane's west end; its existing invitations
and eligibility gates remain unchanged. Sea Walk keeps the asynchronous review noticeboard.

White City balcony forms and Jaffa Port stonework/boats inform distinct city and harbor
compositions. Rooms and streets use a fixed 45°/30° view with screen-relative movement;
the camera follows large maps. Go stays overhead for clear intersections. Character
models supply both eight-way sprites and dialogue busts. This presentation changes no
teaching order, ranks, cast identities or progression rules. [Art direction](ART_DIRECTION.md).
