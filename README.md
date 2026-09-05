# Ninepoint

A top-down 2D RPG about learning to play **Go (baduk)**, built in Godot 4.7.

You have just moved to Steenbeek. There is a salon three steps below the pavement, an old crowd
in the park who play for coffee money, and a beginner tournament at the federation hall. The
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
| Arrow keys | move the cursor |
| Space | place a stone |
| P | pass |
| V (19×19 development route) | whole board / close view; arrows move through the close view |
| R | resign |
| *after both players pass* | Space toggles a group dead or alive, **P** accepts the count |
| Space | dismiss the result and return to the town |

**In a puzzle or lesson**: arrows and Space to play, **R** to reset the position, Esc to
leave. A wrong answer is taken back and explained; a second wrong answer gives you a hint.

**Choosing colours** is a set piece. In an even game the opponent takes a handful of stones
and you call **odd** or **even** (left/right to switch, Space to call it); guess right and
you pick your colour. In a handicap game there is no guessing -- the weaker player takes
Black with the stones already down, and the game says why.

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
attic; Pip in the park will assume you play and teach you **Capture Go** before anybody
explains a rule, because a first game is a better introduction than a first lecture. Wren, in
the club, does the rules properly afterwards — liberties, capture, and why you may not fill in
your own last one. There is no tutorial on the menu, because being taught by somebody is the
point.

Before Kesh, Wren hosts the first proper 9×9: normal passing and scoring, but explicitly
**unrated**. Her short opening refresher covers corner starts, avoiding the first line early,
supporting nearby stones, and answering urgent atari or cuts first. Kesh's following 9×9 is
the first **rated** game, with a card explaining the kyu/dan ladder and rank changes.

Thirteen lessons in all, and each belongs to whoever should be teaching it: Wren has the
rulebook and ko, Kesh teaches you to run and to cut because she is the one cutting you,
Bertie in the park teaches ladders, Tomás behind his counter teaches counting and the
endgame, and Hana takes the classes at the Instituut — corner before side before centre, two
eyes, life and death, the capturing race and the false eye. The board in your room sets you
twelve problems.

**Your rank is a record, not a stat.** Kesh gives you 22 kyu after your first rated game.
After that it moves one step at a time: beat somebody at or above your rank and it goes up
one, lose to somebody at or below it and it goes down one, and nothing else touches it.
Handicap stones are priced in, so beating a 4 kyu who gave you five stones is beating a 19
kyu. Nothing in the game makes your stones stronger. The only thing that improves is you.

**What the opponents cost your machine.** Every character is KataGo's human-style model
playing at that character's rank. The game runs one engine at a time -- the person you are
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
Pip drags you into a game of Capture Go in the park before anyone explains the rules; Wren
teaches them properly, then hosts a safe unrated 9×9; Kesh challenges you to the first rated
game and, win or lose, hands you a rank and tells you
where Hana teaches: the Essenveld Instituut, two tram stops north (Hikaru no Go).
**Act 2, the Essenveld Instituut** -- enrol at the bottom of the lower league, take classes,
play whoever is sitting at a board, and climb a table that is nothing but your own results
(Yu-Gi-Oh! Tag Force / the insei programme). Win three rated games and the board gets
bigger: Tomás keeps a 13x13 under the coats at the back table of De Ketel. A stone of
handicap buys less on a wider board, so the same gap that gave you two on 9x9 gives you
three.

The Steenbeek Cup runs two sections and your card decides which one you are in. The
beginners' section is fifteen kyu and below, on 9x9, with no handicap -- the ceiling does
that job. The open section has no ceiling, is played on 13x13, and hands out stones instead;
it is where the club and the Instituut end up at the same table. If you are still under the
ceiling but have won three rated games you may choose to play up into it, and the registrar
will tell you exactly what that costs before she enters you.

There is no clock. Everyone is where they live, all the time, and a game costs nothing but
the game. The exam and the Cup start when you tell Marguerite you are ready, and run round
after round until they are done.

**The wassalon is open till two**, three doors east of the bar, and it is the one room in the
city that keeps no record of anybody -- no board on the wall, no card. Three people you will
meet again at the Beginner Cup do their washing there: Abel at twenty-one kyu, who is the
only player in Verhaven weaker than you when you start; Dov at nineteen, who counts out
loud; and Moss at sixteen, who has spent three years under the section ceiling on purpose.
Two of them will play you for nothing, off the record. Moss will not: his game counts, and
he is the only one there who wants it to.

There is no relationship system. The game tracks your **record** against each person.

## The vertical slice

Title → New Game → leave your room on Ketelsteeg → Pip in the park teaches you Capture Go →
down into De Ketel → Wren asks whether you have played, teaches you if needed, and gives a
short opening plan → play Wren's unrated full 9×9 → Kesh challenges you to the rated 9×9 and
you settle the colours by nigiri → win or lose, she reacts to the game and gives you a rank →
Tram 4 north → Hana sets you a capture problem → solve it → enrol with Marguerite → read
the league board → save it into one of the three slots.

## Layout

```
src/go/      pure Go rules, nigiri/handicap, lessons -- no engine coupling, unit tested
src/academy/ the Instituut league and the federation's events: standings and draws,
             computed only from games played
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
