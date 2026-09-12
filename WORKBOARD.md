# Ninepoint — Workboard

This is the **operational source of truth** for unfinished work. An agent starts here,
not in the milestone history. It answers: what may be picked up now, what is blocked, and
what evidence makes a task done.

Revision base: `origin/main` and HEAD both `89e1a35`, freshly fetched and verified on 2026-09-12 before the design-baseline audit.
Update the snapshot when reconciling after a merge; it is not a release number.

## How to use this board

| Status | Meaning | Agent action |
|---|---|---|
| `READY` | Scoped, unblocked work | May claim and implement it. |
| `DOING` | Work actively underway | Do not duplicate it; check its branch/owner first. |
| `NEEDS DECISION` | Direction or scope needs an owner decision | Do discovery only; do not silently choose a direction. |
| `BLOCKED` | Cannot proceed until its listed dependency is done | Work on the dependency or another ticket. |
| `LATER` | Valid work, deliberately not next | Do not promote it without updating priorities. |
| `SHIPPED` | Recently delivered summary | Move its full record to `MILESTONES.md` when it stops being useful here. |
| `DROPPED` | Explicitly not doing | Keep the reason; never quietly delete it. |

Before code work, an agent must: sync with `origin/main`; choose one `READY` ticket; change
it to `DOING` with an owner/branch; and keep the scope and acceptance checks here current.
Tiny fixes and documentation-only edits may skip a ticket, but must still update any affected
ticket. A task is `SHIPPED` only after its acceptance checks are recorded. A release-sized
piece of work also gets a new, append-only entry in `MILESTONES.md`.

### Document roles

| Document | Owns | Does not own |
|---|---|---|
| `WORKBOARD.md` | Current status, priority, dependencies, acceptance criteria | Detailed rationale or delivery history |
| `ROADMAP.md` | Product direction, trade-offs, and why a task matters | Whether work is currently underway or done |
| `MILESTONES.md` | Append-only shipped history and verification evidence | The current backlog |
| Design / architecture / art docs | Durable product and technical truth | Task status |

## REV-06 — The board as the thing you read (engine picks on the board)

- Status: `READY` · Priority: `P1` · Owner: unassigned · Branch: none yet.
  Depends on REV-04 (M54) being merged. Owner request after playing the graph review:
  keep the graph, make the board itself carry the analysis, in the way KaTrain does,
  without KaTrain's clutter.
- Scope, in priority order:
  1. **Engine picks on the board.** At the selected move, mark the engine's best two or
     three candidate points with their cost relative to the best ("0", "1", "4") and
     list them in the caption: "Engine's picks: G2, then F1 (about 1 point worse), H5
     (about 4)". Data: `KataGoReviewQuery.parse_line` keeps only `moveInfos[0]`; keep
     the top five `{move, scoreLead}` per turn, and `MatchAnalysis.curve` adds a `top`
     list per entry (labels and player-relative loss, one decimal). A 9×9 review grows
     by a few hundred bytes. The position is the one before your move, so the
     candidates come from `turns[m-1]`.
  2. **Colour the played move by its cost.** The stone marker uses the graph's language:
     green when it matched or was within a point, amber for a few points, red for a big
     loss. `GoBoardView.mark_good` becomes a colour, not a bool; the legend says so.
  3. **A bigger board on the review card.** The card's 140 px board cannot carry numbers.
     Try 176 px with the text column at 142 px, or a full-height layout with the graph
     as a strip; measure the caption with `UiKit.text_height` as the card already does.
     Numbers on the board only when the cell is at least 14 px (9×9, 13×13, 19×19 zoomed);
     otherwise coloured dots and the caption list.
- Mockup, drawn from the recorded Wren position (candidate costs illustrative):
  `docs/review/graph/rev06_mockup.png`.
- Out of scope, deliberately: win rate, visit counts, policy, variation strings, and
  expected-territory shading on every move (it needs ownership per turn, which the
  eight-visit pass does not request and a 19×19 save could not hold; the tints stay on
  the cards under Compare via the second pass, pending REV-05).
- Acceptance: `tests/test_match_analysis.gd` covers the kept candidates and the `top`
  list including White orientation; `review_graph` frames show numbered picks and a
  coloured marker on 9×9; `quay_review_13` / `quay_review_19` presets gain `top` entries
  and prove the size rule; `quay_review` legacy card unchanged; `tools/test.sh` green;
  README controls and `docs/review/GRAPH.md` updated; frames opened.

## REV-04 — Graph-first review POC

- Status: `SHIPPED` (M54, awaiting merge) · Priority: `P1` · Owner: Claude ·
  Branch: `claude/review-graph-poc`, from `origin/main` `725aa6c`.
- Why: REV-03 showed the review's prose layer cannot be made to say more than the
  templates; the owner asked whether reviews are worth keeping at all versus the
  graph-style review every Go site uses. This POC answers by building the graph on the
  existing analysis so the two can be played side by side.
- Scope: the payload gains `curve` (one small entry per player move from the eight-visit
  pass: lead, loss, played and preferred points). The first review card becomes a graph
  of the whole game; Left/Right walk your moves on the board, Up/Down jump between the
  explained positions, Space opens that card, Compare C still works. Opens on the praised
  move. The existing cards, facts, lessons and the second analysis pass are untouched.
- Acceptance (met): `tools/test.sh` **18,239 / 0**, 332 files load, 13 art tests, all engine gates, exit 0; `review_graph` route (a whole 9×9 to the
  count, the review, graph walking, opening a card, Compare C, return, close);
  `quay_review_13` and `quay_review_19` synthetic-curve presets show the graph at thirteen
  and nineteen lines including zoom; `quay_review` still shows the legacy tally card. All
  frames opened, retained in `docs/review/GRAPH.md`. Owner played it on 9×9 and the
  feedback is folded in; independent beginner testing of the review remains open.
- Owner playtest feedback folded in: axis reads ahead/behind with the number in words;
  the dots are named in the legend; Compare states what it shows in the title; Open card
  greys out where there is no card. Separately, the practice Help fallback ("look at the
  empty space near your stones") now names your group with the fewest liberties and the
  opponent's, with coordinates, since empty space was not something a beginner could act on.
- Decision this POC is meant to inform: if the graph is the spine, the second analysis
  pass (about 32 of 45 seconds and most of the card code) is only needed for the
  ownership tints and continuation lines. Keep them or cut them after playing both.

## REV-02 — Optional teaching games (REV-01 Step 5)

- Status: `DOING` · Priority: `P1` · Owner: Codex · Branch: `codex/rev-01-teaching-game`.
- Owner approved the Step 5 implementation plan; HEAD and freshly fetched origin/main
  matched `6ab343a` before branching. Steps 1–4 remain shipped below.
- Scope: opt-in Wren first 9×9 and Kesh handicap practice, bounded 30-visit live
  comparisons, factual questions, provisional-move undo, and optional opponent notes.
- Limits: four-point loss, five committed player turns between questions, shared
  profile deadline for both branches; no LLM, strength changes or new save fields.
- Acceptance: real-engine latency/coverage including White and handicap; pure/failure/
  undo/input tests; played keyboard/mouse questions, Help and return; full regression gate.
- Independent beginner comprehension/fatigue observations remain required and must be
  reported separately from implementation and automated play evidence.
- Technical verification: **18,229 / 0**, 331 loads, 13 art tests, isolated pure gate
  **130 / 0**, teaching protocol **31 / 0**, teaching scene **43 / 0**, and all existing
  engine gates passed. Six real-worker rendered choice/undo/keep/normal routes passed;
  the separately labelled scripted-PV route supplies note screenshots.
- Real-engine final benchmark: startup 3.292 s; six pairs in 1.663–1.897 s, zero timeouts,
  approximately 600–612 MiB sampled process-tree RSS. [Evidence](docs/review/TEACHING.md).
- Repeat: six pairs in 1.752–1.918 s, zero timeouts, 605–615 MiB. Existing
  `rendered_match`, `kesh_practice` and `early_skips` regression routes passed and were inspected.
- Implementation is reviewable; ticket remains open solely for independent beginner
  comprehension and interruption-fatigue observations. LLM narration stays deferred.

## REV-01 — Reviews that explain why

- Status: `SHIPPED` (Steps 1–4, M51) · Priority: `P1` · Owner: Codex · Branch: `codex/rev-01-review-facts`.
- Approved Steps 1–4 only; fresh HEAD = origin/main = `37d007c` before branching.
- Scope: two-pass analysis, pure coordinate-grounded facts and template narration,
  ownership comparisons and existing-lesson links. No live teaching or LLM backend.
- Order: green `tools/test.sh`, document sweep and named commit after each step.
- Acceptance: engine-absent fixtures including colour-mirrored White; single tested ownership
  ordering conversion; real whole 9×9/19×19 analysis with separate pass times; pass-2
  failure/cancellation fallback; saved-review and complete-save bytes before/after.
- Budget: nine detail queries at 200 visits maximum. Stop and ask before lowering visits
  if 9×9 pass 2 exceeds 45 seconds. Omit duplicate-concept lesson cards without extra queries.
- Played acceptance: Wren 9×9 with an abandoned two-liberty group; mistake card names group,
  liberties, capturing sequence and point cost, and opens Kesh's escape lesson. Repeat as
  White; inspect overlays, quiet/legacy cards and leave/reopen. Open screenshots and record
  them in `docs/review/PLAYTEST.md`; add a milestone only when all criteria are met.
- Step 1 measurement stop: whole 9×9, 78 moves / 79 positions, eight analysis threads:
  pass 1 **14.661 s**, pass 2 **50.377 s** (nine queries × 200 visits; budget 45 s).
  All nine detail branches returned full ownership. Legacy saved-review size remains
  **4,640 bytes** before/after. Unit suite: **18,055 passed / 0 failed**.
  Owner approved reducing only pass-branch visits to 50 after this measurement. No step commit,
  full gate, 19×19 measurement or later step is claimed at this stop.
- Step 1 complete: final full gate 18,055 / 0, 317 loads, 13 art tests and integration
  gates pass, including real-pipe detail rejection/cancellation and watchdog. Finished
  9×9 (78 moves): 14.846 / 31.850 s; finished 19×19 (242 moves): 61.661 / 45.597 s.
  Legacy review bytes: 4,639 / 13,946, unchanged. `rendered_match` passed with 18 frames;
  loading, mistake and room-return captures opened. [Evidence](docs/review/PLAYTEST.md).
- Step 2 fixtures were registered before implementation; the red run reported missing
  `ReviewFacts`. Pure fixtures now cover all detectors and mirrored White orientation;
  legal PV capture proof is separate from ownership prediction. Full gate: **18,110 / 0**,
  320 loads, 13 art tests and all engine gates pass; 9×9 passes 15.032 / 34.285 s,
  19×19 passes 61.904 / 45.073 s. `tools/test_review_pure.sh`: **55 / 0** with
  game/autoloads/engine absent. Step 2 complete; runtime cards are unchanged.
- Step 3 complete: deterministic narration, three-sentence and coordinate validation,
  legal-capture wording and Black/White tests. Full gate **18,138 / 0**, 322 loads,
  13 art tests and integration gates pass; isolated facts/narrator gate **83 / 0**.
  Runtime cards are unchanged until Step 4.
- Step 4 technical gate passes: **18,200 / 0**, 325 loads, pure gate **101 / 0**,
  13 art tests and all integrations, including stale-session cancellation during pass 2.
  9×9 passes **14.888 / 31.112 s**, review **4,639 → 10,055 B**, complete save
  **6,957 → 13,721 B**. 19×19 passes **64.443 / 47.909 s**, review
  **13,947 → 48,279 B**, complete save **20,613 → 64,565 B**.
  Wren's actual Black game finished (White +13.5), and F2 was deliberately abandoned
  with two liberties and captured. Black/White cards, ownership and lesson/save-return
  inspected. The selected later error's PV does not finish the capture; a proposed
  explicitly labelled rules-verified continuation was approved after explaining that it
  proves a possible capture, not a forced result. Complete Black/White cards are now
  inspected: F2, G2/F1, the legal three-move capture, about 19 points and Kesh's escape
  lesson. Keyboard/clickable L, normal return and disk reload pass. Final actual-SGF
  analyses: Black 10.372 / 29.872 s; White 10.593 / 30.535 s. All criteria met;
  [opened screenshots and reproduction payloads](docs/review/PLAYTEST.md).
- Plan: [REV-01](docs/review/REV-01.md). Strengths, ranks, policy commentary and new curriculum
  remain outside this task; ask before changing any non-goal.

## Beginner experience and premise — approved baseline, 2026-09-12

The owner requested played investigation, approved [the plan](docs/design-audit/PLAN.md),
then authorized its implementation while away. Both implementation slices are now verified
locally on `codex/cap-01-first-capture`, based on freshly verified `89e1a35`.
[Current evidence](docs/baseline/PLAYTEST.md) and the [independent playtest packet](docs/baseline/BEGINNER-PLAYTEST.md)
separate delivered behavior from the human acceptance still required. Do not rebuild these
slices as though they remain proposals.

### CAP-01 — Make Pip's first encounter teach capture reliably

- Status: `BLOCKED` on independent beginner validation; implementation verified locally.
  Priority: `P1` · Owner: Codex · Branch: `codex/cap-01-first-capture`.
- Approved by the owner's “start on it” on 2026-09-12 after the played audit.
- Audit at the old base: Pip was beatable in seven plies, but used ordinary 18k Go for
  first capture. Two passes could produce a territory loss with zero captures. Help and
  repeat capture practice were absent. Those defects are repaired in this candidate.
- Implemented: explicit demonstration, optional dedicated first-capture practice, H help,
  retry, exact capture replay and neutral two-pass ending. Normal Pip rank/profile,
  honest counters, onward access and old records are preserved. All capture outcomes
  are excluded from ordinary territory review, including legacy records.
- Evidence: final 18,017 unit checks / 0 failures, 316 loads, 13 art tests and all engine
  gates pass. The actual capture scene bypasses installed/missing GTP paths. Maintained
  `capture_practice` and `capture_skip` routes cover replay/save/retry/leave/Wren; selected
  actual frames were opened. [Capture report](docs/capture/PLAYTEST.md).
- Remaining acceptance: independent capture explanation and transfer, recovery and chase
  length observations. No bot or guided demonstration closes those criteria. Follow the
  packet before expanding practice or claiming beginner suitability.

### DESIGN-01 — A local Go community within an ordinary city

- Status: `BLOCKED` on independent newcomer comprehension/motivation validation;
  implementation verified locally. Priority: `P1` · Owner: Codex · Branch: `codex/cap-01-first-capture`.
- Approved by the owner's instruction to complete the full plan on 2026-09-12; fresh
  HEAD = origin/main = `89e1a35` verified before this slice.
- Implemented: newcomer → club invitation → fellow beginners → first local Cup.
  Kettle tables belong to a working bar; community-centre rooms house the Go club.
  Kesh/Hana introduce Noor's shared ambition before registration. Ordinary exchanges,
  notices, explicit refusals and league/Cup return conversations support this framing.
- Existing coastal city, cast, ranks, layout/save IDs and honest league remain. Display
  text changes regenerate maps and arrival caption; rendered geometry remains identical.
- Evidence: fresh `club_journey`, complete `beginner_full_games`, `club_everyday` and
  nine-loss `club_payoff` routes pass with actual opened screenshots. Noor can be met
  before class/registration; payoff acknowledgements and truthful records survive loading.
- Remaining acceptance: newcomers can explain why the group knows one another and give
  a personal reason to continue. There were no independent participants in this work.
- CONTENT-05, ENG-09 and PROG-01 retain full-game strength/stopping/peer validation.
  Their human gates remain open; the new report adds actual games, not a calibration claim.

## Fixed-view art experiment

### ART-07 — PS1-inspired De Ketel experiment

- Status: `SHIPPED` (prototype verified locally; town conversion remains separate) · Priority: `P1` · Owner: Codex · Branch: `codex/ps1-ketel-prototype`.
- Explicitly approved 2026-09-12; READY scope claimed after fresh HEAD = origin/main = `f459336`.
- Scope: opt-in fixed-view 2.5D room, Blender/Python layered renders and eight-direction
  characters, model-rendered busts, existing conversations/match/review, session-only progress.
- Exception: new art tooling and new versions of the four prototype characters are approved;
  shipped Sela maps, character art, Go rules and normal launch remain unchanged.
- Acceptance: inspect composition before animation; walk all aisles and approaches; verify
  furniture sorting, dialogue/choices, match cancel and win/loss return, review and save isolation;
  run normal checks and inspect isolated route screenshots. Full-town conversion is separate.
- Evidence: 16,975 checks (predecessor 16,922), 13 art tests, 292 file loads and all three
  KataGo gates pass. Six final prototype routes / 34 captures plus the unchanged 18-frame
  twelve-map tour passed; representative images opened. Real Wren 9×9 count/loss/review
  analysed 59 positions; synthetic win/loss branches are labelled separately. Save API
  byte preservation, cancelled setup, every aisle and leave/reopen review verified.
- Corrections from play: wider bar/table aisle, inset door approach, measured five-choice
  menu, correct review return hint, missing font glyph removed; Xvfb no longer inherits
  the harness lock. [Build, play and evidence](docs/ps1/README.md).

### ART-08 — Complete rendered presentation

- Status: `SHIPPED` (verified locally, M49) · Priority: `P1` · Owner: Codex · Branch: `codex/ps1-ketel-prototype`.
- Approved 2026-09-12 after ART-07 visual review; HEAD again matched freshly fetched origin/main `f459336`.
- Scope: all twelve existing maps, full cast and passers, model-rendered portraits,
  overhead Go surfaces/stones/bowls, title/opening/travel and shared presentation.
- Owner tram steering: white articulated TLV Red Line appearance, original Blender mesh
  informed by the supplied image and CRRC exterior photographs; five independently sorted sections.
- Preserve Sela's current places, story, rules, board controls, records and saved logical positions.
- Method: Python-coordinated Blender sources, fixed-angle projected scenery and people;
  retain logical map coordinates underneath the presentation for saves and interactions.
- Acceptance: complete map/cast asset coverage, screen-relative normalized movement,
  correct foot occlusion, full technical gate, inspected city/journey/board/review captures.
- No AI-generated illustration assets. Full conversion becomes the normal launch path.

- Evidence: 17,239 checks (predecessor M48: 16,922), 13 art tests, 310 file loads;
  full KataGo integration/review gate and real audio driver pass. All 22 doorway
  connections and all twelve maps inspected; fresh journey, novice losses/Cup/repeat,
  saved positions, actual Wren count/review and 7/9/13/19-line input verified.
  Running measures 1.750× with release/collision/pause lock; activity/portrait return
  inspected. Tram passes both directions, boards both destinations and holds its stop
  when a pass is interrupted. Native and 3× captures opened.
- Corrections from play: texture colour multiplication, waypoint corner clipping,
  rank modal visibility, offscreen speech and competing tram tweens. The running
  harness now projects its physical lane and measures screen distance.
  [Pipeline](docs/ps1/world/README.md) · [Evidence and limits](docs/ps1/world/verification.md).

### ART-09 — Movement, daylight and coastal architecture polish

- Status: `SHIPPED` (local, verified) · Priority: `P1` · Owner: Codex · Branch: `codex/ps1-ketel-prototype`.
- Owner feedback: walking/running arms appear dislocated; city lighting reads as sunset;
  buildings lack doors; black surrounds expose the ends of the renders.
- Fresh fetch verified HEAD = origin/main = `f459336` before this follow-up.
- Scope: connected, fixed-length arm poses; neutral daytime lighting; physical entrance
  art aligned to existing warps; surrounding scenery beyond playable map edges.
  Follow-up direction: varied White City architecture and a Jaffa-inspired working harbor,
  researched from photographs and rebuilt as original meshes.
- Acceptance: inspect motion at walk/run speed, street/daylight/door approaches and all
  map edges; preserve logical collision, transitions, Go rules and saves; run technical
  checks and isolated routes. Python/Blender source remains authoritative.

- Evidence: 17,239 checks, 13 art tests, 310 loads and all three engine gates; six isolated
  routes, 116 frames. Native and 3× coastal frames, gait sequences and all-map contact
  sheets opened. [ART-09 verification](docs/ps1/polish/verification.md).

- Final owner feedback resolved: reduced sky/area-light fill in eight pale interiors;
  attic benchmark (1 frame) and final twelve-map tour (18 frames) passed and were opened.
  Documentation reconciles the production pipeline, fallback/history and shared instructions.

## Sela coastal redesign — approved 2026-09-08

Approved in conversation: a fictional Tel Aviv-inspired city, warm/worn/leafy, a neighborhood
walking loop plus Tram 4, setting and journey changes with every character and portrait frozen.
Base: freshly fetched HEAD = origin/main = `d64ab5f`. Owner: Codex.
Branch: `codex/sela-coastal-redesign`. Existing art-navigation freeze is superseded only
by this explicitly approved layout redesign; Go and progression rules remain protected.

### SELA-01 — Coastal palette and three playable benchmarks

- Status: `SHIPPED` (local benchmark implementation; complete-city verification follows) · Priority: `P1`.
- Evidence: environment build validated all twelve maps; art_tour completed 18 frames at exit 0.
  Opened bar, home, street, arcade and institute captures; canopy refinement included in SELA-02.
- Scope: environment-only colors and architecture; Market Lane, The Kettle, institute court.
- Acceptance: deterministic Python assets, exact preservation of all portraits/sprites,
  played and opened benchmark screenshots with clear thresholds and board approaches.

### SELA-02 — Complete the city and preserve saved journeys

- Status: `SHIPPED` (verified locally) · Priority: `P1`.
- Evidence: twelve-map tour, both tram views/title and all six walking connections
  passed and were opened. Legacy/current save tests pass; all 73 protected hashes match.
- Scope: all twelve maps, Market Lane/Arcade/Sea Walk loop, names and environmental speech,
  title and tram views, coastal ambience, one-time legacy saved-position migration.
- Acceptance: all venues and both travel destinations inspected, loop walked both ways,
  old progress retained and all services reachable. No character/Go/engine changes.

### SELA-03 — Journey verification and document reconciliation

- Status: `SHIPPED` (verified locally, M48) · Priority: `P1`.
- Evidence: 16,904 Godot checks, 13 art tests, 283 loaded files, three engine gates and
  audible-output gate passed. Nine final routes / 273 captures, representative images
  opened. Full boundaries and source references: [Sela report](docs/sela/PLAYTEST.md).
- Scope: navigation contracts, cold-start/skip/loss/Cup/review/save coverage, documentation.
- Acceptance: normal gate, protected asset hashes, opened route evidence; replace broken
  slice_full references with current early/novice routes; beginner difficulty remains unclaimed.

### SELA-04 — Modern articulated Tram 4

- Status: `SHIPPED` (verified locally) · Priority: `P2` · Owner: Codex.
- Approved follow-up: replace the red tram using the supplied white light-rail photograph.
- Base: continuing the reviewed Sela commit `8af988d`; fresh fetch confirms its parent
  `d64ab5f` is still `origin/main`. Starting again at main would discard the approved setting.
- Scope: original Python-drawn white articulated vehicle, dark glazing, rounded cabs,
  roof equipment and a longer silhouette. Preserve characters, routes and boarding flow.
- Evidence: `art_tram` completed 93 captures, exit 0, zero script errors. Opened
  passing frames in both directions, the stopping position and both arrival views.
  All 16,904 Godot checks, 13 art tests, 283 file loads and three engine gates passed.

### SELA-05 — Boulevard ficus and grounded planting

- Status: `SHIPPED` (verified locally) · Priority: `P2` · Owner: Codex · Branch: `codex/sela-coastal-redesign`.
- Approved: replace the rounded trees with Tel Aviv tree references and remove tree-like
  planting on buildings/title roofs. Continue reviewed `947522b`; fresh origin/main is
  still the underlying `d64ab5f`, with the approved Sela/tram work retained.
- Scope: pale branching ficus trunks, irregular dark crowns, clearer low potted plants;
  remove roof, balcony and arch plants that appear suspended. Keep tree footprints,
  navigation, portraits and characters fixed.
- Acceptance: reference inspected, deterministic rebuild, garden/title/facade/arrival
  screenshots opened, route approaches preserved and normal gate passes.

- Evidence: `art_ficus` completed 20 captures; garden, clear façades/title, room pots
  and both tram arrivals opened. `opening` completed eight captures; cold open inspected.
  16,904 checks, 13 art tests, 283 loads and all three KataGo gates pass; all 73 character
  hashes unchanged. Final pot alignment rebuilt, imported, replayed and art-tested.

### SELA-06 — Light-rail shelter and forgiving boarding area

- Status: `SHIPPED` (verified locally) · Priority: `P2` · Owner: Codex · Branch: `codex/sela-coastal-redesign`.
- Approved: redesign the stop from current Jerusalem/Tel Aviv references and fix its tiny
  interaction target. Fresh fetch: `origin/main` remains `d64ab5f`; continue approved
  Sela work at `8b19938` rather than discard it by restarting at main.
- Scope: thin canopy, glazing, seating, machine column, marked five-by-two tile platform;
  boarding prompt anywhere on that strip, independent of facing. Preserve nearby signs,
  home approach, route gates, cancel, tram and all cast pixels.
- Acceptance: inspect references and actual game; board both routes from opposite ends,
  cancel and gated destination, no prompt beyond platform; focused regression and normal gate.

- Evidence: final `art_stop` completed 30 captures, `stop_gates` four; five platform
  positions, four facing directions, cancellation, bounds, notice, walked home stairs,
  both actual destinations and both refusals inspected. 16,922 checks (prior 16,904),
  13 art tests, 283 loads and all three engine gates pass. Cast/tram hashes unchanged.
  Details and shutdown-warning limits: `docs/sela/PLAYTEST.md`.

### SELA-07 — Legible shop signs

- Status: `SHIPPED` (verified locally) · Priority: `P2` · Owner: Codex · Branch: `codex/sela-coastal-redesign`.
- Approved: improve building text beyond the bare utility-font LAUNDRY label. Continue
  reviewed `a4ead1a`; fresh `origin/main` remains its underlying `d64ab5f`.
- Scope: dedicated mixed-case shop lettering, clear sign panels, spacing and small trade
  symbols for Laundry, The Kettle and Paper. Keep UI type, cast and navigation fixed.
- Acceptance: deterministic environment rebuild, actual street/threshold screenshots
  opened at native scale, protected cast and normal verification gate pass.

- Evidence: `art_signs` completed seven captures; three shopfront names and three walked
  interiors opened. 16,922 Godot checks, 13 art tests, 283 loads and three engine gates
  pass. Only the three facade PNGs changed; UI type, maps, cast and tram remain fixed.

- Tram-label correction: same mixed-case lettering on a dark fascia, separate teal 4.
  Only the stop PNG changed; 13 art tests and editor import passed, `art_stop` completed
  30 captures and the lettering/prompt were opened. Runtime tests remain the preceding run.

## Portrait-led sprite preview

### ART-06 — Six rounded, portrait-led characters

- Status: `SHIPPED` (six-person preview verified locally; ready for visual review) · Priority: `P1` · Owner: Codex · Branch: `codex/portrait-led-sprites`.
- Owner approved the preview plan; recorded as ready and claimed on 2026-09-08.
- Scope: Ro, Wren, Kesh, Tomás, Nadia and Sunny; Python-authored head, hair,
  garment and pose variants in the existing walking/activity sheets.
- Owner clarification: floating necks refer to **portraits**, with scarves excepted.
  Lower broad unscarved shoulders for Tomás, Bertie, Abel and Emil. Preserve all
  face/expression pixels and the other seventeen complete portrait strips.
- Acceptance: approved portrait bytes and unchanged remaining world sprites; native/3× comparisons
  with actual floors; played walking, running, conversation and furniture overlap;
  existing art contracts and technical gate pass. Review target is these six only.
- ART-03 remains historical; its shared colours did not establish portrait likeness.
- Evidence: 12 Python art tests, 16,879 Godot checks, 283 loaded files and three
  real-engine gates passed. `portrait_sprites` produced 19 opened screenshots,
  exit 0 and zero script errors; walking/running, five conversations, working poses
  and table overlap inspected. [Preview and exact scope](docs/sprite-preview/PLAYTEST.md).

## Approved art facelift — ART-01 through ART-04

Owner approved the complete richer-same-style plan on 2026-09-08. Base: freshly
fetched HEAD and origin/main both `c51f0853e897e07f3681e163729ef9754275a018`.
Owner: Codex · Branch: `codex/richer-verhaven-art`. Portraits, font metrics, world
scale, navigation and Go behaviour are protected. Work proceeds one package at a time.

### ART-01 — Drawing tools and three benchmark scenes

- Status: `SHIPPED` (verified on branch) · Priority: `P1`.
- Evidence: eight Python art-contract tests pass; `overhaul_art` completed with zero
  script errors. Opened De Ketel, Ketelsteeg and Academy hall benchmark captures: table
  volume, restrained surfaces, recessed windows and street drainage all visible.
- Scope: masked shapes/materials, stable seeds, selective builds and contact sheets;
  De Ketel, Ketelsteeg and Academy hall benchmark artwork.
- Acceptance: deterministic exports and exact portrait preservation; opened matching
  gameplay views show coherent depth, quiet routes and the existing board scale.

### ART-02 — All venues and local prop animation

- Status: `SHIPPED` (verified on branch) · Priority: `P1`; follows ART-01.
- Evidence: `art_tour` inspected all twelve maps, the novice aisle and park; zero
  script errors. Washer captures differ on 78 cloth pixels and zero shell pixels.
  `art_materials` verifies quieter water families after the first quay review.
- Scope: remaining environments, shared prop geometry metadata, localized floor wear,
  distinct crate/school/tournament furniture and generated washer animation.
- Acceptance: all twelve maps inspected; doors, far seats and sorting preserved;
  two different washer frames seen in game without movement of the machine shell.

### ART-03 — Walking and activity silhouettes

- Status: `SHIPPED` (verified on branch) · Priority: `P2`; follows ART-02.
- Evidence: all 21 portrait/sprite comparisons opened; nine art-contract tests pass.
  `art_people` played Wren’s working pose, far-seat sorting and conversation with
  zero errors and opened screenshots. The 26 walking/action sheets retain their contracts.
- Scope: explicitly drawn height/build differences, directional bodies and activity
  poses within the existing sheets. All portrait pixels stay unchanged.
- Acceptance: cast contact sheet and played movement/activity/conversation inspected;
  sheet sizes, feet baselines and portrait hashes checked.

### ART-04 — Title, ceremony, UI and final visual verification

- Status: `SHIPPED` (verified on branch) · Priority: `P2`; follows verified ART-03.
- Evidence: 10 Python art tests, 16,879 Godot checks, 282 loaded files and all three
  KataGo gates passed. Final title, opening, nigiri, 7/9/13/19-line boards, twelve maps,
  thresholds and both tram illustrations played and inspected. See [art evidence](docs/art/PLAYTEST.md).
- Scope: title skyline/sky, bowl/hand volume, UI framing/icons and quiet board surface;
  full technical gate, visual evidence and document reconciliation.
- Acceptance: played title/opening/nigiri/board/room captures, normal gate and art
  checks pass; images opened and limitations recorded in the art playtest report.

### ART-05 — Clean arch masonry and title composition

- Status: `SHIPPED` (verified on branch) · Priority: `P1` · Owner: Codex · Branch: `codex/richer-verhaven-art`.
- Requested from the owner's screenshots: remove the broken diagonal arch joints and
  disconnected column caps; refresh the title and remove the lamp crossing the goban.
- Scope: Python arch/title artwork only, preserving portrait pixels and menu geometry.
- Acceptance: clean radial masonry and continuous pillars; grounded board composition;
  regenerated assets pass art checks and both views are played and inspected.

- Evidence: 10 art tests passed; fresh Godot import reported no parse errors;
  `art_cleanup` completed with zero script errors. Opened title/arch gameplay captures
  at native size and 3×. Existing map footprints, portraits and menu geometry unchanged.

## In progress

### POLISH-02 — Read the town: scale, edges, thresholds and faces

- Status: `SHIPPED` (merged in PR #27 at `c51f085`) · Priority: `P1` · Owner: Claude.
- Base: fetched `origin/main` and HEAD both `ee1b65e`, 2026-09-08.
- Why: the owner played the build and listed nine presentation faults. None of them
  fails a gate — 16,730 checks pass — and all nine are hit inside ten minutes.
- Scope, and the cause found for each:
  1. **The map had no edges.** `ketelsteeg.json` carried twenty walkable boundary
     tiles with no warp and the quay twelve, because both maps are laid with
     full-width row fills. `validate()` had no boundary rule, `MapBuilder` adds no
     bounding box and the player has no clamp: three places that could have caught
     it, none of which looked. Both ends of the street close on brick, the park on
     hedge, the quay on warehouse; `validate()` now fails the build on a walkable
     boundary tile that is not a door.
  2. **Doorways announced nothing.** Every warp has carried a `prompt` since the
     maps were first generated and `build_warps` discarded it. Warps now carry a
     `Doorway` interactable at a priority below a sign, so a door names where it
     goes and [Space] uses it; every interior exit has a coir mat inside it,
     derived from the warps rather than hand-placed; `door_int` has daylight under
     it; the Instituut's dormitory stair has a `stairs_up` tile instead of pavement.
  3. **The tram stop looked like a lamp post.** A concrete boarding platform and a
     generated shelter carrying the route board, in place of a 32×48 sign hung half
     over one of the twenty escape tiles.
  4. **The water was hidden.** The railing gap is three tiles with a gravel path
     worn to it across Molenpark, a lamp and a readable sign.
  5. **Scale.** The attic's "board" was the De Ketel bar table (48×32, board face
     24×22) beside a 16×24 person. `table()` keeps its size and gets a board a
     person's width; `study_desk` is a two-tile writing desk; the laundrette's
     machines are 20×24 rather than 32×36.
  6. **Storefronts.** The laundrette's interior machine bank was painted on its
     outside brick, unframed. Three generated shopfronts — fascia, frame, glass,
     stall riser — with what is behind the glass drawn at the size it really is.
  7. **You could stand on the table, and people drew in front of it.** Props had no
     `z_index` and were parented before `Entities` existed. Furniture that stands on
     the floor now sorts against the cast by the row its legs are on, and board
     tables are solid for their whole drawn depth.
  8. **You could not sit down opposite anybody.** The probe reaches one tile and
     every board is two deep: at Wren's, Joos's and the novices' boards you got the
     flavour text about the board, and at Bertie's stone table nothing happened at
     all. A `seat_across` tile per seated opponent gives their existing Interactable
     a second box on the far chair. `PROBE_REACH` is untouched.
  9. **The opponent's face never moved.** `go_match.gd` set the portrait region once
     and never again. Three new expressions, a pure `GoMood` mapping the tags
     `GoTableTalk` already emits, and a live portrait — which also gives `standing()`
     and both `edge_early` tags their first consumer.
  10. **The title screen.** Font size 21 on a bitmap font whose native size is 9;
     the save summary over the skyline; no cursor and no animation.
- Decisions: polish the title in place, keep `ITEMS` order (≈100 autopilot scripts
  count key presses through it); portraits only, no world emote bubbles; no engine,
  rank, progression or dialogue-content change.
- Acceptance: played routes with opened screenshots for every item, all eleven maps
  validating, and the normal compile/load, rules, content and engine gates.
- Owner review found four more, all fixed and replayed: the title cursor landed on
  greyed-out rows; the cold open was a flat black rectangle; walling the street ends put a
  building across the road for the tram to drive through (`solid_mask` grew `extra_solid`,
  and nothing is drawn at the boundary now); and the shopfronts were opaque slabs laid over
  the brick rather than openings cut into it.
- Verified: `tools/test.sh` **16,863 passed, 0 failed**, **279 files load** (M45: 16,730
  and 277). All three KataGo gates passed; lesson validator zero problems; all twelve
  generated maps validate under the two new rules. `polish_edges`, `polish_thresholds`,
  `polish_street`, `polish_across_board`, `polish_faces`, `polish_faces_capture` and
  `polish_title` were played and their frames opened, along with the `saves`, `run_mode`,
  `overhaul_art` and `early_lessons` regressions.
- Limit: a capture-driven expression was never filmed. Every automated game reached the
  count through early passes (ENG-09), so the remaining tag reactions rest on
  `tests/test_data.gd` rather than on a screenshot. A human playing a real fight is what
  would confirm they read.
- Discovered work: TEST-01 (`slice_full` broken since the early-game merge, reproduced on
  `origin/main`). Incidental fix, no ticket: `SaveSlots._describe` read `d["day"]`, cut
  with the calendar in M37, and threw behind the overwrite and delete confirm cards.
- Evidence and the frames: [`docs/polish/PLAYTEST.md`](docs/polish/PLAYTEST.md).

## Early-game revision — verified for PR review

All five packages shipped in PR #26, merged at `ee1b65e`. Final evidence:
16,730 checks, 277 loaded files, all three KataGo gates, zero lesson-validator problems,
writing and generated-map checks; opened screenshots from manual Wren/Noor/Ivo counted games
and separate Kesh, interruption, review-failure, quay, Cup/exam and mouse routes.
[Before/after report and evidence](docs/early-game/PLAYTEST.md). Merged in PR #26.
PROG-01's independent human gate remains open.

### EARLY-01 — Keep lesson positions visible

- Status: `SHIPPED` (merged in PR #26 at `ee1b65e`) · Priority: `P1` · Owner: Codex · Branch: `codex/early-game-review`.
- Base: fetched origin/main and HEAD both `f1b02c8`, 2026-09-06.
- Owner approved the complete early-game revision plan. Five packages are implemented sequentially.
- Scope: side-panel lesson feedback, inspection, measured pagination, transient board errors.
- Acceptance: played correct/refused lesson answers remain inspectable; successful moves clear old errors; compile/load and focused tests.

### EARLY-02 — Teach and support a complete first game

- Status: `SHIPPED` (merged in PR #26 at `ee1b65e`) · Priority: `P1` · Dependency: EARLY-01. Owner: Codex.
- Scope: four-exercise beginner track, finishing/counting actions, shorter optional openings, deeper optional counting, position-aware Wren help.
- Acceptance: validated legal continuations and scoring; full unrated Wren game with inspected help/pass/count screens.
- Reconciles CONTENT-01's early-game judgement scope. Wren's strength, stopping policy and dead-stone estimator remain unchanged; CONTENT-05 remains open.

### EARLY-03 — Join fellow beginners

- Status: `SHIPPED` (merged in PR #26 at `ee1b65e`) · Priority: `P1` · Dependency: EARLY-02. Owner: Codex.
- Scope: Hana welcome/class before registration, novice voices and continuity, fact-based old-save reconciliation; no new win gate.
- Acceptance: New Game reaches Noor and Ivo; interrupted/skipped lessons and old saves retain access, rank and records; writing checks.

### EARLY-04 — React before reviewing

- Status: `SHIPPED` (merged in PR #26 at `ee1b65e`) · Priority: `P1` · Dependency: EARLY-03. Owner: Codex.
- Scope: record once, world reaction before optional review, supportable explanations and independent move comparisons.
- Acceptance: Yes/No/leave/reload/unavailable/rematch and Cup/exam flows; exact-once records/rank; real-engine review gates.

### EARLY-05 — Make progress and people readable

- Status: `SHIPPED` (merged in PR #26 at `ee1b65e`) · Priority: `P2` · Dependency: EARLY-04. Owner: Codex.
- Scope: novice table details, HUD contrast and live fixture objective, league help, quay directions; final documentation and before/after playtest.
- Acceptance: generated-map validation, full gates, isolated beginner-like Wren/Noor/Ivo counted games and separate Kesh practice coverage with opened screenshots.
- Independent human beginner testing remains the PROG-01 release gate.

### PROG-02 — Make Kesh's opening game optional practice

- Status: `SHIPPED` (implementation merged in PR #25 at `f1b02c8`) · Priority: `P1` · Owner: Codex · Branch: `codex/novice-league`.
- Base reverified on 2026-09-06: HEAD and fetched origin/main both `2a43214`;
  existing uncommitted PROG-01 work retained.
- Decision: owner approved immediate provisional card/invitation followed by optional,
  unrated handicap practice. No placement assessment or novice-route bypass is implied.
- Scope: remove the required even game against 12k Kesh; update her introduction,
  Wren's directions, journal and generated setup. Preserve previous ranks and results.
- Inspection fix: the rank card previously left dialogue consuming its keys underneath;
  dialogue now uses unhandled input so the modal card consumes them first.
- Acceptance: declining reaches the Instituut without a Kesh result; accepting uses
  handicap and changes neither rank nor rated-win count; win/loss reactions remain
  distinct; returning and loading never reassign an existing rank. Play both paths,
  inspect screenshots and run compile/load, rules, content and engine gates.

- Verified: 16,242 checks, 260 files loaded, all three KataGo gates and lesson validation
  passed. New Game through novice-room arrival without Kesh, card/decline/reload, and a
  complete optional handicap game were played with inspected screenshots. The latter
  finished after 69 moves with rank unchanged at 30k; both result branches are tested.
- Evidence: [Kesh welcome playtest](docs/novice/KESH-WELCOME.md). User saves untouched.
  Original verification preceded merge; implementation is now on the revision base.
  PROG-01's broader human-strength release gate remains open.

### PROG-01 — Give beginners a league of their own

- Status: `BLOCKED` for human rank validation; implementation merged in PR #25 · Priority: `P1` · Owner: Codex
  · Branch: `codex/novice-league`.
- Decision: owner approved the beginner-first implementation plan on 2026-09-05.
- Scope: independently configured novice engines first; safe provisional 30k; five
  permanent novice classmates; repeatable, recorded league attempts; handicap Beginner
  Cup finale; optional Academy League/exam; preserve existing saves and cast.
- Order: engine probe and rank arithmetic, then content and league integration, then
  migration, played journeys, and documentation reconciliation.
- Inspection follow-up: new Cup registrations freeze entry rank so changing the player
  card cannot reconstruct earlier pairings differently. Existing Cup pairing/rematch
  rules and already-entered legacy policies are preserved.
- Acceptance: rank/fixture/migration tests, complete isolated beginner and losing/retry
  routes with opened screenshots, real-engine games and normal gates.
- Release gate: target ranks 30k/27k/25k/23k/20k require independent beginner playtesting.
  Engine legality or relative bot results cannot certify those human rank labels.
  Keep this work unshipped until that gate is satisfied; prepare a reviewable build first.
- Verified: 16,137 checks, 260 files loaded, all three real KataGo gates, and lesson
  validator 0 problems. New Game → five complete novice games (3–2) → four complete
  Cup games → ending → retry passed; the all-loss route, Academy six-fixture/reload/retry/
  archive route, legacy league/Cup/exam loads and provisional-rank card were played and
  their screenshots inspected. The subsequent fixed-entry-rank Cup rerun finished 2–2.
- Human feedback (2026-09-06): owner beat Noor and Ivo, both described as "close-ish".
  Encouraging evidence for achievable games; exact ranks and the other three remain unvalidated.
- Strength evidence: 72 complete games, zero discarded/truncated; adjacent stronger
  profiles won 7/8, 7/8, 7/8 and 6/8. This supports differing bot strengths, not the exact
  target ranks or human plausibility. Remaining dependency: independent beginner playtests.
- Evidence and reproducible commands: [novice playtest record](docs/novice/PLAYTEST.md),
  including raw SGFs/configurations, saved route histories and inspected images.
- No shipped milestone, merge or publication is claimed while the human gate is open.


### UI-03 — Town run mode

- Status: `SHIPPED` (verified on branch) · Priority: `P2` · Owner: Codex
  · Branch: `codex/town-run-mode`.
- Base: verified `origin/main` `b0fb0af`.
- Scope: hold either Shift to run at 1.75× the existing walk speed in every explorable
  map; accelerate the existing player gait proportionally and retain distance-based steps.
- Decision: running is transient and unlimited. No toggle, stamina, saved preference,
  new art, NPC speed change, Go-layer change or progression consequence.
- Acceptance: exact walk/run and diagonal speeds, Shift binding, gait scaling and default
  NPC gait are checked; exterior/interior steering, collision, warps, interaction and
  input locks are played through the isolated `run_mode` route and its frames inspected.
- Evidence: `tools/test.sh` passed 14,485 checks with 240 files loaded and all three
  KataGo gates green. `run_mode` measured exactly 1.750× travel, restored walking on
  release, respected wall and menu locks, crossed into De Ketel and reached Wren after
  an indoor run. All three isolated-XDG frames were opened and inspected; no sliding,
  collision, doorway, layout or interaction regression was visible.

### UI-02 — Mouse support across board screens

- Status: `SHIPPED` (M44, verified; [PR #23](https://github.com/jmilne22/ninepoint/pull/23) merged) · Priority: `P1`
  · Owner: Codex · Branch: `codex/board-mouse-support`.
- Base: verified `origin/main` `07b3694`.
- Scope: hover targeting and occupancy-only stone previews, stable 19×19 zoom,
  counting/lesson/review inspection, clickable encounter actions and modal controls.
- Decision: illegal-move handling stays exactly as shipped; no hover legality checks,
  blocked markers or explanations. Keyboard controls remain available.
- Acceptance: all four sizes, mouse-only encounter completion, modal/turn blocking,
  existing illegal lesson attempts, input-event probes and opened gameplay screenshots.
- Follow-up: review Yes/No rows now receive hover/click directly inside the card;
  redundant footer buttons removed. Played Yes/No clicks, hover and keyboard handoff
  (`mouse_review_choice`, `mouse_nineteen`, `thirteen`); screenshots inspected.
  Follow-up load gate: 239 files; 14,476 checks passed.
- Evidence: 14476 checks, 239 files load and all three serial KataGo gates passed.
  All four sizes, counting, ko, puzzle rollback/reset, read-only review, nigiri choices,
  2×/3× window scaling and keyboard handoff were exercised through input events.
  Opened screenshots and fixture limitations: `docs/mouse/PLAYTEST.md`.
  Town input and engine/progression changes are out of scope.

### POLISH-01 — Verhaven art, writing and beginner experience overhaul

- Status: `SHIPPED` (M43, verified on review branch; not merged automatically) · Priority: `P1`
- Owner: Codex · Branch: `codex/verhaven-overhaul` · Base: `277b51d`.
- Scope: all eleven maps, fifteen characters and player-facing text; factual match
  presentation, explicit handicap teaching, repaired beginner progression, distinctive
  generated art, purposeful NPC activities, ordered overheard exchanges and event payoff.
- Decision: preserve Python assets, ranks and Go progression. Empty boards before the
  first rank; no schedules, affection, statistics, errands or engine retuning.
- Reconciles: ENG-08's opening decision, WORLD-02/03 presentation, CONTENT-02/03
  character/event writing, TECH-05/07 affected presentations. Unrelated debt stays separate.
- Acceptance: actual new-player journeys and screenshots reviewed, handicap receiving
  and giving understood in play, every map and result branch inspected, old saves safe,
  plus compilation/load, rules, content and engine gates.
- Evidence: 14235 checks, 236 resources load, three real-engine gates, all eleven maps
  validate, taught positions have zero problems, 18 audio tracks and four stings pass.
  Played journeys, fixture limitations and images: `docs/overhaul/PLAYTEST.md` and
  `docs/overhaul/GALLERY.md`. The ineligible league footer was read in the fresh route.

## Needs decision

### ENG-01 — Choose the production Go-engine strategy

- Status: `SHIPPED` · Priority: `P0`
- Why: KataGo could provide honest opponent strength, dead-stone adjudication, and eventual
  whole-board review, but adds a platform binary, a large model, and an unproven subprocess
  path under `steam-run`.
- Decision: approved bundled KataGo for Linux x64. The packaging boundary is
  `packaging/katago-linux-x64.json`; release engineering pins binary/models/config,
  checksums, licences, and human-style launch arguments there.
- Acceptance: a recorded decision in this ticket and `ROADMAP.md`; if approved, create the
  implementation tickets below with the chosen packaging constraints.
- Context: `ROADMAP.md` §1.

### WORLD-01 — Decide the quay’s purpose

- Status: `SHIPPED` (M40; stale status reconciled during UI-01) · Priority: `P1`
- Decision: preserve the quay as a quiet place to read the last requested game review.
  Its noticeboard retains the review after the player leaves the loading screen.
- Evidence: M40 `quay_review` / `quay_review_19`, the implemented `SignDesk` route,
  and the current role in `GAME_DESIGN.md`.
- Context: `ROADMAP.md` §2.

## Needs decision (new)

### ENG-06 — Measure the cast's real strength

- Status: `SHIPPED` (M41) · Priority: `P1` · Branch: `feat/eng-06-cast-strength`
- Why: M39 calibrated every KataGo profile for latency, legality and fallbacks, never for
  strength. The owner, a beginner, lost every game, including to Abel (21k) and Wren (20k).
- Decision taken: the reference is the same Human-SL model at temperature 1.0 (KataGo's
  "realistic individual") at 20, 15 and 10 kyu, anchored by GNU Go 3.8; the tolerance is
  one stone on 9×9, three ranks; and if the model's 20k floor is still above a beginner,
  temperature above 1.0 for Abel and Wren rather than a label change.
- Evidence: `tools/katago_strength_probe.gd`, 537 games. On the model's own ladder the
  cast sat within about three ranks of its labels (the ladder cannot tell 20k from 15k on
  9×9), and the floor was the problem: a realistic online 20k. Steady temperament
  0.65/0.45 → 0.80/0.65; the 20k configs (Abel, Wren) at temperature 1.5 on every move,
  which reads under 20k (0/8 and 1/8 against the realistic 20k, −31 and −38 a game).
  `katago_calibrate.gd` 28/28, slowest reply 1670 ms; `tools/test.sh` 12505 passed;
  `review_world_wren_loss` / `review_world_wren` played, frames opened. Numbers and the
  two power-offs in `MILESTONES.md` M41. Not done: the owner's own games.
- Context: `ROADMAP.md` §1; `MILESTONES.md` M41; follow-ups ENG-07, ENG-08.

## Ready

### ENG-07 — The heuristic's rank labels are fiction

- Status: `READY` · Priority: `P2`
- Why: M41's strength probe played the shipped heuristic against a realistic 20 kyu
  (KataGo Human-SL at temperature 1.0). At `mistake_rate` 0, `reading_depth` 2 -- the
  setting the autopilot calls 1 dan -- it lost 8 of 8 by 58 points on average; at its
  20-kyu setting, 8 of 8 by 72. It is the fallback when the engine is missing and the
  autopilot's player brain, and neither of those needs a rank, but anything that reads a
  rank off it is reading a number nobody measured.
- Scope: either stop labelling heuristic settings with ranks (the autopilot's `brain_rank`
  and `OpponentProfile.rank_label` on a heuristic profile) or tune and measure them with
  `tools/katago_strength_probe.gd` (`--cells=anchors`). A separate checkout was retuning
  the heuristic's `mistake` table against the same ladder on 2026-09-05; reconcile with it.
- Acceptance: no rank label in the game is attached to a heuristic setting that has not
  been placed on the ladder, and the probe's anchor cells record where each one sits.
- Context: `MILESTONES.md` M41.

### ENG-08 — Stones in the first three games

- Status: `SHIPPED` (M43 decision and presentation) · Priority: `P1`
- Historical M43 decision: early games started empty and Kesh used rated nigiri.
  Superseded by PROG-02 and CAP-01: Pip now offers a prepared demonstration before
  optional empty practice; Wren's full practice remains empty. Kesh issues provisional
  30k before optional unrated rank-handicap practice. Unknown rank is never numerical strength.
- Evidence: fresh and shortcut journeys, actual empty boards, first rating, and subsequent
  handicap teaching inspected. `GoMatchSetup` and `GoRank` preserve unknown strength;
  `tests/test_onboarding.gd` covers the boundary across all supported board sizes.
- Engine floor measurement and further calibration remain ENG-06. This choice does not
  claim the present opponents are easy enough for every newcomer.
- Context: approved POLISH-01 plan; `GAME_DESIGN.md`; M43 play observations.

### TECH-01 — Make JSON data part of the load gate

- Status: `SHIPPED` (M38) · Priority: `P1`
- Scope: validate every dialogue, lesson, puzzle, and banter JSON file in the normal data/load
  test path, not only those reached by a particular fixture.
- Evidence: `tests/check_load.gd` parses every `.json` under `data/` and fails the gate on a
  parse error; `tools/test.sh` reports "223 files, all load".
- Context: `ROADMAP.md` §5.

### UI-01 — Make 19×19 playable in the match UI

- Status: `SHIPPED` (M42) · Priority: `P1` · Owner: Codex · Branch: `codex/ui-01-19x19`
- Agreed scope: development-only 19×19 play, whole-board overview and V zoom,
  cursor-following inspection in matches/counting/reviews, learner-facing controls,
  isolated verification, and played/inspected evidence. Town access and teaching follow later.
- Scope: resolve board and text readability at 19×19 in the match panel. The engine question
  is answered (ENG-03); this supplies development play and zoom for M40 review positions.
- Evidence: two engine-backed games to counting/result/review/world, 105 and 161 legal
  engine replies without fallback; native and 3× frames opened. Physical V, mouse, modal
  blocking, cursor retention, counting toggles, handicap and fallback played. Smaller
  boards, ko and review exits replayed. 14269 checks (M41: 12505), 229 files load, three
  engine gates passed; inherited TECH-06 limitations remain. Full evidence in M42.
- Follow-up: CONTENT-04 owns the teaching introduction, Hana offer and progression gate.
- Context: `ROADMAP.md` §3.

### TEST-01 — `slice_full` has been broken since the early-game merge

- Status: `SHIPPED` (SELA-03 / M48) · Priority: `P2`.
- Resolution: retired `slice_full`; repaired `kesh_skip` around current named choices,
  lesson execution and return timing. Its fresh journey reached novice registration
  and disk reload (80 captures, exit 0, zero script errors). Current docs/runner point
  to it and prepared early/novice routes; older play reports are marked historical.
- Original diagnosis follows (found during POLISH-02, 2026-09-08).
- What happens: the route stops after ten shots with "Experience route timed out waiting
  for lesson_place". Wren's `ask_experience` choices and her lead-in changed in M45, so
  `{"choose": 0}` no longer reaches the liberties lesson and one `interact` no longer
  opens it. The remaining 150-odd steps have never run since.
- **Not a POLISH-02 regression**: reproduced identically on a clean worktree at
  `origin/main` `ee1b65e` — ten shots, same message, same step. M45's evidence list does
  not include `slice_full`, and `tools/autopilot/slice_full.json` was last touched in
  `b915a12`, before the early-game merge.
- Why it matters: `CLAUDE.md` and `docs/overhaul/PLAYTEST.md` both name `slice_full` as a
  preferred verified route. A fixture that stops a sixth of the way in and is still
  described as the canonical New Game journey is the document lying quietly, which is the
  failure mode the "sweep the documents" rule exists for.
- Scope: replay the route by hand against the current early-game flow and rewrite its
  choices and advances, or retire it in favour of `early_lessons` and `novice_journey`,
  which are M45-era and do complete.
- Acceptance: the route reaches its final step, or the documents stop naming it.
- A partial repair was tried and reverted during POLISH-02 rather than left unproven:
  Wren's lead-in does now need an `advance` instead of one tap, but that alone does not
  clear it.

### TECH-02 — Replace duplicated lesson/puzzle reachability lists

- Status: `READY` · Priority: `P2`
- Scope: derive the test’s reached lessons and puzzles from the real track/content data, or
  otherwise make drift impossible.
- Acceptance: adding a track item cannot leave the reachability test green by updating a
  separate hand-maintained copy.
- Context: `ROADMAP.md` §5.

### TECH-03 — Add audibility coverage for positional sound emitters

- Status: `READY` · Priority: `P2`
- Scope: extend audio verification to `washer`, `fryer`, and `stove_crackle`, or document a
  tested alternative that proves they are audible in context.
- Acceptance: every positional emitter has an automated or explicitly manual verification
  route; the check’s limits and exclusions are documented.
- Context: `ROADMAP.md` §5.

### TECH-04 — Separate tournament routing from `World`

- Status: `READY` · Priority: `P2`
- Scope: extract the remaining exam/Cup routing responsibility from `src/rpg/world.gd` into a
  focused component without changing player-facing flow.
- Acceptance: `World` no longer owns tournament routing, existing tournament tests pass, and
  relevant autopilot coverage is played and inspected.
- Context: `ROADMAP.md` §5.

## Shipped engine work

### ENG-02 — Harden the GTP boundary

- Status: `SHIPPED` · Priority: `P0`
- Scope: fix GTP state synchronisation, handicap/set-position handling, per-turn board reset,
  timeout/cancellation, and failure recovery before a production engine can be used.
- Acceptance: an engine-process test proves state sync and timeout behaviour without freezing
  the game; the existing heuristic path remains usable until replacement is approved.
- Context: `ROADMAP.md` §1.

### ENG-03 — Integrate the chosen engine for opponents

- Status: `SHIPPED` · Priority: `P0` · Depends on: `ENG-02`
- Scope: package and select the approved engine, preserve rank labels and handicap rules, and
  provide a graceful unavailable-engine path.
- Acceptance: passed on Linux x64 Eigen-AVX2. The pinned player-black UI fixture completed
  preparation, two legal engine replies, a normal result and world return without fallback;
  the 2026-09-04 all-profile calibration passed 28/28 profiles (maximum normal reply
  1518 ms, zero fallbacks). Beginner, club and advanced cast waves are promoted in order.
- Context: `ROADMAP.md` §1.

### ENG-04 — Rebuild the review on the engine

- Status: `SHIPPED` (M40) · Priority: `P1` · Depends on: `ENG-03`
- Scope: restore the review as the largest score swings of a played game, offered by the
  person you played, on any board the engine takes (7–19), never blocking the return to the
  world, with old rules-only review logic absent.
- Evidence: `tools/katago_review_test.gd` (a whole 9×9 and 19×19 game, every position, and
  a wedged engine failed by the watchdog); fixtures `review_e2e`, `review_13x13`,
  `review_leave`, `review_unavailable`, `quay_review`, `quay_review_19`, screenshots opened;
  full games played through the world route. Numbers in `MILESTONES.md` M40.
- Context: `ROADMAP.md` §1.

## Blocked

### ENG-05 — Engine dead-stone adjudication at the count

- Status: `BLOCKED` · Priority: `P2` · Depends on: a working route that is not
  `final_status_list`
- Scope: replace the heuristic dead-stone proposal at the count with the engine's
  judgement, keeping the player's override.
- Why blocked: `final_status_list dead` hung indefinitely on the bundled Human-SL build
  (M40 found it while wiring the review); `GtpOpponent.dead_stones()` was removed rather
  than shipped dead. The analysis mode's `includeOwnership` output is the candidate route.
- Acceptance: the proposal comes from the engine, disputed stones remain toggleable, and
  a fixture proves the count screen never waits on the engine.
- Context: `ROADMAP.md` §1, §5.

### ENG-09 — Evaluate stopping in beginner and handicap games

- Status: `NEEDS DECISION` · Priority: `P1`.
- Evidence: the revision’s manually played Wren, Noor and Ivo games required repeated
  player passes. A supplemental Kesh run ended after White/Black passed without any
  placements on the five-stone opening; another completed 74 moves normally.
- Scope to decide: reproduce early passes and low-value continuations separately from
  dead-group adjudication (ENG-05). Inspect actual engine/fallback paths and saved SGFs.
- Additional baseline observation: the supported Wren game lasted 89 plies with nine
  White passes; Noor's lasted 89 with four separated Black passes before the final pair;
  Ivo's lasted 89 with only the final pair. SGFs and exact indices are retained in
  [the baseline report](docs/baseline/PLAYTEST.md). The player was a 12k-labelled heuristic,
  so these are stopping traces, not human judgment or proof of a better ending.
- No stopping policy, engine strength or dead estimator changed in EARLY-01..05 or this baseline.
- Acceptance for future work must include actual positions and human beginner observations;
  a shorter bot game is not proof of a better ending.

## Teaching decisions

### CONTENT-05 — Assess Wren's introductory game strength

- Status: `NEEDS DECISION` · Priority: `P1`.
- Owner feedback (2026-09-06): Wren may still be too strong for a new player. Her
  introductory 9×9 keeps the existing engine settings and has no handicap; being
  unrated does not establish an appropriate learning difficulty.
- Confirmed revision decision: keep Wren’s strength unchanged while improving teaching and support.
- Next step: compare independent beginner experience of that supported game with the close-ish Noor/Ivo games,
  then agree whether Wren's introductory profile needs separate strength settings.
  No engine retuning or new teaching encounter is included in PROG-01/02.
- CAP-01 / DESIGN-01 supplement: full supported Wren, Noor and Ivo games, saved SGFs,
  results and count frames are in [the baseline report](docs/baseline/PLAYTEST.md).
  A stronger automated player won all three; no independent beginner comparison occurred.
  Keep the existing strength decision until the prepared human study supplies that evidence.


### CONTENT-01 — Teach whole-board judgement

- Status: `NEEDS DECISION` · Priority: `P2` · Technical dependency `ENG-04` shipped in M40.
- EARLY-02 covers the approved early subset: demonstrated finishing, survival comparisons,
  useful last moves, optional opening comparisons and factual position Help. EARLY-04 revises
  review explanations. These packages do not duplicate a separate curriculum implementation.
- Remaining decision: choose a later whole-board judgement concept and its curriculum position.
- The former generic "small board" habit and blanket first-line advice were removed in EARLY-04.
  Later judgement teaching still needs an agreed scope and human learning evidence.
- Scope: extend the curriculum beyond locally decidable rules into engine-backed judgement.
- Acceptance: new teaching content has checkable positions/evaluation and a played,
  screenshot-reviewed learning route.
- Context: `ROADMAP.md` §4.

### CONTENT-04 — Introduce the transition from thirteen to nineteen lines

- Status: `NEEDS DECISION` · Priority: `P1` · UI foundation: `UI-01`.
- Decision needed: when Hana offers the larger board, what prior experience it requires,
  and the first task that makes a distant move intelligible to a learner.
- Scope: a played teaching introduction, a town offer, and an explicit progression gate.
  The development fixture supplies none of these.
- Evidence from UI-01 inspection: the interface can identify a distant reply and return to
  a chosen point, but the existing local lessons do not explain when to leave a fight,
  why a distant move is larger, or how to judge a group's safety before counting.
  Crowded scoring can be inspected confidently in zoom; deciding which groups are dead
  remains a Go judgement, with the existing heuristic proposal and player override.
- Acceptance: starting with only the current game's teaching, a player understands the
  reason for trying nineteen lines and can act on the first whole-board lesson. Play and
  inspect the whole transition; the owner's experience decides whether it teaches.
- Context: `ROADMAP.md` §3; `GAME_DESIGN.md` teaching order.

## Later

### WORLD-02 — Give Onderbrug a deliberate role beyond Joos

- Status: `SHIPPED` (M43) · Priority: `P2`
- Scope: decide whether its solitude is sufficient; if not, add a permanent interaction or
  environmental story that fits a sealed viaduct dead end without inventing a crowd route.
- Acceptance: the role is observable in play and stated in design documentation.
- Context: `ROADMAP.md` §2.

- M43 evidence: Joos's solitude is deliberate: a dry board corner, maintained equipment, arches and port storage. All approaches and Joos's casual game were inspected.

### WORLD-03 — Rework the wassalon’s permanent three-person layout

- Status: `SHIPPED` (M43) · Priority: `P2`
- Scope: improve readability and social plausibility of three permanent NPCs in a small room.
- Acceptance: the room reads clearly in-game and retains its three-register purpose.
- Context: `ROADMAP.md` §2.

- M43 evidence: The generated laundry room fits its three permanent residents, folding space and two seats at an approachable board. Ordered exchanges and interrupted/resumed folding were observed.

### CONTENT-02 — Extend study-hall character arcs

- Status: `LATER` · Priority: `P2`
- Scope: give Ilse, Sunny, and Orla progression beyond their existing three- and six-game arcs.
- Acceptance: each added arc has result-aware dialogue, data validation, and a played route.
- Context: `ROADMAP.md` §4.

- Reconciliation: M43 deepened the existing three/six-game conversations and exercised both thresholds. Progression beyond six games remains separate and unstarted.

### CONTENT-03 — Create a post-exam ending

- Status: `SHIPPED` (M43) · Priority: `P1`
- Scope: make the end of the exam/Cup arc a proper ending rather than Hana’s final line.
- Acceptance: win and loss/alternate outcomes are intentional, reachable, and reviewed in the
  real game.
- Context: `ROADMAP.md` §4.

- M43 evidence: Every existing exam/Cup outcome has a direct conclusion, visible results and optional return acknowledgements. Both Cup sections completed; exam pass/fail and champion fixtures inspected. No new chapter was added.

### TECH-05 — Clarify the exam and Cup board presentations

- Status: `LATER` · Priority: `P2`
- Scope: visually distinguish the exam list from the Cup draw after their introductory panel.
- Acceptance: screenshots make the mode obvious without relying only on the header.
- Context: `ROADMAP.md` §5.

- Reconciliation: M43 clarifies placing, eligibility, next action and rank tiebreaks on all event boards. Distinct visual structures beyond their labels remain separate UI work.

### TECH-06 — Make testable UI logic live on the pure side

- Status: `SHIPPED` (M43) · Priority: `P2`
- Scope: remove dead assertions caused by `CanvasLayer`/autoload scripts being unavailable to
  headless script tests; start with `ExamBoard.summary()`.
- Acceptance: the affected assertions exercise real code and fail when deliberately broken.
- Context: `ROADMAP.md` §5.

- M43 evidence: The runner defers suite loading until autoload readiness and rejects script errors. ExamBoard assertions now execute real code. Pure/panel extraction remains optional maintenance rather than a silent coverage hole.

### TECH-07 — Resolve remaining UI layout debt

- Status: `LATER` · Priority: `P3`
- Scope: reduce brittle literal positioning where containers or shared layout helpers can do so
  without losing the pixel-art composition.
- Acceptance: targeted panels retain their intended layout across their supported content, and
  visual routes are inspected.
- Context: `ROADMAP.md` §5.

- Reconciliation: M43 measures and paginates affected match, lesson, review, rank and standings surfaces. General conversion of hand-positioned UI into components remains separate.

### TECH-08 — Isolate or retire production test hooks

- Status: `LATER` · Priority: `P3`
- Scope: assess `Autopilot` and `GoMatch.THINK_DELAY_FAST` and isolate them from production
  behaviour where practical.
- Acceptance: test speed/control remains available and production startup does not depend on
  test-only state.
- Context: `ROADMAP.md` §5.

### TECH-09 — Remove the fragile tram await boundary

- Status: `SHIPPED` (M43) · Priority: `P3`
- Scope: replace the `SignDesk` await on a World-owned tram with an ownership-safe event or
  transition boundary.
- Acceptance: tram travel cannot resume code against freed scene state; normal travel remains
  visually identical.
- Context: `ROADMAP.md` §5.

- M43 evidence: SceneRouter now owns destination presentation and map replacement. Actual northbound and southbound travel, skippable exterior views and return routes were inspected.

### TECH-10 — Validate passer routes with the intended movement model

- Status: `LATER` · Priority: `P3`
- Scope: keep route validation aligned with no-pathfinding movement, or adopt a path model and
  test it consistently.
- Acceptance: every generated route is proven traversable by the movement it actually uses.
- Context: `ROADMAP.md` §5.

## Parked

- `wip/cup-epilogue` — Marguerite closes both exam outcomes and points at the Cup as an
  optional city draw, a darker Cup card, and the `cup_day` preset marking the exam finished.
  Found uncommitted in the review branch's tree; nobody has played or inspected it. It is
  the start of CONTENT-03 / TECH-05, not a shipped change.

## Shipped recently

- `M46` — reading the town: closed map edges and a boundary rule in the map
  generator, doorway prompts and mats, the tram stop and the steps to the water,
  furniture measured against the person, three shopfronts, a chair on the far side of
  every board, seven reacting expressions and a rebuilt title card.
- `M42` — development-only nineteen-line overview/zoom, match/count/review navigation,
  isolated fixture tools and observed-play evidence. Teaching transition remains CONTENT-04.
- `M41` — the cast's strength measured in whole games for the first time; the steady
  temperament and the 20k floor retuned from the numbers; the probe, with a memory cap.
- `M40` — the review, rebuilt on KataGo's analysis mode: streamed progress, leaveable, on the
  quay noticeboard afterwards; the shared engine pipe; the temperaments commit that PR #17
  had merged into an already-merged branch.
- `M38`–`M39` — KataGo at the board for every character: packaging manifest, the hardened
  GTP boundary, engine leases, calibration of all 28 profiles.
- `M37` — removed calendar, review, duplicate progression, and other systems that obscured the
  core loop; fixed rank, post-match dialogue, tram interaction, and text layout.
- `M16–M36` — earlier work remains historical context only. Read the named milestone when a
  ticket depends on it; do not infer current work from its old `[done]` label.

## Triage rules

1. New work gets an ID and enters `NEEDS DECISION`, `READY`, or `LATER` before implementation.
2. A discovered defect is `P0` only when it blocks play, risks data loss, or violates a design
   pillar; otherwise use `P1`–`P3` and state its reproduction/impact.
3. Do not make a `BLOCKED` task `READY` by guessing at a dependency’s decision.
4. When shipping, update this board first, then the roadmap if its direction changed, then add
   milestone evidence for release-sized work.
