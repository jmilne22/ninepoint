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
                     rules. Kesh challenges you.     - the league board: your record
                     Hana teaches at the             - the qualifying exam (the goal)
                     Instituut, two stops north.
                          (Hikaru no Go)                  (Tag Force / insei)
```

- **The opening** is the Pokemon position: somebody speaks to the player before the
  world exists and asks what to call them. Hana takes it, which means she is a
  familiar face by the time you meet her in Act 1.
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

**Built:** the day counter. A day holds `SLOTS_PER_DAY` hours; a rated game or a class costs
one, and lessons, puzzles and the unrated games in the park and under the arches are free --
the distinction Go culture already draws, used as the economy. Spending an hour moves
`time_block` through morning, afternoon, dusk and night, which is what finally makes the
atmosphere systems visible in play. Sleeping is the only thing that advances the day, so the
player is never punished for sitting and thinking about a position. The term ends in the
Beginner Cup on day `CUP_DAY`; the qualifying exam is the same machinery and is not built.

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
exam that culls you, and everything recorded. Below, after dark, **De Ketel** and
**Onderbrug**: an hourly rate chalked on a slate, brass hooks with the regulars' cards on
them, cash on the crate, and nobody asking to see your papers.

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
| Knowledge | Lessons, puzzles, proverbs, reviews. Lives in the human's head. |

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
One town, six locations, eight people who have somewhere to be at a given hour.
Better a café whose owner remembers your last game than a continent of silent villagers.

### P5 — Losing is content
This is a game about a beginner. The rival will beat you, probably several times.
Defeat advances the story, unlocks a review with the teacher (built — see section 6),
and never blocks progress. There is no game-over screen.

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

Compact, walkable, vertical: a street with rooms above it and rooms below it. Eight locations:

| Location | Role | Regulars |
|---|---|---|
| **The attic** (player's home) | Save point, sleep to advance day, study desk (puzzles) | — |
| **De Ketel** | Rated games, lessons, the hooks | Tomás, Wren, Kesh, Hana |
| **Onderbrug** (the arches) | Money games, blitz, night | Bertie, Pip, Joos |
| **Molenpark** | Fast outdoor games, the stone tables, daylight | Bertie, Pip |
| **Ketelsteeg** | The street: tram stop, wassalon, noticeboard, the stationer's | — |
| **The quay** | Grey water and one bench. Where you go after losing | — |
| **Essenveld Instituut** | Classes, the internal league, the study hall | Hana, Marguerite, the students |
| **Bondszaal** | The federation hall: tournaments and the exam | Marguerite |

**Built so far:** Ketelsteeg (street + park end), De Ketel, and the four Instituut rooms. The
attic, Onderbrug, the quay and the Bondszaal are designed and not built.

### Schedules
NPCs occupy different locations by time-of-day block (Morning / Afternoon / Evening).
Time advances when the player sleeps and on certain story beats — not on a real-time clock,
so the player is never punished for thinking about a position.

## 5. Cast

Eight characters for the prototype. Ranks are real ranks; the ladder from 20k to 5d is the
game's difficulty curve made human.

| # | Name | Rank | Role | Personality | Style at the board |
|---|---|---|---|---|---|
| 1 | **Wren Calloway** | 20k | Beginner friend | Warm, anxious, over-apologises, genuinely delighted by other people's good moves | Plays contact moves everywhere; no plan, no malice |
| 2 | **Kesh Idowu** | 12k | Recurring rival | Sharp, impatient, competitive in a way she is slightly embarrassed by; keeps score of your meetings | Cuts first, counts never. Fast. Punishes loose shapes |
| 3 | **Pip Arnesen** | 18k | Enthusiastic weaker player | Boundless, loud, wants to play *right now*, loses cheerfully | Attempts ladders. The ladders do not work. Attempts them again |
| 4 | **Bertie Vale** | 4k | Older park player | Gruff, dry, generous underneath; deals in proverbs of variable relevance | Territorial, fast, solid. Will not fight you; will out-count you |
| 5 | **Nadia Ferreira** | 2k | Club regular | Methodical, encyclopaedic, carries a joseki book she quotes at you | Opens by the book. Struggles when you leave the book |
| 6 | **Hana Oyelaran** | 5d | Club teacher | Patient, unhurried, asks questions instead of answering them | Teaching games at handicap; will not crush you, will not let you off |
| 7 | **Tomás Beir** | 8k | Café owner | Easy, hospitable, plays exactly one game a day and means it | Loose, instinctive, surprisingly good endgame |
| 8 | **Marguerite Sable** | 1d | Tournament organiser | Brisk, fair, allergic to slow pairing | Precise, orthodox, low-risk |
| 9 | **Joos** | `?` | The man at the arches | Laconic, unimpressed, will not discuss himself. No surname offered | Territorial and patient. Three dan behind a label he refuses to fill in |

### Player rank
Starts **unranked**. After the first rated club game you are given a provisional rank
(22k for the slice). Rank moves on rated results only — park blitz and café games are unrated,
which is itself a piece of Go culture worth teaching.

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
   └──────── MatchResult ◄──── the review ◄───┘
      (winner, margin, resigned?, board size, handicap, komi, move count, findings)
```
`MatchResult` is the *only* thing the RPG learns from a game. Dialogue, quests, rank and
relationships all read from it. The Go board knows nothing about NPCs, quests or the town.

### The review

In Go the review is usually longer than the game, and it is where the learning actually
happens. So a match does not end at the result card: the person you just played walks you
back through your own board first.

`GoReview` replays the finished game from its move list and reports what happened in it. It
works in three layers, and the separation is the design:

**What happened.** Fourteen detectors, each a fact about the board: a group left in atari
and where its liberty was, a group that died when a move would have saved it, an eye you
filled, stones you put on one liberty, a capture of theirs you never took, a group you kept
feeding after it was lost, your own territory filled in at the end, a cut you answered
somewhere else, a ladder you ran into, a game you should have stopped playing. And four that
are not optional: a capture, a group you got out, an atari you answered, and the best move
you played.

**What it cost.** A `GoEvaluator` prices every finding in points, so the review can lead
with the worst thing that happened rather than the thing whose detector happened to shout
loudest. The shipped implementation, `GoProgress`, counts what a person counts — stones on
the board, plus the empty points that only one colour has walled off — after every move.
That curve also answers the question a beginner most wants answered and no single finding
can: *where did the game turn?*

**Who says it.** `GoReviewVoice` overlays a character's file on `default.json`, so Kesh is
furious and precise, Hana asks rather than tells, and Joos manages four words.

Four rules keep it a review rather than an audit:

- **It always opens with something you did.** Not "when there is something to praise" —
  always. P5 says losing is content, and a list of failures makes it punishment instead. The
  compliment used to be conditional, which meant the bad games were the likeliest to open on
  a criticism; measuring it found 44 of 60 games doing exactly that. `best_moment` is the
  floor: every game contains a move after which you were better off.
- **Only what you are ready to hear.** The gate holds back only the kinds that genuinely
  need a stronger reader. It used to follow the lesson order, which was wrong — lessons are
  ordered by what builds on what, a review by what you can act on tomorrow.
- **One of each kind, at most three, told in the order they happened.** Four ignored ataris
  are one mistake made four times, and the review says so rather than saying it four times.
- **Only from somebody stronger — but refusing is not silence.** Wren is 20k and will not
  tell you what you did wrong once you pass her. She will still tell you what was good, and
  where the game turned, because neither of those needs authority she does not have.

And then it does two things a list of sentences cannot. Each finding carries a **takeaway**,
one portable sentence that is the rule rather than the voice, and the id of the lesson that
covers it. And where a finding has a single right answer, the review **hands the position
back as a puzzle** — the mistake you made ninety seconds ago, to solve now, which is the
readiest a beginner ever is. The whole game is steppable with the arrow keys throughout,
because "how did we get here" is the question actually being asked.

Across games, `GoReviewHistory` reads the compact summary each match leaves in
`GameState.match_records` and notices the pattern a single review cannot: that this is the
third game running. `head_to_head` records your results; this records your play.

None of this needs an engine. A group that had one liberty and died is a fact about the
board rather than an opinion about it, and so is the arithmetic that says it cost eleven
points — those are the mistakes that decide games at kyu strength. Judgement — *this move
was worth four points rather than nine* — is what an engine would add, and it is a sentence
no beginner can act on. `The Conquest of Go` bundles KataGo for exactly that and pays for it
in hundreds of megabytes, a build per platform, and forum threads about the engine freezing;
`GoEvaluator` is the seam where it could go later without touching a detector or a line of
dialogue. The review also grows rarer as the player improves, because a clean game produces
little to say, which makes it one more honest signal of the only progression this game
believes in.

### Rules implemented (milestone 1)
9×9; stone placement; liberties; capture; suicide illegal; ko (simple ko, with positional
superko available); passing; two passes ends the game; dead-stone marking; Japanese
(territory + prisoners) and Chinese (area) scoring; configurable komi; handicap placement.

### Teaching order
Concepts are introduced by opponents and puzzles in this sequence, and the game does not
present an opponent whose style requires a concept the player has not been shown:

1. Liberties, capture, self-capture (Wren, capture puzzle)
2. Two eyes, life and death basics (Hana)
3. Connection and cutting (Kesh)
4. Corner > side > centre, opening shape (Nadia)
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
which is how the game is taught in clubs everywhere:

| # | Lesson | Where |
|---|---|---|
| 1 | **Liberties** -- a stone's breathing room; edges and corners have fewer; chains share them | Wren, `data/lessons/liberties.json` |
| 2 | **Capture** -- fill the last liberty; chains die whole | Wren, `data/lessons/capture.json` |
| 3 | **Capture Go** -- a real 7x7 game, first capture wins, no territory and no counting | Pip, in the park |
| 4 | **No self-capture** -- and the exception that captures create | Wren, `data/lessons/self_capture.json` |
| 5 | Two eyes and life | Hana *(not yet built)* |
| 6 | Passing, territory, counting -- then a full 9x9 | Hana *(not yet built)* |

Two entry points, both optional so a player who already knows Go is never detained:
**"Learn to play"** on the title screen runs lessons 1, 2 and 4 back to back and then puts
you on Ketelsteeg; and Wren asks, the first time you meet her, whether you have played
before. Capture Go is a real match against a real opponent, not a scripted set piece --
`GoGame.capture_goal` is a rule of the engine, not a special case in the UI.

### Puzzles and lessons
Puzzles are small board positions with a goal (*capture the marked group*, *make two eyes*,
*save your stones*) and a set of accepted solution moves, plus a hint and a written
explanation shown on success. They live in `data/puzzles/*.json` and use the same board
renderer as real matches. The study desk at home replays any puzzle already unlocked.

## 7. Quests

Quests are data. The slice ships one:

**"First Stones"** *(Q_FIRST_STONES)*
1. Leave your room.
2. Find De Ketel, further along Ketelsteeg.
3. Speak to Wren inside — she explains the Beginner Cup.
4. Speak to Kesh; accept her 9×9 challenge.
5. Play the game. (Either result advances.)
6. Speak to Hana, who has been watching, and solve her capture puzzle.
→ Rewards: provisional rank 22k, De Ketel membership key item, Kesh relationship established.

Planned quest shapes beyond the slice: *ladder* quests (beat three park players),
*fetch-with-meaning* quests (return Nadia's joseki book after using it), *tournament arcs*.

## 8. Tournaments (post-slice design)

The Steenbeek Beginner Cup: 4 rounds, McMahon-ish pairing against NPCs near your rank,
one game per in-game day, played on 9×9 or 13×13 depending on the section entered.
Between rounds you may study, review with Hana, or scout opponents in the café.
Placing changes your rank and unlocks the 13×13 section of the club.

## 9. Progression map (full game sketch)

| Chapter | Board | Player rank arc | Gate |
|---|---|---|---|
| 1 Arrival | 9×9 | unranked → 22k | Vertical slice |
| 2 The Hooks | 9×9 → 13×13 | 22k → 17k | Win 3 rated games |
| 3 Beginner Cup | 13×13 | 17k → 14k | Enter tournament |
| 4 The Park Crowd | 13×13 | 14k → 10k | Beat Bertie at 4 stones |
| 5 Kesh, Even | 19×19 | 10k → 8k | Rival match, no handicap |
| 6 Teaching Game | 19×19 | 8k → 6k | Hana at 9 stones, then 6 |

Each rank step is gated on the human actually winning games at the appropriate handicap.
The game will not hand out a rank for time served.

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

Online play, real-time clocks, SGF import/export UI (games are recorded and the review
reads them, but there is no kifu browser),
a second town, romance systems, crafting.
