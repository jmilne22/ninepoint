# Early-game revision — implementation and playtest

PR review candidate, 7 September 2026. Base: `f1b02c84dc521407c716623dd561778d0c05e73f`, verified equal to freshly fetched `origin/main` before work. Branch: `codex/early-game-review`. Prepared for PR review; no merge or release.

**Verdict:** the opening now gives a beginner a substantially clearer explanation of what a complete game asks of them. Preserve the city, cast, optional practice and league structure. The largest remaining uncertainty is whether learners can transfer the prepared finishing examples to their own messy positions. Wren's loss and the long passing sequences make independent beginner testing essential; they do not justify changing strength on this evidence alone.

This is an **AI walkthrough using beginner-like choices**, not independent human testing. The before/after comparison concerns observed content and behavior. Predicted understanding, enjoyment and motivation are interpretations. It is not a controlled experiment or a measurement of learning gains. No subjective audio assessment was performed.

## What changed

| Category | Before, observed in the original review | Implemented and observed afterward | Likely newcomer effect / remaining question |
|---|---|---|---|
| Writing | Wren's experience choices ignored Pip; later she referred an already carded player back to Kesh. | Explicit Pip acknowledgment; card continuity; Kesh offers a starting entry before optional practice and asks for a return game. | The conversation remembers the route the player took. |
| Writing | Noor and Ivo converged on the same offers and event remarks; Ivo repeated his introduction. | Noor wants company through the league and Cup; Ivo works around deliveries and wants to finish. Five individual event-voice files and introduction flags. | More reason to remember classmates; the effect on attachment is still a prediction. |
| Progression | Thirteen prescribed rules/opening exercises, with no pre-game finishing demonstration. | Four rules exercises, four finishing beats, two optional opening comparisons. Longer rule and territory examples remain refreshers. | Fewer repeated answers and a more complete task model. Ten steps are still substantial before the first full game. |
| Progression | Hana repeated a basic capture, then sent the player through registration, board, and a return to class. | Welcome and survival comparison first; registration and board next; Noor then Ivo. Capture remains optional. | Arrival feels more like joining a class and avoids the default return trip. |
| Setting | Novice possessions existed mainly in dialogue; HUD competed with scenery. | Generated table details and seats; contrasting HUD with actual fixtures and next opponent. | Room and record are easier to read. Props remain tiny at native resolution. |
| Other | Correct-answer overlays hid the board; fixed-turn practice prompts sometimes described absent threats. | Side explanations preserve positions and inspection; Help checks actual legal captures and own atari. | The player can verify the sentence against the board. |
| Other | Count components appeared after acceptance; reviews preceded the opponent's reaction. | Proposed marks and component totals before acceptance; reaction before optional analysis. | Results can be inspected before agreement, and conversations land before analysis. |
| Other | Review advice overstated safety and attack value; a recommendation could split into a nearly empty page. | Distinct connected groups, immediate captures/liberties, independent move comparisons, paragraph pagination, explicit engine preference. | More supportable advice; large engine point differences still need human explanation. |

The [original review](BEFORE.md) is retained with its cited screenshots. Its implementation references describe the base build, not the revised source.

## Main playthrough: manually chosen moves

The game ran on its live-input harness in a dedicated user-data directory. I chose movement, dialogue and board moves from visible screens, opening screenshots throughout. No navigation planner, autoplay, move-selection bot or engine suggestion chose moves in this route. Choices favored obvious captures, short extensions, replies to adjacent threats and tentative territory boundaries. Passing sometimes occurred too early; legal rejections and losses were allowed to stand.

Route completed: New Game and name → attic note and board → Pip → Wren's four rules exercises → finishing → optional openings → full Wren game and review → Kesh card, decline and return → tram → Hana welcome and first class → registration and league board → novice room → full Noor and Ivo games. Sora and Emil were also approached. Broader laundrette, quay and Tomás exploration is recorded in the before review; the after run did not repeat every town conversation.

| Game | Before | After | Evidence and interpretation |
|---|---|---|---|
| Pip | Win, 13 plies | Loss, 16 plies | [SGF](manual-0-pip.sgf). Losing still leads onward. |
| Wren | Loss by 2.5, 78 plies | Loss by 29.5, 64 plies | [SGF](manual-1-wren.sgf), [result](wren-result.png). Unrated; strength unchanged. Different moves and games cannot establish a difficulty trend. |
| Noor | Win by 16.5, 86 plies | Win by 12.5, 81 plies | [SGF](manual-2-noor.sgf), [result](noor-result.png). First fixture and rank step recorded. |
| Ivo | Win by 21.5, 94 plies | Win by 1.5, 78 plies | [SGF](manual-3-ivo.sgf), [result](ivo-result.png). Second fixture; rank 28k, 2/5 complete, Lea next. |

The after games contain 10 player passes against Wren, six against Noor and five against Ivo. Wren's opponent continued after the first pass; the new explanation correctly says this is permitted and does not concede. Noor played five further stones after the first player pass; Ivo played four. I continued with simple local moves or another pass. This remains an endgame judgment problem for a beginner, even with clearer controls. Neither Help nor this report promises that an uncertain position is safe to pass.

[Actual final save](playthrough-save.json) retains four match records, the two novice fixtures and review payloads. It is also the declared fixture for `early_quay`. The main run was iterative: lesson marking, inspection, opening wording and pagination were corrected when observed, with a lesson restart. It is not presented as one uninterrupted run of a frozen final build. Final supplemental routes rechecked the changed presentation and branches. Tool delays and restarts are excluded from any claim about human pacing.

## 1. Writing

The best material is still physical and ordinary: Wren makes room among cups, Kesh wants another game, and the novice tables hold the things their occupants brought. Noor's wish for company gives the school route a modest personal purpose; the Cup can grow out of that. This follows the intended walk–talk–play loop without adding affection, schedules or another progression.

Noor's loss reaction and Ivo's loss reaction were seen after the manually played wins. Their win reactions were inspected separately after deliberate player resignations. They now speak before the review offer and do not immediately contradict a request for thinking time with a rematch menu. Normal game options return on the next interaction. Ivo did not repeat the first-meeting text. [Noor](noor-reaction.png), [Ivo](ivo-reaction.png), [Wren before review](wren-reaction.png), [issued-card acknowledgment](kesh-card-return.png).

Small writing fixes are complete: “extend” replaces joining stones already connected; Pip is recognized; the card is a provisional starting entry; quay directions say south past the park; novice banter introduces atari/ko in plain language. The machine limits and printed scripts were checked. These improvements should not be mistaken for proof that the story hook is now compelling to a new human player.

## 2. Progression

The most consequential change is teaching the finish before the full game. The 7×7 lesson visibly demonstrates an actual two-eye group and an inescapable stone, a useful boundary move, two passes, then editable scoring. It never equates fewer than two eyes with death. The prepared count is Black 6, White 2.5; toggling F3 changes the territory/prisoner preview and must be restored before confirmation. Tomás's separate example adds earlier prisoners and komi: Black 8, White 8.5.

[Retained board and explanation](lesson-board-visible.png), [marked count](count-marked.png), [unmarked comparison](count-unmarked.png), [component explanation](count-explanation.png), [Tomás's deeper count](tomas-count.png).

Hana's first class asks the player to distinguish genuine separate eyes from an apparent eye whose boundary can be captured. This applies the club idea instead of restarting capture instruction. The default route then goes to registration, the back-wall board and the lower-west novice door. A returning or experienced player can defer or skip the material; the optional arrival capture can be entered and left without being recorded as solved. [Hana class](hana-class.png), [skip route reaches registration](experienced-school-entry.png).

The honest progression remains worth preserving: Wren's loss did not block the card or school; optional Kesh practice did not move rank; losing all five novice fixtures still allowed the Cup in supplemental coverage. No fictitious lesson completions, replacement losses, or new win requirement were introduced.

**Remaining priority:** independently test whether a beginner can explain a dead mark in their own Wren ending, choose one useful late move, and say why they passed. A clean prepared example is not enough to establish that transfer. CONTENT-05 remains open for Wren's experience; ENG-09 records questionable stopping sequences separately from engine strength and ENG-05 dead-stone estimation.

## 3. Setting

The club and school now express different priorities without moving the named cast: Kesh wants the player back at the table; Hana asks what they want to understand; Noor wants company through a first league. The city, tram, rain, old board and optional practice remain the right foundation.

The novice room has a postcard, pencil, papers, repair materials and cushion in generated table art, with two seats per table and the same clear walking routes. This makes dialogue details visible, although their exact identities are easier to read enlarged than at native size. [Room](novice-room.png). The HUD makes the next step legible against both club and school backgrounds; after Ivo it reads the actual two completed fixtures and Lea next. [Progress](two-fixtures.png), [league help](league-help.png).

The manual harness required some doorway alignment attempts. That is not evidence of equivalent human control difficulty. The Pip return appeared at the street's attic-side spawn rather than precisely where the encounter began; this needs a focused return-position investigation before treating it as a navigation conclusion. It did not block the route. No additional lore panels were needed.

## 4. Controls, counting and review

Help is visible in Wren's actual game. A capture I could inspect was highlighted during the manual game; prepared supplemental positions separately verify own-atari and capture highlighting, modal input blocking and successful-action error clearing. The general fallback does not invent a group in trouble, including when ko prevents an apparent capture. [Capture Help](practice-capture-help.png), [atari Help](practice-atari-help.png), [old error cleared](practice-error-cleared.png).

The actual Wren count showed totals before acceptance. At Ivo's count, removing the proposed A8 dead mark reduced Black's preview by four points; restoring it restored the total. Manual overrides remained available. Proposed marks are not presented as authoritative life-and-death adjudication. [Wren count](wren-count.png).

The new completion order was observed in the world: accept score, record once, opponent reaction, optional review. Wren and Noor reviews completed in place; I left Ivo's loading panel with Escape. The completed Ivo analysis was later read at the quay from the actual saved record. The two comparison screens apply the played move and the engine preference independently to the original board. They do not play an invented reply or purport to demonstrate the engine's whole score judgment. [Played move](review-comparison-played.png), [engine preference](review-comparison-preferred.png), [complete recommendation page](review-recommendation.png).

**Remaining priority:** an engine can still prefer a move by tens of points while the immediate description says only that liberties changed. That gap is now honestly labeled, but it can remain hard to learn from. Test whether a beginner can name one usable idea after a review; do not infer usefulness from the existence of cards or matched-move counts.

## Supplemental coverage — automated, not beginner difficulty evidence

These routes use declared isolated saves, scripted navigation, direct map setup where stated, prepared boards, resignations and/or bot play. They establish branch and interface behavior, not newcomer wayfinding or human difficulty. Representative screenshots were opened, rather than treating exit status as sufficient evidence.

| Route | What passed |
|---|---|
| `early_lessons` | Four rules exercises, refusal feedback, finishing proofs, passing, count toggles, two opening comparisons; Wren Help and reaction. |
| `early_skips` | Escape during introduction; Wren return and explicit skips; actual Help on two prepared positions; occupied-move error cleared; Hana defer/return, optional capture cancellation, class skip; registration and disk reload preserve access. |
| `early_counting` | Tomás inspection, mark toggles, exact totals and completion. |
| `early_kesh` | Card, decline, reload, return; complete 74-ply bot practice, Black wins by 0.5, rank stays 30k. Review No, reload, later Yes, full analysis and close leave one result. Wren recognizes issued card. |
| `novice_losses` | Five resigned novice fixtures, Cup eligibility, four resigned Cup rounds, ending announcement before review, repeat novice attempt starts at zero. |
| `early_review_failure` | Hung and missing engines; leave/loading; reload interrupts old analysis; starting another match cancels it; real rematch adds exactly one new record. Review paths alone preserve results, rank and fixtures. |
| `early_quay` | Actual main-run Ivo payload, comparison boards, close and disk reload preserve four records, rank 28k and two fixtures. Direct map setup is not a wayfinding test. |
| `mouse_review_choice`, `mouse_review` | World-offer hover/keyboard/click, saved 19×19 review inspection, zoom, paging and close. |
| `early_exam_pass`, `early_exam_fail` | Saved final exam round, deliberate resignation, both completion outcomes before optional review; six results and eligibility preserved through reload. |

One early supplemental Kesh attempt passed twice on the initial five-stone handicap position and reached an overwhelming count with no player placements. It was not used as the required full practice game. The final 74-ply run supplies that coverage; the earlier behavior is logged for ENG-09 rather than silently discarded. Several supplemental scripts initially used stale choice assumptions, an old root-only review lookup, or an incorrect expected error string. These harness failures were corrected and rerun; they are not reported as game crashes or human failures.

## Verification and reproducibility

`tools/test.sh`: **16,730 passed, 0 failed**, **277 files load**, compile/import clean. Previous base: 16,242 checks and 260 loaded files. All three real KataGo gates passed. Review gate: 79/79 9×9 positions in 14.2 s; 241/241 19×19 positions in 59.4 s; stalled engine returned in 6.1 s. The final gate also includes the count regression: toggling an unrelated group cannot substitute for inspecting the proposed dead group. `tools/check_lessons.py`: zero problems. Generated maps validated. Printed dialogue and writing-rule checks passed. `git diff --check` passed. [Full gate log](verification/full-gates.log) and supplemental logs are retained in `verification/`.

Focused regressions cover legal/refused continuations, pass state, exact count totals, nonexistent/ko-blocked Help targets, connected-group deduplication including three groups, necessary first-line moves, unsupported safety claims, independent comparisons, pagination, old-save reconciliation and record-once review paths. Save cases include before Pip, partial Wren teaching, after Wren, before/after registration and completed novice fixtures. Completed quests, rank, records and fixture indices remain intact; no capture puzzle result is fabricated.

Run supplemental routes with a separate `XDG_DATA_HOME`, for example:

```bash
XDG_DATA_HOME="$HOME/.cache/ninepoint-review-verification" \
OUT="$HOME/.cache/ninepoint-review-shots" \
tools/run_game.sh tools/autopilot/early_lessons.json
```

All runs remain serial under the existing exclusive lock. Existing user progress was preserved. No opponent profile, strength, stopping policy, dead-stone estimator or Go scoring rule was changed. Save fields and lesson actions are additive; original single-move lessons retain their behavior. Existing shutdown ObjectDB/resource warnings were observed in some supplemental quits; no script errors occurred in the successful routes.

The original documentation and full milestone history, previous playtests, voice guide and documented Pokémon TCG, Tag Force, Hikaru no Go and HammerLock influences were read before the initial review. Historical intentions were separated from current behavior. Documentation knowledge did not count as information the player had received.

Independent beginner testing remains required for learning, pace, motivation, Wren's suitability and the novice rank labels. PROG-01's human gate remains open.
