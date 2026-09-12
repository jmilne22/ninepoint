# REV-01 — Reviews that explain *why*, and a teaching game

Handoff for an agent working in `jmilne22/ninepoint` (Godot 4.7, GDScript). Read
`AGENTS.md` first; every rule there still applies, especially rule 2 (`src/go/` knows
nothing about the game) and rule 9 (play it before calling it done).

## Approved session boundary

Implement Steps 1–4 only. Step 5 and the optional narrator backend remain unstarted.
The approved execution plan uses query-level `maxVisits` overrides on one process:
8 for the score pass, 200 for actual/best comparisons. The first nine-query 9×9
measurement took 50.377 seconds in pass 2; work stopped and the owner approved
50 visits for pass branches only. Further visit changes require the owner’s decision
with measurements. The budget is 45 seconds for 9×9 pass 2.
Ownership is copied in documented top-left-first row-major order, after validation;
real A1/B3 probes and asymmetric tests establish the ordering. After enrichment,
duplicate or unsupported lesson cards are omitted without replacement queries.
The owner also approved a labelled “One legal example” when the selected engine PV
predicts group death without showing the capture. Keep the first two legally replayed PV
moves and demonstrate an immediate capture only if rules replay captures the entire named
chain. Preserve the original PV and its `captured_at` separately. This illustrates a
possible continuation; it establishes neither a forced capture nor the engine's preferred
line. The cost is still the engine's move comparison, not a valuation of that example.
No additional query or visit change is authorized. Revalidate examples on save load.
The original proposal below remains as context; this authorization takes precedence.

## Problem

Review cards say things like *"Yours placed a stone at E5 with 4 liberties. D4 would have
placed a stone at D4 with 4 liberties."* This is because:

1. `src/go_ai/move_explainer.gd` only describes a move's **immediate** mechanics
   (capture / connect / extend / contact / first line / space). The reason a move is good
   almost always lives in what happens next, which is never examined.
2. `src/go_ai/katago_analysis.gd` discards the data that carries the "why":
   `includeOwnership: false`, `includePolicy: false`, and `parse_line` keeps only
   `scoreLead` for the top two moves. The `pv` is dropped. `maxVisits = 8`.
3. There is no position *after the engine's preferred move*, so nothing can compare
   outcomes.

Goal: every review claim is a **fact derived from engine output** (ownership maps and
principal variations), phrased in beginner vocabulary that maps onto lessons the town
already teaches. No free-text generation is on the critical path.

## Architecture (new and changed files)

```
src/go_ai/katago_analysis.gd   CHANGED  two-pass query; keep pv + ownership
src/go_ai/review_facts.gd      NEW      pure: ownership maps + pv -> facts
src/go_ai/review_narrator.gd   NEW      pure: facts -> sentences (templates)
src/go_ai/match_analysis.gd    CHANGED  findings carry facts + narration + lesson id
src/go_ai/move_explainer.gd    KEPT     still used for the "strength" card's "does"
src/go_ui/review_comparison.gd CHANGED  tint ownership diff on the boards
src/autoload/match_review_service.gd CHANGED  drive pass 2
tests/test_review_facts.gd     NEW      fixture ownership maps, no engine
tests/test_match_analysis.gd   CHANGED  new payload shape
tools/katago_review_test.gd    CHANGED  real-engine gate covers pass 2
```

`review_facts.gd` and `review_narrator.gd` are `RefCounted`, static, and take plain
Arrays/Dictionaries so they run with the engine absent.

## Step 1 — Two-pass analysis (`katago_analysis.gd`, `match_review_service.gd`)

**Pass 1 (unchanged cost):** every turn, `maxVisits` 8, score only. Feeds
`MatchAnalysis.select_moments` exactly as now.

**Pass 2 (new):** for each selected finding (max 3) at move index `i` with position
`moves[:i]`, send three short queries on the same engine process, each with
`analyzeTurns: [last]`, `includeOwnership: true`, and
`-override-config maxVisits=200`:

| query id            | moves                     | gives                                      |
|---------------------|---------------------------|--------------------------------------------|
| `f{n}_actual`       | `moves[:i] + [actual]`    | ownership after the played move, opponent's best reply + `pv` |
| `f{n}_best`         | `moves[:i] + [best]`      | ownership after the engine's move          |
| `f{n}_pass`         | `moves[:i] + [pass]`      | scoreLead if the player had played elsewhere |

Also capture, from the pass-1 line for turn `i`, `moveInfos[0].pv` (first 6 moves) and
`moveInfos[0].scoreLead`; and from `f{n}_actual`, `moveInfos[0].pv`.

`parse_line` must now return, when present: `ownership` (Array[float], length
`size*size`, Black-positive, in KataGo's row order — document the order and add a
conversion to `GoBoard` index order in one place), and `pv` for the top move.

Budget: 3 findings × 3 queries × 200 visits on the bundled CPU build. Measure; if a 9×9
review exceeds ~45 s on the reference desktop, drop `f{n}_pass` to 50 visits first, then
`maxVisits` to 100. Stream `progress` for pass 2 as for pass 1. Watchdog and cancel
semantics unchanged; a pass-2 failure degrades the card to today's behaviour, never to
"failed".

Keep `includePolicy: false` — not needed for this milestone.

## Step 2 — `ReviewFacts` (`src/go_ai/review_facts.gd`, pure)

Inputs per finding: `size`, `cells` (before the move), `player`, `actual`, `best`,
`own_actual`, `own_best` (both player-relative: multiply by −1 for White), `lead_actual`,
`lead_best`, `lead_pass` (player-relative), `pv_after_actual`, `pv_best`.

Output: `Dictionary` of facts, every one coordinate-checked. Implement in this order and
stop when the budget is spent; the first three are the payoff.

1. **`region_lost`** — points where `own_best − own_actual > 0.5`. Flood-fill into
   connected regions (4-adjacent). For each region: `points` (rounded sum of the
   ownership delta), `area` (a coarse name: "lower-left corner", "left side", "centre",
   derived from the region's centroid on the board thirds), `anchor` (the label of the
   point with the largest delta). Report regions ≥ 2 points, largest first, max 2.
2. **`group_died`** — for each of the player's chains in `cells` (use
   `GoBoard.all_chains()`), mean ownership in `own_actual` vs `own_best`. If it falls from
   ≥ +0.3 to ≤ −0.3: `{anchor, stones, liberties_before}`. Same test on the opponent's
   chains for **`group_saved`** (the opponent's group went from dead to alive) —
   the mirror mistake beginners make constantly (failing to finish a capture).
3. **`refutation`** — first 2 to 4 moves of `pv_after_actual` as labels with colours,
   only if `region_lost` or `group_died` is non-empty (otherwise the line is not a
   refutation of anything the card can name).
4. **`slow_move`** — true when `(lead_best − lead_actual) ≥ MEANINGFUL_LOSS` and
   `(lead_actual − lead_pass) < 1.0`. Report `worth_actual`, `worth_best`
   (both relative to passing, rounded).
5. **`urgent_elsewhere`** — true when Manhattan distance(actual, best) ≥ size/2 and
   `group_died` non-empty. Marks "you played away from the fire".
6. **`concept`** — one of, in priority order:
   `group_died` → `"liberties"`, `group_saved` → `"capture"`, `region_lost` with
   `refutation` whose second move is adjacent to the player's stones → `"connection"`,
   `slow_move` → `"value"`, else `"unknown"`. Map each to an existing lesson id (look them
   up in `data/` lessons; Wren = liberties/rules, Kesh = escape/connection, Bertie =
   ladders, Hana = eyes). Put the mapping in one const table in `review_facts.gd`.

Do **not** attempt: shape names, "thickness", "influence", direction of play, joseki, or
any claim that cannot be pointed to on the board with a coordinate or a region.

Tests (`tests/test_review_facts.gd`): hand-written 9×9 fixtures — a corner given away
(region_lost), a two-liberty group left to die (group_died + urgent_elsewhere), an
opponent group let off the hook (group_saved), a 1-point endgame move while an 8-point
one waited (slow_move), and a quiet move with identical maps (all facts empty, concept
"unknown"). Also test White orientation: the same fixture as White must produce the same
facts.

## Step 3 — `ReviewNarrator` (`src/go_ai/review_narrator.gd`, pure)

Facts → up to three short sentences, plain words, one idea each. Numbers rounded to the
nearest point; "about" in front of anything from ownership. Order: what the move did (from
`MoveExplainer`, one clause), the cost (`group_died` / `region_lost`), the refutation,
then the lesson pointer. Examples of the target register:

- *"Your move at E5 was worth about 1 point. Your group at C3 had two liberties. White
  plays D2 and it is dead — about 9 points. Kesh's lesson on escaping covers this."*
- *"This gave up about 6 points in the lower-left. After D4 instead, that corner stays
  yours."*
- *"White's group at G7 had one liberty. H7 captures it; instead it lived."*

Constraints from `data/dialogue/VOICES.md` apply where the card is voiced by an NPC:
short lines, no rules taught in speech (the card is a card, not dialogue — check with the
writing tests which surface it uses). Quiet findings keep today's "steady" summary.

## Step 4 — Wire into `MatchAnalysis` and the cards

- Finding payload gains: `facts`, `narration` (Array[String]), `lesson_id`,
  `own_actual`, `own_best` (store as `PackedFloat32Array` quantised to 1 decimal; saves
  must stay small — measure a 19×19 review's save size before and after).
- `available()` validates: every coordinate in `narration` appears in `facts`; if not,
  drop to the old `critique` text rather than failing the review.
- `select_moments`: the "lesson" card must have a different `concept` from the
  "mistake" card, using the new concept, not `MoveExplainer`'s.
- `review_comparison.gd`: on the "your move" and "engine's move" boards, tint empty
  points by ownership (two low-alpha colours, strength ∝ |ownership|), and outline
  `region_lost` regions. Add a **Lesson L** action that opens the mapped lesson via the
  existing lesson runner, if the lesson id is set.
- Old saves without `facts` render exactly as today.

## Step 5 — Teaching game (second milestone, after 1–4 ship)

Reuse `ReviewFacts` live during Wren's unrated 9×9 and Kesh's handicap practice only.

- On the player's confirmed move, before the opponent replies, run one analysis query
  (`maxVisits` 30, ownership on) for `position + actual` and for `position + best` where
  `best` is from a prior query of `position` (cache it while the player thinks).
- If player-relative loss ≥ `TEACH_THRESHOLD` (start at 4.0 on 9×9) **and**
  `ReviewFacts` produces a `group_died`, `group_saved` or `region_lost` ≥ 4 points, the
  opponent interrupts with one question, not the answer: *"Before that — how many
  liberties does your group at C3 have?"* Offer **Undo** and **Play it anyway**. At most
  one interrupt per five moves; never in rated games.
- Explain the opponent's move after it is played, using the same facts on the
  opponent's PV: *"Wren played D2. That threatens to cut C3 from E3."* Only when a fact
  fires; otherwise silence.
- Latency budget: the extra query must stay under the profile's existing per-move
  deadline; if it misses, skip the interrupt silently.

## Optional, last — local LLM narrator

Only after Step 3 exists, and only as a paraphraser. `ReviewNarrator` gains an optional
backend: POST `facts` + an NPC persona to a local OpenAI-compatible endpoint (Ollama or
llama.cpp server, URL from a user setting, default off) with the instruction to restate
the facts in the NPC's voice and mention nothing not in them. Validate the reply: every
coordinate must appear in `facts`, length ≤ 3 sentences, no words from a small
forbidden list ("thickness", "influence", "joseki", "moyo"). Any failure → template text.
The game must be identical with the endpoint unreachable.

## Done criteria

- `tools/test.sh` green, including `tests/test_review_facts.gd`.
- `godot --headless --path . --script res://tools/katago_review_test.gd` passes with
  pass 2 on a whole 9×9 and 19×19 game, and prints the wall-clock time of each pass.
- Play Wren's 9×9, deliberately leave a two-liberty group to die, request the review:
  the mistake card names the group, its liberties, the capturing sequence, the point
  cost, and offers Kesh's lesson. Screenshot in `docs/review/PLAYTEST.md`.
- Play the same game as White (developer fixture) and confirm the same card.
- A quiet game still produces "steady", never an invented finding.
- Save size for a reviewed 19×19 game reported in `MILESTONES.md`.

## Non-goals

No new opponent strengths, no rank changes, no policy-based "what a human would play"
commentary, no shape vocabulary, no LLM on the critical path.
