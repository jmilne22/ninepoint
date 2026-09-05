# Ninepoint

A top-down 2D RPG about learning to play **Go (baduk)**, built in Godot 4.7.

You have just moved to Steenbeek. There is a salon three steps below the pavement, regulars
in the park who keep a table free, and a beginner tournament at the federation hall. The
previous tenant left a board and a bowl of stones in your room, and no instructions.

You do not know what it is. That is where the game starts.

There is no combat. Encounters are games of Go, opponents are ranked in kyu and dan, and
**the player character never gains a statistic** — the only thing that gets stronger is the
person holding the controller.

## Read this first

| Document | What it covers |
|---|---|
| [GAME_DESIGN.md](GAME_DESIGN.md) | Pillars, the town, the cast, how difficulty is expressed in Go's own terms |
| [ARCHITECTURE.md](ARCHITECTURE.md) | The one rule (the Go module knows nothing about the game), module boundaries, the world↔Go seam, the KataGo-ready opponent interface |
| [ART_DIRECTION.md](ART_DIRECTION.md) | Palette, tiles, how a character stays consistent between sprite and portrait |
| [WORKBOARD.md](WORKBOARD.md) | **Current source of truth for agents:** ready work, blockers, priorities, and done criteria |
| [ROADMAP.md](ROADMAP.md) | Product direction and trade-offs behind the current workboard |
| [MILESTONES.md](MILESTONES.md) | Append-only history of what shipped and how it was verified |

## Playing it

```bash
tools/play.sh
```

That's it. Godot 4.7 is required; on this machine it lives at `~/.local/bin/godot`
(a `steam-run` wrapper — see the note on running Godot under NixOS).

### Controls

**In the town**

| | |
|---|---|
| Arrow keys or WASD | walk |
| Hold Shift while moving | run |
| Space (or Enter / E / Z) | talk, read, advance dialogue, take the tram |
| Up / Down then Space | pick a dialogue choice |
| Tab | menu — save game, save to another slot, back to title |
| Esc | back out of a menu |

**Saves**

There are three slots. The title screen offers **Continue** (the one you played most
recently) and **Load Game** (pick any of them); the pause menu's *Save game* writes back to
the slot you are playing, and *Save to slot…* puts it wherever you like.

| | |
|---|---|
| Up / Down then Space | pick a slot |
| Del (or D) | delete the highlighted slot |
| Esc | back out |

Deleting asks first, and the confirmation answers only to **Del** — Space will not do it, on
purpose. Saving over somebody else's game asks too; saving over your own does not.

**New Game** takes the first empty slot and goes straight into the opening. It only asks
where to put you when all three slots are full.

**At the board**

| | |
|---|---|
| Mouse movement | preview an empty intersection and show its coordinate |
| Left click | place a stone, or toggle a group during counting |
| Arrow keys | move the cursor |
| Space | place a stone |
| P | pass |
| V (19×19 development route) | whole board / close view; arrows move through the close view |
| R | offer resignation; R confirms, Esc cancels |
| H (handicap games) | reopen the handicap explanation without changing the game |
| *after both players pass* | Space toggles a group dead or alive, **P** accepts the count |
| Space | dismiss the result, then choose whether to review the game |

The board screens also have clickable buttons for their actions: passing, resignation,
count acceptance, colour choices, explanations, results and review navigation.
Review Yes/No choices can be clicked directly inside their card. Keyboard
shortcuts remain available. Hover previews indicate placement only: illegal moves are
explained when clicked, exactly as before. During the opponent's turn, hovering identifies
a point without previewing a stone. At the count, hovering outlines the whole group.

On nineteen lines, **Zoom V / Whole** switches views, and **< / > / Up / Dn** pans the
close view. Mouse targeting never shifts the board under the pointer. Keyboard arrows
still move the selection and follow it through the close view.

**In a puzzle or lesson**: click or use arrows and Space to play, and Esc or **Leave** to
exit. Puzzles also offer **Reset R**. Explanation and result cards have **Continue** buttons. A wrong answer is taken back and explained; a second wrong answer gives you a hint.

**Choosing colours** is a set piece. In an even game the opponent takes a handful of stones
and you call **odd** or **even** (left/right to switch, Space to call it); guess right and
you pick your colour. In a handicap game there is no guessing -- the weaker player takes
Black with the stones already down, and the game says why.

Your first handicap game pauses with the actual stones highlighted. Space advances two
short explanations; Esc skips them. Black receives the starting stones and White moves
next. Those stones can join groups and be captured. Komi adds points to White's score;
the usual half-point prevents a tie. Right explains how this matchup's number was chosen.
H brings the explanation back during setup or play. Later games show a shorter summary.

The panel distinguishes **Capture Go**, **practice**, **casual** and **rated** games.
Practice and casual games leave rank unchanged. The opening Capture Go and Wren's first
practice start empty; Kesh's optional practice uses handicap after she issues your card. No unranked player is assigned
an invented numerical strength to calculate a head start.

**19×19 is available for development play**, with a whole-board view and a close
view that follows the cursor. The footer names the selected intersection. Lines
continuing beyond a close view mean the board continues there; they are not an edge.
An opponent move outside the view is named in the panel. Press V to see the whole board
again without losing your selected point. Counting supports both views.

On a 19×19 review card, V opens a close view at your move and arrows inspect the board.
V or Esc returns to the whole board; Left/Right then reads the next page or position.
Long explanations keep the move legend on each page. The town
still offers 9×9 and 13×13: the introduction to nineteen lines will come with its teaching
transition, not with this interface change.

### Never played Go?

Then you are the person this was built for. Start a New Game and carry the board out of the
attic; Pip in the park across the road offers **Capture Go**. A short, player-controlled reminder
beside the empty board shows how to place and capture stones. Wren, in
the club, does the rules properly afterwards — liberties, capture, and why you may not fill in
your own last one. There is no tutorial on the menu, because being taught by somebody is the
point.

Before Kesh, Wren hosts the first proper 9×9: normal passing and scoring, but explicitly
**unrated**. Her short opening refresher covers corner starts, avoiding the first line early,
supporting nearby stones, and answering urgent atari or cuts first. Kesh then gives you a
provisional novice card and directions to the Instituut. You can head there immediately,
or stay for optional **unrated handicap practice**. This is not a placement test.

Thirteen lessons in all, and each belongs to whoever should be teaching it: Wren has the
rulebook and ko, Kesh teaches you to run and to cut because she is the one cutting you,
Bertie in the park teaches ladders, Tomás behind his counter teaches counting and the
endgame, and Hana takes the classes at the Instituut: two eyes, life and death, the capturing race
and the false eye. Wren offers the optional corner, side and centre comparison. The board in your room sets you
twelve problems.

**Your rank is a record, not a stat.** Kesh gives you provisional 30 kyu when you ask for your novice card: a starting club estimate.
After that it moves one step at a time: beat somebody at or above your rank and it goes up
one, lose to somebody at or below it and it goes down one, and nothing else touches it.
Handicap stones are priced in, so beating a 4 kyu who gave you five stones is beating a 19
kyu. Nothing in the game makes your stones stronger. The only thing that improves is you.

**What the opponents cost your machine.** Opponents use KataGo's human-style model. The new novice cohort has separate fixed
strength settings below its 20k profile floor; these target ranks still need human playtesting. The game runs one engine at a time -- the person you are
sitting across from, and after the game one analysis process for the review -- which is
about a gigabyte of memory, one CPU thread, a second or so a move on a desktop CPU with
AVX2, and 400 MB of model files fetched once by `tools/setup_katago.sh`. Without the
package the game still plays, against the built-in heuristic opponent.

### Development

```bash
tools/test.sh                       # compile check + headless suite (Go rules, AI, content)
tools/setup_katago.sh               # download + checksum-verify Linux x64 KataGo for local play
tools/setup_katago.sh --verify      # check the local KataGo package without downloading
godot --headless --path . --script res://tools/katago_review_test.gd   # the review over whole 9x9 and 19x19 games
tools/run_game.sh tools/autopilot/slice_full.json   # drive the whole slice, screenshot each beat
tools/run_game.sh tools/autopilot/win_path.json     # load a save, take the rival's win branch, do the puzzle
python3 tools/build_assets.py       # regenerate all art and audio, deterministically
python3 tools/check_lessons.py      # verify every taught position against the rules
python3 tools/gen_maps.py           # rebuild the town from its placement script
python3 tools/gen_content.py        # rebuild NPC / opponent / quest resources
python3 tools/gen_tileset_resource.py   # rebuild the Godot TileSet from the atlas manifest
python3 tools/make_test_save.py beat_kesh   # a save in a hard-to-reach state, for testing
python3 tools/make_test_save.py beat_kesh 2 Ada 42   # ...in slot 2, as Ada, at 42 minutes
```

### Isolated development play and verification

Use a separate checkout and an absolute `XDG_DATA_HOME` while somebody is playing.
Godot, the save-fixture generator and screenshot runner use that same data root. The
headless save tests also write slots; their backup/restore is not safe alongside live play
in the same data directory. The runner checks its path and locks before writing fixtures.

```bash
XDG_DATA_HOME=/home/user/.local/share/ninepoint-ui-01 tools/test.sh
XDG_DATA_HOME=/home/user/.local/share/ninepoint-ui-01 tools/play.sh -- --katago-trial=res://tools/fixtures/katago_trial_19x19.tres
XDG_DATA_HOME=/home/user/.local/share/ninepoint-ui-01 tools/run_game.sh tools/autopilot/nineteen.json
XDG_DATA_HOME=/home/user/.local/share/ninepoint-ui-01 TIMEOUT=1500 tools/run_game.sh tools/autopilot/nineteen_game.json
```

The trial is unrated and developer-only. Its five-second engine deadline is a starting
budget for nineteen lines; the shipped smaller-board opponent profiles are unchanged.
This verifies legal play and latency, not a new rank calibration. For manual use, initialise
the checkout with the editor/import pass first, as `tools/test.sh` does.

## Structure

**Opening** -- Hana speaks to you and asks your name (Pokemon).
**Act 1, Steenbeek** -- you have no idea what Go is. Somebody left a board in your room.
Pip invites you to Capture Go in the park; Wren
teaches them properly, then hosts a safe unrated 9×9. Kesh issues your provisional novice
card and points you to Hana at the Essenveld Instituut, two tram stops north. Her
handicap practice game is optional and leaves your rank unchanged.
**Act 2, the Essenveld Instituut** — enrol with Marguerite in the Novice League, take
classes, and play five classmates in the lower west room. Their target ranks range from
30k to 20k. The board shows the next fixture, games completed, and everyone's results.
Everyone starts at zero; NPC games are simulated once after each player round. Wins
come first, then the stronger entry rank, then name. Extra practice never changes a fixture.
Finish an attempt and Marguerite can start another; Left/Right on the board browses the
saved attempts. A later win cannot erase an earlier loss.

Finish all five novice fixtures, at any placing, to receive the main Cup invitation.
You can also enter earlier with a rank. The beginners' section is 15k and weaker on 9×9,
with handicap based on rank. The open section has no ceiling and uses 13×13 with handicap.
With three rated wins you may play up into open while still under the beginner ceiling.
Those same three wins open Tomás's 13×13 back table at De Ketel.

**Finishing the Cup is the beginner ending**, whatever your placing. Afterwards Marguerite
can register you for the optional Academy League: opponents from Kesh's 12k to her own 1d.
Complete all six fixtures; the top four eligible entrants, excluding the registrar, can
sit the advanced exam. Losing a whole attempt still permits a fresh one.

Old saves keep their rank, record, reviews and certificates. Their league becomes a
legacy Academy attempt; novice enrolment is a separate choice. Already-entered old Cups
keep their original rules for the remaining rounds.

New Cup entries also save the player's entry rank for the draw. Rated results may change
handicap at the next board, but cannot reconstruct earlier Cup pairings from a different
rank. The Cup retains its existing score-based pairing rule, including an occasional
rematch when the six-player draw cannot pair the remaining players afresh. Legacy active
Cups retain their original policy. This is separate from leagues, where every scheduled
pair appears exactly once per attempt.

There is no clock. Everyone is where they live, all the time, and a game costs nothing but
the game. The exam and the Cup start when you tell Marguerite you are ready, and run round
after round until they are done.

**The wassalon**, three doors east of the bar, has washing machines, a folding counter
and a shared Go table. Three people you can meet again at the Beginner Cup do their washing there: Abel at twenty-one kyu, who has come to Verhaven for the Cup; Dov at nineteen, who counts out
loud; and Moss at sixteen, who has spent three years under the section ceiling on purpose.
Two of them will play you for nothing, off the record. Moss will not: his game counts, and
he is the only one there who wants it to.

There is no relationship system. The game tracks your **record** against each person.

## The vertical slice

Title → New Game → leave your room on Ketelsteeg → Pip in the park teaches you Capture Go →
down into De Ketel → Wren asks whether you have played, teaches you if needed, and gives a
short optional opening plan → play Wren's practice full 9×9 → ask Kesh for your novice card
and invitation → leave immediately or stay for optional unrated handicap practice →
Tram 4 north → Hana sets you a capture problem → solve it → enrol with Marguerite → read
the Novice League board → five classmates → the Beginner Cup ending → optional Academy
registration. Save your progress into one of three slots.

## Layout

```
src/go/      pure Go rules, nigiri/handicap, lessons -- no engine coupling, unit tested
src/academy/ the Instituut league and the federation's events: standings and draws,
             saved attempts, player game history and explicit simulated NPC results
src/go_ai/   opponent interface, KataGo at the board and over a finished game, the
             heuristic AI that stands in when the engine is missing
src/go_ui/   board view, match scene, puzzle scene, lesson runner, the nigiri ceremony
src/rpg/     town, player, NPCs, maps, the tram
src/dialogue/ src/quest/ src/ui/ src/autoload/   (SaveSystem lives in src/autoload/)
data/        maps, dialogue, NPCs, opponents, quests, puzzles -- all of it data
art/         generated pixel art
audio/       generated sound effects and music
tools/       art and content generators, test and run harnesses
tests/       headless suites
```


The M43 art, writing and beginner-experience pass has an illustrated
[screen gallery](docs/overhaul/GALLERY.md) and [observed play report](docs/overhaul/PLAYTEST.md).
