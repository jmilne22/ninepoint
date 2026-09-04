# Ninepoint

A top-down 2D RPG about learning to play **Go (baduk)**, built in Godot 4.7.

You have just moved to Steenbeek. There is a salon three steps below the pavement, an old crowd
in the park who play for coffee money, and a beginner tournament in a fortnight. The previous
tenant left a board and a bowl of stones in your room, and no instructions.

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
| [MILESTONES.md](MILESTONES.md) | What is built, and how each piece was verified |
| [ROADMAP.md](ROADMAP.md) | What is **not** built, in priority order |

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
| Space (or Enter / E / Z) | talk, read, advance dialogue |
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
| R | resign |
| *after both players pass* | Space toggles a group dead or alive, **P** accepts the count |
| Space | dismiss the result and return to the town |

**In the review afterwards**: whoever you played walks you back through two or three
moments from your own game — Space to go on, Esc to skip it. It only happens when there was
something worth saying and somebody stronger than you to say it, so a clean game goes
straight back to the town.

**In a puzzle or lesson**: arrows and Space to play, **R** to reset the position, Esc to
leave. A wrong answer is taken back and explained; a second wrong answer gives you a hint.

**Choosing colours** is a set piece. In an even game the opponent takes a handful of stones
and you call **odd** or **even** (left/right to switch, Space to call it); guess right and
you pick your colour. In a handicap game there is no guessing -- the weaker player takes
Black with the stones already down, and the game says why.

### Never played Go?

Then you are the person this was built for. Start a New Game and carry the board out of the
attic; Pip in the park will assume you play and teach you **Capture Go** before anybody
explains a rule, because a first game is a better introduction than a first lecture. Wren, in
the club, does the rules properly afterwards — liberties, capture, and why you may not fill in
your own last one. There is no tutorial on the menu, because being taught by somebody is the
point.

Thirteen lessons in all, and each belongs to whoever should be teaching it: Wren has the
rulebook and ko, Kesh teaches you to run and to cut because she is the one cutting you,
Bertie in the park teaches ladders, Tomás behind his counter teaches counting and the
endgame, and Hana takes the classes at the Instituut — corner before side before centre, two
eyes, life and death, the capturing race and the false eye. The board in your room sets you
twelve problems.

Books, on the other hand, are not lessons. Ilse Brandt in the study hall has read four on the
opening and two on the endgame and is nine kyu, and she will tell you so before she tells you
to read the first forty pages of Nadia's. You can borrow it. It is worth borrowing. It will
not be the thing that beats her.

**Your rank is a record, not a stat.** It is recomputed from the games you have actually
played — the strength of your opposition adjusted by your score against it, with handicap
stones counted honestly — and it is stored nowhere. Nothing in the game makes your stones
stronger. The only thing that improves is you.

### Development

```bash
tools/test.sh                       # compile check + headless suite (Go rules, AI, content)
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

## Structure

**Opening** -- Hana speaks to you and asks your name (Pokemon).
**Act 1, Steenbeek** -- you have no idea what Go is. Somebody left a board in your room.
Pip drags you into a game of Capture Go in the park before anyone explains the rules; Wren
teaches them properly; Kesh challenges you; Hana tells you she teaches at the Essenveld
Instituut, two tram stops north (Hikaru no Go).
**Act 2, the Essenveld Instituut** -- enrol at the bottom of the lower league, take classes,
play whoever is sitting at a board, and climb a table that is nothing but your own results
(Yu-Gi-Oh! Tag Force / the insei programme). Win three rated games and the board gets
bigger: Tomas keeps a 13x13 under the coats at the back table of De Ketel, and there is
another in the study hall. A stone of handicap buys less on a wider board, so the same gap
that gave you two on 9x9 gives you three.

The Steenbeek Cup runs two sections and your card decides which one you are in. The
beginners' section is fifteen kyu and below, on 9x9, with no handicap -- the ceiling does
that job. The open section has no ceiling, is played on 13x13, and hands out stones instead;
it is where the club and the Instituut end up at the same table. If you are still under the
ceiling but have won three rated games you may choose to play up into it, and the registrar
will tell you exactly what that costs before she enters you.

There is no relationship system. The game tracks your **record** against each person.

## The vertical slice

Title → New Game → leave your room on Ketelsteeg → walk down into De Ketel →
Wren asks whether you have played, and teaches you if not → she explains the Beginner Cup →
Kesh challenges you to 9×9 and you settle the colours by nigiri → play a real game of Go →
win or lose, her dialogue changes → Hana sets you a capture problem → solve it → save it
into one of the three slots.

## Layout

```
src/go/      pure Go rules, nigiri/handicap, lessons -- no engine coupling, unit tested
src/academy/ the Instituut league and the federation's events: standings and draws,
             computed only from games played
src/go_ai/   opponent interface, the shipped heuristic AI, a GTP adapter for KataGo
src/go_ui/   board view, match scene, puzzle scene
src/rpg/     town, player, NPCs, maps
src/club/    the De Ketel hooks: a ladder counting every game, not only the rated ones
src/dialogue/ src/quest/ src/ui/ src/autoload/   (SaveSystem lives in src/autoload/)
data/        maps, dialogue, NPCs, opponents, quests, puzzles -- all of it data
art/         generated pixel art
audio/       generated sound effects and music
tools/       art and content generators, test and run harnesses
tests/       headless suites
```
