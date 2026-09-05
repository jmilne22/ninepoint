# Ninepoint — Workboard

This is the **operational source of truth** for unfinished work. An agent starts here,
not in the milestone history. It answers: what may be picked up now, what is blocked, and
what evidence makes a task done.

Snapshot: `origin/main` at `8343f62` plus the M40 review branch. Update the snapshot when
the board is reconciled after a merge; do not treat it as a release number.

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

- Status: `NEEDS DECISION` · Priority: `P1`
- Why: after schedules were cut, the quay is a bench and two signs. It must either gain a
  permanent reason to visit or be removed/merged into another location.
- Decision needed: add a resident/activity, preserve it intentionally as a quiet place with a
  concrete gameplay use, or cut it.
- Acceptance: the chosen role is stated in `GAME_DESIGN.md`, and a follow-up implementation
  ticket exists if the map remains.
- Context: `ROADMAP.md` §2.

## Needs decision (new)

### ENG-06 — Measure the cast's real strength

- Status: `NEEDS DECISION` · Priority: `P1`
- Why: M39 calibrated every KataGo profile for latency, legality and fallbacks, never for
  strength. M40's autoplay brain (the shipped heuristic at `mistake_rate` 0, `reading_depth`
  2, labelled 1 dan) lost to Abel's 21-kyu profile by 43 points and, at its 12-kyu setting,
  to Wren's 20 kyu by 86. Either the Human-SL profiles play well above their labels at eight
  visits, or the heuristic plays well below its own. Rule 3 says the labels are real ranks;
  nothing has checked that they are.
- Decision needed: what reference to measure against (a fixed-strength engine setting,
  GNU Go, or a person), and what to do if the beginner profiles are too strong for the
  first hour of play.
- Acceptance: a recorded measurement per beginner profile and a stated tolerance.
- Context: `ROADMAP.md` §1; `MILESTONES.md` M40.

## Ready

### TECH-01 — Make JSON data part of the load gate

- Status: `SHIPPED` (M38) · Priority: `P1`
- Scope: validate every dialogue, lesson, puzzle, and banter JSON file in the normal data/load
  test path, not only those reached by a particular fixture.
- Evidence: `tests/check_load.gd` parses every `.json` under `data/` and fails the gate on a
  parse error; `tools/test.sh` reports "223 files, all load".
- Context: `ROADMAP.md` §5.

### UI-01 — Make 19×19 playable in the match UI

- Status: `READY` · Priority: `P1`
- Scope: resolve board and text readability at 19×19 in the match panel. The engine question
  is answered (ENG-03) and the review already reads a 19×19 game (M40); what is missing is
  the board at the table.
- Acceptance: a 19×19 match is legible and playable at the supported resolution and is
  inspected in the real game.
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

### CONTENT-01 — Teach whole-board judgement

- Status: `BLOCKED` · Priority: `P2` · Depends on: `ENG-04`
- Scope: extend the curriculum beyond locally decidable rules into engine-backed judgement.
- Acceptance: new teaching content has checkable positions/evaluation and a played,
  screenshot-reviewed learning route.
- Context: `ROADMAP.md` §4.

## Later

### WORLD-02 — Give Onderbrug a deliberate role beyond Joos

- Status: `LATER` · Priority: `P2`
- Scope: decide whether its solitude is sufficient; if not, add a permanent interaction or
  environmental story that fits a sealed viaduct dead end without inventing a crowd route.
- Acceptance: the role is observable in play and stated in design documentation.
- Context: `ROADMAP.md` §2.

### WORLD-03 — Rework the wassalon’s permanent three-person layout

- Status: `LATER` · Priority: `P2`
- Scope: improve readability and social plausibility of three permanent NPCs in a small room.
- Acceptance: the room reads clearly in-game and retains its three-register purpose.
- Context: `ROADMAP.md` §2.

### CONTENT-02 — Extend study-hall character arcs

- Status: `LATER` · Priority: `P2`
- Scope: give Ilse, Sunny, and Orla progression beyond their existing three- and six-game arcs.
- Acceptance: each added arc has result-aware dialogue, data validation, and a played route.
- Context: `ROADMAP.md` §4.

### CONTENT-03 — Create a post-exam ending

- Status: `LATER` · Priority: `P1`
- Scope: make the end of the exam/Cup arc a proper ending rather than Hana’s final line.
- Acceptance: win and loss/alternate outcomes are intentional, reachable, and reviewed in the
  real game.
- Context: `ROADMAP.md` §4.

### TECH-05 — Clarify the exam and Cup board presentations

- Status: `LATER` · Priority: `P2`
- Scope: visually distinguish the exam list from the Cup draw after their introductory panel.
- Acceptance: screenshots make the mode obvious without relying only on the header.
- Context: `ROADMAP.md` §5.

### TECH-06 — Make testable UI logic live on the pure side

- Status: `LATER` · Priority: `P2`
- Scope: remove dead assertions caused by `CanvasLayer`/autoload scripts being unavailable to
  headless script tests; start with `ExamBoard.summary()`.
- Acceptance: the affected assertions exercise real code and fail when deliberately broken.
- Context: `ROADMAP.md` §5.

### TECH-07 — Resolve remaining UI layout debt

- Status: `LATER` · Priority: `P3`
- Scope: reduce brittle literal positioning where containers or shared layout helpers can do so
  without losing the pixel-art composition.
- Acceptance: targeted panels retain their intended layout across their supported content, and
  visual routes are inspected.
- Context: `ROADMAP.md` §5.

### TECH-08 — Isolate or retire production test hooks

- Status: `LATER` · Priority: `P3`
- Scope: assess `Autopilot` and `GoMatch.THINK_DELAY_FAST` and isolate them from production
  behaviour where practical.
- Acceptance: test speed/control remains available and production startup does not depend on
  test-only state.
- Context: `ROADMAP.md` §5.

### TECH-09 — Remove the fragile tram await boundary

- Status: `LATER` · Priority: `P3`
- Scope: replace the `SignDesk` await on a World-owned tram with an ownership-safe event or
  transition boundary.
- Acceptance: tram travel cannot resume code against freed scene state; normal travel remains
  visually identical.
- Context: `ROADMAP.md` §5.

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
