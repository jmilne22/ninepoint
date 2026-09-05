# Ninepoint — Workboard

This is the **operational source of truth** for unfinished work. An agent starts here,
not in the milestone history. It answers: what may be picked up now, what is blocked, and
what evidence makes a task done.

Snapshot: `origin/main` at `2a43214`, fetched and HEAD equality verified before PROG-01.
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

## In progress

### PROG-02 — Make Kesh's opening game optional practice

- Status: `SHIPPED` (verified on branch; not merged) · Priority: `P1` · Owner: Codex · Branch: `codex/novice-league`.
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
  No merge or publication; PROG-01's broader human-strength release gate remains open.

### PROG-01 — Give beginners a league of their own

- Status: `BLOCKED` for release; implementation verified · Priority: `P1` · Owner: Codex
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
- Decision: Pip's first Capture Go and Wren's first practice start empty. Kesh's first
  rated game uses nigiri. An unknown rank is never treated as numerical strength.
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

## Teaching decisions

### CONTENT-05 — Assess Wren's introductory game strength

- Status: `NEEDS DECISION` · Priority: `P1`.
- Owner feedback (2026-09-06): Wren may still be too strong for a new player. Her
  introductory 9×9 keeps the existing engine settings and has no handicap; being
  unrated does not establish an appropriate learning difficulty.
- Next step: compare human beginner experience with the close-ish Noor/Ivo games,
  then agree whether Wren's introductory profile needs separate strength settings.
  No engine retuning or new teaching encounter is included in PROG-01/02.


### CONTENT-01 — Teach whole-board judgement

- Status: `NEEDS DECISION` · Priority: `P2` · Technical dependency `ENG-04` shipped in M40.
- Decision needed: choose the next judgement concept and its place in the curriculum.
  Engine availability no longer blocks this ticket; content scope is still unchosen.
- UI-01 evidence: a nineteen-line review still says "a small board" in the generic
  lone-stone habit. Explanations need board-size context when this content is scoped.
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
