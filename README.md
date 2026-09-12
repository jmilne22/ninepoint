# Ninepoint

A PS1-inspired 2.5D RPG about learning to play **Go (baduk)**, built in Godot 4.7.

You have just moved to **Sela**, a fictional coastal city of pale balconies, shady ficus trees,
and little tables outside shops. Your room is above a closed stationer's on Market Lane.
Pip plays in the boulevard garden, Wren welcomes beginners at The Kettle, and Tram 4
connects the neighborhood to the club rooms in the community centre and the Cup at Assembly Hall.
The previous tenant left a board and a bowl of stones in your room, and no instructions.

You do not know what it is. That is where the game starts. The people you meet belong
to a small local club. Learn with them, meet another newcomer, and get ready for a first
amateur tournament together. You can finish the Cup even if you lose every round.

There is no combat. Encounters are games of Go, opponents are ranked in kyu and dan, and
**the player character never gains a statistic** — the only thing that gets stronger is the
person holding the controller.

The whole game uses [model-rendered rooms, characters and Go assets](docs/ps1/world/README.md).
Walk screen-relative through fixed-angle rooms and streets; play Go on a clear overhead
board. Portraits are rendered from the same original character models as the sprites.
Market Lane has varied White City-inspired balconies and shaded entrances; Sea Walk
has warm stone port buildings and fishing boats inspired by Jaffa.
The earlier isolated room experiment remains available through `tools/play_ps1.sh`.

## Read this first

| Document | What it covers |
|---|---|
| [GAME_DESIGN.md](GAME_DESIGN.md) | Pillars, the town, the cast, how difficulty is expressed in Go's own terms |
| [ARCHITECTURE.md](ARCHITECTURE.md) | The one rule (the Go module knows nothing about the game), module boundaries, the world↔Go seam, the KataGo-ready opponent interface |
| [ART_DIRECTION.md](ART_DIRECTION.md) | Rendered art, coastal references, materials and shared character models |
| [WORKBOARD.md](WORKBOARD.md) | **Current source of truth for agents:** ready work, blockers, priorities, and done criteria |
| [ROADMAP.md](ROADMAP.md) | Product direction and trade-offs behind the current workboard |
| [MILESTONES.md](MILESTONES.md) | Append-only history of what shipped and how it was verified |

## Playing it

On a fresh checkout, import the checked-in assets once, then launch:

```bash
godot --headless --path . --editor --quit
tools/play.sh
```

Godot 4.7 is required; on this machine it lives at `~/.local/bin/godot`
(a `steam-run` wrapper — see the note on running Godot under NixOS).

### Controls

**In the town**

| | |
|---|---|
| Arrow keys or WASD | walk in screen directions |
| Hold Shift while moving | run |
| Space (or Enter / E / Z) | talk, read, advance dialogue, take the tram, go through a door |
| Up / Down then Space | pick a dialogue choice |
| Tab | menu — save game, save to another slot, back to title |
| Esc | back out of a menu |

Doorways say where they go. Stand in front of one and the name of the place appears at the
bottom of the screen; walk into it or press Space. Inside a building the way out is the
door with the mat in front of it.

You can sit down opposite somebody at their board. Walk round to the far chair, face the
board and press Space — Wren's teaching board, Kesh's window table, Joos's crate, Bertie's
stone table in the park and every table in the novice room.

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
| H | position help in Wren’s first practice; counting help at any count; handicap help during handicap play |
| *after both players pass* | Space toggles a group dead or alive, **P** accepts the count |
| Space | dismiss the result, hear the opponent’s reaction, then choose whether to review |
| C (review) | compare the original position, your move, and the engine’s preferred move |

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
attic; Pip in the park across the road offers a **capture demonstration**. Fill the marked
last liberty and watch the stone come off. Then choose empty-board Capture Go practice,
repeat the example, or ask for directions to Wren. **Help H** inspects a group and shows
available captures. **P** ends this practice without a winner; **R** offers resignation.
Pip offers retries and a replay of the last capture, including after saving and loading. Wren, in
the club, does the rules properly afterwards — liberties, capture, and why you may not fill in
your own last one. There is no tutorial on the menu, because being taught by somebody is the
point.

Wren acknowledges Capture Go and offers four short rules exercises, then a prepared
7×7 finish: living and dead groups, a useful final move, passing, and checking a dead-group
mark against the score. Explanations stay beside the board until you advance. Her optional
opening comparison distinguishes a starting position from a completed territory boundary.
Then play her **unrated** 9×9. The side panel describes the current position; **Help H**
highlights a capture or a group with one liberty when one exists. Passing does not concede,
and the count shows territory, prisoners and komi before you accept the proposed marks.

Kesh gives you a provisional novice card and points toward fellow beginners at the
club rooms. You can leave immediately or stay for **unrated handicap practice**. Hana
welcomes you and offers either a visit to Noor or the first class before registration: applying two-eye knowledge
to an apparent eye that can be filled. Her capture problem remains optional. Noor wants
company through the league and toward the Cup; Ivo fits complete games around deliveries.

Seventeen lesson files cover the short beginner track and optional refreshers. Wren keeps
the longer rules and territory exercises; Kesh teaches escape and connection, Bertie
ladders, Tomás score inspection, and Hana the school classes. Experienced players may
explicitly skip teaching. The desk in your room also offers twelve puzzles.

**Your rank is a record, not a stat.** Kesh gives you provisional 30 kyu when you ask for your novice card: the novice starting entry.
After that it moves one step at a time: beat somebody at or above your rank and it goes up
one, lose to somebody at or below it and it goes down one, and nothing else touches it.
Handicap stones are priced in, so beating a 4 kyu who gave you five stones is beating a 19
kyu. Nothing in the game makes your stones stronger. The only thing that improves is you.

**What the opponents cost your machine.** Full-game opponents use KataGo's human-style model. Pip's Capture Go practice uses a small local policy and needs no engine. The new novice cohort has separate fixed
strength settings below its 20k profile floor; these target ranks still need human playtesting. The game runs one engine at a time -- the person you are
sitting across from, and after the game one analysis process for the review -- which is
about a gigabyte of memory, one CPU thread, a second or so a move on a desktop CPU with
AVX2, and 400 MB of model files fetched once by `tools/setup_katago.sh`. Without the
package the game still plays, against the built-in heuristic opponent.

### Development

Art builds require Blender and Pillow; the checked-in game does not. See the
[rendered pipeline guide](docs/ps1/world/README.md) for the NixOS command.
The full test gate requires the pinned KataGo package, including its models; run
`tools/setup_katago.sh` first. Playing with the heuristic fallback does not require it.

```bash
tools/setup_katago.sh               # download + checksum-verify the pinned Linux x64 package
tools/test.sh                       # compile/load, suites and real-engine integration gates
tools/setup_katago.sh --verify      # check the local KataGo package without downloading
godot --headless --path . --script res://tools/katago_review_test.gd   # the review over whole 9x9 and 19x19 games
tools/run_game.sh tools/autopilot/kesh_skip.json   # drive the whole slice, screenshot each beat
tools/run_game.sh tools/autopilot/win_path.json     # load a save, take the rival's win branch, do the puzzle
python3 tools/build_assets.py       # regenerate all art, map dressing and audio, deterministically
python3 tools/build_assets.py --groups environments --output /home/user/.cache/ninepoint-preview
python3 tools/portrait_sprite_preview.py   # six-character portrait/sprite comparison
python3 tools/art_contact_sheet.py --root /home/user/.cache/ninepoint-preview --output /home/user/.cache/ninepoint-props.png
python3 tests/test_art.py           # portrait preservation, navigation and asset contracts
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
**Act 1, Sela** -- you have no idea what Go is. Somebody left a board in your room.
Pip offers a capture demonstration and optional practice in the park; Wren
teaches rules and finishing, then hosts a supported unrated 9×9. Kesh issues your provisional novice
card and points you to Hana at the community centre, reached by Tram 4 north. Her
handicap practice game is optional and leaves your rank unchanged.
**Act 2, the club rooms** — meet Hana and take or explicitly skip the welcome
class. You can meet Noor first: she is through the hall’s lower west door and wants
company for the Cup. Enrol with Marguerite in the Novice League, and play five classmates in the lower west room. Their target ranks range from
30k to 20k. The board shows the next fixture, games completed, and everyone's results.
Everyone starts at zero; NPC games are simulated once after each player round. Wins
come first, then the stronger entry rank, then name. Extra practice never changes a fixture.
Finish an attempt and Marguerite can start another; Left/Right on the board browses the
saved attempts. A later win cannot erase an earlier loss.

Finish all five novice fixtures, at any placing, to receive the main Cup invitation.
You can also enter earlier with a rank. The beginners' section is 15k and weaker on 9×9,
with handicap based on rank. The open section has no ceiling and uses 13×13 with handicap.
With three rated wins you may play up into open while still under the beginner ceiling.
Those same three wins open Tomás's 13×13 back table at The Kettle.

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

**The Laundry**, three doors east of the bar, has washing machines, a folding counter
and a shared Go table. Three people you can meet again at the Beginner Cup do their washing there: Abel at twenty-one kyu, who has come to Sela for the Cup; Dov at nineteen, who counts out
loud; and Moss at sixteen, who has spent three years under the section ceiling on purpose.
Two of them will play you for nothing, off the record. Moss will not: his game counts, and
he is the only one there who wants it to.

There is no relationship system. The game tracks your **record** against each person.

## The vertical slice

Title → New Game → attic note → Pip’s Capture Go → Wren’s four rules exercises →
finishing lesson → optional opening comparison → supported unrated 9×9 → reaction/review →
Kesh’s novice card (optional handicap practice) → tram north → Hana’s welcome and first
class → registration → back-wall league board → Noor → Ivo → remaining novice fixtures →
Beginner Cup ending → optional Academy registration. Save into one of three slots.

[Revision playtest and before/after evidence](docs/early-game/PLAYTEST.md) separates the
AI walkthrough from automated supplemental checks and independent human testing.

## Layout

```
src/go/      pure Go rules, nigiri/handicap, lessons -- no engine coupling, unit tested
src/academy/ the club leagues and the federation's events: standings and draws,
             saved attempts, player game history and explicit simulated NPC results
src/go_ai/   opponent interface, KataGo at the board and over a finished game, the
             heuristic AI that stands in when the engine is missing
src/go_ui/   board view, match scene, puzzle scene, lesson runner, the nigiri ceremony
src/rpg/     town, player, NPCs, maps, projection/depth shaders, the tram
src/prototype/ketel/   opt-in session-only room experiment
src/dialogue/ src/quest/ src/ui/ src/autoload/   (SaveSystem lives in src/autoload/)
data/        maps, dialogue, NPCs, opponents, quests, puzzles -- all of it data
art/         rendered production assets plus the retained grid fallback
audio/       generated sound effects and music
tools/       art and content generators, test and run harnesses
tests/       headless suites
```


The M43 art, writing and beginner-experience pass has an illustrated
[screen gallery](docs/overhaul/GALLERY.md) and [observed play report](docs/overhaul/PLAYTEST.md).


The earlier richer-art pass established recessed architecture, material-specific
furniture, local wear, moving washer drums and more distinct walking poses. Its
screenshots show the former Verhaven setting. The [art playtest](docs/art/PLAYTEST.md) includes matching
before/after views and played screenshots from every room.

The earlier [portrait-led sprite preview](docs/sprite-preview/PLAYTEST.md) revised Ro, Wren,
Kesh, Tomás, Nadia and Sunny with rounded silhouettes and more distinct working poses.
That historical pass preserved other sprites and portrait faces. ART-08 replaces the
production cast with shared models and rendered busts. The old report includes
old/new comparisons and actual gameplay captures for reviewing this first package.

## The coastal neighborhood

Market Lane, Sea Walk and the Arcade form a short walking loop. The garden steps lead
to the water; the steps at Sea Walk's east end return through the Arcade. Joos's board
is in the passage's quiet side alcove. The review board remains beside the shaded sea bench.
Tram 4 is a rendered white articulated light-rail vehicle inspired by the Tel Aviv Red Line,
with rounded cabs, wraparound dark glazing and roof equipment.
At its glass shelter, stand anywhere on the marked platform and press Space when
**Board Tram 4** appears. You do not need to face the pole. Choose a destination or Not now.

Character identities are preserved in the new models. Old saves retain their progress;
the earlier Sela layout migration uses safe entrances, while ART-08 preserves exact
logical positions and introduces no additional relocation.
The [Sela playtest report](docs/sela/PLAYTEST.md) records the original layout migration.
Current presentation evidence is in the [rendered-game report](docs/ps1/world/verification.md)
and [coastal polish report](docs/ps1/polish/verification.md).
