# POLISH-02: observed play

Branch `polish/verhaven-readability`, from verified `origin/main` `ee1b65e`.
All play used a separate `XDG_DATA_HOME` (`/home/user/.ninepoint-polish-xdg`) and separate
`OUT`/`LOG` paths; the player's own save slots were never touched. `run_game.sh` takes an
exclusive lock, so every route below ran serially.

Screenshots were written to `/tmp/ninepoint-polish` while the work ran, and opened at
native 384×216 and at 3×–5× nearest-neighbour for anything smaller than a tile.

## What was found by looking, not by testing

Nine of these came from the owner's own play. Five more came from opening the frames:

- **The wassalon's exterior kept its interior tiles.** Shrinking `washer_bank` from 128 px
  to 80 uncovered three orphan `washer` tiles the old prop's bounding box had been hiding.
  `finish()` retires them with the rest of the miniature furniture now.
- **Wren's board sign became unreachable** the moment the table under it turned solid for
  its whole depth: she was standing on the only walkable neighbour the middle of the table
  had. It moved one tile west, where there is a place to stand.
- **Moss was already sitting in Dov's far chair**, which is the point of that board. Dov
  has no `seat_across`; the wassalon sign moved instead.
- **The first far-seat box only just reached.** A 16-wide box centred on the chair
  overlapped the probe by three pixels across two tiles of table. It is 24×28 now, nudged
  six pixels toward the board, and Bertie answers.
- **The opponent's face was pinned to one expression for the whole opening.** Whole-board
  area scoring on a nearly empty board says whoever moved first owns everything — the same
  trap `check_lessons.py` guards the taught positions against — so `standing()` reported
  "losing" for White from move one and Kesh looked worried at an empty board. The standing
  is only consulted after the opening now (`move_number() > GoTableTalk.EARLY_MOVES`).
- **A live script error in the save menu, unrelated to this work.** `SaveSlots._describe`
  still read `d["day"]`, a field that went with the calendar in M37, so overwriting or
  deleting another slot threw `Invalid access to key 'day'` behind the confirm card. No
  gate opens those cards. Fixed and replayed; the card now reads
  "Cass, 22k, 6 min at Essenveld Instituut -- Study Hall."

## The frames

Native 384×216 captures, kept here so the claims above can be checked against them.

| | |
|---|---|
| [The west end of Ketelsteeg](screenshots/street-west-end.png) | brick, the tram shelter, and the player stopped |
| [The east end](screenshots/street-east-end.png) | the viaduct abutment closes the street |
| [The park's east end](screenshots/park-east-end.png) | hedge |
| [The Tram 4 stop](screenshots/tram-stop.png) | shelter, route board, boarding slab |
| [A doorway](screenshots/door-prompt.png) | `De Ketel   [Space]` from the pavement |
| [The way out](screenshots/exit-mat.png) | `Ketelsteeg   [Space]`, mat inside the door |
| [The steps to the water](screenshots/steps-to-the-water.png) | the gravel path from the kerb |
| [The shopfronts](screenshots/shopfronts.png) | PAPIER, DE KETEL and the kettle sign, cut into the brick |
| [The laundrette front](screenshots/shopfronts-wassalon.png) | WASSALON, and no machines on the outside wall |
| [The title with no saves](screenshots/title-no-saves.png) | the cursor has stepped over the greyed rows to Quit |
| [The cold open](screenshots/cold-open.png) | dusk and rain, not a black rectangle |
| [Inside the wassalon](screenshots/wassalon-inside.png) | machines, counter and board at one scale |
| [The attic desk](screenshots/attic-desk.png) | the board is the width of the player |
| [Bertie's far side](screenshots/bertie-far-side.png) | where nothing used to happen |
| [Bertie answers](screenshots/bertie-answers.png) | across the stone table |
| [Wren's teaching board](screenshots/wren-far-side.png) | the prompt reaches over it |
| [The title card](screenshots/title.png) | and [its load list](screenshots/title-load.png) |
| [A portrait after a game](screenshots/portrait-after-a-game.png) | Wren, happy, through the shared column map |
| [The novice room](screenshots/novice-room.png) | five two-seat tables at the new scale |
| [Ivo, from the far chair](screenshots/novice-far-seat.png) | and the player drawn behind his table |

## Owner review, and what it changed

The owner looked at the first pass and found four more things. All four were right.

- **The cursor sat on greyed-out rows.** With no save on disk, Continue and Load Game are
  disabled, and stepping onto one and pressing [Space] produced silence — a menu that looks
  broken rather than answered. The cursor steps over them now.
  ([frame](screenshots/title-no-saves.png))
- **"Why is this screen just black?"** The cold open — the first screen of the game — was a
  flat `#14121a` rectangle with a portrait and a board floating on it. It now has the title
  card's dusk with rain falling through it, and the portrait and board have a frame and a
  shadow so they sit on it. ([frame](screenshots/cold-open.png))
- **"Why put a brick at the edge? Now the tram goes through it."** Exactly so: walling both
  ends of Ketelsteeg put a building across the middle of the road and the tram drove through
  it every thirty seconds. `solid_mask` grew an `extra_solid` set: the pavement, the road,
  the rails and the park run straight off both sides as they always did, nothing is drawn
  at the boundary, and the column is simply not walkable. You stop where the camera stops.
  ([west](screenshots/street-west-end.png), [east](screenshots/street-east-end.png))
- **"This building is sloppy."** The shopfronts were opaque slabs with a coloured bar across
  the top, laid over the brick with their own edges showing. They are cut into the wall now:
  a hanging board on two brackets, a window opening with a frame and a stone sill, and
  everything else transparent. The kettle sign moved off the roof to beside the steps.
  ([frame](screenshots/shopfronts.png))

## Routes played

| Route | Observed |
|---|---|
| `polish_edges` | Walked west and east along the pavement and through Molenpark until stopped. Both street ends close on brick under the viaduct and the tram shelter; the park closes on hedge. The quay stops at warehouse flank at both ends. No frame shows the player off the map. |
| `polish_thresholds` | `De Ketel   [Space]` and `Ketelsteeg   [Space]` read at the door from either side; the mat is on the tile inside. Entered and left De Ketel and the wassalon by pressing Space at the door rather than walking in. Followed the gravel path from the kerb to the water without prior knowledge. |
| `polish_street` | Walked the street west to east. Three shopfronts with legible fascias; no washing machines on the brick. Inside the wassalon the machine bank, the folding counter and the board all read at one scale. In the attic the board on the desk is the width of the player. |
| `polish_across_board` | Stood on the far chair at Bertie's stone table, Wren's teaching board and Kesh's window table and opened all three conversations. Bertie's far side previously produced nothing at all — no prompt, no response. |
| `polish_faces` | A real game at De Ketel, hand-clicked move by move, with the opponent panel photographed after each reply. |
| `polish_faces_capture` | Pip's Capture Go from a New Game, same sampling. |
| `polish_title` | The restyled card at each menu row, the load list over it, and the return. |
| `polish_fixes` | With no saves on disk: the cursor stepping over Continue and Load Game, and the cold open's backdrop. |

## The expression evidence, and its limit

The portrait region in each frame was compared pixel-for-pixel against all seven columns of
that character's strip. Two exact matches (difference **0**) were recorded on different
columns in real play:

- `neutral` at the start of Pip's Capture Go, before anything had happened;
- `thinking` at the count in Wren's game and through Pip's, which is correct: the last
  event in both was a pass, and `i_pass`/`you_pass` map to `thinking`.

That establishes the region is chosen at runtime from the board and that at least two moods
reach the screen. **A capture-driven face was not filmed.** Every automated game reached the
count through early passes rather than through a fight — the open ENG-09 behaviour, not
something this work changed — and the hand-clicked openings never made contact. The
remaining tags are covered by `tests/test_data.gd`, which asserts every tag and every
standing maps to a real column, that a tag outranks a standing, and that an unknown tag
with no standing is a neutral face. A human beginner playing a real fight is what would
actually confirm the reactions read.

## Regressions replayed

`saves` (title menu order, the slot list, overwrite and delete confirmations, and that
[Space] still refuses to delete), `run_mode` (Shift-run, collision, warps and interaction
after the solidity changes), `overhaul_art` (all eleven maps at their entrances and useful
interiors) and `early_lessons` (the whole lesson, match, reaction and review flow, 50
frames, completed).

`slice_full` was attempted as the New Game regression and **stops after ten shots** with
"Experience route timed out waiting for lesson_place". It does the same thing on a clean
worktree at `origin/main` `ee1b65e`, at the same step: Wren's choices moved in M45 and the
route has not been replayed since. Filed as TEST-01. A one-step repair was tried and
reverted rather than left unproven.

## Supporting gates

`tools/test.sh`: **16,863 checks passed, 0 failed**, 279 files load (M43/EARLY: 16,730 and
277). All three real KataGo gates passed — the service gate, a whole 9×9 review in 14.5 s
and a 19×19 in 60.9 s, and the stalled-analysis watchdog. `tools/check_lessons.py` reports
0 problems. All twelve generated maps validate, including the two new rules: no walkable
map-boundary tile that is not a door, and every declared far seat walkable, reachable and
square on across its own furniture.

Green checks are supporting evidence. What this document records is what was on screen.
